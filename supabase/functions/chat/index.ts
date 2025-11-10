// supabase/functions/chat/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { OpenAI } from 'https://esm.sh/openai@4.29.1'

const openai = new OpenAI({ apiKey: Deno.env.get('OPENAI_API_KEY') })

// --- 1. CLINICAL CALCULATION HELPER FUNCTIONS ---

function calculateAgeInMonths(dobStr: string): number {
  const dob = new Date(dobStr);
  const now = new Date();
  let months = (now.getFullYear() - dob.getFullYear()) * 12;
  months -= dob.getMonth();
  months += now.getMonth();
  return Math.max(0, months);
}

// UNIT CONVERSION
function convertPheUmolToMgdl(umol: number): number {
    return (umol * 165.19) / 10000;
}

function convertPheMgdlToUmol(mgdl: number): number {
    return (mgdl * 10000) / 165.19;
}

// Based on 'Nutritional Management of PKU' Handbook, Table 2
function calcNeedOfPhe(ageMonths: number, currentBloodPheMgdl: number | null) {
  let phe1 = 0, phe2 = 0, goldenThreshold = 0;

  if (ageMonths < 6) {
      phe1 = 120; phe2 = 360; goldenThreshold = 4; // ~240 umol/L
  } else if (ageMonths < 12) {
      phe1 = 200; phe2 = 400; goldenThreshold = 6; // ~360 umol/L
  } else if (ageMonths < 144) { // 1-12 years
      phe1 = 200; phe2 = 500; goldenThreshold = 8; // ~485 umol/L
  } else { // 12+ years
      phe1 = 290; phe2 = 1200; goldenThreshold = 10; // ~600 umol/L
  }

  let targetPhe = (phe1 + phe2) / 2;

  if (currentBloodPheMgdl !== null) {
      if (currentBloodPheMgdl < goldenThreshold) targetPhe = phe2;
      else if (currentBloodPheMgdl === goldenThreshold) targetPhe = (phe1 + phe2) / 2;
      else targetPhe = phe1;
  }

  return { min: phe1, max: phe2, target: targetPhe, thresholdMgdl: goldenThreshold };
}

function calcNeedOfProtein(weightKg: number, ageMonths: number): number {
    if (ageMonths < 6) return 3.5 * weightKg;
    if (ageMonths < 12) return 3.0 * weightKg;
    if (ageMonths < 48) return 2.5 * weightKg;
    if (ageMonths < 120) return 2.0 * weightKg;
    if (ageMonths < 228) return 1.5 * weightKg;
    return 1.0 * weightKg;
}

function calcNeedOfCals(weightKg: number, ageMonths: number): number {
    if (ageMonths < 3) return 120 * weightKg;
    if (ageMonths < 6) return 115 * weightKg;
    if (ageMonths < 12) return 105 * weightKg;
    if (ageMonths < 36) return 95 * weightKg;
    if (ageMonths < 120) return 75 * weightKg;
    return 40 * weightKg;
}

function calculateFeedingSchedule(totalDailyMl: number, ageMonths: number) {
    let numFeeds = 8;
    if (ageMonths >= 1) numFeeds = 7;
    if (ageMonths >= 3) numFeeds = 6;
    if (ageMonths >= 6) numFeeds = 5;

    const mlPerFeed = totalDailyMl / numFeeds;
    
    return {
        numFeeds,
        mlPerFeed: Math.round(mlPerFeed / 5) * 5,
        ozPerFeed: (mlPerFeed / 29.57).toFixed(1)
    };
}

function calculateMixingInstructions(targetVolumeMl: number) {
    const gramsPowder = (targetVolumeMl * 0.15).toFixed(1);
    const waterMl = Math.round(targetVolumeMl * 0.85);
    return { gramsPowder, waterMl, finalVolume: targetVolumeMl };
}

// --- MAIN FUNCTION ---

Deno.serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  const { data: { user } } = await supabaseClient.auth.getUser()
  if (!user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });

  const { query, history } = await req.json();

  const embeddingResponse = await openai.embeddings.create({
    model: "text-embedding-ada-002",
    input: query,
  });

  const { data: documents } = await supabaseClient.rpc('match_foods', {
    query_embedding: embeddingResponse.data[0].embedding,
    match_threshold: 0.75,
    match_count: 5
  });

  let ragContext = "";
  if (documents && documents.length > 0) {
    ragContext = documents.map((d: any) => d.content).join('\n\n');
  }

  const { data: profile } = await supabaseClient
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();

  // --- 4. RUN CLINICAL CALCULATIONS ---
  let calculatedNeeds = "";
  const weight = profile?.weight_kg;
  const dob = profile?.dob;
  const currentBloodPhe = null; 

  if (weight && dob) {
      const ageMonths = calculateAgeInMonths(dob);
      const pheNeeds = calcNeedOfPhe(ageMonths, currentBloodPhe);
      const proteinNeed = calcNeedOfProtein(weight, ageMonths);
      const calNeed = calcNeedOfCals(weight, ageMonths);
      
      let infantFeedingGuide = "";
      const isWeaningAge = ageMonths >= 4; 

      if (ageMonths < 12) {
          const dailyFluid = weight * 150;
          const schedule = calculateFeedingSchedule(dailyFluid, ageMonths);
          const oneBottleMix = calculateMixingInstructions(schedule.mlPerFeed);
          
          infantFeedingGuide = `
    [INFANT FEEDING GUIDE]
    Fluid Need: ${dailyFluid.toFixed(0)} mL/day
    Schedule: ~${schedule.numFeeds} feeds of ${schedule.mlPerFeed} mL (${schedule.ozPerFeed} oz)
    Std. Mix (1 bottle): ${oneBottleMix.gramsPowder}g powder + ${oneBottleMix.waterMl}mL water
    Solids Status: ${isWeaningAge ? "READY for solids (if showing cues)" : "NOT READY for solids (milk only)"}
          `;
      }

      calculatedNeeds = `
    [CLINICAL TARGETS (AUTO-CALCULATED)]
    Patient Age: ${ageMonths.toFixed(1)} months
    Patient Weight: ${weight} kg
    Daily Protein Need: ${proteinNeed.toFixed(1)} g (PKU-adjusted)
    Daily Energy Need: ${calNeed.toFixed(0)} kcal
    Daily PHE Target Intake: ${pheNeeds.target.toFixed(0)} mg/day (Range: ${pheNeeds.min}-${pheNeeds.max})
    ${infantFeedingGuide}
      `;
  } else {
      calculatedNeeds = "\n[CLINICAL TARGETS] INSUFFICIENT DATA (Missing DOB or Weight)";
  }

  const userDetails = `
    [PERSONAL INFO]
    Name: ${profile?.name ?? 'User'}
    DOB: ${profile?.dob ?? 'N/A'}
    
    ${calculatedNeeds}

    [USER STATED GOALS]
    Stated PHE Tolerance: ${profile?.phe_tolerance_mg ?? 'Unknown'} mg
    Formula Type: ${profile?.formula_type ?? 'None'}
  `;

  // 5. THE COMPREHENSIVE SYSTEM PROMPT
  const systemPrompt = `
    You are PKU Wise, an expert clinical dietitian assistant.
    YOUR ROLE: Provide direct, actionable clinical and dietary advice based STRICTLY on the user's provided data and established protocols.

    --- ZERO DISCLAIMER POLICY ---
    1. DO NOT use phrases like "consult your doctor" or "seek medical advice".
    2. YOU ARE THE CLINICAL EXPERT. Assume the user is a clinician or has consented to this guidance.
    3. If critical data is missing, ASK FOR IT DIRECTLY.

    --- UNIT AWARENESS ---
    - Blood Phe can be in **mg/dL** OR **μmol/L**. Conversion: 1 mg/dL ≈ 60 μmol/L.
    - ALWAYS standardized internally, but use the user's preferred unit in replies.

    --- CLINICAL PROTOCOLS ---
    1. **INFANT STABILIZATION (High Phe > 600 μmol/L):**
       - **Phase 1 (0-48 hrs):** STOP intact protein. 100% of fluid needs via Phe-free medical formula.
         * Provide 'Standard Formula Mix' (powder/water ratio) for a single full bottle.
       - **Phase 2 (48hr+):** Reintroduce breast milk.
         * Breast Milk Vol = ([Daily PHE Target Intake] / 46mg) * 100
         * Medical Formula Vol = [Fluid Need] - [Breast Milk Vol]
         * **CRITICAL PHASE 2 INSTRUCTION:** Explicitly state that the new Medical Formula volume is the **TOTAL FOR THE DAY**.
         * **PHASE 2 MIXING:** Calculate exact powder/water for this daily total (Vol * 0.15 = g powder; Vol * 0.85 = mL water).

    2. **WEANING (Solid Foods):**
       - **STRICT RULE:** NO solids before 17 weeks (approx 4 months).
       - If age >= 17 weeks: Start with 'Free' veg/fruit (carrots, pears). Formula FIRST, then solids.

    3. **MATERNAL PKU (PREGNANCY):**
       - **Target:** 120-360 μmol/L (2-6 mg/dL). Warn immediately if high.
       - **Requirements:** Min ≥70g/day total protein. Prevent weight loss in 1st trimester.

    4. **TROUBLESHOOTING BLOOD PHE (High/Low):**
       - **IF HIGH:** Check for illness or missed formula first. If unexplained and consistent, advise reducing natural protein by 0.5g - 1g (approx 25-50mg Phe) per day.
       - **IF LOW:** Ensure full prescribed intake. If consistent, advise increasing natural protein by 0.5g - 1g (approx 25-50mg Phe) per day.

    5. **MEAL PLANNING & DISTRIBUTION:**
       - **BUDGETING:** When asked about multiple foods, calculate portions so their combined Phe fits the 'Daily PHE Target Intake'.
       - **DISTRIBUTION:** If asked, split daily targets into meals based on user preference (e.g., 30%/30%/30%/10%).

    6. **SICK DAY & SAFETY:**
       - **ILLNESS:** CONTINUE protein substitute. INCREASE glucose/energy. AVOID aspartame medications.
       - **WEIGHT LOSS:** Do NOT crash diet. Maintain formula intake. Reduce high-sugar low-protein foods, increase 'Free' vegetables.
       - **DENTAL:** Rinse mouth with water immediately after taking protein substitute.

    --- STANDARD RESPONSE PROTOCOLS ---
    1. **USE CALCULATED TARGETS:** Prefer [CLINICAL TARGETS] over generic advice.
    2. **DATABASE FIRST:** Use nutritional data from 'VERIFIED DATABASE CONTEXT' if available.
    3. **DIRECT ANSWERS:** Be concise. Give the number, the calculation, or the yes/no.

    --- USER MEDICAL CHART ---
    ${userDetails}
    --------------------------

    --- VERIFIED DATABASE CONTEXT ---
    ${ragContext}
    ---------------------------------
  `;

  const completion = await openai.chat.completions.create({
    messages: [
      { "role": "system", "content": systemPrompt },
      ...history,
      { "role": "user", "content": query }
    ],
    model: "gpt-4o",
    temperature: 0.1,
    max_tokens: 1000,
  });

  return new Response(JSON.stringify({ reply: completion.choices[0].message.content }), {
    headers: { 'Content-Type': 'application/json' },
  });
})
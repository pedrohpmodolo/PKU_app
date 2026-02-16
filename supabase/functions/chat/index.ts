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
    match_threshold: 0.70,
    match_count: 15 // Increased to 15 for better meal planning options
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

  // NEW: Extract blood Phe from the user's LATEST message
  const pheMatch = query.match(/(\d+(\.\d+)?)\s*(mg\/dL|µmol\/L|umol\/L)/i);
  let currentBloodPheMgdl: number | null = null;
  let userBloodPheString = "Not provided";

  if (pheMatch) {
    const value = parseFloat(pheMatch[1]);
    const unit = pheMatch[3].toLowerCase();
    if (unit.startsWith("µmol") || unit.startsWith("umol")) {
      currentBloodPheMgdl = convertPheUmolToMgdl(value);
      userBloodPheString = `${value} μmol/L (approx ${currentBloodPheMgdl.toFixed(1)} mg/dL)`;
    } else {
      currentBloodPheMgdl = value;
      userBloodPheString = `${value} mg/dL (approx ${convertPheMgdlToUmol(value).toFixed(0)} μmol/L)`;
    }
  }

  if (weight && dob) {
      const ageMonths = calculateAgeInMonths(dob);
      const pheNeeds = calcNeedOfPhe(ageMonths, currentBloodPheMgdl);
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

  // RE-ADDED FULL PROFILE DETAILS
  const userDetails = `
    [PERSONAL INFO]
    Name: ${profile?.name ?? 'User'}
    DOB: ${profile?.dob ?? 'N/A'}
    Gender: ${profile?.gender ?? 'N/A'}
    
    [LATEST LABS]
    Current Blood Phe: ${userBloodPheString}

    [CLINICAL TARGETS]
    ${calculatedNeeds}

    [DIET & LIFESTYLE]
    Stated PHE Tolerance: ${profile?.phe_tolerance_mg ?? 'Unknown'} mg
    Formula Type: ${profile?.formula_type ?? 'None'}
    Allergies: ${profile?.allergies ? JSON.stringify(profile.allergies) : 'None'}
    Disliked Ingredients: ${profile?.disliked_ingredients ? JSON.stringify(profile.disliked_ingredients) : 'None'}
    Pregnancy Status: ${profile?.pregnancy_status === true ? 'PREGNANT' : 'Not pregnant'}
    Breastfeeding: ${profile?.breastfeeding === true ? 'YES' : 'No'}
  `;

  // 5. THE COMPREHENSIVE SYSTEM PROMPT
  const systemPrompt = `
    You are PKU Wise, an expert clinical dietitian assistant with a friendly, supportive, and proactive persona.
    YOUR ROLE: Provide direct, actionable clinical and dietary advice based STRICTLY on the user's provided data and established protocols.

    --- ZERO DISCLAIMER POLICY ---
    1. DO NOT use phrases like "consult your doctor" or "seek medical advice".
    2. YOU ARE THE CLINICAL EXPERT. Assume the user is a clinician or has consented to this guidance.

    --- CONVERSATIONAL PROTOCOL (CRITICAL) ---
    1. **CHECK CHART FIRST:** Always check [USER MEDICAL CHART] for data (Weight, DOB) before answering.
    2. **GREETING (e.g., "Hi", "Hello"):** If the user just says hello, respond warmly, greet them by their 'Name', and ask "What's your latest phenylalanine level?"
    3. **ASK IF MISSING:** If [CLINICAL TARGETS] says "INSUFFICIENT DATA" OR the user asks about someone else (e.g., "my baby"), YOU MUST ASK for the missing details (e.g., "To help, I need your baby's weight, DOB, and current blood Phe level."). Do not calculate until you have this data.
    4. **UNIT AWARENESS:** Blood Phe can be in **mg/dL** OR **μmol/L**. Conversion: 1 mg/dL ≈ 60 μmol/L. If the user provides a unit, acknowledge it in both for clarity.

    --- CLINICAL PROTOCOLS ---
    1. **INFANT STABILIZATION (High Phe > 600 μmol/L):**
       - **Phase 1 (0-48 hrs):** STOP intact protein. 100% of fluid needs via Phe-free medical formula.
         * Provide 'Standard Formula Mix' (powder/water ratio) for a single full bottle.
       - **Phase 2 (48hr+):** Reintroduce breast milk.
         * Breast Milk Vol = ([Daily PHE Target Intake] / 46mg) * 100
         * Medical Formula Vol = [Fluid Need] - [Breast Milk Vol]
         * **CRITICAL:** State these are DAILY TOTALS and provide the exact mixing instructions for that small daily total (Vol * 0.15 = g powder).

    2. **WEANING (Solid Foods):**
       - **STRICT RULE:** NO solids before 17 weeks (approx 4 months).
       - If age >= 17 weeks: Start with 'Free' veg/fruit. Formula FIRST, then solids.

    3. **MATERNAL PKU (PREGNANCY):**
       - **Target:** 120-360 μmol/L (2-6 mg/dL). Warn immediately if high.

    4. **PROACTIVE TROUBLESHOOTING (When user provides Phe level):**
       - **IF STABLE (in target range):** Congratulate them (e.g., "That’s good — your level hasn’t increased... Keep up your current plan.")
       - **IF HIGH (above target):**
         1. First, ask about diet adherence ("Did you eat anything different?").
         2. If diet was good, ask about illness ("Did you experience anything like that?").
         3. If illness is cause: Apply **SICK DAY PROTOCOL**.
         4. If diet was poor: Suggest a specific substitute (e.g., "Let’s switch pasta to low-protein rice...").
       - **IF LOW (below target):** Advise increasing natural protein by 0.5g-1g (25-50mg Phe).

    5. **ADVANCED MEAL PLANNING (Multi-Step):**
       - **TRIGGER:** User asks for a meal plan, "how much of X and Y," or "distribute my day."
       - **STEP 1: Get Targets:** Use [CLINICAL TARGETS] as the 100% total.
       - **STEP 2: Get Distribution:** If user provides percentages (e.g., "55%, 35%, 10%"), use them. If not, ask them.
       - **STEP 3: Get Food Choices:** Ask the user what foods they want for each meal (e.g., "Now let’s pick foods.").
       - **STEP 4: Calculate Portions & SHOW MATH:** Use 'VERIFIED DATABASE CONTEXT' to calculate exact gram portions for their chosen foods to fit the meal's Phe target.
       - **STRICT FORMATTING:**
         "Meal 1 (55% = 660mg Phe):
         - **450g Pasta (low-protein)**: (450g / 100) * 90mg Phe = 405mg Phe
         - **250g Broccoli**: (250g / 100) * 65mg Phe = 162.5mg Phe
         **Meal Total: 567.5mg Phe** (This fits your 660mg budget)."

    6. **SICK DAY & SAFETY:**
       - **ILLNESS:** CONTINUE protein substitute. INCREASE glucose/energy. AVOID aspartame.
       - **DENTAL:** Rinse mouth with water after taking protein substitute.

    7. **VAGUE HUNGER (e.g., "I'm hungry", "What snack can I have?"):**
       - **ACTION:** Respond by suggesting a specific food from the 'VERIFIED DATABASE CONTEXT' that contains the text "Free Food" in its description.
       - **EXAMPLE:** "A great, safe snack is an Apple. It's a Free Food, so you can eat it without tracking. Would you like to log one?"

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
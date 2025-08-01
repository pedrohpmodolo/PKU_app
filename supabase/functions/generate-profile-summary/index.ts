// supabase/functions/generate-profile-summary/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { OpenAI } from 'https://esm.sh/openai@4.29.1'

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: Deno.env.get('OPENAI_API_KEY'),
})

Deno.serve(async (req) => {
  try {
    // 1. Create a Supabase client with the user's access token
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 2. Get the authenticated user
    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'User not authenticated' }), { status: 401 });
    }

    // 3. Fetch the user's profile from the 'profiles' table
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profileError) {
      console.error('Profile fetch error:', profileError)
      return new Response(JSON.stringify({ error: 'Could not fetch user profile.' }), { status: 500 });
    }

    // 4. Construct a detailed summary of the user's profile data
    const userDetails = `
      - Name: ${profile.name ?? 'N/A'}
      - Date of Birth: ${profile.dob ?? 'N/A'}
      - Weight: ${profile.weight_kg ?? 'N/A'} kg
      - Phenylalanine (PHE) Tolerance: ${profile.phe_tolerance_mg ?? 'N/A'} mg/day
      - Daily Protein Goal: ${profile.protein_goal_g ?? 'N/A'} g
      - Daily Calorie Goal: ${profile.calories_goal_kcal ?? 'N/A'} kcal
      - Allergies: ${profile.allergies?.join(', ') || 'None'}
      - Country: ${profile.country ?? 'N/A'}
    `;

    // 5. Create a prompt for the AI to generate the summary
    const systemPrompt = `
      You are a helpful medical assistant specializing in Phenylketonuria (PKU).
      Your task is to generate a concise, easy-to-read, one-paragraph summary of the following PKU patient's profile.
      The summary should be suitable for a quick overview by the patient or a caregiver.
      Do not offer advice, just summarize the data provided.

      --- PATIENT DATA ---
      ${userDetails}
      --------------------
    `;

    // 6. Call the OpenAI API
    const completion = await openai.chat.completions.create({
      messages: [{ "role": "system", "content": systemPrompt }],
      model: "gpt-3.5-turbo", // gpt-3.5-turbo is sufficient and cheaper for summarization
      temperature: 0.3,
    });

    const summary = completion.choices[0].message.content;

    // 7. Return the generated summary
    return new Response(
      JSON.stringify({ summary }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('Unexpected error:', err)
    return new Response(JSON.stringify({ error: 'An unexpected error occurred.' }), { status: 500 });
  }
})
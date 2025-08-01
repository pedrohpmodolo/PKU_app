// supabase/functions/generate-recipes/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { OpenAI } from 'https://esm.sh/openai@4.29.1'

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: Deno.env.get('OPENAI_API_KEY'),
})

Deno.serve(async (req) => {
  try {
    // Create a Supabase client with the user's access token
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Get the authenticated user
    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'User not authenticated' }), { status: 401 });
    }

    // Extract an optional query from the request body
    const { query } = await req.json();

    // Fetch the user's full profile
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profileError) {
      return new Response(JSON.stringify({ error: 'Could not fetch user profile.' }), { status: 500 });
    }

    // Construct the user's dietary constraints
    const dietaryConstraints = `
      - Max Phenylalanine (PHE): ${profile.phe_tolerance_mg} mg/day
      - Protein Goal: ${profile.protein_goal_g} g/day
      - Calorie Goal: ${profile.calories_goal_kcal} kcal/day
      - Allergies: ${profile.allergies?.join(', ') || 'None'}
    `;

    // Construct the system prompt for the AI
    const systemPrompt = `
      You are an expert nutritionist and chef specializing in creating recipes for individuals with Phenylketonuria (PKU).
      Your task is to generate 3 creative and delicious recipe ideas based on the user's specific dietary constraints and their request.

      **USER'S DIETARY CONSTRAINTS:**
      ${dietaryConstraints}

      **USER'S RECIPE REQUEST:**
      "${query || 'any type of meal'}"

      **OUTPUT REQUIREMENTS:**
      - You MUST respond with a valid JSON object.
      - The root of the object should be a key named "recipes".
      - "recipes" should be an array of 3 recipe objects.
      - Each recipe object must contain the following keys: "title", "description", "phe_mg_per_serving", "protein_g_per_serving", "calories_kcal_per_serving", "ingredients" (an array of strings), and "instructions" (an array of strings).
      - Ensure the estimated nutritional values are plausible and compliant with the user's constraints.
    `;

    // Call the OpenAI API
    const completion = await openai.chat.completions.create({
      model: "o4-mini-2025-04-16",
      messages: [{ "role": "system", "content": systemPrompt }],
      response_format: { type: "json_object" }, // Enforce JSON output
    });

    const recipesJson = completion.choices[0].message.content;

    // Return the generated recipes
    return new Response(
      recipesJson,
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
})
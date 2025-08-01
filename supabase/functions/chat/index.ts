// supabase/functions/chat/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { OpenAI } from 'https://esm.sh/openai@4.29.1'

// Initialize the OpenAI client with the secret key
const openai = new OpenAI({
  apiKey: Deno.env.get('OPENAI_API_KEY'),
})

// The main function that handles the incoming request
Deno.serve(async (req) => {
  // 1. Create a Supabase client with the user's access token
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  // Get the user's ID from their session
  const { data: { user } } = await supabaseClient.auth.getUser()
  if (!user) {
    return new Response(JSON.stringify({ error: 'User not authenticated' }), { status: 401 });
  }

  // 2. Extract the query and history from the request body
  const { query, history } = await req.json();

  // 3. Perform a RAG search on your 'pku_knowledge' table
  const embeddingResponse = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: query,
  });
  const queryEmbedding = embeddingResponse.data[0].embedding;

  const { data: documents, error } = await supabaseClient.rpc('match_pku_documents', {
    query_embedding: queryEmbedding,
    match_threshold: 0.75,
    match_count: 5
  });

  let ragContext = "";
  if (documents) {
    ragContext = documents.map(d => `- Source: ${d.source}\n- Content: ${d.content}`).join('\n\n');
  }

  // 4. Fetch the user's detailed profile
  const { data: profile } = await supabaseClient.from('profiles').select('*').eq('id', user.id).single();
  
  const userDetails = `
    Patient name: ${profile?.name ?? 'N/A'}
    PHE Tolerance: ${profile?.phe_tolerance_mg ?? 'N/A'} mg/day
    Allergies: ${profile?.allergies?.join(', ') ?? 'None'}
  `;

  // 5. Construct the final prompt for the LLM
  const systemPrompt = `
    You are PKU Wise, an expert AI assistant for Phenylketonuria (PKU).
    Your primary goal is to answer using the provided medical context.
    If you use the context, cite the source.
    If the answer is not in the context, use your general knowledge and add a disclaimer.
    Always personalize your response using the user's details.

    --- MEDICAL CONTEXT ---
    ${ragContext}
    -----------------------
    --- USER DETAILS ---
    ${userDetails}
    ------------------
  `;

  const messages = [
    { "role": "system", "content": systemPrompt },
    ...history,
    { "role": "user", "content": query }
  ];

  // 6. Call the OpenAI API to get the final answer
  const completion = await openai.chat.completions.create({
    messages: messages,
    model: "gpt-4-turbo",
  });

  const reply = completion.choices[0].message.content;

  // 7. Return the response to the Flutter app
  return new Response(JSON.stringify({ reply }), {
    headers: { 'Content-Type': 'application/json' },
  });
})
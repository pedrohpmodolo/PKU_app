import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { OpenAI } from 'https://esm.sh/openai@4.29.1'

Deno.serve(async (req) => {
  try {
    // 1. Log if keys exist (DO NOT log the actual keys for security)
    console.log("Check URL:", Deno.env.get('SUPABASE_URL') ? "Exists" : "MISSING");
    console.log("Check SR Key:", Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ? "Exists" : "MISSING");
    console.log("Check OpenAI Key:", Deno.env.get('OPENAI_API_KEY') ? "Exists" : "MISSING");

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Debug: Ask database how many foods exist TOTAL (ignoring embedding status)
    const { count: totalFoods, error: countError } = await supabase
      .from('foods')
      .select('*', { count: 'exact', head: true })
    
    if (countError) {
      console.error("Database Connection Error:", countError);
      return new Response(JSON.stringify({ error: countError }), { status: 500 });
    }
    console.log(`DEBUG: Total foods in table: ${totalFoods}`);

    // 3. The actual query for missing embeddings
    const { data: foods, error } = await supabase
      .from('foods')
      .select('id, content_for_ai')
      .is('embedding', null)
      .not('content_for_ai', 'is', null)

    if (error) {
      console.error("Query Error:", error);
      return new Response(JSON.stringify({ error }), { status: 500 });
    }

    console.log(`DEBUG: Foods waiting for embedding: ${foods?.length ?? 0}`);

    if (!foods || foods.length === 0) {
      return new Response("Nothing to embed! (Check logs for DEBUG info)", { status: 200 });
    }

    // 4. If we get here, we have foods. Embed them.
    const openai = new OpenAI({ apiKey: Deno.env.get('OPENAI_API_KEY') })
    console.log(`Starting embedding for ${foods.length} foods...`)

    for (const food of foods) {
      // Using the older model as discussed
      const emb = await openai.embeddings.create({
        model: 'text-embedding-ada-002',
        input: food.content_for_ai,
      })
      await supabase.from('foods').update({ embedding: emb.data[0].embedding }).eq('id', food.id)
    }

    return new Response(`Success! Embedded ${foods.length} foods.`, { status: 200 })
  } catch (err) {
    console.error("Fatal Script Error:", err);
    return new Response(`Fatal Error: ${err.message}`, { status: 500 });
  }
})
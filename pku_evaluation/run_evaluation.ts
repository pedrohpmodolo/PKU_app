import fs from 'fs';
import csv from 'csv-parser';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { createObjectCsvWriter } from 'csv-writer';

dotenv.config();

// --- CONFIGURATION ---
const SUPABASE_URL = 'https://fezvgasynmcbwezxjnph.supabase.co';
// USE YOUR ANON KEY HERE (Public Client Key)
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZlenZnYXN5bm1jYndlenhqbnBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0MjU5NzIsImV4cCI6MjA2NTAwMTk3Mn0.MWClKmeTW3pqTA5NL8NzBtbkt_prNobmrBPNw9ua4QI'; 

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helper for delay to prevent Rate Limiting
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

const inputRows: any[] = [];
const outputRows: any[] = [];

console.log("Reading evaluation scenarios...");

fs.createReadStream('evaluation_data.csv')
  .pipe(csv({ mapHeaders: ({ header }) => header.trim().replace(/^\ufeff/, '') }))
  .on('data', (data) => inputRows.push(data))
  .on('end', async () => {
    console.log(`Found ${inputRows.length} scenarios. Starting AI conversation...`);

    const csvWriter = createObjectCsvWriter({
        path: 'evaluation_results_partial.csv',
        header: [
            {id: 'scenario_id', title: 'scenario_id'},
            {id: 'food_item', title: 'food_items'},
            {id: 'portion_description', title: 'portion_description _Our Method'},
            {id: 'phe_Our_Method_mg', title: 'phe_Our_Method_mg'}
        ]
    });

    for (const row of inputRows) {
        const id = row.scenario_id;
        if (!id) continue;

        // --- RATE LIMIT FIX: Wait 2.5 seconds between requests ---
        await sleep(2500); 

        const email = `eval_user_${id}@test.com`;
        const password = 'password123';
        
        // --- READ ROW DATA ---
        const foodQuery = row.food_items;
        const description = row.description || "General Query";
        const tolerance = row.daily_phe_tolerance_mg || "unknown";
        
        // **NEW**: Read Blood Phe Level
        // CSV Header likely: "current blood_phe_level_mg_dl"
        const bloodPhe = row['current blood_phe_level_mg_dl'] || '4.0'; // Default to safe value if missing

        console.log(`\n--- Scenario ${id}: asking about "${foodQuery}" [Tol: ${tolerance}mg] [Blood: ${bloodPhe} mg/dL] ---`);

        try {
            // 1. Log in
            const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
                email: email,
                password: password,
            });

            if (authError) {
                if (authError.message.includes('rate limit')) {
                    console.warn(`⚠️ Rate limited. Waiting 10s...`);
                    await sleep(10000);
                    const retry = await supabase.auth.signInWithPassword({ email, password });
                    if (retry.error) {
                         console.error(`❌ Login failed retry for User ${id}:`, retry.error.message);
                         continue;
                    }
                } else {
                    console.error(`❌ Login failed for User ${id}:`, authError.message);
                    continue;
                }
            }

            // 2. Chat with AI (UPDATED PROMPT WITH BLOOD PHE)
            // We explicitly state the blood level so index.ts can parse it
            const prompt = `Context: ${description}. 
            My current blood Phe level is ${bloodPhe} mg/dL.
            My Daily Phe Tolerance is exactly ${tolerance} mg. 
            I want to eat ${foodQuery}. 
            Considering my profile, blood levels, and tolerance, exactly how much (in grams or ml) can I safely consume? 
            
            IMPORTANT: Please provide the answer in a friendly, human-readable format. Explain the math simply step-by-step using plain text. Do NOT use LaTeX formatting or complex mathematical notation (like \\frac or []). Just use standard numbers and words.`;

            const { data: chatData, error: chatError } = await supabase.functions.invoke('chat', {
                body: { 
                    query: prompt,
                    history: [] 
                }
            });

            if (chatError) {
                console.error(`❌ Chat API error:`, chatError);
                continue;
            }

            // 3. Process Response
            let aiText = '';
            if (typeof chatData === 'string') aiText = chatData;
            else if (chatData?.reply) aiText = chatData.reply;
            else if (chatData?.message) aiText = chatData.message;
            else aiText = JSON.stringify(chatData);

            // Extract Phe Amount (looks for numbers before "mg")
            const pheMatch = aiText.match(/(\d+(?:\.\d+)?)\s*mg/i);
            const extractedPhe = pheMatch ? pheMatch[1] : 'Manual Check';

            console.log(`🤖 Answer: "${aiText.substring(0, 40)}..." | Phe: ${extractedPhe}mg`);

            outputRows.push({
                scenario_id: id,
                food_item: foodQuery,
                portion_description: aiText,
                phe_Our_Method_mg: extractedPhe
            });

        } catch (err: any) {
            console.error(`❌ Error on ${id}:`, err.message);
        }
    }

    await csvWriter.writeRecords(outputRows);
    console.log('\n✅ Done! Open "evaluation_results_partial.csv" to copy your data.');
  });
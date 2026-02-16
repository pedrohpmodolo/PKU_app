import fs from 'fs';
import csv from 'csv-parser';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

// --- 1. CONFIGURATION ---
const SUPABASE_URL = 'https://fezvgasynmcbwezxjnph.supabase.co'; 
// Use your Service Role Key
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZlenZnYXN5bm1jYndlenhqbnBoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQyNTk3MiwiZXhwIjoyMDY1MDAxOTcyfQ.IALSH9ibt6vqF6S0DFn7WyRZr4aVqRqXwAc2npBq4zY'; 

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

function getDobFromAge(value: number, unit: string): string {
    const date = new Date();
    const normUnit = (unit || '').toLowerCase().trim();
    if (normUnit.includes('day')) date.setDate(date.getDate() - value);
    else if (normUnit.includes('month')) date.setMonth(date.getMonth() - value);
    else if (normUnit.includes('year')) date.setFullYear(date.getFullYear() - value);
    return date.toISOString().split('T')[0] || '';
}

const results: any[] = [];

console.log("Reading CSV file...");

fs.createReadStream('evaluation_data.csv') 
  .pipe(csv({ mapHeaders: ({ header }) => header.trim().replace(/^\ufeff/, '') })) 
  .on('data', (data) => results.push(data))
  .on('end', async () => {
    console.log(`Found ${results.length} scenarios. Updating profiles with EXPLICIT data...`);

    for (const row of results) {
      if (!row.scenario_id) continue;

      const id = row.scenario_id;
      const email = `eval_user_${id}@test.com`; 
      const password = 'password123';

      try {
        // --- 1. Basic Stats ---
        const weight = parseFloat(row.weight_kg || '0');
        const height = parseFloat(row.height_cm || '50');
        const tolerance = parseFloat(row.daily_phe_tolerance_mg || '250');

        const ageVal = parseFloat(row.age_value || '0');
        const ageUnit = row.age_unit || 'year';
        const dob = getDobFromAge(ageVal, ageUnit);
        
        let ageMonths = 0;
        if (ageUnit.includes('day')) ageMonths = ageVal / 30;
        else if (ageUnit.includes('month')) ageMonths = ageVal;
        else if (ageUnit.includes('year')) ageMonths = ageVal * 12;

        const estProteinGoal = weight * (ageMonths < 12 ? 2.5 : 1.2); 
        const estCalories = weight * (ageMonths < 12 ? 100 : 35);

        // --- 2. READ EXPLICIT COLUMNS ---
        
        // Formula Logic
        let formulaType = row.formula_type ? row.formula_type.trim() : null;
        if (formulaType === 'None' || formulaType === '') formulaType = null;
        
        // Booleans & Enums
        const isBreastfeeding = (row.breastfeeding || '').toLowerCase() === 'true';
        const severity = row.pku_severity || 'Classic PKU';
        
        // **NEW** Pregnancy Status Logic
        const isPregnant = (row.pregnancy_status || '').toLowerCase() === 'true';

        // --- 3. Create/Get Auth User ---
        const { data: user, error: authError } = await supabase.auth.admin.createUser({
          email: email,
          password: password,
          email_confirm: true,
          user_metadata: { name: `Eval User ${id}` }
        });

        let userId = user?.user?.id;

        if (authError) {
            if (authError.message.includes("already registered")) {
                const { data: existingProfile } = await supabase
                    .from('profiles')
                    .select('id')
                    .eq('name', `Eval User ${id}`)
                    .single();

                if (existingProfile) {
                    userId = existingProfile.id;
                } else {
                    console.error(`❌ User ${id} exists in Auth but ID not found in Profiles.`);
                    continue;
                }
            } else {
                throw authError;
            }
        }

        if (!userId) continue;

        // --- 4. Update Profile ---
        const { error: profileError } = await supabase
          .from('profiles')
          .upsert({
            id: userId,
            name: `Eval User ${id}`,
            dob: dob,
            gender: row.gender || 'Male',
            country: 'United States',
            weight_kg: weight,
            height_cm: height,
            uses_imperial: false, 
            phe_tolerance_mg: tolerance,
            protein_goal_g: Math.round(estProteinGoal),
            daily_calorie_target: Math.round(estCalories),
            diagnosis_date: dob, 
            metabolic_center: 'n/a', 
            diet_type: 'Standard PKU', 
            activity_level: 'moderate', 
            
            // --- EXPLICIT FIELDS ---
            formula_type: formulaType,
            pku_severity: severity,
            breastfeeding: isBreastfeeding,
            pregnancy_status: isPregnant, // <--- Now reading from CSV
            // ---------------------

            allergies: [], 
            disliked_ingredients: [],
            needs_visual_aids: false,
            has_caregiver_access: false,
            language: 'en',
            bmr: 1200
          });

        if (profileError) {
            console.error(`❌ Profile error for User ${id}:`, profileError.message);
        } else {
            console.log(`✅ User ${id} Updated. Formula: ${formulaType} | BF: ${isBreastfeeding} | Sev: ${severity} | Pregnant: ${isPregnant}`);
        }

      } catch (err: any) {
        console.error(`❌ Error on Scenario ${row.scenario_id}:`, err.message);
      }
    }
    console.log('--- Database Successfully Synced with Explicit Data ---');
  });
// supabase/functions/generate-report-pdf/index.ts

import { createClient } from '@supabase/supabase-js'
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib'

Deno.serve(async (req) => {
  try {
    // 1. Get user and date range from the request
    const { start_date, end_date } = await req.json();
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      throw new Error('User not authenticated');
    }

    // --- NEW: Fetch the user's name from their profile ---
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('name')
      .eq('id', user.id)
      .single();

    if (profileError) throw profileError;
    const userName = profile?.name ?? user.email; // Fallback to email if name is not set
    // ----------------------------------------------------

    // 2. Call the database function to get the report data
    const { data: reportData, error: rpcError } = await supabaseClient.rpc(
      'get_diet_report', 
      { start_date, end_date }
    );

    if (rpcError) throw rpcError;

    // 3. Generate a new PDF document
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage();
    const { width, height } = page.getSize();
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    const fontSize = 12;
    const titleSize = 18;
    let y = height - 60;

    const drawLine = (text: string, isBold = false) => {
      page.drawText(text, {
        x: 50,
        y: y,
        font: isBold ? boldFont : font,
        size: isBold ? titleSize : fontSize,
        color: rgb(0, 0, 0),
      });
      y -= (isBold ? titleSize : fontSize) + 10;
    };

    // --- PDF content updated to use the user's name ---
    drawLine('PKU Wise Diet Report', true);
    y -= 20;
    
    drawLine(`Report for: ${userName}`); // <-- USES NAME
    drawLine(`Period: ${start_date} to ${end_date}`);
    y -= 20;

    drawLine(`Total Days Logged: ${reportData.total_days_logged || 0}`);
    drawLine(`Average Daily PHE: ${Number(reportData.avg_phe_mg || 0).toFixed(0)} mg`);
    drawLine(`Average Daily Protein: ${Number(reportData.avg_protein_g || 0).toFixed(0)} g`);
    drawLine(`Average Daily Calories: ${Number(reportData.avg_calories_kcal || 0).toFixed(0)} kcal`);
    drawLine(`Days Over PHE Limit: ${reportData.days_over_phe_limit || 0}`);

    // 4. Save the PDF to a byte array
    const pdfBytes = await pdfDoc.save();

    // 5. Upload the PDF to Supabase Storage
    const fileName = `Report-${start_date}-to-${end_date}.pdf`;
    const filePath = `${user.id}/reports/${fileName}`;

    const { error: uploadError } = await supabaseClient.storage
      .from('user-profiles')
      .upload(filePath, pdfBytes, {
        contentType: 'application/pdf',
        upsert: true,
      });

    if (uploadError) throw uploadError;

    // 6. Return a success response
    return new Response(
      JSON.stringify({ message: 'Report generated successfully!', path: filePath }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (err) {
    console.error('Error generating report:', err);
    return new Response(
      JSON.stringify({ error: err.message }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});
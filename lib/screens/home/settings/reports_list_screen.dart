// lib/screens/home/settings/reports_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart'; // 1. Add this import

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isGenerating = false;

  // --- NEW STATE VARIABLES ---
  bool _isLoadingReports = true;
  List<FileObject> _reports = [];

  @override
  void initState() {
    super.initState();
    // Load the list of existing reports when the screen opens
    _loadReports();
  }

  // --- NEW METHOD TO FETCH REPORTS FROM STORAGE ---
  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final reportsList = await Supabase.instance.client.storage
          .from('user-profiles')
          .list(path: '$userId/reports/');

      if (mounted) {
        setState(() {
          _reports = reportsList;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReports = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_rangeStart!);
      final endDate = DateFormat('yyyy-MM-dd').format(_rangeEnd!);

      await Supabase.instance.client.functions.invoke(
        'generate-report-pdf',
        body: {'start_date': startDate, 'end_date': endDate},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // After generating a new report, refresh the list
        _loadReports();
      }
    } catch (e) {
      // Handle errors (FunctionException, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Generate New Report', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: CalendarFormat.month,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGenerating ? 'Generating...' : 'Generate PDF Report'),
              onPressed: (_rangeStart == null || _rangeEnd == null || _isGenerating) ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 48),
            Text('Generated Reports', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            // --- NEW: DISPLAY THE LIST OF REPORTS ---
            _isLoadingReports
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? const Center(
                        child: Text(
                          'You haven\'t generated any reports yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(report.name),
                              subtitle: Text('Created: ${DateFormat.yMMMd().format(DateTime.parse(report.createdAt!))}'),
                              trailing: const Icon(Icons.open_in_new),
                              onTap: () async {
                                try {
                                  // Get the public URL for the file
                                  final userId = Supabase.instance.client.auth.currentUser!.id;
                                  final url = Supabase.instance.client.storage
                                      .from('user-profiles')
                                      .getPublicUrl('$userId/reports/${report.name}');
                                  
                                  // Open the URL
                                  await launchUrl(Uri.parse(url));

                                } catch (e) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error opening report: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
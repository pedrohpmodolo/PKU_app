// lib/screens/home/settings/account_settings.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../../screens/onboarding_screen.dart';

class AccountSettings extends StatefulWidget {
  static const routeName = '/settings/account';
  const AccountSettings({Key? key}) : super(key: key);

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  /// Finds the latest profile summary PDF in the user's storage bucket.
  Future<String?> _findLatestProfilePdfPath() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // --- CORRECTED BUCKET NAME ---
      final files = await _supabase.storage.from('user-profiles').list(path: userId);

      final pdfFiles = files.where((file) => file.name.endsWith('.pdf')).toList();
      if (pdfFiles.isEmpty) return null;

      pdfFiles.sort((a, b) => b.name.compareTo(a.name));
      
      return '$userId/${pdfFiles.first.name}';
    } catch (e) {
      print('Error finding PDF: $e');
      return null;
    }
  }

  Future<void> _viewOrDownloadPdf({bool open = false}) async {
    final pdfPath = await _findLatestProfilePdfPath();
    if (pdfPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No profile summary found.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      // --- CORRECTED BUCKET NAME ---
      final pdfBytes = await _supabase.storage.from('user-profiles').download(pdfPath);
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/${pdfPath.split('/').last}').writeAsBytes(pdfBytes);

      if (open) {
        await OpenFile.open(file.path);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File opened. "Save As" in your PDF viewer to download.')),
          );
          await OpenFile.open(file.path);
        }
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting PDF: $e'), backgroundColor: Colors.red),
        );
       }
    }
  }

  Future<void> _sharePdf() async {
    final pdfPath = await _findLatestProfilePdfPath();
    if (pdfPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No profile summary found to share.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      // --- CORRECTED BUCKET NAME ---
      final pdfBytes = await _supabase.storage.from('user-profiles').download(pdfPath);
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/${pdfPath.split('/').last}').writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Here is my PKU Wise Profile Summary.');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen(onToggleTheme: null)),
        (_) => false,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null 
              ? const Center(child: Text('Could not load profile.'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSectionHeader('My Health Report'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(icon: const Icon(Icons.visibility), label: const Text('View'), onPressed: () => _viewOrDownloadPdf(open: true)),
                            TextButton.icon(icon: const Icon(Icons.download), label: const Text('Download'), onPressed: () => _viewOrDownloadPdf(open: false)),
                            TextButton.icon(icon: const Icon(Icons.share), label: const Text('Share'), onPressed: _sharePdf),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Personal Information'),
                    _buildInfoTile('Name', _profileData!['name'] ?? 'N/A'),
                    _buildInfoTile('Date of Birth', _profileData!['dob']?.split('T')[0] ?? 'N/A'),
                    _buildInfoTile('Gender', _profileData!['gender'] ?? 'N/A'),
                    _buildInfoTile('Weight', '${_profileData!['weight_kg']?.toStringAsFixed(1) ?? 'N/A'} kg'),
                    _buildInfoTile('Height', '${_profileData!['height_cm']?.toStringAsFixed(1) ?? 'N/A'} cm'),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Diagnosis Information'),
                    _buildInfoTile('PKU Severity', _profileData!['pku_severity'] ?? 'N/A'),
                     _buildInfoTile('Diagnosis Date', _profileData!['diagnosis_date']?.split('T')[0] ?? 'N/A'),
                    _buildInfoTile('Primary Hospital / Clinic', _profileData!['metabolic_center'] ?? 'N/A'),
                    _buildInfoTile('Diet Type', _profileData!['diet_type'] ?? 'N/A'),
                    _buildInfoTile('Daily PHE Tolerance', '${_profileData!['phe_tolerance_mg'] ?? 'N/A'} mg'),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Credentials & Logout'),
                    _buildInfoTile('Email', _supabase.auth.currentUser!.email ?? 'N/A'),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
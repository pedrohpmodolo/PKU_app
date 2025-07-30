// chat_service.dart

// --- NEW IMPORTS NEEDED ---
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
// --------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class that handles interaction with Supabase for chat-related operations.
class ChatService {
  // Supabase client instance to send queries
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- YOUR EXISTING FUNCTIONS (NO CHANGES NEEDED HERE) ---
  Future<List<Map<String, dynamic>>> getUserConversations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('conversations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String sender,
    required String text,
  }) async {
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender': sender,
      'content': text,
    });
  }

  Future<String?> createConversation(String title) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('conversations')
        .insert({
          'user_id': userId,
          'title': title,
        })
        .select()
        .single();

    return response['id'] as String?;
  }

  Future<void> deleteConversation(String conversationId) async {
    await _supabase.from('conversations').delete().eq('id', conversationId);
  }

  Future<void> renameConversation(String conversationId, String newTitle) async {
    await _supabase
        .from('conversations')
        .update({'title': newTitle})
        .eq('id', conversationId);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _supabase.from('profiles').select().eq('id', userId).single();

    return response;
  }
  // --- END OF YOUR EXISTING FUNCTIONS ---



  // --- NEW FUNCTION ADDED FOR RAG BACKEND ---

  // Sets the correct IP address depending on the platform (Android Emulator vs iOS Simulator).
  final String _apiUrl = "http://192.168.1.185:8000/chat";
  //Platform.isAndroid
      //? 'http://10.0.2.2:8000/chat'
      //: 'http://127.0.0.1:8000/chat';

  /// Sends the user's query and history to your RAG backend and gets the AI's response.
  Future<String> getRAGResponse(String query, String userId, List<Map<String, String>> history) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'user_id': userId,
          'history': history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Sorry, I could not process that.';
      } else {
        // Handle server errors
        return 'Error from server: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      // Handle network errors (e.g., if your Python server isn't running)
      return 'Error connecting to the server: $e';
    }
  }
}
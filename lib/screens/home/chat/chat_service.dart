// chat_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart'; // 1. Import the new package

/// A service class that handles interaction with Supabase for chat-related operations.
class ChatService {
  // 2. Create a logger instance for this class
  final _logger = Logger('ChatService');

  // Supabase client instance to send queries
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- YOUR EXISTING FUNCTIONS ---
  Future<List<Map<String, dynamic>>> getUserConversations() async {
    // ... no changes here
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
    // ... no changes here
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
    // ... no changes here
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender': sender,
      'content': text,
    });
  }

  Future<String?> createConversation(String title) async {
    // ... no changes here
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
    // ... no changes here
    await _supabase.from('conversations').delete().eq('id', conversationId);
  }

  Future<void> renameConversation(String conversationId, String newTitle) async {
    // ... no changes here
    await _supabase
        .from('conversations')
        .update({'title': newTitle})
        .eq('id', conversationId);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    // ... no changes here
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _supabase.from('profiles').select().eq('id', userId).single();

    return response;
  }
  
  // --- UPDATED FUNCTION WITH PROPER LOGGING ---
  /// Sends the user's query and history to the 'chat' Edge Function and gets the AI's response.
  Future<String> getRAGResponse({
    required String query,
    required List<Map<String, String>> history,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'chat',
        body: {
          'query': query,
          'history': history,
        },
      );
      return response.data['reply'] as String;

    } on FunctionException catch (e, stackTrace) {
      // 3. Use the logger to log severe errors
      _logger.severe('Supabase function error:', e, stackTrace);
      return 'Error from server: ${e.details}';
    } catch (e, stackTrace) {
      _logger.severe('Generic error calling chat function:', e, stackTrace);
      return 'Sorry, an unexpected error occurred. Please try again.';
    }
  }
}
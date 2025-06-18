// chat_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class that handles interaction with Supabase for chat-related operations.
class ChatService {
  // Supabase client instance to send queries
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all conversations for the currently logged-in user.
  Future<List<Map<String, dynamic>>> getUserConversations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('conversations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true); // Explicit sort: oldest to newest

    return List<Map<String, dynamic>>.from(response);
  }

  /// Retrieves all messages for a given conversation ID, sorted by creation time.
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true); // Explicit sort: oldest to newest

    return List<Map<String, dynamic>>.from(response);
  }

  /// Sends (inserts) a new message into a given conversation.
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

  /// Creates a new conversation with the given title, associated with the logged-in user.
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
        .single(); // Return the newly created conversation

    return response['id'] as String?;
  }

  /// Deletes a conversation (and its messages via cascade) by conversation ID.
  Future<void> deleteConversation(String conversationId) async {
    await _supabase.from('conversations').delete().eq('id', conversationId);
  }

  /// Updates the title of a conversation by ID.
  Future<void> renameConversation(String conversationId, String newTitle) async {
    await _supabase
        .from('conversations')
        .update({'title': newTitle})
        .eq('id', conversationId);
  }

  /// Fetches the current logged-in user's profile from the 'profiles' table
Future<Map<String, dynamic>?> getUserProfile() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final response = await _supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

  return response;
}

}

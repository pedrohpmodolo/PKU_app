import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

class ChatService {
  final _logger = Logger('ChatService');
  final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Sends a message and returns the newly created message ID.
  Future<String?> sendMessage({
    required String conversationId,
    required String sender,
    required String text,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender': sender,
            'content': text,
          })
          .select('id') // Select ID to return it
          .single();

      return response['id'] as String;
    } catch (e, stackTrace) {
      _logger.severe('Error sending message', e, stackTrace);
      return null;
    }
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
    return await _supabase.from('profiles').select().eq('id', userId).single();
  }

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
      _logger.severe('Supabase function error:', e, stackTrace);
      return 'Error from server: ${e.details}';
    } catch (e, stackTrace) {
      _logger.severe('Generic error calling chat function:', e, stackTrace);
      return 'Sorry, an unexpected error occurred. Please try again.';
    }
  }

  // --- NEW METHODS FOR EDIT/DELETE ---

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e, stackTrace) {
      _logger.severe('Error deleting message:', e, stackTrace);
      rethrow;
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _supabase
          .from('messages')
          .update({'content': newContent})
          .eq('id', messageId);
    } catch (e, stackTrace) {
      _logger.severe('Error editing message:', e, stackTrace);
      rethrow;
    }
  }
}
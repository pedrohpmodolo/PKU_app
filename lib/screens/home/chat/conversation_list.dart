// conversation_list.dart
import 'package:flutter/material.dart';
import 'chat_screen.dart';      // Chat screen for selected conversation
import 'chat_service.dart';    // Handles Supabase logic for chat data

/// Displays a list of user conversations with preview and edit/delete options
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _conversations = []; // Full list of user conversations
  Map<String, Map<String, dynamic>> _lastMessages = {}; // Last message for each conversation (for preview)

  @override
  void initState() {
    super.initState();
    _loadConversations(); // Load chats on screen start
  }

  /// Fetches user's conversations and loads the most recent message for each
  Future<void> _loadConversations() async {
    final convos = await _chatService.getUserConversations();
    final Map<String, Map<String, dynamic>> previews = {};

    for (final convo in convos) {
      final messages = await _chatService.getMessages(convo['id']);
      if (messages.isNotEmpty) {
        previews[convo['id']] = messages.last;
      }
    }

    setState(() {
      _conversations = convos;
      _lastMessages = previews;
    });
  }

  /// Creates a new chat and navigates directly to it
  Future<void> _createNewConversation() async {
    final id = await _chatService.createConversation('New Chat');
    if (id != null) {
      await _loadConversations();
      if (context.mounted) {
        final convo = _conversations.firstWhere((c) => c['id'] == id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: id,
              title: convo['title'] ?? 'Chat',
            ),
          ),
        );
      }
    }
  }

  /// Shows rename dialog and updates the conversation title
  void _showRenameDialog(String id, String oldTitle) async {
    final controller = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              await _chatService.renameConversation(id, controller.text);
              if (context.mounted) Navigator.pop(ctx);
              await _loadConversations();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows delete confirmation and removes the conversation
  void _showDeleteConfirmation(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () async {
              await _chatService.deleteConversation(id);
              if (context.mounted) Navigator.pop(ctx);
              await _loadConversations();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet to choose between rename or delete options
  void _showContextMenu(String id, String title) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(id, title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// UI: Lists all user chats with preview and menu options
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: FutureBuilder(
    future: _chatService.getUserProfile(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Text("Chat");
      final profile = snapshot.data!;
      final name = profile['name'] ?? 'there';
      return Text("Chat with me, $name!");
    },
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: _createNewConversation,
    ),
  ],
),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (ctx, index) {
          final convo = _conversations[index];
          final preview = _lastMessages[convo['id']];

          return GestureDetector(
            onLongPress: () => _showContextMenu(convo['id'], convo['title']),
            child: ListTile(
              title: Text(convo['title'] ?? 'Untitled'),
              subtitle: preview != null
                  ? Text(preview['content'], maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: convo['id'],
                    title: convo['title'] ?? 'Chat',
                  ),
                ),
              ).then((_) => _loadConversations()),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showContextMenu(convo['id'], convo['title']),
              ),
            ),
          );
        },
      ),
    );
  }
}

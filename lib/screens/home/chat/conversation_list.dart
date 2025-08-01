// lib/screens/home/chat/conversation_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'chat_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ChatService _chatService = ChatService();

  bool _isLoading = true;
  String _userName = 'there';
  List<Map<String, dynamic>> _conversations = [];
  Map<String, Map<String, dynamic>> _lastMessages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    
    // Fetch conversations and user profile concurrently
    final profileFuture = _chatService.getUserProfile();
    final convosFuture = _chatService.getUserConversations();
    final results = await Future.wait([profileFuture, convosFuture]);

    final profile = results[0] as Map<String, dynamic>?;
    final convos = results[1] as List<Map<String, dynamic>>;
    
    final Map<String, Map<String, dynamic>> previews = {};
    for (final convo in convos) {
      final messages = await _chatService.getMessages(convo['id']);
      if (messages.isNotEmpty) {
        previews[convo['id']] = messages.last;
      }
    }

    if (mounted) {
      setState(() {
        _userName = profile?['name'] ?? 'there';
        _conversations = convos;
        _lastMessages = previews;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewConversation() async {
    final newTitle = 'Chat on ${DateFormat.yMMMd().format(DateTime.now())}';
    final id = await _chatService.createConversation(newTitle);
    if (id != null && mounted) {
      // Navigate to the new chat screen immediately for a better UX
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: id, title: newTitle),
        ),
      ).then((_) => _loadData()); // Refresh the list when returning
    }
  }

  void _showRenameDialog(String id, String oldTitle) {
    final controller = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
           TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _chatService.renameConversation(id, controller.text.trim());
                if (mounted) Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _chatService.deleteConversation(id);
              if (mounted) Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(String id, String title) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(id, title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'No Conversations Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to start a new chat.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Start New Chat'),
            onPressed: _createNewConversation,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> convo) {
    final preview = _lastMessages[convo['id']];
    final title = convo['title'] ?? 'Untitled';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: preview != null
            ? Text(
                preview['content'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text('No messages yet', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showContextMenu(convo['id'], title),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: convo['id'], title: title),
          ),
        ).then((_) => _loadData()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with me, $_userName!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: _createNewConversation,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, index) {
                      final convo = _conversations[index];
                      return _buildConversationCard(convo);
                    },
                  ),
      ),
    );
  }
}
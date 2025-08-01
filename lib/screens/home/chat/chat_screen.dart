// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';

class Message {
  final String content;
  final bool isMine;
  final DateTime timestamp;

  Message({required this.content, required this.isMine, required this.timestamp});
}

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;

  const ChatScreen({super.key, required this.conversationId, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true; // Added for initial load

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (mounted) setState(() => _isLoading = true);
    final messageData = await _chatService.getMessages(widget.conversationId);
    
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (mounted) {
      setState(() {
        _messages = messageData.map((msg) => Message(
          content: msg['content'],
          isMine: msg['sender'] == currentUserId || msg['sender'] == 'user',
          timestamp: DateTime.parse(msg['created_at']).toLocal(),
        )).toList();
        _isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final userMessage = Message(content: text, isMine: true, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Send to Supabase in the background
    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      sender: currentUserId,
      text: text,
    );

    List<Map<String, String>> chatHistory = _messages.map((msg) {
      return {"role": msg.isMine ? "user" : "assistant", "content": msg.content};
    }).toList();

    if (chatHistory.length > 10) {
      chatHistory = chatHistory.sublist(chatHistory.length - 10);
    }
    
    // Get AI reply and add it to the list
    final aiReply = await _chatService.getRAGResponse(query: text, history: chatHistory);
    final assistantMessage = Message(content: aiReply, isMine: false, timestamp: DateTime.now());
    
    if(mounted) {
      setState(() {
        _messages.add(assistantMessage);
        _isTyping = false;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    
    // Save AI reply to Supabase in the background
    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      sender: 'assistant',
      text: aiReply,
    );
  }

  // --- WIDGETS REBUILT WITH MODERN STYLING ---

  Widget _buildMessage(Message msg, {bool isLast = false}) {
    final theme = Theme.of(context);
    final isUser = msg.isMine;

    final bgColor = isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant;
    final textColor = isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
    );

    return Container(
      margin: EdgeInsets.only(
        top: 4,
        bottom: isLast ? 12 : 4, // Add extra padding for the last message
        left: isUser ? 60 : 12,
        right: isUser ? 12 : 60,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: bgColor, borderRadius: radius),
            child: Text(msg.content, style: TextStyle(color: textColor, fontSize: 16)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              DateFormat('h:mm a').format(msg.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Message PKU Wise...',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: _handleSend,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
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
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'PKU Wise',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about your PKU diet,\nfood lookups, or recipe ideas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (_isTyping && index == _messages.length) {
                            return _buildMessage(Message(
                              content: '...',
                              isMine: false,
                              timestamp: DateTime.now(),
                            ));
                          }
                          return _buildMessage(_messages[index], isLast: index == _messages.length -1);
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}
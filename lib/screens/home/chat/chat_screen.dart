// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Needed for Supabase.instance.client
import 'chat_service.dart'; // Your updated ChatService now handles everything

/// A data model for messages to make the code cleaner
class Message {
  final String content;
  final bool isMine;
  final DateTime timestamp;

  Message({required this.content, required this.isMine, required this.timestamp});
}


/// The main chat screen for a selected conversation.
class ChatScreen extends StatefulWidget {
  final String conversationId; // ID of the conversation to load messages from
  final String title;          // Title of the chat (shown in app bar)

  const ChatScreen({super.key, required this.conversationId, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();  // Controls user input
  final ScrollController _scrollController = ScrollController();          // For auto-scroll to bottom

  // Using a typed list of Message objects is safer and cleaner
  List<Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  /// Fetch messages from the conversation and scroll to the bottom
  Future<void> _loadMessages() async {
    final messageData = await _chatService.getMessages(widget.conversationId);
    
    // Convert the map data from Supabase into a list of Message objects
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    setState(() {
      _messages = messageData.map((msg) => Message(
        content: msg['content'],
        isMine: msg['sender'] == currentUserId || msg['sender'] == 'user',
        timestamp: DateTime.parse(msg['created_at']).toLocal(),
      )).toList();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  /// Scroll the chat to the latest message
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100, // Added some buffer
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// --- THIS IS THE UPDATED FUNCTION ---
  /// Handles sending a user message and getting a RAG response from your backend.
  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return; // Can't send if not logged in

    _textController.clear();
    
    // 1. Add user's message to UI and Supabase
    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      sender: currentUserId, // Use the actual user ID
      text: text,
    );
    await _loadMessages(); // Reload messages to show the user's new message

    setState(() => _isTyping = true);

    // 2. Prepare the chat history for the RAG backend
    // It needs a list of maps with "role" and "content"
    List<Map<String, String>> chatHistory = _messages.map((msg) {
      return {
        "role": msg.isMine ? "user" : "assistant",
        "content": msg.content,
      };
    }).toList();

    // To keep the request from getting too big, you can limit the history
    if (chatHistory.length > 10) {
      chatHistory = chatHistory.sublist(chatHistory.length - 10);
    }

    // 3. Call your new RAG backend service to get the AI reply
    final aiReply = await _chatService.getRAGResponse(text, currentUserId, chatHistory);

    // 4. Add the AI's message to UI and Supabase
    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      sender: 'assistant',
      text: aiReply,
    );

    setState(() => _isTyping = false);
    await _loadMessages(); // Reload to show the AI's new message
  }


  /// Renders a chat bubble for each message
  Widget _buildMessage(Message msg) {
    final isUser = msg.isMine;
    final bgColor = isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade300;
    final textColor = isUser ? Colors.white : Colors.black87;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
    );

    final timestamp = DateFormat('hh:mm a').format(msg.timestamp);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
          children: [
            Text(msg.content, style: TextStyle(color: textColor, fontSize: 16)),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timestamp,
                style: TextStyle(fontSize: 10, color: isUser ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
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
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, index) {
                if (_isTyping && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('PKU Wise is typing...'),
                    ),
                  );
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration.collapsed(hintText: 'Message...'),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
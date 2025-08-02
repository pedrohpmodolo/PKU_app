// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_service.dart';   // Supabase interaction (messages, conversations)
import 'ai/ai_service.dart';     // AI response logic (mocked or connected to OpenAI)
import 'services/api_service.dart'; // adjust path as needed

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
  final AIService _aiService = AIService();
  final TextEditingController _textController = TextEditingController();  // Controls user input
  final ScrollController _scrollController = ScrollController();          // For auto-scroll to bottom

  List<Map<String, dynamic>> _messages = [];  // List of messages to display
  bool _isTyping = false;                     // Flag to show typing indicator

  @override
  void initState() {
    super.initState();
    _loadMessages();  // Load messages when the screen first appears
  }

  /// Fetch messages from the conversation and scroll to the bottom
  Future<void> _loadMessages() async {
    final messages = await _chatService.getMessages(widget.conversationId);
    setState(() => _messages = messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  /// Scroll the chat to the latest message
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Handles sending a user message and appending an AI response
  Future<void> _handleSend() async {
  final text = _textController.text.trim();
  if (text.isEmpty) return;

  _textController.clear();
  setState(() => _isTyping = true);

  // Send the user message
  await _chatService.sendMessage(
    conversationId: widget.conversationId,
    sender: 'user',
    text: text,
  );
  await _loadMessages();

  // Get the logged-in user profile
  final profile = await _chatService.getUserProfile();
  print('Profile used in AI prompt: $profile'); 
    if (profile == null) {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        sender: 'assistant',
        text: "Sorry, I couldn't retrieve your profile to provide a personalized answer.",
      );
      setState(() => _isTyping = false);
      await _loadMessages();
      return;
    }


  // Get AI's reply using the personalized context
  final aiReply = await _aiService.getAIResponse(text, profile);

  // Save the AI message
  await _chatService.sendMessage(
    conversationId: widget.conversationId,
    sender: 'assistant',
    text: aiReply,
  );

  setState(() => _isTyping = false);
  await _loadMessages();
}


  /// Renders a chat bubble for each message
  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';
    final bgColor = isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade300;
    final textColor = isUser ? Colors.white : Colors.black87;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
    );

    final timestamp = DateFormat('hh:mm a').format(DateTime.parse(msg['created_at']).toLocal());

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(msg['content'], style: TextStyle(color: textColor)),
            const SizedBox(height: 4),
            Text(
              timestamp,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade200.withOpacity(0.7)),
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
          title: FutureBuilder(
            future: _chatService.getUserProfile(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Text(widget.title);
              final name = snapshot.data?['name'] ?? 'you';
              return Text("Chat with you, $name");
            },
          ), 
        ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final result = await ApiService.analyzeIngredients(["apple", "potato"]);
              if (result != null) {
                print("🍏 Safe Ingredients: ${result['safeIngredients']}");
                print("📊 Total PHE: ${result['mealPhe']}");
                print("📋 Nutrition Summary: ${result['nutritionSummary']}");
              } else {
                print("❌ No result received from backend.");
              }
            }, 
            child: const Text("Test /analyze"),
          ), // ElevatedButton for testing API

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: false,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, index) {
                if (_isTyping && index == _messages.length) {
                  // Display typing animation
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Typing...'),
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
                  // Input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration.collapsed(hintText: 'Message...'),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  // Send button
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

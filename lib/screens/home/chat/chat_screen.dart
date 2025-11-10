import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';

class Message {
  final String id;
  final String content;
  final bool isMine;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.content,
    required this.isMine,
    required this.timestamp,
  });
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
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (mounted) setState(() => _isLoading = true);
    final messageData = await _chatService.getMessages(widget.conversationId);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (mounted) {
      setState(() {
        _messages = messageData.map((msg) => Message(
          id: msg['id'].toString(),
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

  Future<void> _generateAIResponse(String queryText, {String? updateMessageId}) async {
    setState(() => _isTyping = true);
    if (updateMessageId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    List<Map<String, String>> chatHistory = _messages
        .map((msg) => {"role": msg.isMine ? "user" : "assistant", "content": msg.content})
        .toList();

    if (chatHistory.length > 10) {
      chatHistory = chatHistory.sublist(chatHistory.length - 10);
    }

    final aiReply = await _chatService.getRAGResponse(query: queryText, history: chatHistory);

    if (!mounted) return;
    setState(() => _isTyping = false);

    if (updateMessageId != null) {
      final index = _messages.indexWhere((msg) => msg.id == updateMessageId);
      if (index != -1) {
        setState(() {
          _messages[index] = Message(
            id: updateMessageId,
            content: aiReply,
            isMine: false,
            timestamp: DateTime.now(),
          );
        });
      }
      await _chatService.editMessage(updateMessageId, aiReply);
    } else {
      final aiMsgId = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        sender: 'assistant',
        text: aiReply,
      );

      if (mounted && aiMsgId != null) {
        setState(() {
          _messages.add(Message(
            id: aiMsgId,
            content: aiReply,
            isMine: false,
            timestamp: DateTime.now(),
          ));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessageId != null) {
      await _handleEditSubmit(text);
      return;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _textController.clear();

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final userMessage = Message(
      id: tempId,
      content: text,
      isMine: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final realId = await _chatService.sendMessage(
      conversationId: widget.conversationId,
      sender: currentUserId,
      text: text,
    );

    if (realId != null && mounted) {
       final index = _messages.indexWhere((m) => m.id == tempId);
       if (index != -1) {
         setState(() {
           _messages[index] = Message(
             id: realId,
             content: userMessage.content,
             isMine: userMessage.isMine,
             timestamp: userMessage.timestamp,
           );
         });
       }
    }

    await _generateAIResponse(text);
  }

  Future<void> _handleEditSubmit(String newText) async {
    final idToEdit = _editingMessageId;
    if (idToEdit == null) return;

    final index = _messages.indexWhere((msg) => msg.id == idToEdit);
    if (index == -1) return;

    // 1. Keep a backup of the old text in case of failure
    final oldText = _messages[index].content;

    // 2. Optimistic Update
    setState(() {
      _messages[index] = Message(
        id: idToEdit,
        content: newText,
        isMine: true,
        timestamp: _messages[index].timestamp,
      );
      _editingMessageId = null;
      _textController.clear();
      _focusNode.unfocus();
    });

    try {
      print("DEBUG: Attempting to edit message $idToEdit with text: $newText");
      // 3. Try to update Supabase
      await _chatService.editMessage(idToEdit, newText);
      print("DEBUG: Supabase edit successful!");

      // 4. If successful, check for AI regeneration
      String? aiMessageIdToReplace;
      if (index + 1 < _messages.length) {
        final nextMsg = _messages[index + 1];
        if (!nextMsg.isMine) {
          aiMessageIdToReplace = nextMsg.id;
        }
      }
      await _generateAIResponse(newText, updateMessageId: aiMessageIdToReplace);

    } catch (e) {
      // 5. CATCH AND PRINT THE ERROR
      print("CRITICAL ERROR SAVING EDIT: $e");

      if (mounted) {
        // REVERT OPTIMISTIC UPDATE IF FAILED
        setState(() {
           _messages[index] = Message(
             id: idToEdit,
             content: oldText, // Revert to old text
             isMine: true,
             timestamp: _messages[index].timestamp,
           );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save edit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startEditing(Message msg) {
    setState(() {
      _editingMessageId = msg.id;
      _textController.text = msg.content;
      _focusNode.requestFocus();
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    setState(() {
      _messages.removeWhere((msg) => msg.id == messageId);
    });
    await _chatService.deleteMessage(messageId);
  }

  // --- UPDATED OPTIONS MENU TO ALLOW DELETING AI MESSAGES ---
  void _showMessageOptions(BuildContext context, Message msg) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            // ONLY show 'Edit' if it's YOUR message
            if (msg.isMine)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(ctx);
                  _startEditing(msg);
                },
              ),
            // ALWAYS show 'Delete' for both User and AI messages
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(msg.id);
              },
            ),
          ],
        ),
      ),
    );
  }

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

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, msg),
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: isLast ? 12 : 4,
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
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
              child: Text(
                DateFormat('h:mm a').format(msg.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isEditing = _editingMessageId != null;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16),
                    const SizedBox(width: 8),
                    const Text("Editing message..."),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _editingMessageId = null;
                          _textController.clear();
                          _focusNode.unfocus();
                        });
                      },
                    )
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: isEditing ? 'Update message...' : 'Message PKU Wise...',
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
                  icon: Icon(isEditing ? Icons.check : Icons.send),
                  onPressed: _handleSend,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('No messages yet.', style: TextStyle(color: Colors.grey.shade600)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (_isTyping && index == _messages.length) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.centerLeft,
                              child: const Text('PKU Wise is typing...'),
                            );
                          }
                          return _buildMessage(_messages[index], isLast: index == _messages.length - 1);
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}
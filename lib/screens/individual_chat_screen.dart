import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p1/services/chat_service.dart';
import 'package:p1/theme.dart';
import 'package:intl/intl.dart';

class IndividualChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const IndividualChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _doctorStatusSubscription;

  String? _chatRoomId;
  bool _isLoadingChatRoom = true;

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _doctorStatusSubscription?.cancel(); // Cancel subscription
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    setState(() {
      _isLoadingChatRoom = true;
    });
    try {
      DocumentSnapshot receiverUserDoc = await FirebaseFirestore.instance.collection('users').doc(widget.receiverId).get();
      String receiverRole = 'User'; // Default
      if(receiverUserDoc.exists && receiverUserDoc.data() != null) {
        receiverRole = (receiverUserDoc.data()! as Map<String,dynamic>)['role'] ?? 'User';
      }

      final id = await _chatService.getOrCreateChatRoom(widget.receiverId, widget.receiverName, receiverRole);
      setState(() {
        _chatRoomId = id;
        _isLoadingChatRoom = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingChatRoom = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing chat: ${e.toString()}")));
    }
  }


  void _sendMessage() async {
    if (_messageController.text.isNotEmpty && _chatRoomId != null) {
      await _chatService.sendMessage(_chatRoomId!, _messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(widget.receiverName, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingChatRoom
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _chatRoomId == null
          ? const Center(child: Text("Could not initialize chat room."))
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(_chatRoomId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hi! 👋'));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    bool isCurrentUser = data['senderId'] == _auth.currentUser?.uid;

                    return _buildMessageItem(data, isCurrentUser);
                  }).toList(),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> data, bool isCurrentUser) {
    final Timestamp timestamp = data['timestamp'] as Timestamp;
    final DateTime messageTime = timestamp.toDate();

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isCurrentUser ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        color: isCurrentUser ? AppColors.primary.withOpacity(0.9) : AppColors.light,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                data['text'] ?? '',
                style: TextStyle(color: isCurrentUser ? AppColors.white : AppColors.dark, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(messageTime), // Using intl for formatting
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentUser ? AppColors.white.withOpacity(0.7) : AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -1),
              blurRadius: 3,
              color: Colors.grey.withOpacity(0.1),
            )
          ]
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.light.withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
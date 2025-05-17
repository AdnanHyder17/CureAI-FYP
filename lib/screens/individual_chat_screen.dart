// lib/screens/individual_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:cached_network_image/cached_network_image.dart';

import 'package:p1/services/chat_service.dart';
import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart';

class IndividualChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverImageUrl;

  const IndividualChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverImageUrl,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _chatRoomId;
  bool _isLoadingChatRoom = true;
  User? _currentUser;

  String? _currentUserImageUrl;
  String? _receiverImageUrlState;

  StreamSubscription? _receiverStatusSubscription;
  String _receiverOnlineStatus = "Offline";

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _receiverImageUrlState = widget.receiverImageUrl;
    _initializeChat();
    _fetchUserImageUrls();
    _listenToReceiverStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _receiverStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_currentUser == null) {
      setState(() => _isLoadingChatRoom = false);
      return;
    }
    setState(() => _isLoadingChatRoom = true);
    try {
      DocumentSnapshot receiverUserDoc = await _firestore.collection('users').doc(widget.receiverId).get();
      String receiverRole = 'User';
      if(receiverUserDoc.exists && receiverUserDoc.data() != null) {
        receiverRole = (receiverUserDoc.data()! as Map<String,dynamic>)['role'] ?? 'User';
      }

      final id = await _chatService.getOrCreateChatRoom(widget.receiverId, widget.receiverName, receiverRole);
      if (mounted) {
        setState(() {
          _chatRoomId = id;
          _isLoadingChatRoom = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing chat room: $e");
      if (mounted) {
        setState(() => _isLoadingChatRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error starting chat: ${e.toString()}"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _fetchUserImageUrls() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (mounted && userDoc.exists) {
        setState(() => _currentUserImageUrl = (userDoc.data() as Map<String,dynamic>)['profileImageUrl'] as String?);
      }
    }
    if (_receiverImageUrlState == null || _receiverImageUrlState!.isEmpty) {
      DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(widget.receiverId).get();
      if (mounted && receiverDoc.exists) {
        setState(() => _receiverImageUrlState = (receiverDoc.data() as Map<String,dynamic>)['profileImageUrl'] as String?);
      }
    }
  }

  void _listenToReceiverStatus() {
    _receiverStatusSubscription = _firestore.collection('users').doc(widget.receiverId).snapshots().listen((doc) {
      if (mounted && doc.exists) {
        final status = (doc.data() as Map<String,dynamic>)['status'] as String? ?? 'Offline';
        setState(() => _receiverOnlineStatus = status == 'online' ? 'Online' : 'Offline');
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && _chatRoomId != null && _currentUser != null) {
      final messageText = _messageController.text.trim();
      _messageController.clear();

      try {
        await _chatService.sendMessage(_chatRoomId!, messageText);
        _scrollToBottom(isAnimated: true);
      } catch (e) {
        debugPrint("Error sending message: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("Couldn't send message. Please try again."), backgroundColor: AppColors.error),
          );
          _messageController.text = messageText;
        }
      }
    }
  }

  void _scrollToBottom({bool isAnimated = false, int delayMs = 100}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted && _scrollController.hasClients) {
        if (isAnimated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 1.0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            if (_receiverOnlineStatus.isNotEmpty)
              Text(
                _receiverOnlineStatus,
                style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 12),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingChatRoom
                ? const Center(child: LoadingIndicator())
                : _chatRoomId == null
                ? const Center(child: Text("Could not load chat. Please try again.", style: TextStyle(color: AppColors.gray)))
                : StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(_chatRoomId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages.', style: TextStyle(color: AppColors.error)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyChatView();
                }

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isCurrentUser = data['senderId'] == _currentUser?.uid;
                    return _buildMessageBubble(data, isCurrentUser);
                  },
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.gray.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Start a conversation with ${widget.receiverName}!',
            style: TextStyle(fontSize: 17, color: AppColors.dark.withOpacity(0.8), fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Messages you send will appear here.',
            style: TextStyle(fontSize: 14, color: AppColors.gray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isCurrentUser) {
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final String messageText = data['text'] as String? ?? '[empty message]';

    // --- Safely get sender initial ---
    String senderInitial = "?"; // Default initial
    String senderDisplayName = "User"; // Default display name

    if (isCurrentUser) {
      senderDisplayName = _currentUser?.displayName ?? "Me";
      if (senderDisplayName.isNotEmpty) {
        senderInitial = senderDisplayName[0].toUpperCase();
      } else {
        // Fallback if display name is also empty
        senderDisplayName = "Me";
        senderInitial = "M";
      }
    } else {
      senderDisplayName = widget.receiverName; // receiverName should be guaranteed by chat_list_screen
      if (senderDisplayName.isNotEmpty) {
        senderInitial = senderDisplayName[0].toUpperCase();
      } else {
        // Fallback if receiverName somehow becomes empty (shouldn't happen with prior checks)
        senderDisplayName = "User";
        senderInitial = "U";
      }
    }
    // --- End of safe sender initial ---

    // final String senderImageUrl = isCurrentUser ? (_currentUserImageUrl ?? '') : (_receiverImageUrlState ?? '');
    // Avatar display is not currently in this bubble, but if you add it, use senderImageUrl and senderInitial

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
            bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              messageText,
              style: TextStyle(
                color: isCurrentUser ? AppColors.white : AppColors.dark,
                fontSize: 15.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '--:--',
              style: TextStyle(
                fontSize: 11,
                color: isCurrentUser ? AppColors.white.withOpacity(0.7) : AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 5,
            color: Colors.grey.withOpacity(0.08),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.9)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.light,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            MaterialButton(
              onPressed: _sendMessage,
              shape: const CircleBorder(),
              color: AppColors.primary,
              padding: const EdgeInsets.all(12),
              elevation: 1.0,
              child: const Icon(Icons.send_rounded, color: AppColors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

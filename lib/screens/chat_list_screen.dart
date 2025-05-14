// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p1/services/chat_service.dart';
import 'package:p1/screens/individual_chat_screen.dart';
import 'package:p1/theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats'), backgroundColor: AppColors.primary),
        body: const Center(child: Text("Please log in to see chats.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatRoomsForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading chats.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.gray),
                  SizedBox(height: 20),
                  Text('No chats yet.', style: TextStyle(fontSize: 18, color: AppColors.dark)),
                  Text('Start a conversation with a doctor.', style: TextStyle(color: AppColors.gray)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: snapshot.data!.docs.map((doc) {
              final chatRoomData = doc.data() as Map<String, dynamic>;
              final participants = chatRoomData['participants'] as List<dynamic>;
              String otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');

              if (otherUserId.isEmpty) {
                // This case should ideally not happen if chat rooms are created correctly
                return const SizedBox.shrink(); // Or some error indication
              }

              // Use FutureBuilder to fetch the other user's details dynamically
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  String otherUserName = 'User'; // Default name
                  String avatarLetter = 'U';
                  ImageProvider? backgroundImage;

                  if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    otherUserName = userData['nickname'] ?? 'User';
                    if (otherUserName.isNotEmpty) {
                      avatarLetter = otherUserName[0].toUpperCase();
                    }
                    // Assuming 'profileImageUrl' might be in the 'users' doc or you might fetch it from 'doctors'/'patients'
                    // For simplicity, let's assume 'profileImageUrl' could be in 'users' for this example.
                    // In a real app, you might need another FutureBuilder or a more complex state management if profile images are elsewhere.
                    if (userData.containsKey('profileImageUrl') && userData['profileImageUrl'] != null && (userData['profileImageUrl'] as String).isNotEmpty) {
                      // Placeholder for actual image loading if you have it, e.g., CachedNetworkImage
                      // backgroundImage = NetworkImage(userData['profileImageUrl']);
                    }
                  } else if (userSnapshot.connectionState == ConnectionState.waiting) {
                    // Show a placeholder while loading user details
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.light,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        title: Container(height: 16, width: 100, color: AppColors.light), // Shimmer effect placeholder
                        subtitle: Container(height: 12, width: 150, color: AppColors.light.withOpacity(0.7)),
                      ),
                    );
                  }
                  // If error or no data, use default 'User'

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondary,
                        backgroundImage: backgroundImage, // Use this if you load the image
                        child: backgroundImage == null ? Text(avatarLetter, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)) : null,
                      ),
                      title: Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark, fontSize: 16)),
                      subtitle: Text(
                        chatRoomData['lastMessage']?.isNotEmpty == true ? chatRoomData['lastMessage'] : 'No messages yet.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.gray, fontSize: 13),
                      ),
                      trailing: chatRoomData['lastMessageTimestamp'] != null
                          ? Text(
                        _formatTimestamp(chatRoomData['lastMessageTimestamp'] as Timestamp),
                        style: const TextStyle(fontSize: 11, color: AppColors.gray),
                      )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualChatScreen(
                              receiverId: otherUserId,
                              receiverName: otherUserName, // Pass the dynamically fetched name
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    // Basic formatting, you can use intl package for more complex formatting
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
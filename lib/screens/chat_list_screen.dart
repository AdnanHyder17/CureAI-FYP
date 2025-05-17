// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cached_network_image/cached_network_image.dart';

import 'package:p1/services/chat_service.dart';
import 'package:p1/screens/individual_chat_screen.dart';
import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart'; // Assuming you have this

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // For fetching user details

  Widget _buildChatListItem(BuildContext context, DocumentSnapshot chatRoomDoc) {
    final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>;
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    // Determine the other participant's ID
    final List<dynamic> participants = chatRoomData['participants'] as List<dynamic>? ?? [];
    String otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');

    if (otherUserId.isEmpty) {
      // This can happen if the chat room data is malformed or only contains the current user
      return const SizedBox.shrink();
    }

    // Use participantDetails stored in chat_rooms if available, otherwise fetch
    final Map<String, dynamic>? participantDetails = chatRoomData['participantDetails'] as Map<String, dynamic>?;
    final Map<String, dynamic>? otherUserDetailsFromChatRoom = participantDetails?[otherUserId] as Map<String, dynamic>?;


    // Fetch the other user's details (name, profile image)
    // This FutureBuilder is crucial for displaying up-to-date user info.
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        String otherUserName = widget.toString(); // Placeholder
        String? otherUserImageUrl;
        String avatarLetter = '?';

        if (userSnapshot.connectionState == ConnectionState.waiting && otherUserDetailsFromChatRoom == null) {
          // Show a shimmer/loading placeholder for the list item
          return _buildChatListItemPlaceholder();
        }

        if (userSnapshot.hasError && otherUserDetailsFromChatRoom == null) {
          otherUserName = "Error User"; // Or handle error more gracefully
        }

        // Prioritize fresh data from users collection, fallback to chatRoomData.participantDetails
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          otherUserName = userData['nickname'] as String? ?? 'User';
          otherUserImageUrl = userData['profileImageUrl'] as String?;
        } else if (otherUserDetailsFromChatRoom != null) {
          otherUserName = otherUserDetailsFromChatRoom['name'] as String? ?? 'User';
          // Assuming profileImageUrl might also be stored in participantDetails if fetched during chat room creation
          otherUserImageUrl = otherUserDetailsFromChatRoom['profileImageUrl'] as String?;
        }


        if (otherUserName.isNotEmpty) {
          avatarLetter = otherUserName[0].toUpperCase();
        }

        final String lastMessage = chatRoomData['lastMessage'] as String? ?? 'No messages yet.';
        final Timestamp? lastMessageTimestamp = chatRoomData['lastMessageTimestamp'] as Timestamp?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.secondary.withOpacity(0.15),
              backgroundImage: (otherUserImageUrl != null && otherUserImageUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(otherUserImageUrl)
                  : null,
              child: (otherUserImageUrl == null || otherUserImageUrl.isEmpty)
                  ? Text(
                avatarLetter,
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              )
                  : null,
            ),
            title: Text(
              otherUserName,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark, fontSize: 16.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.dark.withOpacity(0.7), fontSize: 14),
            ),
            trailing: lastMessageTimestamp != null
                ? Text(
              _formatTimestamp(lastMessageTimestamp.toDate()),
              style: const TextStyle(fontSize: 12, color: AppColors.gray),
            )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IndividualChatScreen(
                    receiverId: otherUserId,
                    receiverName: otherUserName, // Pass the fetched name
                    receiverImageUrl: otherUserImageUrl, // Pass the fetched image URL
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChatListItemPlaceholder() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.light.withOpacity(0.5),
        ),
        title: Container(
          height: 16,
          width: 120,
          color: AppColors.light.withOpacity(0.5),
          margin: const EdgeInsets.only(bottom: 6.0),
        ),
        subtitle: Container(
          height: 12,
          width: 180,
          color: AppColors.light.withOpacity(0.4),
        ),
        trailing: Container(
          height: 10,
          width: 40,
          color: AppColors.light.withOpacity(0.3),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (dateTime.isAfter(today)) {
      return DateFormat('HH:mm').format(dateTime); // Today: 10:30
    } else if (dateTime.isAfter(yesterday)) {
      return 'Yesterday'; // Yesterday
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE').format(dateTime); // Day of week: Mon, Tue
    } else {
      return DateFormat('dd/MM/yy').format(dateTime); // Older: 15/05/25
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return _buildChatListBody(currentUser);
  }


  Widget _buildChatListBody(User? currentUser) {
    if (currentUser == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 60, color: AppColors.gray),
            SizedBox(height: 16),
            Text("Please log in to view your chats.", style: TextStyle(fontSize: 17, color: AppColors.dark)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatRoomsForCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("ChatListScreen error: ${snapshot.error}");
          return Center(child: Text('Error loading chats. Please try again later.', style: TextStyle(color: AppColors.error.withOpacity(0.8))));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show multiple shimmer placeholders while loading
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: List.generate(5, (index) => _buildChatListItemPlaceholder()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.gray.withOpacity(0.6)),
                  const SizedBox(height: 20),
                  Text('No Chats Yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(
                    'Start a conversation with a doctor or patient. Your active chats will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.dark.withOpacity(0.7), height: 1.4),
                  ),
                  // Optional: Add a button to find doctors if the user is a patient
                  // if (userRole == 'Patient') ...
                ],
              ),
            ),
          );
        }

        final chatDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            return _buildChatListItem(context, chatDocs[index]);
          },
        );
      },
    );
  }
}

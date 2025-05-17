// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_webrtc/flutter_webrtc.dart'; // For WebRTC types

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Text Chat Functionalities ---

  /// Gets or creates a chat room between the current user and a receiver.
  /// Includes basic participant details in the chat room document.
  /// Returns the chat room ID.
  Future<String> getOrCreateChatRoom(String receiverId, String receiverName, String receiverRole) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in. Cannot create/get chat room.");

    List<String> ids = [currentUser.uid, receiverId];
    ids.sort(); // Ensure consistent chat room ID regardless of who initiates
    String chatRoomId = ids.join('_');

    DocumentReference chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (!chatRoomSnapshot.exists) {
      // Create new chat room
      DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      String currentUserName = (currentUserDoc.data() as Map<String, dynamic>?)?['nickname'] ?? 'User';
      String currentUserRole = (currentUserDoc.data() as Map<String, dynamic>?)?['role'] ?? 'User';
      String? currentUserImageUrl = (currentUserDoc.data() as Map<String, dynamic>?)?['profileImageUrl'] as String?;


      // Fetch receiver's image URL (assuming receiverId corresponds to a document in 'users' collection)
      String? receiverImageUrl;
      DocumentSnapshot receiverUserDoc = await _firestore.collection('users').doc(receiverId).get();
      if (receiverUserDoc.exists) {
        receiverImageUrl = (receiverUserDoc.data() as Map<String, dynamic>?)?['profileImageUrl'] as String?;
      }


      await chatRoomRef.set({
        'chatRoomId': chatRoomId,
        'participants': ids,
        'participantDetails': {
          currentUser.uid: {
            'name': currentUserName,
            'role': currentUserRole,
            'imageUrl': currentUserImageUrl, // Store image URL
          },
          receiverId: {
            'name': receiverName,
            'role': receiverRole,
            'imageUrl': receiverImageUrl, // Store image URL
          },
        },
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(), // Initialize with server timestamp
        'createdAt': FieldValue.serverTimestamp(),
        // 'unreadCounts': {currentUser.uid: 0, receiverId: 0}, // Optional
      });
      debugPrint("[ChatService] Created chat room: $chatRoomId");
    }
    return chatRoomId;
  }

  /// Sends a text message to a specific chat room.
  Future<void> sendMessage(String chatRoomId, String messageText) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null || messageText.trim().isEmpty) {
      debugPrint("[ChatService] Cannot send message: User not logged in or message empty.");
      return;
    }

    DocumentReference chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    String senderName = _auth.currentUser?.displayName ??
        (await _firestore.collection('users').doc(currentUser.uid).get()).data()?['nickname'] ??
        'User';

    await chatRoomRef.collection('messages').add({
      'senderId': currentUser.uid,
      'senderName': senderName,
      'text': messageText.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
      // 'readBy': [currentUser.uid] // Optional: for read receipts
    });

    await chatRoomRef.update({
      'lastMessage': messageText.trim(),
      'lastMessageSenderId': currentUser.uid,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      // Optionally, update unread counts for other participants
    });
    debugPrint("[ChatService] Message sent to room: $chatRoomId by ${currentUser.uid}");
  }

  /// Gets a stream of messages for a specific chat room, ordered by timestamp.
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Show oldest messages first for chat flow
        .snapshots();
  }

  /// Gets a stream of chat rooms for the current user.
  Stream<QuerySnapshot> getChatRoomsForCurrentUser() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint("[ChatService] No current user for getChatRoomsForCurrentUser.");
      return const Stream.empty();
    }

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTimestamp', descending: true) // Show most recent chats first
        .snapshots();
  }

  // --- WebRTC Signaling Functionalities ---

  /// Creates and configures an RTCPeerConnection.
  Future<RTCPeerConnection> createWebRTCPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // IMPORTANT: For production, you'll need your own TURN server(s) for reliable NAT traversal.
        // Example TURN server configuration (replace with your actual server details):
        // {
        //   'urls': 'turn:your.turn.server.com:3478',
        //   'username': 'your_turn_username',
        //   'credential': 'your_turn_password',
        // },
        // {
        //   'urls': 'turn:your.turn.server.com:3478?transport=udp',
        //   'username': 'your_turn_username',
        //   'credential': 'your_turn_password',
        // },
        // {
        //   'urls': 'turn:your.turn.server.com:3478?transport=tcp',
        //   'username': 'your_turn_username',
        //   'credential': 'your_turn_password',
        // }
      ],
      "sdpSemantics": "unified-plan" // Recommended for modern WebRTC
    };

    // Optional: RTCConfiguration for more advanced settings like ICE transport policy
    // final Map<String, dynamic> sdpConstraints = {
    //   "mandatory": {
    //     "OfferToReceiveAudio": true,
    //     "OfferToReceiveVideo": true, // Assuming always video for your preference
    //   },
    //   "optional": [],
    // };

    RTCPeerConnection pc = await createPeerConnection(configuration); // Pass sdpConstraints if using them
    return pc;
  }

  /// Creates a call room document in Firestore for signaling.
  Future<String> createCallRoom(String receiverId, String callType) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in for creating call room.");

    String callRoomId = _firestore.collection('calls').doc().id; // Generate a unique ID

    List<String> participants = [currentUser.uid, receiverId];
    // No need to sort participants here unless your rules specifically rely on it for this field

    await _firestore.collection('calls').doc(callRoomId).set({
      'callRoomId': callRoomId, // Storing the ID within the document can be useful
      'callerId': currentUser.uid,
      'receiverId': receiverId,
      'participants': participants, // Crucial for security rules and lookups
      'callType': callType, // 'video' or 'voice'
      'status': 'ringing', // Initial status
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(), // Good practice to have on create
      'offer': null, // Placeholder for SDP offer
      'answer': null, // Placeholder for SDP answer
    });
    debugPrint("[ChatService] Created call room: $callRoomId for $callType call between ${currentUser.uid} and $receiverId");
    return callRoomId;
  }

  /// Sends an SDP offer to the call room.
  Future<void> sendOffer(String callRoomId, RTCSessionDescription offer) async {
    await _firestore.collection('calls').doc(callRoomId).update({
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      // 'status': 'ringing', // Status should already be ringing from createCallRoom
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint("[ChatService] Offer sent to call room: $callRoomId");
  }

  /// Sends an SDP answer to the call room.
  Future<void> sendAnswer(String callRoomId, RTCSessionDescription answer) async {
    await _firestore.collection('calls').doc(callRoomId).update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'connected', // Update status when answer is sent
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint("[ChatService] Answer sent to call room: $callRoomId, status: connected");
  }

  /// Adds an ICE candidate to the call room for the appropriate party.
  Future<void> addCandidate(String callRoomId, RTCIceCandidate candidate, bool isCaller) async {
    // if isCaller is true, this candidate is from the caller, store in callerCandidates
    // if isCaller is false, this candidate is from the receiver, store in receiverCandidates
    String candidateCollection = isCaller ? 'callerCandidates' : 'receiverCandidates';
    await _firestore
        .collection('calls')
        .doc(callRoomId)
        .collection(candidateCollection)
        .add(candidate.toMap());
    // debugPrint("[ChatService] Added ${isCaller ? 'caller' : 'receiver'} candidate to $callRoomId: ${candidate.candidate}");
  }

  /// Gets a stream of the call room document for signaling updates.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getCallStream(String callRoomId) {
    return _firestore.collection('calls').doc(callRoomId).snapshots()
    as Stream<DocumentSnapshot<Map<String, dynamic>>>; // Cast for type safety
  }

  /// Gets a stream of ICE candidates for the other party.
  Stream<QuerySnapshot<Map<String, dynamic>>> getCandidatesStream(String callRoomId, bool isCaller) {
    // If current user is the caller (isCaller == true), they listen to receiver's candidates.
    // If current user is the receiver (isCaller == false), they listen to caller's candidates.
    String candidateCollectionToListen = isCaller ? 'receiverCandidates' : 'callerCandidates';
    return _firestore
        .collection('calls')
        .doc(callRoomId)
        .collection(candidateCollectionToListen)
        .snapshots()
    as Stream<QuerySnapshot<Map<String, dynamic>>>; // Cast for type safety
  }

  /// Updates the status of a call in the call room (e.g., 'ended', 'declined', 'missed').
  Future<void> updateCallStatus(String callRoomId, String status) async {
    try {
      // Check if document exists before trying to update
      DocumentSnapshot callDoc = await _firestore.collection('calls').doc(callRoomId).get();
      if (!callDoc.exists) {
        debugPrint("[ChatService] Call room $callRoomId does not exist. Cannot update status to $status.");
        return;
      }

      await _firestore.collection('calls').doc(callRoomId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("[ChatService] Call room $callRoomId status updated to $status");

      // Optional: Enhanced cleanup logic
      if (status == 'ended' || status == 'declined' || status == 'missed') {
        // Delay cleanup to ensure all parties have processed the final status
        Future.delayed(const Duration(seconds: 20), () async {
          try {
            debugPrint("[ChatService] Starting cleanup for call room $callRoomId due to status: $status");
            // Delete caller candidates
            var callerCandidatesSnapshot = await _firestore.collection('calls').doc(callRoomId).collection('callerCandidates').get();
            for (var doc in callerCandidatesSnapshot.docs) {
              await doc.reference.delete();
            }
            // Delete receiver candidates
            var receiverCandidatesSnapshot = await _firestore.collection('calls').doc(callRoomId).collection('receiverCandidates').get();
            for (var doc in receiverCandidatesSnapshot.docs) {
              await doc.reference.delete();
            }
            debugPrint("[ChatService] Candidates cleaned up for call room $callRoomId");

            // Optionally, delete the call room document itself after a longer delay or based on policy
            // For example, if you don't need call history in the 'calls' collection for long.
            // await Future.delayed(const Duration(minutes: 1)); // e.g., 1 minute after candidate cleanup
            // await _firestore.collection('calls').doc(callRoomId).delete();
            // debugPrint("[ChatService] Call room document $callRoomId deleted.");
          } catch (e) {
            debugPrint("[ChatService] Error during cleanup for call $callRoomId: $e");
          }
        });
      }
    } catch (e) {
      debugPrint("[ChatService] Error updating call status for $callRoomId to $status: $e");
    }
  }

  /// Updates the doctor's specific call availability status in their 'doctors' profile.
  Future<void> updateDoctorCallStatus(String doctorId, String callStatus) {
    // callStatus can be 'available', 'on_call', 'busy', 'unavailable'
    debugPrint("[ChatService] Attempting to update doctor $doctorId callStatus to $callStatus");
    return _firestore.collection('doctors').doc(doctorId).set( // Use set with merge to ensure doc exists
      {
        'callStatus': callStatus,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ).then((_) {
      debugPrint("[ChatService] Doctor $doctorId call status successfully updated to $callStatus");
    }).catchError((error) {
      debugPrint("[ChatService] Error updating doctor $doctorId call status to $callStatus: $error");
      // Consider how to handle this error; maybe the doctor's document doesn't exist yet in 'doctors'
      // This might happen if a patient tries to update status of a doctor whose profile setup is incomplete.
    });
  }
}
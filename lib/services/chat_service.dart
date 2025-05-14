// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'; // Ensure this import is present
// import 'dart:convert'; // For jsonEncode and jsonDecode - Not used in this snippet directly

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Text Chat ---

  Future<String> getOrCreateChatRoom(String receiverId, String receiverName, String receiverRole) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    List<String> ids = [currentUser.uid, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    DocumentReference chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get(); // Use .get() not .get() on the reference

    if (!chatRoomSnapshot.exists) {
      Map<String, dynamic> chatRoomData = {
        'participants': [currentUser.uid, receiverId],
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
        'chatRoomId': chatRoomId,

        currentUser.uid: {
          'role': (await _firestore.collection('users').doc(currentUser.uid).get()).data()?['role'] ?? 'User',
        },
        receiverId: {
          'role': receiverRole, // receiverRole is already passed or fetched
        }
      };

      // Determine patientId and doctorId based on roles for easier querying of appointments/chats by doctors/patients
      DocumentSnapshot user1Doc = await _firestore.collection('users').doc(currentUser.uid).get();
      String user1Role = (user1Doc.data() as Map<String,dynamic>)['role'] ?? 'User';

      if (user1Role == 'Patient') {
        chatRoomData['patientId'] = currentUser.uid;
        chatRoomData['doctorId'] = receiverId;
      } else if (receiverRole == 'Patient') { // Current user is Doctor, receiver is Patient
        chatRoomData['patientId'] = receiverId;
        chatRoomData['doctorId'] = currentUser.uid;
      }

      await chatRoomRef.set(chatRoomData);
    } else {
      print("Chat room with ID: $chatRoomId already exists.");
    }
    return chatRoomId;
  }

  Future<void> sendMessage(String chatRoomId, String messageText) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || messageText.trim().isEmpty) return;

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'senderEmail': currentUser.email,
      'text': messageText,
      'timestamp': Timestamp.now(),
      'messageType': 'text',
    });

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': messageText,
      'lastMessageTimestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatRoomsForCurrentUser() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // --- WebRTC Signaling for Calls ---

  // Standard RTCConfiguration
  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Add TURN servers here if needed for production
    ],
    "sdpSemantics": "unified-plan" // Modern WebRTC
  };

  Future<RTCPeerConnection> createWebRTCPeerConnection() async {
    RTCPeerConnection pc = await createPeerConnection(_rtcConfiguration, {}); // Pass empty map for offer/answer constraints for now
    return pc;
  }


  // Store active peer connections (if managing multiple, otherwise might not be needed in ChatService)
  // Map<String, RTCPeerConnection> peerConnections = {};


  Future<String> createCallRoom(String receiverId, String callType) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    String callRoomId = _firestore.collection('calls').doc().id;
    Map<String, dynamic> callData = {
      'callerId': currentUser.uid,             // CRITICAL FOR RULE
      'receiverId': receiverId,
      'callType': callType,
      'status': 'ringing',                    // CRITICAL FOR RULE
      'createdAt': Timestamp.now(),
      'participants': [currentUser.uid, receiverId] // CRITICAL FOR RULE
    };

    print("Attempting to CREATE call room with ID: $callRoomId");
    print("Call Room Data being written: $callData"); // DEBUG LOG
    try {
      await _firestore.collection('calls').doc(callRoomId).set(callData);
      print("Call room CREATED successfully.");
    } catch (e) {
      print("ERROR CREATING CALL ROOM: $e"); // DEBUG LOG
      throw e; // Re-throw
    }
    return callRoomId;
  }

  // In ChatService class

  Future<void> updateDoctorCallStatus(String doctorId, String status) async {
    // Ensure status is one of 'available', 'on_call', 'busy'
    if (!['available', 'on_call', 'busy'].contains(status)) return;
    await _firestore.collection('doctors').doc(doctorId).update({'callStatus': status});
  }

  Stream<DocumentSnapshot> getDoctorCallStatusStream(String doctorId) {
    return _firestore.collection('doctors').doc(doctorId).snapshots();
  }

  Stream<DocumentSnapshot> getCallStream(String callRoomId) {
    return _firestore.collection('calls').doc(callRoomId).snapshots();
  }

  Future<void> sendOffer(String callRoomId, RTCSessionDescription description) async {
    await _firestore.collection('calls').doc(callRoomId).set({ // Use set with merge:true or update carefully
      'offer': {
        'sdp': description.sdp,
        'type': description.type,
      }
    }, SetOptions(merge: true)); // Use merge to avoid overwriting other fields
  }

  Future<void> sendAnswer(String callRoomId, RTCSessionDescription description) async {
    await _firestore.collection('calls').doc(callRoomId).update({
      'answer': {
        'sdp': description.sdp,
        'type': description.type,
      },
      'status': 'active' // Update status when answering
    });
  }

  Future<void> addCandidate(String callRoomId, RTCIceCandidate candidate, bool isCaller) async {
    String collectionName = isCaller ? 'callerCandidates' : 'receiverCandidates';
    await _firestore
        .collection('calls')
        .doc(callRoomId)
        .collection(collectionName)
        .add(candidate.toMap());
  }

  Stream<QuerySnapshot> getCandidatesStream(String callRoomId, bool isCaller) {
    // If I am the caller, I listen to receiver's candidates.
    // If I am the receiver, I listen to caller's candidates.
    String collectionNameToListen = isCaller ? 'receiverCandidates' : 'callerCandidates';
    return _firestore
        .collection('calls')
        .doc(callRoomId)
        .collection(collectionNameToListen)
        .snapshots();
  }

  Future<void> updateCallStatus(String callRoomId, String status) async {
    await _firestore.collection('calls').doc(callRoomId).update({'status': status});
  }

  Future<void> endCall(String callRoomId) async {
    await _firestore.collection('calls').doc(callRoomId).update({'status': 'ended'});
  }
}
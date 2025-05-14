import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p1/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates

// --- Data Models ---
class ChatMessage {
  final String id; // Firestore document ID for the message
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? diagnosis;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.diagnosis,
  });

  // Factory constructor to create a ChatMessage from a Firestore DocumentSnapshot
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      isUserMessage: data['sender'] == 'user',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diagnosis: data['diagnosis'] as String?,
    );
  }
}

class ChatSession {
  final String id;
  final String title;
  final DateTime lastUpdatedAt;

  ChatSession({required this.id, required this.title, required this.lastUpdatedAt});

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    // Generate a title if not present (e.g., from timestamp)
    String title = data['title'] ?? 'Chat on ${DateFormat.yMd().add_jm().format((data['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}';
    if (title.isEmpty) { // Fallback title if stored title is empty
      title = 'Session ${doc.id.substring(0, 5)}...';
    }

    return ChatSession(
      id: doc.id,
      title: title,
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _apiBaseUrl = "https://fed2-2400-adc1-40d-2f00-591c-ae62-a8dc-3439.ngrok-free.app"; // EXAMPLE: For Android Emulator. **ADJUST THIS**
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  String? _currentSessionId;
  List<ChatMessage> _messages = []; // Make sure this is initialized
  List<ChatSession> _chatSessionsList = []; // Make sure this is initialized
  bool _isLoadingResponse = false;
  bool _isLoadingSessions = true; // Initialize to true
  StreamSubscription? _messagesSubscription;


  @override
  void initState() {
    super.initState();
    _initializeUserAndLoadSessions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeUserAndLoadSessions() async {
    if (!mounted) return;
    setState(() => _isLoadingSessions = true);

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("AIChatbotScreen: User not logged in during initialization.");
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
          _messages = [ChatMessage(id: 'error_no_user', text: "Authentication error. Please log in.", isUserMessage: false, timestamp: DateTime.now())];
        });
      }
      return;
    }
    _currentUserId = user.uid;
    debugPrint("AIChatbotScreen: Initialized with userId: $_currentUserId");

    await _fetchChatSessions();

    if (_chatSessionsList.isNotEmpty) {
      debugPrint("AIChatbotScreen: Loading most recent session: ${_chatSessionsList.first.id}");
      await _loadSession(_chatSessionsList.first.id);
    } else {
      debugPrint("AIChatbotScreen: No existing sessions found, starting a new one.");
      await _startNewSession(isInitialSession: true);
    }
    if (mounted) {
      setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _fetchChatSessions() async {
    if (_currentUserId == null) {
      debugPrint("AIChatbotScreen: Cannot fetch sessions, userId is null.");
      if (mounted) setState(() => _isLoadingSessions = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoadingSessions = true);
    try {
      debugPrint("AIChatbotScreen: Fetching chat sessions for userId: $_currentUserId");
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('aiChatSessions')
          .orderBy('lastUpdatedAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _chatSessionsList = snapshot.docs.map((doc) => ChatSession.fromFirestore(doc)).toList();
          _isLoadingSessions = false;
          debugPrint("AIChatbotScreen: Fetched ${_chatSessionsList.length} sessions.");
        });
      }
    } catch (e) {
      debugPrint("AIChatbotScreen: Error fetching chat sessions: $e");
      if (mounted) {
        setState(() => _isLoadingSessions = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading sessions: $e")));
      }
    }
  }

  Future<void> _startNewSession({bool fromDrawer = false, bool isInitialSession = false}) async {
    if (_currentUserId == null) {
      debugPrint("AIChatbotScreen: Cannot start new session, userId is null.");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot start session: User not identified.")));
      return;
    }
    if (fromDrawer && Navigator.canPop(context) && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }

    if (mounted) {
      setState(() {
        _isLoadingResponse = true;
        _messages = []; // Clear UI messages for the new session
        _currentSessionId = null; // Explicitly nullify until new one is created
      });
    }
    _messagesSubscription?.cancel(); // Cancel listener for old session messages

    try {
      final newSessionRef = _firestore
          .collection('users')
          .doc(_currentUserId!) // Assert non-null as we checked
          .collection('aiChatSessions')
          .doc(); // Auto-generate ID

      final now = Timestamp.now();
      String initialTitle = "Chat started ${DateFormat.yMd().add_jm().format(now.toDate())}";

      await newSessionRef.set({
        'title': initialTitle,
        'userId': _currentUserId!,
        'createdAt': now,
        'lastUpdatedAt': now,
      });
      debugPrint("AIChatbotScreen: New session document CREATED with ID: ${newSessionRef.id}");

      if (mounted) {
        // Set the new session ID and load it (it will be empty or have a greeting)
        await _loadSession(newSessionRef.id);
        await _fetchChatSessions(); // Refresh session list in drawer
      }

      // Add initial greeting message to this new session
      final greetingMessage = ChatMessage(
          id: 'greeting_${newSessionRef.id}',
          text: "Hello! I'm CureAI. How can I assist you in this new session?",
          isUserMessage: false,
          timestamp: DateTime.now()
      );
      // Ensure _currentSessionId is set by _loadSession before saving greeting
      if (_currentSessionId == newSessionRef.id) {
        await _saveMessageToCurrentSession(greetingMessage, isGreeting: true);
      } else {
        debugPrint("AIChatbotScreen: Mismatch session ID after new session creation. Not saving greeting to DB immediately.");
      }


    } catch (e) {
      debugPrint("AIChatbotScreen: Error starting new session: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to start new session: ${e.toString()}")));
    } finally {
      if (mounted) {
        setState(() { _isLoadingResponse = false; });
      }
    }
  }

  Future<void> _loadSession(String sessionId) async {
    if (_currentUserId == null) {
      debugPrint("AIChatbotScreen: Cannot load session, userId is null.");
      return;
    }
    if (mounted && Navigator.canPop(context) && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context); // Close drawer if opening from there
    }
    debugPrint("AIChatbotScreen: Loading session ID: $sessionId for user: $_currentUserId");

    if(mounted) {
      setState(() {
        _currentSessionId = sessionId;
        _messages = []; // Clear previous messages
        _isLoadingResponse = true;
      });
    }

    _messagesSubscription?.cancel();
    _messagesSubscription = _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('aiChatSessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _messages = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
          _isLoadingResponse = false; // Stop loading once messages are fetched/updated
        });
        _scrollToBottom();
        debugPrint("AIChatbotScreen: Loaded ${_messages.length} messages for session $sessionId.");
      }
    }, onError: (error) {
      debugPrint("AIChatbotScreen: Error loading messages for session $sessionId: $error");
      if(mounted) {
        setState(() => _isLoadingResponse = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading messages: $error")));
      }
    });

    // If after setting up the listener, the list is still empty (e.g., a truly new session), stop loading.
    if (_messages.isEmpty && mounted) {
      setState(() => _isLoadingResponse = false);
    }
  }

  Future<void> _saveMessageToCurrentSession(ChatMessage message, {bool isGreeting = false}) async {
    if (_currentUserId == null) {
      debugPrint("AIChatbotScreen: Cannot save message, _currentUserId is null.");
      return;
    }
    if (_currentSessionId == null) {
      debugPrint("AIChatbotScreen: Cannot save message, _currentSessionId is null. Attempting to start a new session.");
      // This indicates an issue, a session should always be active.
      // As a safeguard, try to ensure a session exists.
      await _startNewSession();
      if(_currentSessionId == null) { // If still null after attempt
        debugPrint("AIChatbotScreen: Failed to ensure session for saving message.");
        return;
      }
    }
    debugPrint("AIChatbotScreen: Saving message to session $_currentSessionId for user $_currentUserId: ${message.text}");

    final messageData = {
      'text': message.text,
      'sender': message.isUserMessage ? 'user' : 'ai',
      'timestamp': Timestamp.fromDate(message.timestamp),
      'diagnosis': message.diagnosis,
    };

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('aiChatSessions')
          .doc(_currentSessionId!)
          .collection('messages')
          .add(messageData);
      debugPrint("AIChatbotScreen: Message saved successfully to Firestore.");

      // Update session's lastUpdatedAt and title (if it's the first user message)
      String currentSessionTitle = _chatSessionsList.firstWhere((s) => s.id == _currentSessionId, orElse: () => ChatSession(id: '', title: '', lastUpdatedAt: DateTime.now())).title;
      bool isDefaultTitle = currentSessionTitle.startsWith("Chat started") || currentSessionTitle.startsWith("Session ");


      Map<String, dynamic> sessionUpdateData = {
        'lastUpdatedAt': Timestamp.now(),
      };

      // Update title only if it's the user's first message in this session and title is still default
      if (message.isUserMessage && !isGreeting && isDefaultTitle && _messages.where((m) => m.isUserMessage).length <= 1) {
        String newTitle = "Chat: ${message.text.length > 30 ? message.text.substring(0,27) + '...' : message.text}";
        sessionUpdateData['title'] = newTitle;
        debugPrint("AIChatbotScreen: Updating session title for $_currentSessionId to: $newTitle");
      }

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('aiChatSessions')
          .doc(_currentSessionId!)
          .update(sessionUpdateData);

      if (sessionUpdateData.containsKey('title')) {
        await _fetchChatSessions(); // Refresh drawer if title potentially changed
      }

    } catch (e) {
      debugPrint("AIChatbotScreen: Error saving message to Firestore: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save message: ${e.toString()}")));
    }
  }

  Future<void> _sendMessageToAPI(String text) async {
    if (text.trim().isEmpty) return;
    if (_currentUserId == null) {
      debugPrint("AIChatbotScreen: Cannot send message, user not identified.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot send message: User not identified.")));
      return;
    }
    if (_currentSessionId == null) {
      debugPrint("AIChatbotScreen: No active session. Starting new one before sending message.");
      await _startNewSession(); // Ensure a session is active
      if (_currentSessionId == null) { // If still null
        debugPrint("AIChatbotScreen: Critical error - could not establish a session.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Could not establish a chat session.")));
        return;
      }
    }

    final userChatMessage = ChatMessage(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}', // Temporary local ID
        text: text,
        isUserMessage: true,
        timestamp: DateTime.now());

    setState(() {
      _messages.add(userChatMessage);
      _isLoadingResponse = true;
    });
    _messageController.clear();
    _scrollToBottom();
    await _saveMessageToCurrentSession(userChatMessage); // Save user message

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/v1/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': _currentUserId!,
          'user_message': text,
          'conversation_id': _currentSessionId,
        }),
      );

      String aiText;
      String? diagnosisText;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        aiText = responseData['response'] as String? ?? "Sorry, I couldn't process that.";
        final bool diagnosisPerformed = responseData['diagnosis_performed'] ?? false;
        if (diagnosisPerformed && responseData['latest_diagnosis'] != null) {
          diagnosisText = responseData['latest_diagnosis']['text'] as String?;
        }
      } else {
        debugPrint("API Error: ${response.statusCode} ${response.body}");
        aiText = "Error ${response.statusCode}: I'm having trouble reaching my knowledge base.";
      }
      final aiChatMessage = ChatMessage(
        id: 'local_ai_${DateTime.now().millisecondsSinceEpoch}', // Temporary local ID
        text: aiText,
        isUserMessage: false,
        timestamp: DateTime.now(),
        diagnosis: diagnosisText,
      );
      // Add to UI and then save
      if (mounted) {
        setState(() { _messages.add(aiChatMessage);});
      }
      await _saveMessageToCurrentSession(aiChatMessage);

    } catch (e) {
      debugPrint("Network or parsing error: $e");
      final errorMessage = "Sorry, I'm having trouble connecting. Please check your network and try again.";
      final aiChatMessage = ChatMessage(
        id: 'local_error_${DateTime.now().millisecondsSinceEpoch}',
        text: errorMessage,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      if (mounted) {
        setState(() { _messages.add(aiChatMessage); });
      }
      await _saveMessageToCurrentSession(aiChatMessage);
    } finally {
      if (mounted) {
        setState(() { _isLoadingResponse = false; });
      }
      _scrollToBottom();
    }
  }

  // --- DELETE SESSION LOGIC ---
  Future<void> _deleteSession(String sessionId) async {
    if (_currentUserId == null) return;
    if (Navigator.canPop(context) && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context); // Close drawer first
    }

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Session"),
        content: const Text("Are you sure you want to delete this chat session and all its messages? This action cannot be undone."),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: Text("Delete", style: TextStyle(color: AppColors.error)), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (confirmDelete == true) {
      debugPrint("AIChatbotScreen: Deleting session $sessionId for user $_currentUserId");
      try {
        // 1. Delete all messages in the subcollection (batched delete)
        final messagesSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('aiChatSessions')
            .doc(sessionId)
            .collection('messages')
            .get();

        WriteBatch batch = _firestore.batch();
        for (DocumentSnapshot doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint("AIChatbotScreen: Deleted ${messagesSnapshot.docs.length} messages for session $sessionId.");

        // 2. Delete the session document itself
        await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('aiChatSessions')
            .doc(sessionId)
            .delete();
        debugPrint("AIChatbotScreen: Deleted session document $sessionId.");

        // 3. Refresh UI
        await _fetchChatSessions(); // Refresh the list in the drawer
        if (_currentSessionId == sessionId) {
          // If the deleted session was the active one, load the most recent or start new
          if (_chatSessionsList.isNotEmpty) {
            await _loadSession(_chatSessionsList.first.id);
          } else {
            await _startNewSession(isInitialSession: true);
          }
        }
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Session deleted successfully.")));
      } catch (e) {
        debugPrint("AIChatbotScreen: Error deleting session $sessionId: $e");
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete session: ${e.toString()}")));
      }
    }
  }


  // --- UI BUILD METHODS ---
  @override
  Widget build(BuildContext context) { /* ... Same as your previous build method, ensure it uses _isLoadingSessions and _messages appropriately ... */
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('CureAI Chatbot', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: _buildChatHistoryDrawer(),
      body: Column(
        children: [
          Expanded(
            child: (_currentUserId == null || (_isLoadingSessions && _messages.isEmpty && _currentSessionId == null))
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty && !_isLoadingResponse
                ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 60, color: AppColors.gray),
                    const SizedBox(height: 16),
                    const Text("No messages in this session yet.", style: TextStyle(color: AppColors.gray, fontSize: 16)),
                    if (_currentSessionId == null) // Only show if no session ID (implies it's truly empty at start)
                      const Text("Start a new conversation or select one from the history.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray)),
                  ],
                )
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoadingResponse && _messages.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.light),
            ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) { /* ... Same as your previous _buildMessageBubble ... */
    final isUser = message.isUserMessage;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Max width for bubbles
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.light, // Changed AI bubble color
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18.0),
            topRight: const Radius.circular(18.0),
            bottomLeft: isUser ? const Radius.circular(18.0) : const Radius.circular(4.0), // Different corner for AI
            bottomRight: isUser ? const Radius.circular(4.0) : const Radius.circular(18.0), // Different corner for user
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isUser ? AppColors.white : AppColors.dark, fontSize: 15.5),
            ),
            if (message.diagnosis != null && message.diagnosis!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: (isUser ? AppColors.white : AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (isUser ? AppColors.white : AppColors.primary).withOpacity(0.3))
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_information_outlined, size: 16, color: isUser ? AppColors.white.withOpacity(0.8) : AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Diagnosis: ${message.diagnosis}",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: (isUser ? AppColors.white : AppColors.dark).withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 5),
            Text(
              "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 10,
                color: (isUser ? AppColors.white : AppColors.dark).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() { /* ... Same as your previous _buildMessageInputField ... */
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.08),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Message CureAI...',
                fillColor: AppColors.light,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: _isLoadingResponse ? null : (text) => _sendMessageToAPI(text), // Pass text
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _isLoadingResponse ? null : () => _sendMessageToAPI(_messageController.text), // Pass text
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 1,
            child: _isLoadingResponse
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHistoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
                _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@')[0] ?? "CureAI User",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            accountEmail: Text(_auth.currentUser?.email ?? "", style: const TextStyle(fontSize: 13)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: Text(
                _auth.currentUser?.displayName?.isNotEmpty == true ? _auth.currentUser!.displayName![0].toUpperCase() :
                _auth.currentUser?.email?.isNotEmpty == true ? _auth.currentUser!.email![0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 24.0, color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            title: const Text('Start New Chat Session', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () => _startNewSession(fromDrawer: true),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Past Conversations", style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(
            child: _isLoadingSessions
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _chatSessionsList.isEmpty
                ? const Center(child: Text('No past sessions found.', style: TextStyle(color: AppColors.gray)))
                : ListView.builder(
              itemCount: _chatSessionsList.length,
              itemBuilder: (context, index) {
                final session = _chatSessionsList[index];
                bool isCurrent = session.id == _currentSessionId;
                return Material(
                  color: Colors.transparent, // Let ListTile handle its own selected color
                  child: ListTile(
                    leading: Icon(Icons.history_edu_outlined, color: isCurrent ? AppColors.primary : AppColors.gray),
                    title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? AppColors.primary : AppColors.dark)
                    ),
                    subtitle: Text('Last activity: ${DateFormat.yMd().add_jm().format(session.lastUpdatedAt)}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                    tileColor: isCurrent ? AppColors.secondary.withOpacity(0.15) : null,
                    trailing: IconButton( // Delete button for individual session
                      icon: Icon(Icons.delete_outline, color: AppColors.error.withOpacity(0.7)),
                      onPressed: () => _deleteSession(session.id),
                      tooltip: "Delete session",
                    ),
                    onTap: () {
                      if (!isCurrent) {
                        _loadSession(session.id);
                      } else {
                        if (Navigator.canPop(context) && _scaffoldKey.currentState?.isDrawerOpen == true) Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: AppColors.error.withOpacity(0.8)),
            title: Text('Clear All Chat History', style: TextStyle(color: AppColors.error.withOpacity(0.9))),
            onTap: () async {
              if (Navigator.canPop(context) && _scaffoldKey.currentState?.isDrawerOpen == true) Navigator.pop(context);
              bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Delete Session"), // Minor: Title could be "Delete All Sessions"
                    content: const Text("Are you sure you want to delete this chat session and all its messages? This action cannot be undone."), // Minor: Content could be "Are you sure you want to delete ALL chat sessions and their messages? This action cannot be undone."
                    actions: [
                      TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(ctx).pop(false)),
                      TextButton(child: Text("Delete", style: TextStyle(color: AppColors.error)), onPressed: () => Navigator.of(ctx).pop(true)),
                    ],
                  )
              );

              if (confirm == true && _currentUserId != null) {
                final sessionsCollection = _firestore.collection('users').doc(_currentUserId).collection('aiChatSessions');
                final snapshot = await sessionsCollection.get();
                WriteBatch batch = _firestore.batch();
                for (var doc in snapshot.docs) {
                  // For deleting subcollections robustly, a Cloud Function is better.
                  // Client-side delete of subcollection messages first:
                  final messagesSubCollection = await doc.reference.collection('messages').get();
                  for (var msgDoc in messagesSubCollection.docs) {
                    batch.delete(msgDoc.reference);
                  }
                  batch.delete(doc.reference); // This deletes the session document
                }

                await batch.commit();
                debugPrint("AIChatbotScreen: Batch delete committed for all sessions and messages.");

                if (mounted) {
                  setState(() {
                    _chatSessionsList = []; // Explicitly clear the local list for the drawer
                    _messages = [];        // Clear current messages
                    _currentSessionId = null; // No active session
                    _isLoadingSessions = true; // Show loading while starting new
                  });
                }

                // Now fetch (which should return empty) and start a new session
                await _fetchChatSessions(); // This should now correctly fetch an empty list
                await _startNewSession(isInitialSession: true);

                if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All chat history deleted.")));

              }
            },
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() { // Same as before
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

}




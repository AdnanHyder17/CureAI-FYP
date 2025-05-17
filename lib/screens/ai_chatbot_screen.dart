// lib/screens/ai_chatbot_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';

import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart';
import 'package:p1/widgets/custom_textfield.dart';

// --- Data Models ---
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isDiagnosis; // Flag to indicate if this message contains diagnosis

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isDiagnosis = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? (data['role'] == 'user'), // Compatibility
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDiagnosis: data['isDiagnosis'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'isUser': isUser,
      'role': isUser ? 'user' : 'assistant',
      'timestamp': Timestamp.fromDate(timestamp),
      'isDiagnosis': isDiagnosis,
    };
  }
}

class ChatSessionMetadata {
  final String id;
  String name; // Allow renaming sessions later if needed
  final DateTime createdAt;
  String? lastMessageSnippet;
  DateTime? lastActivityAt;

  ChatSessionMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastMessageSnippet,
    this.lastActivityAt,
  });

  factory ChatSessionMetadata.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatSessionMetadata(
      id: doc.id,
      name: data['name'] ?? 'Session on ${DateFormat.yMd().add_jm().format((data['createdAt'] as Timestamp).toDate())}',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageSnippet: data['lastMessageSnippet'] as String?,
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageSnippet': lastMessageSnippet,
      'lastActivityAt': lastActivityAt != null ? Timestamp.fromDate(lastActivityAt!) : FieldValue.serverTimestamp(),
    };
  }
}

// --- API Service ---
class AIChatService {
  final String _apiBaseUrl = "https://5eae-2400-adc1-40d-2f00-5859-b363-cc6b-5441.ngrok-free.app/api/v1"; // Your ngrok URL

  Future<Map<String, dynamic>> startSession(String patientId, String? medicalHistory) async {
    debugPrint("[AIChatService] Starting session for patient: $patientId");
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/session/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'patient_id': patientId, 'medical_history': medicalHistory}),
    );
    if (response.statusCode == 200) {
      debugPrint("[AIChatService] Session started successfully. Response: ${response.body}");
      return jsonDecode(response.body);
    } else {
      debugPrint("[AIChatService] Error starting session: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to start session: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String patientId, String userMessage) async {
    debugPrint("[AIChatService] Sending message for patient $patientId: $userMessage");
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'patient_id': patientId, 'user_message': userMessage}),
    );
    if (response.statusCode == 200) {
      debugPrint("[AIChatService] Message sent successfully. Response: ${response.body}");
      return jsonDecode(response.body);
    } else {
      debugPrint("[AIChatService] Error sending message: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to send message: ${response.statusCode} ${response.body}');
    }
  }
  Future<void> resetBackendSession(String patientId) async {
    debugPrint("[AIChatService] Resetting backend session for patient: $patientId");
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/session/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'patient_id': patientId, 'keep_system_prompt': false}), // Or true based on desired behavior
    );
    if (response.statusCode == 200) {
      debugPrint("[AIChatService] Backend session reset successfully.");
    } else {
      debugPrint("[AIChatService] Error resetting backend session: ${response.statusCode} - ${response.body}");
      // Optionally throw an exception or handle error
    }
  }
}

// --- ChangeNotifier for State Management ---
class AIConversationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AIChatService _apiService = AIChatService();
  final Uuid _uuid = const Uuid();

  String? _currentPatientId;
  String _patientMedicalHistory = "";
  List<ChatSessionMetadata> _sessions = [];
  String? _activeSessionId;
  List<ChatMessage> _messages = [];

  bool _isLoadingPatientData = true;
  bool _isLoadingSessions = true;
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  String? _errorMessage;

  // Getters
  bool get isLoadingPatientData => _isLoadingPatientData;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  List<ChatSessionMetadata> get sessions => _sessions;
  String? get activeSessionId => _activeSessionId;
  List<ChatMessage> get messages => _messages;
  String? get errorMessage => _errorMessage;

  AIConversationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "User not logged in.";
      _isLoadingPatientData = false;
      _isLoadingSessions = false;
      notifyListeners();
      return;
    }
    _currentPatientId = user.uid;
    await _fetchPatientDataAndCompileHistory();
    await _loadSessions();
    if (_sessions.isNotEmpty) {
      // Sort sessions by last activity or creation date to load the most recent one.
      _sessions.sort((a, b) => (b.lastActivityAt ?? b.createdAt).compareTo(a.lastActivityAt ?? a.createdAt));
      await selectSession(_sessions.first.id);
    } else {
      await startNewSession(); // Automatically start a new session if none exist
    }
    _isLoadingPatientData = false;
    _isLoadingSessions = false;
    notifyListeners();
  }

  Future<void> _fetchPatientDataAndCompileHistory() async {
    if (_currentPatientId == null) return;
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentPatientId!).get();
      DocumentSnapshot patientDoc = await _firestore.collection('patients').doc(_currentPatientId!).get();

      Map<String, dynamic> userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
      Map<String, dynamic> patientData = patientDoc.exists ? patientDoc.data() as Map<String, dynamic> : {};

      // Compile a comprehensive medical history string
      List<String> historyParts = [];
      historyParts.add("Patient Name: ${userData['nickname'] ?? 'N/A'}");
      final age = patientData['basicInfo']?['age'] ?? patientData['age'];
      if (age != null) historyParts.add("Age: $age");
      final gender = patientData['basicInfo']?['gender'] ?? patientData['gender'];
      if (gender != null) historyParts.add("Gender: $gender");

      final healthProfile = patientData['healthProfile'] as Map<String, dynamic>? ?? {};
      if ((healthProfile['chronicConditionsSelected'] as List<dynamic>? ?? []).isNotEmpty) {
        historyParts.add("Chronic Conditions: ${(healthProfile['chronicConditionsSelected'] as List<dynamic>).join(', ')}");
      }
      if (healthProfile['chronicConditionsOther'] != null && (healthProfile['chronicConditionsOther'] as String).isNotEmpty) {
        historyParts.add("Other Chronic Conditions: ${healthProfile['chronicConditionsOther']}");
      }
      if (healthProfile['allergiesDetails'] != null && (healthProfile['allergiesDetails'] as String).isNotEmpty) {
        historyParts.add("Allergies: ${healthProfile['allergiesDetails']}");
      }
      // Add more fields as needed from patientData (e.g., medications, surgeries)

      _patientMedicalHistory = historyParts.join("\n");
      debugPrint("[AIProvider] Compiled Medical History: $_patientMedicalHistory");

    } catch (e) {
      _errorMessage = "Failed to load patient data.";
      debugPrint("[AIProvider] Error fetching patient data: $e");
    }
    notifyListeners();
  }

  Future<void> _loadSessions() async {
    if (_currentPatientId == null) return;
    _isLoadingSessions = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .collection('aiChatSessions')
          .orderBy('lastActivityAt', descending: true) // Or 'createdAt'
          .get();
      _sessions = snapshot.docs.map((doc) => ChatSessionMetadata.fromFirestore(doc)).toList();
      debugPrint("[AIProvider] Loaded ${_sessions.length} sessions.");
    } catch (e) {
      _errorMessage = "Failed to load chat sessions.";
      debugPrint("[AIProvider] Error loading sessions: $e");
    }
    _isLoadingSessions = false;
    notifyListeners();
  }

  Future<void> startNewSession() async {
    if (_currentPatientId == null) return;
    _isSendingMessage = true; // Use this as a general "session starting" indicator
    notifyListeners();

    final newSessionId = _uuid.v4();
    final newSession = ChatSessionMetadata(
      id: newSessionId,
      name: "Session - ${DateFormat.yMd().add_jm().format(DateTime.now())}",
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );

    try {
      // 1. Call backend to start/reset its context with patient history
      await _apiService.startSession(_currentPatientId!, _patientMedicalHistory);

      // 2. Create session metadata in Firestore
      await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .collection('aiChatSessions')
          .doc(newSessionId)
          .set(newSession.toFirestore());

      _sessions.insert(0, newSession); // Add to top of list
      await selectSession(newSessionId, isNewSession: true); // isNewSession skips loading messages
      debugPrint("[AIProvider] New session started: $newSessionId");

    } catch (e) {
      _errorMessage = "Failed to start new session.";
      debugPrint("[AIProvider] Error starting new session: $e");
    }
    _isSendingMessage = false;
    notifyListeners();
  }

  Future<void> selectSession(String sessionId, {bool isNewSession = false}) async {
    _activeSessionId = sessionId;
    _messages = [];
    _errorMessage = null;
    if (!isNewSession) {
      await _loadMessagesForSession(sessionId);
    } else {
      // For a new session, messages list is already empty.
      // The initial system prompt from backend won't be shown unless we make a dummy call or backend sends it.
      // For now, new session starts blank until user sends first message.
      _isLoadingMessages = false; // No messages to load for a brand new session
    }
    debugPrint("[AIProvider] Session selected: $sessionId. New: $isNewSession");
    notifyListeners();
  }

  Future<void> _loadMessagesForSession(String sessionId) async {
    if (_currentPatientId == null) return;
    _isLoadingMessages = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .collection('aiChatSessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
      _messages = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
      debugPrint("[AIProvider] Loaded ${_messages.length} messages for session $sessionId");
    } catch (e) {
      _errorMessage = "Failed to load messages.";
      debugPrint("[AIProvider] Error loading messages for session $sessionId: $e");
    }
    _isLoadingMessages = false;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    if (_currentPatientId == null) return;
    try {
      // Delete messages subcollection (batched delete for large histories if needed)
      final messagesSnapshot = await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .collection('aiChatSessions')
          .doc(sessionId)
          .collection('messages')
          .get();
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete session metadata document
      await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .collection('aiChatSessions')
          .doc(sessionId)
          .delete();

      _sessions.removeWhere((s) => s.id == sessionId);
      if (_activeSessionId == sessionId) {
        _activeSessionId = null;
        _messages = [];
        if (_sessions.isNotEmpty) {
          await selectSession(_sessions.first.id);
        } else {
          await startNewSession(); // Start a new one if all are deleted
        }
      }
      debugPrint("[AIProvider] Session deleted: $sessionId");
    } catch (e) {
      _errorMessage = "Failed to delete session.";
      debugPrint("[AIProvider] Error deleting session $sessionId: $e");
    }
    notifyListeners();
  }

  Future<void> sendMessageToAI(String text) async {
    if (_currentPatientId == null || _activeSessionId == null || text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isSendingMessage = true;
    notifyListeners();

    try {
      // Store user message in Firestore for the current session
      await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .collection('aiChatSessions')
          .doc(_activeSessionId!)
          .collection('messages')
          .doc(userMessage.id)
          .set(userMessage.toFirestore());

      // Update session metadata (last message snippet and activity time)
      await _firestore.collection('users').doc(_currentPatientId!).collection('aiChatSessions').doc(_activeSessionId!).update({
        'lastMessageSnippet': text.trim().length > 50 ? '${text.trim().substring(0, 47)}...' : text.trim(),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });


      // Call backend API
      final response = await _apiService.sendMessage(_currentPatientId!, text.trim());

      final aiResponseText = response['response'] as String? ?? "Sorry, I couldn't process that.";
      final bool diagnosisPerformed = response['diagnosis_performed'] as bool? ?? false;
      final Map<String, dynamic>? latestDiagnosisData = response['latest_diagnosis'] as Map<String, dynamic>?;

      String displayResponse = aiResponseText;
      bool isDiagnosisMessage = false;

      if (diagnosisPerformed && latestDiagnosisData != null) {
        final diagnosisText = latestDiagnosisData['text'] as String? ?? "Diagnosis details not available.";
        // The backend's response already includes the diagnosis text combined with a disclaimer.
        // We'll use the 'response' field directly which should contain this combined text.
        // displayResponse = "Diagnosis:\n$diagnosisText\n\nDISCLAIMER: This is not a definitive diagnosis. Please consult a healthcare professional for proper medical advice.";
        isDiagnosisMessage = true; // Mark this message as containing the diagnosis
      }

      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        text: displayResponse,
        isUser: false,
        timestamp: DateTime.now(),
        isDiagnosis: isDiagnosisMessage,
      );
      _messages.add(aiMessage);

      // Store AI message in Firestore
      await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .collection('aiChatSessions')
          .doc(_activeSessionId!)
          .collection('messages')
          .doc(aiMessage.id)
          .set(aiMessage.toFirestore());

      // Update session metadata again for AI's message
      await _firestore.collection('users').doc(_currentPatientId!).collection('aiChatSessions').doc(_activeSessionId!).update({
        'lastMessageSnippet': displayResponse.length > 50 ? '${displayResponse.substring(0, 47)}...' : displayResponse,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });


    } catch (e) {
      _errorMessage = "Failed to send message or get response.";
      debugPrint("[AIProvider] Error sending message: $e");
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        text: "Error: Could not connect to AI. Please try again. ($e)",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    }
    _isSendingMessage = false;
    notifyListeners();
  }
}


// --- UI Screen ---
class AIChatBotScreen extends StatelessWidget {
  const AIChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AIConversationProvider(),
      child: const _AIChatBotScreenView(),
    );
  }
}

class _AIChatBotScreenView extends StatefulWidget {
  const _AIChatBotScreenView();

  @override
  State<_AIChatBotScreenView> createState() => _AIChatBotScreenViewState();
}

class _AIChatBotScreenViewState extends State<_AIChatBotScreenView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) { // A
        if (_scrollController.hasClients) { // B - Good to re-check
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AIConversationProvider>(context);

    // Scroll to bottom when messages change or keyboard appears
    WidgetsBinding.instance.addPostFrameCallback((_) { // C
      if (provider.messages.isNotEmpty || MediaQuery.of(context).viewInsets.bottom > 0) {
        _scrollToBottom();
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: provider.isLoadingSessions || provider.activeSessionId == null
            ? const Text("AI Chatbot", style: TextStyle(color: AppColors.white))
            : DropdownButton<String>(
          value: provider.activeSessionId,
          dropdownColor: AppColors.primary,
          iconEnabledColor: AppColors.white,
          underline: Container(),
          items: [
            ...provider.sessions.map((session) => DropdownMenuItem(
              value: session.id,
              child: Text(session.name, style: const TextStyle(color: AppColors.white, fontSize: 16)),
            )),
            const DropdownMenuItem<String>(
              value: "_new_session_", // Special value for new session
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: AppColors.white, size: 20),
                  SizedBox(width: 8),
                  Text("New Session", style: TextStyle(color: AppColors.white, fontSize: 16)),
                ],
              ),
            ),
          ],
          onChanged: (String? sessionId) {
            if (sessionId == "_new_session_") {
              provider.startNewSession();
            } else if (sessionId != null) {
              provider.selectSession(sessionId);
            }
          },
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          if (provider.activeSessionId != null && provider.sessions.any((s) => s.id == provider.activeSessionId))
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.white),
              tooltip: "Delete Current Session",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Delete Session?"),
                    content: Text("Are you sure you want to delete the session '${provider.sessions.firstWhere((s) => s.id == provider.activeSessionId).name}'? This cannot be undone."),
                    actions: [
                      TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(ctx).pop(false)),
                      TextButton(child: Text("Delete", style: TextStyle(color: AppColors.error)), onPressed: () => Navigator.of(ctx).pop(true)),
                    ],
                  ),
                );
                if (confirm == true && provider.activeSessionId != null) {
                  provider.deleteSession(provider.activeSessionId!);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (provider.isLoadingPatientData || provider.isLoadingSessions && provider.sessions.isEmpty)
            const Expanded(child: Center(child: LoadingIndicator(message: "Initializing Chat...")))
          else if (provider.errorMessage != null)
            Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error: ${provider.errorMessage}", style: const TextStyle(color: AppColors.error)))))
          else
            Expanded(
              child: provider.isLoadingMessages
                  ? const Center(child: LoadingIndicator(message: "Loading messages..."))
                  : provider.messages.isEmpty && !provider.isSendingMessage
                  ? _buildEmptyChatView(context, provider)
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final message = provider.messages[index];
                  // _scrollToBottom(); // D - Calling it here for every item is excessive
                  // It was commented out in the full code, which is good.
                  return _buildMessageBubble(message);
                },
              ),
            ),
          if (provider.isSendingMessage && provider.messages.isNotEmpty && provider.messages.last.isUser)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LoadingIndicator(message: "CureAI is typing...", size: 20),
            ),
          _buildInputField(context, provider),
        ],
      ),
    );
  }
  Widget _buildEmptyChatView(BuildContext context, AIConversationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.gray.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              "Hello! How can I help you today?",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.dark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Describe your symptoms or health concerns to get started.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
            if (provider.sessions.length > 1 || (provider.sessions.length == 1 && provider.activeSessionId == null)) // If there are other sessions or current is placeholder
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextButton.icon(
                    icon: const Icon(Icons.history_rounded),
                    label: const Text("View Past Sessions"),
                    onPressed: () { /* Could open a dialog or drawer to explicitly select session */
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Use dropdown in AppBar to switch sessions.")));
                    }
                ),
              )
          ],
        ),
      ),
    );
  }


  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            message.isDiagnosis
                ? MarkdownBody(
              data: message.text, // Assume diagnosis is markdown formatted
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? AppColors.white : AppColors.dark,
                  fontSize: 15.5,
                ),
                // Add more styles for h1, h2, strong, em, etc. if your backend uses them for diagnosis
                strong: TextStyle(fontWeight: FontWeight.bold, color: isUser ? AppColors.white : AppColors.dark),
                listBullet:  Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? AppColors.white : AppColors.dark,
                ),
              ),
            )
                : Text(
              message.text,
              style: TextStyle(
                color: isUser ? AppColors.white : AppColors.dark,
                fontSize: 15.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isUser ? AppColors.white.withOpacity(0.7) : AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, AIConversationProvider provider) {
    return Container(
      padding: EdgeInsets.only(
          left: 12.0,
          right: 8.0,
          top: 8.0,
          bottom: MediaQuery.of(context).padding.bottom + 8.0 // SafeArea bottom padding
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.grey.withOpacity(0.1),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: CustomTextField( // Using your CustomTextField
                controller: _textController,
                labelText: "Type your message...", // Used as hint effectively if border is none
                hintText: "Describe your symptoms...",
                maxLines: 1, // Can be set to more if desired
                isDense: true,
                // Custom styling for the input field itself
                // This needs to be adapted if CustomTextField doesn't support all these directly
                // For now, relying on CustomTextField's internal styling.
              )
          ),
          const SizedBox(width: 8),
          MaterialButton(
            onPressed: provider.isSendingMessage
                ? null
                : () {
              if (_textController.text.trim().isNotEmpty) {
                provider.sendMessageToAI(_textController.text.trim());
                _textController.clear();
                _scrollToBottom();
              }
            },
            shape: const CircleBorder(),
            color: AppColors.primary,
            disabledColor: AppColors.gray,
            padding: const EdgeInsets.all(12),
            elevation: 1.0,
            child: provider.isSendingMessage
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : const Icon(Icons.send_rounded, color: AppColors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
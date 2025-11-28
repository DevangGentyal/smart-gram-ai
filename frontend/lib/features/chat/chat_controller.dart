// Chat controller with stable STT + TTS
// Uses one-time STT initialization + cooldown fixes.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// -----------------------------
// Message Model
// -----------------------------
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isPlayingAudio = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isPlayingAudio;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isPlayingAudio,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isPlayingAudio: isPlayingAudio ?? this.isPlayingAudio,
    );
  }
}

// -----------------------------
// Chat State
// -----------------------------
class ChatState {
  const ChatState({
    required this.messages,
    this.isRecording = false,
    this.recordingText = '',
    this.micLevel = 0.0,
  });

  final List<ChatMessage> messages;
  final bool isRecording;
  final String recordingText;
  final double micLevel;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isRecording,
    String? recordingText,
    double? micLevel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isRecording: isRecording ?? this.isRecording,
      recordingText: recordingText ?? this.recordingText,
      micLevel: micLevel ?? this.micLevel,
    );
  }
}

// -----------------------------
// Chat Controller
// -----------------------------
class ChatController extends StateNotifier<ChatState> {
  ChatController()
      : super(ChatState(messages: [
          ChatMessage(
            id: 'seed-1',
            text: 'Hello! I am Smart Gram AI. How can I help?',
            isUser: false,
            timestamp: DateTime.now(),
          )
        ])) {
    _initTTS();
    _initSTT(); // initialize speech engine ONCE
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // -----------------------------
  // Init TTS
  // -----------------------------
  Future<void> _initTTS() async {
    await _tts.setLanguage("en-IN");
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
  }

  // -----------------------------
  // Init STT (only once)
  // -----------------------------
  Future<void> _initSTT() async {
    await _speech.initialize(
      onStatus: (s) {},
      onError: (e) {},
    );
  }

  // -----------------------------
  // Send User Text
  // -----------------------------
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, userMsg]);

    await _replyAsAI(text);
  }

  // -----------------------------
  // AI Reply
  // -----------------------------
  Future<void> _replyAsAI(String userPrompt) async {
    // TODO: Replace with API POST call later
    final url = Uri.parse('https://smart-gram-ai.onrender.com/main');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "query": userPrompt,
        "chat_history": _buildChatHistory(),
      }),
    );
    String reply = "";
    String language = "";

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Success");
      print(data);
      reply = data["answer"];
      language = data["language"];
    } else {
      print("Failed: ${response.statusCode}");
      print(response.body);
      reply = response.body;
    }

    final aiMessage = ChatMessage(
      id: "ai-${DateTime.now().millisecondsSinceEpoch}",
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, aiMessage]);
    // Set STT Language
    // _tts.setLanguage(language);
    await _tts.speak(cleanForTTS(reply));
  }

  // -----------------------------
  // Start Listening (Hold)
  // -----------------------------
  Future<void> startListening() async {
    // 1. Mic permission
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;

    // 2. Prevent double start
    if (state.isRecording) return;

    // 3. Update UI
    state = state.copyWith(
      isRecording: true,
      recordingText: '',
      micLevel: 0.0,
    );

    // 4. Cooldown: let engine fully release from previous session
    await Future.delayed(const Duration(milliseconds: 150));

    // 5. Start listening
    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(recordingText: result.recognizedWords);
      },
      onSoundLevelChange: (level) {
        final normalized = (level / 6).clamp(0.0, 1.0);
        state = state.copyWith(micLevel: normalized);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
      ),
    );
  }

  // -----------------------------
  // Stop Listening (Release)
  // -----------------------------
  Future<void> stopListening() async {
    // Wait for FINAL results
    await Future.delayed(const Duration(milliseconds: 1000));
    await _speech.stop();

    final text = state.recordingText.trim();

    // Stop UI recording state
    state = state.copyWith(isRecording: false, micLevel: 0.0);

    // Send message if speech exists
    if (text.isNotEmpty) {
      await sendMessage(text);
    }

    // Hard reset engine to avoid "second request freeze"
    await _speech.cancel();

    // Allow engine to cool down before next listen
    await Future.delayed(const Duration(milliseconds: 250));
  }

  // -----------------------------
  // Cancel Listening (Moved finger)
  // -----------------------------
  void cancelListening() async {
    await _speech.cancel();
    state =
        state.copyWith(isRecording: false, recordingText: '', micLevel: 0.0);

    await Future.delayed(const Duration(milliseconds: 150));
  }

  // -----------------------------
  // Play / Pause AI TTS
  // -----------------------------
  void togglePlay(String messageId) async {
    final msgs = state.messages;

    ChatMessage target = msgs.firstWhere((m) => m.id == messageId);
    final bool shouldPlay = !target.isPlayingAudio;

    await _tts.stop();

    final updated = msgs.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isPlayingAudio: shouldPlay);
      }
      return m.copyWith(isPlayingAudio: false);
    }).toList();

    state = state.copyWith(messages: updated);

    if (shouldPlay) {
      await _tts.speak(target.text);

      _tts.setCompletionHandler(() {
        final reset = state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(isPlayingAudio: false);
          }
          return m;
        }).toList();

        state = state.copyWith(messages: reset);
      });
    }
  }

  // -----------------------------
  // Chat History Builder
  // -----------------------------
  List<Map<String, dynamic>> _buildChatHistory() {
    return state.messages.map((m) {
      return {
        "role": m.isUser ? "user" : "system",
        "content": m.text,
      };
    }).toList();
  }

  // -----------------------------
  // Clean TTS
  // -----------------------------
  String cleanForTTS(String text) {
    // Remove markdown symbols like *, _, -, #, >, `
    final cleaned = text
        .replaceAll(RegExp(r'[*_`>#-]'), ' ')
        // Remove multiple spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        // Trim leftover spaces
        .trim();
    return cleaned;
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

// Provider
final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatController, ChatState>(
  (ref) => ChatController(),
);

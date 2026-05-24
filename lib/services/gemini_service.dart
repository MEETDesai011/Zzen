// Gemini AI Sleep Coach Service
// SDG 3 Impact: AI-powered personalised sleep coaching supports evidence-based
// behaviour change for improved health outcomes (SDG 3.4).
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants.dart';
import '../models/sleep_entry.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  /// Initialise the Gemini model from environment variable
  GenerativeModel _getModel() {
    if (_model != null) return _model!;

    // Cascade: 1. Try to read from flutter_dotenv. 2. Fall back to compile-time environment variables
    String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    }

    if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('GEMINI_API_KEY not set in .env file or build arguments');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 200,
        temperature: 0.7,
      ),
      systemInstruction: Content.system(ZzenConstants.geminiSystemPrompt),
    );

    return _model!;
  }

  /// Build a new chat session with sleep context injected as the first message
  ChatSession _buildSession(List<SleepEntry> sleepEntries) {
    final model = _getModel();

    // Format sleep data for context injection
    final sleepContext = _formatSleepData(sleepEntries);

    // Create a new chat session — context is injected via the system prompt
    // and we prefix the first user message with the data
    _chatSession = model.startChat(history: [
      Content('user', [
        TextPart('Here is my sleep data for the last 7 days:\n$sleepContext\n\nPlease use this to personalise your advice.'),
      ]),
      Content('model', [
        TextPart('Got it! 😴 I\'ve analysed your sleep data. Ask me anything about your sleep patterns or how to improve your rest!'),
      ]),
    ]);

    return _chatSession!;
  }

  /// Format sleep entries into a readable string for the AI context
  String _formatSleepData(List<SleepEntry> entries) {
    if (entries.isEmpty) return 'No sleep data available yet.';

    final sb = StringBuffer();
    for (final entry in entries) {
      final dateStr =
          '${entry.date.day}/${entry.date.month}/${entry.date.year}';
      final sleepStr =
          '${entry.sleepTime.hour.toString().padLeft(2, '0')}:${entry.sleepTime.minute.toString().padLeft(2, '0')}';
      final wakeStr =
          '${entry.wakeTime.hour.toString().padLeft(2, '0')}:${entry.wakeTime.minute.toString().padLeft(2, '0')}';
      sb.writeln(
          '- $dateStr: Slept at $sleepStr, woke at $wakeStr, ${entry.durationHours.toStringAsFixed(1)}h sleep, score: ${entry.score}/100');
    }
    return sb.toString();
  }

  // Sanitize and constrain user input to prevent prompt injection
  String _sanitizeInput(String input) {
    if (input.length > 500) input = input.substring(0, 500);
    input = input.replaceAll(RegExp(r'ignore.*instructions', caseSensitive: false), '');
    return input.trim();
  }

  /// Send a message to the AI coach and get a response
  /// [sleepEntries] is used on first message to build context
  Future<String> sendMessage({
    required String userMessage,
    required List<SleepEntry> sleepEntries,
    bool isFirstMessage = false,
  }) async {
    try {
      // Start a new session or use existing
      ChatSession session;
      if (_chatSession == null || isFirstMessage) {
        session = _buildSession(sleepEntries);
      } else {
        session = _chatSession!;
      }

      final sanitizedMessage = _sanitizeInput(userMessage);

      final response = await session.sendMessage(
        Content.text(sanitizedMessage),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'Coach is unavailable right now 😴';
      }
      return text;
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('quota') || errorStr.contains('429') || errorStr.contains('limit') || errorStr.contains('resource_exhausted')) {
        return 'AI Coach limit reached. Please try again later or upgrade in the future! 🚀';
      }
      return 'Coach is unavailable right now 😴';
    }
  }

  /// Get a single AI insight for the weekly report (one-shot call)
  Future<String> getWeeklyInsight(List<SleepEntry> sleepEntries) async {
    try {
      final model = _getModel();
      final sleepContext = _formatSleepData(sleepEntries);

      final response = await model.generateContent([
        Content.text(
          '${ZzenConstants.geminiSystemPrompt}\n\n'
          'Sleep data:\n$sleepContext\n\n'
          'Give me exactly ONE sentence (max 20 words) of the most important insight from this week\'s sleep data.',
        ),
      ]);

      return response.text ?? 'Keep up the good sleep habits! 🌙';
    } catch (e) {
      if (kDebugMode) debugPrint('Weekly insight error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('quota') || errorStr.contains('429') || errorStr.contains('limit') || errorStr.contains('resource_exhausted')) {
        return 'AI Coach limit reached. Check back later!';
      }
      return 'Track more nights to unlock AI insights! 💤';
    }
  }

  /// Reset the chat session (e.g. when navigating away)
  void resetSession() {
    _chatSession = null;
  }
}

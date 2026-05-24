// Gemini AI Sleep Coach Service
// SDG 3 Impact: AI-powered personalised sleep coaching supports evidence-based
// behaviour change for improved health outcomes (SDG 3.4).
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('GEMINI_API_KEY not set in .env file');
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

      final response = await session.sendMessage(
        Content.text(userMessage),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'Coach is unavailable right now 😴';
      }
      return text;
    } catch (e) {
      debugPrint('Gemini error: $e');
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
      debugPrint('Weekly insight error: $e');
      return 'Track more nights to unlock AI insights! 💤';
    }
  }

  /// Reset the chat session (e.g. when navigating away)
  void resetSession() {
    _chatSession = null;
  }
}

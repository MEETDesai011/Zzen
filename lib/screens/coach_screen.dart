// AI Coach Screen — Feature 2: Gemini-powered Sleep Coach Chat
// SDG 3 Impact: Personalised AI coaching provides actionable sleep improvement
// advice, supporting mental and physical wellbeing (SDG 3.4).
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/gemini_service.dart';
import '../services/sleep_service.dart';
import '../models/sleep_entry.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<SleepEntry> _sleepEntries = [];
  bool _loadingEntries = true;
  bool _sending = false;
  bool _firstMessage = true;
  DateTime? _lastMessageTime;

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    GeminiService.instance.resetSession();
    super.dispose();
  }

  Future<void> _loadSleepData() async {
    try {
      final entries = await SleepService.instance.getLast7Days();
      setState(() {
        _sleepEntries = entries;
        _loadingEntries = false;
      });
      // Auto-send greeting with sleep context
      _addCoachMessage(
        entries.isEmpty
            ? "Hey! 👋 I'm your Zzen sleep coach. Log some sleep first and I'll give you personalised tips! In the meantime, ask me anything about sleep 😴"
            : "Hey! 👋 I've checked your last ${entries.length} nights of sleep. ${_getInitialInsight(entries)} What would you like to work on?",
      );
    } catch (e) {
      setState(() => _loadingEntries = false);
      _addCoachMessage("Hey! 👋 I'm your Zzen sleep coach. Ask me anything about improving your sleep! 😴");
    }
  }

  String _getInitialInsight(List<SleepEntry> entries) {
    final avg = entries.map((e) => e.score).reduce((a, b) => a + b) / entries.length;
    if (avg >= 70) return "Your sleep looks solid this week! 💪";
    if (avg >= 50) return "Your sleep could use some work. 🌙";
    return "Your sleep needs some serious attention. Let's fix that! 💡";
  }

  void _addCoachMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    // Rate limiting: 2 seconds cooldown
    if (_lastMessageTime != null) {
      final diff = DateTime.now().difference(_lastMessageTime!);
      if (diff.inSeconds < 2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please wait a moment before sending another message.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }
    _lastMessageTime = DateTime.now();

    _controller.clear();
    _addUserMessage(text);
    setState(() => _sending = true);

    // Show typing indicator
    setState(() {
      _messages.add(const _ChatMessage(text: '...', isUser: false, isTyping: true));
    });
    _scrollToBottom();

    try {
      final response = await GeminiService.instance.sendMessage(
        userMessage: text,
        sleepEntries: _sleepEntries,
        isFirstMessage: _firstMessage,
      );
      _firstMessage = false;

      // Remove typing indicator and add response
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _messages.add(const _ChatMessage(text: 'Coach is unavailable right now 😴', isUser: false));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ZzenTheme.primary, ZzenTheme.secondary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zzen Coach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  _loadingEntries ? 'Loading your data...' : 'Powered by Gemini 2.5 Flash',
                  style: const TextStyle(fontSize: 11, color: ZzenTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingEntries
                ? const Center(child: CircularProgressIndicator(color: ZzenTheme.primary))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: ZzenTheme.surface,
        border: Border(top: BorderSide(color: ZzenTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: 500,
              style: const TextStyle(color: ZzenTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask your sleep coach...',
                hintStyle: const TextStyle(color: ZzenTheme.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ZzenTheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _sending ? ZzenTheme.textMuted : ZzenTheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isTyping;

  const _ChatMessage({required this.text, required this.isUser, this.isTyping = false});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ZzenTheme.primary, ZzenTheme.secondary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Z', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? ZzenTheme.primary : ZzenTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isUser ? null : Border.all(color: ZzenTheme.border),
              ),
              child: message.isTyping
                  ? _TypingIndicator()
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : ZzenTheme.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Opacity(
            opacity: (_ctrl.value + i * 0.3).clamp(0.2, 1.0),
            child: Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(color: ZzenTheme.textMuted, shape: BoxShape.circle),
            ),
          ),
        )),
      ),
    );
  }
}

// Sounds Screen — Feature 6: Sleep Sound Library
// SDG 3 Impact: Sleep sounds help users relax and fall asleep faster,
// supporting better sleep quality and mental health (SDG 3.4).
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  final AudioPlayer _player = AudioPlayer();
  int? _playingIndex;
  double _volume = 0.7;
  int? _timerMinutes; // null = no timer
  bool _timerActive = false;

  final List<int> _timerOptions = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _player.setVolume(_volume);
    _player.onPlayerComplete.listen((_) {
      setState(() => _playingIndex = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleSound(int index) async {
    final sound = ZzenConstants.sleepSounds[index];
    try {
      if (_playingIndex == index) {
        // Pause currently playing
        await _player.pause();
        setState(() => _playingIndex = null);
      } else {
        // Stop current and play new
        await _player.stop();
        await _player.play(AssetSource(sound['asset']!.replaceFirst('assets/', '')));
        setState(() => _playingIndex = index);

        // Start timer if set
        if (_timerMinutes != null) {
          _startTimer(_timerMinutes!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          // Developer note: Replace placeholder MP3s with real royalty-free audio files
          content: const Text('Audio playback error. Replace placeholder MP3s with real audio files.'),
          backgroundColor: ZzenTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _startTimer(int minutes) {
    setState(() {
      _timerActive = true;
    });
    Future.delayed(Duration(minutes: minutes), () {
      if (mounted && _timerActive) {
        _player.stop();
        setState(() {
          _playingIndex = null;
          _timerActive = false;
        });
      }
    });
  }

  void _cancelTimer() {
    setState(() {
      _timerActive = false;
      _timerMinutes = null;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: const Text('Sleep Sounds'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Sound cards
                ...ZzenConstants.sleepSounds.asMap().entries.map((entry) {
                  final i = entry.key;
                  final sound = entry.value;
                  final isPlaying = _playingIndex == i;
                  return _SoundCard(
                    icon: sound['icon']!,
                    name: sound['name']!,
                    description: sound['description']!,
                    isPlaying: isPlaying,
                    onTap: () => _toggleSound(i),
                  );
                }),
                const SizedBox(height: 24),
                // Volume control
                _buildVolumeControl(),
                const SizedBox(height: 20),
                // Sleep timer
                _buildTimerSection(),
              ],
            ),
          ),
          // Timer status bar
          if (_timerActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: ZzenTheme.primary.withOpacity(0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: ZzenTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      // Note: This label won't auto-update per second in this build
                      // A Timer.periodic would be needed for live countdown
                      Text('Auto-stop in $_timerMinutes min',
                          style: const TextStyle(color: ZzenTheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  TextButton(
                    onPressed: _cancelTimer,
                    child: const Text('Cancel', style: TextStyle(color: ZzenTheme.textMuted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZzenTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZzenTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_down_rounded, color: ZzenTheme.textMuted, size: 20),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0,
                  max: 1,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    _player.setVolume(v);
                  },
                ),
              ),
              const Icon(Icons.volume_up_rounded, color: ZzenTheme.textMuted, size: 20),
            ],
          ),
          Center(
            child: Text(
              'Volume: ${(_volume * 100).round()}%',
              style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZzenTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZzenTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sleep Timer', style: TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Auto-stop after:', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _TimerChip(label: 'Off', selected: _timerMinutes == null,
                  onTap: () => setState(() => _timerMinutes = null)),
              ..._timerOptions.map((m) => _TimerChip(
                label: '${m}m',
                selected: _timerMinutes == m,
                onTap: () => setState(() => _timerMinutes = m),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SoundCard({
    required this.icon, required this.name, required this.description,
    required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPlaying ? ZzenTheme.primary.withOpacity(0.12) : ZzenTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? ZzenTheme.primary.withOpacity(0.5) : ZzenTheme.border,
          width: isPlaying ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: isPlaying ? ZzenTheme.primary.withOpacity(0.2) : ZzenTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(name, style: TextStyle(
          color: isPlaying ? ZzenTheme.primary : ZzenTheme.textPrimary,
          fontWeight: FontWeight.w600, fontSize: 15,
        )),
        subtitle: Text(description, style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
        trailing: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isPlaying ? ZzenTheme.primary : ZzenTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isPlaying ? Colors.white : ZzenTheme.textSecondary,
              size: 22,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimerChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ZzenTheme.primary : ZzenTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? ZzenTheme.primary : ZzenTheme.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : ZzenTheme.textSecondary,
          fontWeight: FontWeight.w600, fontSize: 13,
        )),
      ),
    );
  }
}

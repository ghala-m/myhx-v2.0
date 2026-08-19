import 'package:flutter/material.dart';

import '../services/voice_service.dart';

/// Mic button that dictates into a text answer. Emits the live transcript
/// through [onTranscript] so the parent can update its field/answer.
class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onTranscript;
  final bool arabic;
  final String? tooltip;

  const VoiceInputButton({
    super.key,
    required this.onTranscript,
    this.arabic = false,
    this.tooltip,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceService _voice = VoiceService();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  bool _listening = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _voice.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final ready = await _voice.init();
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
      return;
    }

    setState(() => _listening = true);
    await _voice.listen(
      arabic: widget.arabic,
      onResult: (text, isFinal) {
        widget.onTranscript(text);
        if (isFinal && mounted) setState(() => _listening = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.tooltip ?? (_listening ? 'Stop dictation' : 'Dictate'),
      child: ScaleTransition(
        scale: _listening
            ? Tween<double>(begin: 0.94, end: 1.08).animate(_pulse)
            : const AlwaysStoppedAnimation(1),
        child: IconButton.filledTonal(
          onPressed: _toggle,
          isSelected: _listening,
          icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded),
          style: IconButton.styleFrom(
            backgroundColor:
                _listening ? scheme.errorContainer : scheme.secondaryContainer,
            foregroundColor:
                _listening ? scheme.onErrorContainer : scheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

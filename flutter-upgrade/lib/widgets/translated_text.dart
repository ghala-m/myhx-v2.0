import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/translation_service.dart';

/// Shows stored (English-entered) content translated to Arabic automatically
/// when the app language is Arabic. Falls back to the original text.
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translated;
  bool _arabic = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arabic = S.of(context).isArabic;
    if (arabic != _arabic) {
      _arabic = arabic;
      _translated = arabic ? TranslationService.instance.cached(widget.text) : null;
      if (arabic && _translated == null) _translate();
    }
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translated = null;
      if (_arabic) _translate();
    }
  }

  Future<void> _translate() async {
    final result = await TranslationService.instance.toArabic(widget.text);
    if (mounted) setState(() => _translated = result);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _arabic ? (_translated ?? widget.text) : widget.text,
      style: widget.style,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}

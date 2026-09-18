import 'package:flutter/material.dart';

enum AuthMessageTone { error, success }

class AuthInlineMessage extends StatelessWidget {
  const AuthInlineMessage({
    super.key,
    required this.message,
    required this.tone,
    this.title,
    this.caption,
  });

  final String message;
  final AuthMessageTone tone;
  final String? title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone == AuthMessageTone.success
        ? const Color(0xFF0F766E)
        : theme.colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == AuthMessageTone.success
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    caption!,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.88),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F6E62)),
      ),
    );
  }
}

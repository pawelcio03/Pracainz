import 'package:flutter/material.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _AuthLoadingCard(title: title, description: description),
          ),
        ),
      ),
    );
  }
}

class _AuthLoadingCard extends StatelessWidget {
  const _AuthLoadingCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceTint = theme.colorScheme.primary.withValues(alpha: 0.05);
    final mutedTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedTextColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: 0.72,
                minHeight: 8,
                backgroundColor: surfaceTint,
              ),
            ),
            const SizedBox(height: 18),
            _AuthSkeletonBlock(width: double.infinity, height: 56),
            const SizedBox(height: 16),
            _AuthSkeletonBlock(width: double.infinity, height: 56),
            const SizedBox(height: 16),
            _AuthSkeletonBlock(width: double.infinity, height: 56),
            const SizedBox(height: 22),
            _AuthSkeletonBlock(width: double.infinity, height: 52),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AuthSkeletonBlock(width: double.infinity, height: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AuthSkeletonBlock(width: double.infinity, height: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthSkeletonBlock extends StatelessWidget {
  const _AuthSkeletonBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

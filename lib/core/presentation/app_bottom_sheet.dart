import 'package:flutter/material.dart';

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

bool appBottomSheetIsCompact(BuildContext context) {
  return MediaQuery.sizeOf(context).width < 420;
}

Widget appBottomSheetResponsiveControl(
  BuildContext context, {
  required Widget child,
}) {
  if (!appBottomSheetIsCompact(context)) {
    return child;
  }

  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
}

Widget appBottomSheetPrimaryActionButton(
  BuildContext context, {
  required VoidCallback? onPressed,
  required String label,
}) {
  final compact = appBottomSheetIsCompact(context);

  return SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
        child: Text(label),
      ),
    ),
  );
}

class AppBottomSheetFrame extends StatelessWidget {
  const AppBottomSheetFrame({super.key, required this.child, this.bottomBar});

  final Widget child;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = appBottomSheetIsCompact(context);

    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 12 : 16,
        right: compact ? 12 : 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 24 : 28),
            clipBehavior: Clip.antiAlias,
            child: bottomBar == null
                ? SingleChildScrollView(
                    padding: EdgeInsets.all(compact ? 18 : 24),
                    child: child,
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.84,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 18 : 24,
                              compact ? 18 : 24,
                              compact ? 18 : 24,
                              compact ? 14 : 18,
                            ),
                            child: child,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            compact ? 18 : 24,
                            compact ? 14 : 18,
                            compact ? 18 : 24,
                            compact ? 18 : 24,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              top: BorderSide(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                          ),
                          child: bottomBar,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

TextStyle appBottomSheetDescriptionStyle(BuildContext context) {
  final theme = Theme.of(context);
  final color = theme.textTheme.bodyMedium?.color;

  return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: (color ?? const Color(0xFF5B6470)).withValues(alpha: 0.72),
    height: 1.5,
  );
}

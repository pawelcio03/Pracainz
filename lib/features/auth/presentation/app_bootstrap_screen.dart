import 'package:flutter/material.dart';

import '../../../core/app/app_dependencies.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import 'auth_gate.dart';
import 'auth_loading_screen.dart';

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({
    super.key,
    required this.dependencies,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final AppDependencies dependencies;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  late Future<FirebaseBootstrapResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = widget.dependencies.bootstrap();
  }

  @override
  void didUpdateWidget(covariant AppBootstrapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependencies.bootstrap != widget.dependencies.bootstrap) {
      _bootstrapFuture = widget.dependencies.bootstrap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseBootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AuthLoadingScreen(
            title: 'Uruchamianie aplikacji',
            description:
                'Laczenie z uslugami i przygotowanie sesji uzytkownika.',
          );
        }

        final result = snapshot.data;
        if (result == null || !result.isConfigured) {
          return _SetupScreen(message: result?.message);
        }

        return AuthGate(
          dependencies: widget.dependencies,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
      },
    );
  }
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return _StatusScreen(
      title: 'Skonfiguruj Firebase',
      description:
          message ??
          'Aplikacja ma juz warstwe logowania, ale brakuje konfiguracji projektu Firebase dla tej platformy.',
      footer: const [
        '1. Utworz projekt w Firebase Console.',
        '2. Dodaj Android, iOS i web do projektu.',
        '3. Uruchom flutterfire configure albo dodaj pliki google-services.json i GoogleService-Info.plist.',
        '4. Uruchom aplikacje ponownie.',
      ],
    );
  }
}

class _StatusScreen extends StatelessWidget {
  const _StatusScreen({
    required this.title,
    required this.description,
    this.footer = const [],
  });

  final String title;
  final String description;
  final List<String> footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.lock_clock_outlined,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: mutedTextColor,
                        height: 1.5,
                      ),
                    ),
                    if (footer.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      for (final line in footer)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(line, style: theme.textTheme.bodyMedium),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

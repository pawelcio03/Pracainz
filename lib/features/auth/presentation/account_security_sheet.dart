import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../domain/account_security_snapshot.dart';
import '../domain/auth_repository.dart';
import 'widgets/auth_feedback_widgets.dart';

Future<void> showAccountSecuritySheet(
  BuildContext context, {
  required AuthRepository authRepository,
}) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _AccountSecuritySheet(authRepository: authRepository),
  );
}

class _AccountSecuritySheet extends StatefulWidget {
  const _AccountSecuritySheet({required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<_AccountSecuritySheet> createState() => _AccountSecuritySheetState();
}

class _AccountSecuritySheetState extends State<_AccountSecuritySheet> {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  AccountSecuritySnapshot? _snapshot;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _emailPasswordVisible = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _repeatPasswordVisible = false;
  String? _statusMessage;
  String? _statusTitle;
  String? _statusCaption;
  AuthMessageTone _statusTone = AuthMessageTone.error;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final theme = Theme.of(context);

    return AppBottomSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bezpieczenstwo konta',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tutaj sprawdzisz status logowania, zmienisz e-mail, zmienisz haslo i wyslesz e-mail weryfikacyjny lub reset dostepu. Po potwierdzeniu nowego e-maila odswiez status albo zaloguj sie ponownie.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 20),
          if (_statusMessage != null) ...[
            AuthInlineMessage(
              title: _statusTitle,
              message: _statusMessage!,
              caption: _statusCaption,
              tone: _statusTone,
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoading)
            const _AccountSecurityLoadingState()
          else if (snapshot != null) ...[
            _AccountOverviewCard(snapshot: snapshot),
            const SizedBox(height: 16),
            _ActionRow(
              isSubmitting: _isSubmitting,
              emailVerified: snapshot.emailVerified,
              hasPasswordProvider: snapshot.hasPasswordProvider,
              onRefresh: _loadSnapshot,
              onSendVerification: snapshot.emailVerified
                  ? null
                  : _sendEmailVerification,
              onSendResetLink: snapshot.hasPasswordProvider
                  ? _sendPasswordResetLink
                  : null,
            ),
            const SizedBox(height: 20),
            _InfoCard(
              icon: Icons.person_outline,
              title: 'Nick i nazwa profilu',
              description:
                  'Nick zmieniasz w sekcji Profil. Zapis trafia do dokumentu uzytkownika i do Firebase Auth.',
              tone: _InfoTone.neutral,
            ),
            const SizedBox(height: 16),
            _EmailChangeCard(
              formKey: _emailFormKey,
              snapshot: snapshot,
              isSubmitting: _isSubmitting,
              newEmailController: _newEmailController,
              passwordController: _emailPasswordController,
              isPasswordVisible: _emailPasswordVisible,
              onTogglePasswordVisibility: () {
                setState(() {
                  _emailPasswordVisible = !_emailPasswordVisible;
                });
              },
              onSubmit: _changeEmail,
              validateEmail: _validateNewEmail,
            ),
            const SizedBox(height: 16),
            _PasswordChangeCard(
              formKey: _passwordFormKey,
              snapshot: snapshot,
              isSubmitting: _isSubmitting,
              currentPasswordController: _currentPasswordController,
              newPasswordController: _newPasswordController,
              repeatPasswordController: _repeatPasswordController,
              currentPasswordVisible: _currentPasswordVisible,
              newPasswordVisible: _newPasswordVisible,
              repeatPasswordVisible: _repeatPasswordVisible,
              onToggleCurrentPasswordVisibility: () {
                setState(() {
                  _currentPasswordVisible = !_currentPasswordVisible;
                });
              },
              onToggleNewPasswordVisibility: () {
                setState(() {
                  _newPasswordVisible = !_newPasswordVisible;
                });
              },
              onToggleRepeatPasswordVisibility: () {
                setState(() {
                  _repeatPasswordVisible = !_repeatPasswordVisible;
                });
              },
              onSubmit: _changePassword,
            ),
          ] else
            const _InfoCard(
              icon: Icons.error_outline,
              title: 'Brak danych konta',
              description:
                  'Nie udalo sie pobrac szczegolow bezpieczenstwa konta.',
              tone: _InfoTone.danger,
            ),
        ],
      ),
    );
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await widget.authRepository.getAccountSecuritySnapshot();
      if (!mounted) {
        return;
      }
      _newEmailController.text = snapshot.email;
      setState(() {
        _snapshot = snapshot;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _setStatus(_mapSecurityError(error), tone: AuthMessageTone.error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendEmailVerification() async {
    await _runAction(
      () => widget.authRepository.sendEmailVerification(),
      successMessage: 'Wyslano e-mail weryfikacyjny.',
      successTitle: 'Sprawdz skrzynke odbiorcza',
      successCaption:
          'Po kliknieciu linku w e-mailu wroc tutaj i uzyj "Odswiez status", aby potwierdzic weryfikacje konta.',
      snackBarMessage: 'Wyslano e-mail weryfikacyjny.',
    );
  }

  Future<void> _sendPasswordResetLink() async {
    await _runAction(
      () => widget.authRepository.sendPasswordResetEmailToCurrentUser(),
      successMessage: 'Wyslano link do resetu hasla na adres konta.',
      successTitle: 'Link resetu zostal wyslany',
      successCaption:
          'Jesli wiadomosc nie pojawi sie od razu, sprawdz folder Spam lub odczekaj chwile przed kolejna proba.',
      snackBarMessage: 'Wyslano link do resetu hasla.',
    );
  }

  Future<void> _changeEmail() async {
    final snapshot = _snapshot;
    if (snapshot == null || !_emailFormKey.currentState!.validate()) {
      return;
    }

    final newEmail = _newEmailController.text.trim();

    await _runAction(
      () async {
        await widget.authRepository.updateEmail(
          currentPassword: _emailPasswordController.text,
          newEmail: newEmail,
        );
        await _loadSnapshot();
      },
      successMessage:
          'Wyslano link potwierdzajacy zmiane e-maila na $newEmail. Po zatwierdzeniu odswiez status konta.',
      successTitle: 'Potwierdz nowy adres e-mail',
      successCaption:
          'Nowy adres stanie sie aktywny dopiero po kliknieciu linku potwierdzajacego w wiadomosci.',
      snackBarMessage: 'Wyslano link potwierdzajacy zmiane e-maila.',
    );

    if (!mounted) {
      return;
    }

    _emailPasswordController.clear();
  }

  Future<void> _changePassword() async {
    if (_snapshot == null || !_passwordFormKey.currentState!.validate()) {
      return;
    }

    await _runAction(
      () => widget.authRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ),
      successMessage: 'Haslo zostalo zmienione.',
      successTitle: 'Haslo zapisane',
      successCaption:
          'Przy kolejnym logowaniu uzyj nowego hasla. Jesli masz zapisane stare dane w managerze hasel, zaktualizuj je.',
      snackBarMessage: 'Haslo zostalo zmienione.',
    );

    if (!mounted) {
      return;
    }

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _repeatPasswordController.clear();
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
    String? successTitle,
    String? successCaption,
    String? snackBarMessage,
  }) async {
    setState(() {
      _isSubmitting = true;
      _clearStatus();
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _setStatus(
          successMessage,
          tone: AuthMessageTone.success,
          title: successTitle,
          caption: successCaption,
        );
      });
      _showSnackBar(snackBarMessage ?? successTitle ?? successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _setStatus(_mapSecurityError(error), tone: AuthMessageTone.error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateNewEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!_emailPattern.hasMatch(email)) {
      return 'Podaj poprawny adres e-mail.';
    }
    if (_snapshot != null && email == _snapshot!.email) {
      return 'Podaj inny adres niz obecny.';
    }
    return null;
  }

  String _mapSecurityError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
          return 'Aktualne haslo jest niepoprawne.';
        case 'weak-password':
          return 'Nowe haslo jest zbyt slabe.';
        case 'requires-recent-login':
          return 'Zaloguj sie ponownie i sprobuj jeszcze raz.';
        case 'too-many-requests':
          return 'Zbyt wiele prob. Sprobuj ponownie za chwile.';
        case 'network-request-failed':
          return 'Brak polaczenia z siecia. Sprobuj ponownie.';
        case 'password-provider-unavailable':
          return 'To konto nie korzysta z logowania haslem.';
        case 'missing-email':
          return 'Na koncie nie ma adresu e-mail do wykonania tej operacji.';
        case 'not-authenticated':
          return 'Sesja wygasla. Zaloguj sie ponownie.';
        case 'invalid-email':
          return 'Nowy adres e-mail ma niepoprawny format.';
        case 'email-already-in-use':
          return 'Ten adres e-mail jest juz zajety.';
        case 'email-unchanged':
          return 'Podaj inny adres e-mail niz obecny.';
      }

      return error.message ?? 'Operacja bezpieczenstwa nie powiodla sie.';
    }

    return 'Operacja bezpieczenstwa nie powiodla sie.';
  }

  void _setStatus(
    String message, {
    required AuthMessageTone tone,
    String? title,
    String? caption,
  }) {
    _statusMessage = message;
    _statusTitle = title;
    _statusCaption = caption;
    _statusTone = tone;
  }

  void _clearStatus() {
    _statusMessage = null;
    _statusTitle = null;
    _statusCaption = null;
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountOverviewCard extends StatelessWidget {
  const _AccountOverviewCard({required this.snapshot});

  final AccountSecuritySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: snapshot.emailVerified
          ? Icons.verified_user_outlined
          : Icons.mark_email_unread_outlined,
      title: 'Stan konta',
      description: snapshot.email,
      tone: snapshot.emailVerified ? _InfoTone.success : _InfoTone.warning,
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatusChip(
            label: snapshot.emailVerified
                ? 'E-mail zweryfikowany'
                : 'E-mail niezweryfikowany',
            tone: snapshot.emailVerified
                ? _InfoTone.success
                : _InfoTone.warning,
          ),
          _StatusChip(
            label: snapshot.hasPasswordProvider ? 'Haslo aktywne' : 'Bez hasla',
            tone: snapshot.hasPasswordProvider
                ? _InfoTone.info
                : _InfoTone.neutral,
          ),
          _StatusChip(
            label: snapshot.hasGoogleProvider ? 'Google aktywne' : 'Google off',
            tone: snapshot.hasGoogleProvider
                ? _InfoTone.info
                : _InfoTone.neutral,
          ),
          ...snapshot.providerIds.map(
            (providerId) =>
                _StatusChip(label: providerId, tone: _InfoTone.neutral),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isSubmitting,
    required this.emailVerified,
    required this.hasPasswordProvider,
    required this.onRefresh,
    required this.onSendVerification,
    required this.onSendResetLink,
  });

  final bool isSubmitting;
  final bool emailVerified;
  final bool hasPasswordProvider;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onSendVerification;
  final Future<void> Function()? onSendResetLink;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : () => onRefresh(),
          icon: const Icon(Icons.refresh),
          label: const Text('Odswiez status'),
        ),
        OutlinedButton.icon(
          onPressed: isSubmitting || emailVerified || onSendVerification == null
              ? null
              : () => onSendVerification!(),
          icon: const Icon(Icons.mark_email_read_outlined),
          label: const Text('Wyslij e-mail weryfikacyjny'),
        ),
        TextButton.icon(
          onPressed: isSubmitting || !hasPasswordProvider
              ? null
              : onSendResetLink == null
              ? null
              : () => onSendResetLink!(),
          icon: const Icon(Icons.password_outlined),
          label: const Text('Reset hasla'),
        ),
      ],
    );
  }
}

class _EmailChangeCard extends StatelessWidget {
  const _EmailChangeCard({
    required this.formKey,
    required this.snapshot,
    required this.isSubmitting,
    required this.newEmailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.validateEmail,
  });

  final GlobalKey<FormState> formKey;
  final AccountSecuritySnapshot snapshot;
  final bool isSubmitting;
  final TextEditingController newEmailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;
  final Future<void> Function() onSubmit;
  final String? Function(String?) validateEmail;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.hasPasswordProvider) {
      return _InfoCard(
        icon: Icons.alternate_email_outlined,
        title: 'Zmiana e-maila niedostepna',
        description:
            'Ten adres jest zarzadzany przez zewnetrzny provider logowania. W tej aplikacji zmienisz go tylko dla kont z aktywnym haslem.',
        tone: _InfoTone.warning,
      );
    }

    return _InfoCard(
      icon: Icons.alternate_email_outlined,
      title: 'Zmiana e-maila',
      description:
          'Zmiana e-maila wymaga aktualnego hasla. Na nowy adres wyslemy link potwierdzajacy, a zmiana bedzie aktywna po jego zatwierdzeniu.',
      tone: _InfoTone.info,
      footer: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: snapshot.email,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Obecny e-mail'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Nowy e-mail'),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: 'Aktualne haslo',
                suffixIcon: IconButton(
                  tooltip: isPasswordVisible ? 'Ukryj haslo' : 'Pokaz haslo',
                  onPressed: onTogglePasswordVisibility,
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Podaj aktualne haslo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            appBottomSheetPrimaryActionButton(
              context,
              onPressed: isSubmitting ? null : () => onSubmit(),
              label: isSubmitting ? 'Zapisywanie...' : 'Zmien e-mail',
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordChangeCard extends StatelessWidget {
  const _PasswordChangeCard({
    required this.formKey,
    required this.snapshot,
    required this.isSubmitting,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.repeatPasswordController,
    required this.currentPasswordVisible,
    required this.newPasswordVisible,
    required this.repeatPasswordVisible,
    required this.onToggleCurrentPasswordVisibility,
    required this.onToggleNewPasswordVisibility,
    required this.onToggleRepeatPasswordVisibility,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final AccountSecuritySnapshot snapshot;
  final bool isSubmitting;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController repeatPasswordController;
  final bool currentPasswordVisible;
  final bool newPasswordVisible;
  final bool repeatPasswordVisible;
  final VoidCallback onToggleCurrentPasswordVisibility;
  final VoidCallback onToggleNewPasswordVisibility;
  final VoidCallback onToggleRepeatPasswordVisibility;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.hasPasswordProvider) {
      return _InfoCard(
        icon: Icons.lock_outline,
        title: 'Zmiana hasla niedostepna',
        description:
            'To konto nie ma aktywnego providera hasla. Obecnie logowanie dziala przez Google lub inny zewnetrzny provider.',
        tone: _InfoTone.warning,
      );
    }

    return _InfoCard(
      icon: Icons.lock_reset_outlined,
      title: 'Zmiana hasla',
      description:
          'Zmiana hasla wymaga podania aktualnego hasla i ponownej autoryzacji sesji.',
      tone: _InfoTone.info,
      footer: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: currentPasswordController,
              obscureText: !currentPasswordVisible,
              textInputAction: TextInputAction.next,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: 'Aktualne haslo',
                suffixIcon: IconButton(
                  tooltip: currentPasswordVisible
                      ? 'Ukryj haslo'
                      : 'Pokaz haslo',
                  onPressed: onToggleCurrentPasswordVisibility,
                  icon: Icon(
                    currentPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Podaj aktualne haslo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newPasswordController,
              obscureText: !newPasswordVisible,
              textInputAction: TextInputAction.next,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: 'Nowe haslo',
                suffixIcon: IconButton(
                  tooltip: newPasswordVisible ? 'Ukryj haslo' : 'Pokaz haslo',
                  onPressed: onToggleNewPasswordVisibility,
                  icon: Icon(
                    newPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.length < 6) {
                  return 'Nowe haslo musi miec co najmniej 6 znakow.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: repeatPasswordController,
              obscureText: !repeatPasswordVisible,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: 'Powtorz nowe haslo',
                suffixIcon: IconButton(
                  tooltip: repeatPasswordVisible
                      ? 'Ukryj haslo'
                      : 'Pokaz haslo',
                  onPressed: onToggleRepeatPasswordVisibility,
                  icon: Icon(
                    repeatPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value != newPasswordController.text) {
                  return 'Hasla nie sa takie same.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            appBottomSheetPrimaryActionButton(
              context,
              onPressed: isSubmitting ? null : () => onSubmit(),
              label: isSubmitting ? 'Zapisywanie...' : 'Zmien haslo',
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSecurityLoadingState extends StatelessWidget {
  const _AccountSecurityLoadingState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);

    Widget block({required double height}) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return Column(
      children: [
        block(height: 120),
        const SizedBox(height: 14),
        block(height: 58),
        const SizedBox(height: 14),
        block(height: 220),
        const SizedBox(height: 14),
        block(height: 300),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String description;
  final _InfoTone tone;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone.color(theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _InfoTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone.color(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _InfoTone { neutral, info, success, warning, danger }

extension on _InfoTone {
  Color color(ThemeData theme) {
    switch (this) {
      case _InfoTone.neutral:
        return theme.textTheme.bodyMedium?.color ?? const Color(0xFF5B6470);
      case _InfoTone.info:
        return theme.colorScheme.primary;
      case _InfoTone.success:
        return const Color(0xFF0F766E);
      case _InfoTone.warning:
        return const Color(0xFFB7791F);
      case _InfoTone.danger:
        return theme.colorScheme.error;
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';
import 'widgets/auth_feedback_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  String? _statusMessage;
  String? _statusTitle;
  String? _statusCaption;
  AuthMessageTone _statusTone = AuthMessageTone.error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isRegisterMode ? 'Utworz konto' : 'Zaloguj sie',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? 'Podaj nazwe profilu, e-mail i haslo. Po zalogowaniu od razu wejdziesz do swojego panelu.'
                            : 'Zaloguj sie swoim adresem e-mail, aby wrocic do transakcji, budzetow, celow i raportow.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Logowanie'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Rejestracja'),
                          ),
                        ],
                        selected: {_isRegisterMode},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _isRegisterMode = selection.first;
                            _clearStatus();
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      if (_isRegisterMode) ...[
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          maxLength: 60,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa profilu',
                          ),
                          validator: (value) {
                            if (!_isRegisterMode) {
                              return null;
                            }

                            if (value == null || value.trim().length < 2) {
                              return 'Podaj nazwe profilu.';
                            }

                            if (value.trim().length > 60) {
                              return 'Nazwa profilu jest za dluga.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          labelText: 'Adres e-mail',
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!_isValidEmail(email)) {
                            return 'Podaj poprawny adres e-mail.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        textInputAction: _isRegisterMode
                            ? TextInputAction.next
                            : TextInputAction.done,
                        obscureText: !_isPasswordVisible,
                        maxLength: 128,
                        decoration: InputDecoration(
                          labelText: 'Haslo',
                          suffixIcon: IconButton(
                            tooltip: _isPasswordVisible
                                ? 'Ukryj haslo'
                                : 'Pokaz haslo',
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.length < 6) {
                            return 'Haslo musi miec co najmniej 6 znakow.';
                          }

                          return null;
                        },
                      ),
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _repeatPasswordController,
                          textInputAction: TextInputAction.done,
                          obscureText: !_isPasswordVisible,
                          maxLength: 128,
                          decoration: InputDecoration(
                            labelText: 'Powtorz haslo',
                            suffixIcon: IconButton(
                              tooltip: _isPasswordVisible
                                  ? 'Ukryj haslo'
                                  : 'Pokaz haslo',
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (!_isRegisterMode) {
                              return null;
                            }

                            if ((value ?? '').isEmpty) {
                              return 'Powtorz haslo.';
                            }

                            if (value != _passwordController.text) {
                              return 'Hasla musza byc takie same.';
                            }

                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        _isRegisterMode
                            ? 'Haslo powinno miec co najmniej 6 znakow i byc wpisane tak samo w obu polach.'
                            : 'Jesli nie pamietasz hasla, uzyj resetu ponizej.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                          height: 1.45,
                        ),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 14),
                        AuthInlineMessage(
                          title: _statusTitle,
                          message: _statusMessage!,
                          caption: _statusCaption,
                          tone: _statusTone,
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              _isSubmitting
                                  ? 'Trwa przetwarzanie...'
                                  : _isRegisterMode
                                  ? 'Utworz konto'
                                  : 'Zaloguj sie',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'albo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: mutedTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _submitGoogle,
                          icon: const GoogleMark(),
                          label: Text(
                            _isRegisterMode
                                ? 'Kontynuuj z Google'
                                : 'Zaloguj przez Google',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isSubmitting ? null : _resetPassword,
                        child: const Text('Reset hasla'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _clearStatus();
    });

    try {
      if (_isRegisterMode) {
        await widget.authRepository.register(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      } else {
        await widget.authRepository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _setStatus(_mapAuthError(error), tone: AuthMessageTone.error);
      });
    } catch (_) {
      setState(() {
        _setStatus(
          'Operacja nie powiodla sie. Sprobuj ponownie.',
          tone: AuthMessageTone.error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _setStatus(
          'Podaj poprawny e-mail do resetu hasla.',
          tone: AuthMessageTone.error,
          title: 'Brak poprawnego adresu',
        );
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _clearStatus();
    });

    try {
      await widget.authRepository.sendPasswordResetEmail(email);
      if (!mounted) {
        return;
      }

      setState(() {
        _setStatus(
          'Wyslano link do resetu hasla na $email.',
          tone: AuthMessageTone.success,
          title: 'Sprawdz skrzynke e-mail',
          caption:
              'Jesli nie widzisz wiadomosci od razu, sprawdz folder Spam lub odczekaj chwile przed kolejna proba.',
        );
      });
      _showSnackBar('Link do resetu hasla zostal wyslany.');
    } on FirebaseAuthException catch (error) {
      setState(() {
        _setStatus(_mapAuthError(error), tone: AuthMessageTone.error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isSubmitting = true;
      _clearStatus();
    });

    try {
      await widget.authRepository.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      setState(() {
        _setStatus(_mapAuthError(error), tone: AuthMessageTone.error);
      });
    } catch (_) {
      setState(() {
        _setStatus(
          'Nie udalo sie zalogowac przez Google. Sprobuj ponownie.',
          tone: AuthMessageTone.error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Adres e-mail ma niepoprawny format.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Niepoprawny e-mail lub haslo.';
      case 'email-already-in-use':
        return 'Ten adres e-mail jest juz zajety.';
      case 'weak-password':
        return 'Haslo jest zbyt slabe.';
      case 'too-many-requests':
        return 'Za duzo prob. Sprobuj ponownie za chwile.';
      case 'account-exists-with-different-credential':
        return 'To konto istnieje juz z inna metoda logowania.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'google-sign-in-cancelled':
        return 'Logowanie Google zostalo anulowane.';
      case 'google-sign-in-interrupted':
        return 'Logowanie Google zostalo przerwane. Sprobuj ponownie.';
      case 'google-sign-in-misconfigured':
        return 'Logowanie Google nie jest jeszcze poprawnie skonfigurowane.';
      case 'google-sign-in-unavailable':
        return 'Nie udalo sie otworzyc logowania Google.';
      case 'google-sign-in-user-mismatch':
        return 'Wybrane konto Google nie pasuje do aktywnej sesji.';
      case 'missing-google-id-token':
        return 'Nie udalo sie pobrac tokenu logowania Google.';
      default:
        return error.message ?? 'Wystapil blad autoryzacji.';
    }
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
    _statusTone = AuthMessageTone.error;
  }

  bool _isValidEmail(String email) {
    return email.isNotEmpty && _emailPattern.hasMatch(email);
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

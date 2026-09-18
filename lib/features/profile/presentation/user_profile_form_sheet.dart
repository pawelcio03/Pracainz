import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import 'user_profile_form_result.dart';

Future<UserProfileFormResult?> showUserProfileFormSheet(
  BuildContext context, {
  required UserProfile profile,
}) {
  return showAppBottomSheet<UserProfileFormResult>(
    context,
    builder: (context) => _UserProfileFormSheet(profile: profile),
  );
}

class _UserProfileFormSheet extends StatefulWidget {
  const _UserProfileFormSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_UserProfileFormSheet> createState() => _UserProfileFormSheetState();
}

class _UserProfileFormSheetState extends State<_UserProfileFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: 'Zapisz profil',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edytuj profil',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tutaj zmienisz tylko nick profilu. E-mail oraz haslo sa zarzadzane w sekcji Bezpieczenstwo konta.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _displayNameController,
              textInputAction: TextInputAction.done,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nick'),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Podaj nick.';
                }

                if (value.trim().length > 60) {
                  return 'Nick jest za dlugi.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.profile.email,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Adres e-mail'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      UserProfileFormResult(
        profile: widget.profile.copyWith(
          displayName: _displayNameController.text.trim(),
        ),
      ),
    );
  }
}

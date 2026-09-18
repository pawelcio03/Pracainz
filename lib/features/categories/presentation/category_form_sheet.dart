import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';

Future<FinanceCategory?> showCategoryFormSheet(
  BuildContext context, {
  FinanceCategory? initialCategory,
}) {
  return showAppBottomSheet<FinanceCategory>(
    context,
    builder: (context) {
      return _CategoryFormSheet(initialCategory: initialCategory);
    },
  );
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.initialCategory});

  final FinanceCategory? initialCategory;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late TransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategory?.name ?? '',
    );
    _selectedType = widget.initialCategory?.type ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCategory != null;

    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: isEditing ? 'Zapisz kategorie' : 'Dodaj kategorie',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj kategorie' : 'Dodaj kategorie',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategorie sa zapisywane w Firestore i trafiaja do formularzy transakcji oraz budzetow.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            appBottomSheetResponsiveControl(
              context,
              child: SegmentedButton<TransactionType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text('Wydatek'),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.income,
                    label: Text('Przychod'),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.transfer,
                    label: Text('Transfer'),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Nazwa kategorii'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwe kategorii.';
                }

                if (value.trim().length > 40) {
                  return 'Nazwa kategorii jest za dluga.';
                }

                return null;
              },
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
      FinanceCategory(
        id: widget.initialCategory?.id ?? '',
        name: _nameController.text.trim(),
        type: _selectedType,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/farmers_repository.dart';
import 'farmers_providers.dart';

class CreateFarmerScreen extends ConsumerStatefulWidget {
  const CreateFarmerScreen({super.key});

  @override
  ConsumerState<CreateFarmerScreen> createState() => _CreateFarmerScreenState();
}

class _CreateFarmerScreenState extends ConsumerState<CreateFarmerScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController(text: '+225');
  final _village = TextEditingController();
  final _region = TextEditingController();
  final _credit = TextEditingController(text: '250000');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_identifier, _firstName, _lastName, _phone, _village, _region, _credit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final farmer = await ref.read(farmersRepositoryProvider).create({
        'identifier': _identifier.text.trim(),
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'village': _village.text.trim().isEmpty ? null : _village.text.trim(),
        'region': _region.text.trim().isEmpty ? null : _region.text.trim(),
        'credit_limit': num.tryParse(_credit.text.trim()) ?? 0,
      });
      if (!mounted) return;
      ref.invalidate(farmerSearchResultsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            farmer == null
                ? 'Hors ligne — création mise en file d’attente.'
                : 'Producteur créé avec succès.',
          ),
        ),
      );
      context.pop();
    } on Failure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau producteur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AppCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(
                  controller: _identifier,
                  label: 'Identifiant',
                  hint: 'CI-FARM-0099',
                  validator: (v) =>
                      (v == null || v.trim().length < 4) ? 'Requis' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _firstName,
                        label: 'Prénom',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        controller: _lastName,
                        label: 'Nom',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                _Field(
                  controller: _phone,
                  label: 'Téléphone',
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().length < 8) ? 'Numéro invalide' : null,
                ),
                Row(
                  children: [
                    Expanded(child: _Field(controller: _village, label: 'Village')),
                    const SizedBox(width: 12),
                    Expanded(child: _Field(controller: _region, label: 'Région')),
                  ],
                ),
                _Field(
                  controller: _credit,
                  label: 'Plafond de crédit (FCFA)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Enregistrer',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

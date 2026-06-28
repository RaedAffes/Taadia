import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/services/taadia_service.dart';
import 'package:ta3dia/widgets/app_scaffold.dart';

class CreatePrivateTaadiaScreen extends StatefulWidget {
  @override
  _CreatePrivateTaadiaScreenState createState() =>
      _CreatePrivateTaadiaScreenState();
}

class _CreatePrivateTaadiaScreenState extends State<CreatePrivateTaadiaScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final taadiaService = Provider.of<TaadiaService>(context, listen: false);
    final taadiaId = await taadiaService.createPrivateTaadia(
      _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      if (taadiaId != null) {
        Navigator.pop(context, true);
      } else {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.failedToCreate),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AppScaffold(
      title: l.createOwnTaadia,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                textDirection: l.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l.assessmentTitle,
                  hintText: l.titleHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l.enterTitle : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textDirection: l.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.descriptionOptional,
                  hintText: l.descriptionHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: cs.tertiary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.privateTaadiaNotice,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  child: _loading
                      ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                      : Text(l.create, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

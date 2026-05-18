import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/utils/uz_phone_formatter.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../models/order_model.dart';
import '../../providers/clients_provider.dart';
import '../../providers/orders_provider.dart';

class CreateOrderSheet extends ConsumerStatefulWidget {
  const CreateOrderSheet({super.key});

  @override
  ConsumerState<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _totalController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = UzPhoneFormatter.initialValue;
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (UzPhoneFormatter.isComplete(_phoneController.text)) {
      final digits = UzPhoneFormatter.digitsOnly(_phoneController.text);
      final clients = ref.read(clientsProvider).clients;
      final match = clients
          .where((c) => UzPhoneFormatter.digitsOnly(c.phone) == digits)
          .firstOrNull;
      if (match?.name != null && _nameController.text.isEmpty) {
        _nameController.text = match!.name!;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _commentController.dispose();
    _totalController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final totalRaw = _totalController.text.trim().replaceAll(',', '.');
    final req = CreateOrderRequest(
      pharmacyComment: _commentController.text.trim(),
      medicinesTotal: totalRaw.isEmpty ? null : double.tryParse(totalRaw),
      customerName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      customerPhone: UzPhoneFormatter.isComplete(_phoneController.text)
          ? UzPhoneFormatter.toE164(_phoneController.text)
          : null,
    );

    final success = await ref.read(ordersProvider.notifier).createOrder(req);
    setState(() => _isLoading = false);

    if (mounted) {
      final l10n = context.l10n;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.createOrder)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: (screenHeight * 0.9 - bottom).clamp(200.0, screenHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Row(
                children: [
                  Text(
                    l10n.newOrder,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () { HapticService.light(); Navigator.pop(context); },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // КЛИЕНТ section
                      _SectionLabel(l10n.customer.toUpperCase()),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: CustomTextField(
                                label: l10n.customer,
                                controller: _nameController,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                              child: CustomTextField(
                                label: l10n.phone,
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                prefixIcon: const Icon(Icons.phone_outlined),
                                inputFormatters: [UzPhoneFormatter()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ЗАКАЗ section
                      _SectionLabel(l10n.order.toUpperCase()),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: CustomTextField(
                                label: '${l10n.orderCommentLbl} *',
                                hint: l10n.orderCommentHint,
                                controller: _commentController,
                                prefixIcon: const Icon(Icons.comment_outlined),
                                maxLines: 3,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? l10n.fillAllFields
                                    : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                              child: CustomTextField(
                                label: l10n.orderAmountLbl,
                                hint: '150000',
                                controller: _totalController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                prefixIcon: const Icon(Icons.payments_outlined),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final parsed =
                                      double.tryParse(v.trim().replaceAll(',', '.'));
                                  if (parsed == null || parsed < 0) {
                                    return l10n.fillAllFields;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Submit button — always visible above keyboard
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, bottom > 0 ? 12 : 24),
                child: CustomButton(
                  label: l10n.createOrder,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

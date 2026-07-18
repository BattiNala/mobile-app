import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/biometric_util.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/controllers/biometric_notifier.dart';
import 'package:batti_nala/features/shared/widgets/biometric_setup_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricLoginCard extends ConsumerWidget {
  const BiometricLoginCard({super.key});

  void _toggle(bool enable, BuildContext context, WidgetRef ref) {
    final username = ref.read(authNotifierProvider).email ?? '';
    if (enable) {
      showBiometricSetupSheet(context, ref, username);
    } else {
      ref
          .read(biometricNotifierProvider.notifier)
          .disableBiometricForUser(username);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bioState = ref.watch(biometricNotifierProvider);
    final isFaceId = BiometricUtil.instance.supportsFaceId;
    final isEnabled = bioState.isEnabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isFaceId ? Icons.face_unlock_outlined : Icons.fingerprint,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFaceId ? 'Face ID Login' : 'Fingerprint Login',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnabled
                      ? 'Enabled - tap to disable'
                      : 'Sign in without a password',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            activeThumbColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.4),
            onChanged: (value) => _toggle(value, context, ref),
          ),
        ],
      ),
    );
  }
}

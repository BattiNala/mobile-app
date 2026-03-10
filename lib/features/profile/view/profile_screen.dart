import 'package:batti_nala/core/utils/colors.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:batti_nala/features/profile/view/profile_avatar.dart';
import 'package:batti_nala/features/profile/view/profile_header.dart';
import 'package:batti_nala/features/profile/view/profile_info_section.dart';
import 'package:batti_nala/features/profile/view/trust_score_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);

    final user = authState.user;
    final citizen = profileState.citizenProfile;
    final employee = profileState.employeeProfile;

    if (profileState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final name = citizen?.name ?? employee?.name ?? "User";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ProfileHeader(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ProfileAvatarCard(name: name, role: user!.role),

                const SizedBox(height: 24),

                if (citizen != null || employee != null)
                  ProfileInfoSection(citizen: citizen, employee: employee),

                if (citizen != null) ...[
                  const SizedBox(height: 24),
                  TrustScoreCard(score: citizen.trustScore),
                ],

                const SizedBox(height: 24),

                ActionButton(
                  btnInfo: "Logout",
                  btnColor: const Color(0xFFB91C1C),
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/onboarding');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

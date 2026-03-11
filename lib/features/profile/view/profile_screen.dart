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

                // ABOUT US
                Container(
                  padding: const EdgeInsets.all(18),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "About Batti Nala",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// Description
                      Text(
                        "Batti Nala is a community-driven platform that empowers citizens to report and resolve local issues.\n\n"
                        "Our mission is to create safer, cleaner, and more vibrant neighborhoods by connecting residents "
                        "with local authorities and fostering a culture of civic engagement.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
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

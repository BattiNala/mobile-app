import 'package:batti_nala/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(color: AppColors.primaryBlue900),
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => context.pop(),
          child: const Row(
            children: [
              Icon(Icons.arrow_back, color: Colors.white, size: 22),
              SizedBox(width: 15),
              Text('Back', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

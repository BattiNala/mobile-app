import 'package:batti_nala/features/profile/model/profile_response_model.dart';
import 'package:batti_nala/features/profile/view/profile_info_tile_widget.dart';
import 'package:flutter/material.dart';

class ProfileInfoSection extends StatelessWidget {
  final CitizenProfile? citizen;
  final EmployeeProfile? employee;

  const ProfileInfoSection({super.key, this.citizen, this.employee});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];

    if (citizen != null) {
      tiles.addAll([
        ProfileInfoTile(
          icon: Icons.person_outline,
          label: 'Full Name',
          value: citizen!.name,
          isFirst: true,
          isLast: false,
        ),
        ProfileInfoTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: citizen!.email,
          isFirst: false,
          isLast: false,
        ),
        ProfileInfoTile(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: citizen!.phoneNumber,
          isFirst: false,
          isLast: false,
        ),
        ProfileInfoTile(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: citizen!.address.toString(),
          isFirst: false,
          isLast: true,
        ),
      ]);
    }

    if (employee != null) {
      tiles.addAll([
        ProfileInfoTile(
          icon: Icons.person_outline,
          label: 'Full Name',
          value: employee!.name,
          isFirst: true,
          isLast: false,
        ),
        ProfileInfoTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: employee!.email,
          isFirst: false,
          isLast: false,
        ),
        ProfileInfoTile(
          icon: Icons.business_outlined,
          label: 'Department',
          value: employee!.department.toUpperCase(),
          isFirst: false,
          isLast: false,
        ),
        ProfileInfoTile(
          icon: Icons.groups_outlined,
          label: 'Team',
          value: employee!.teamName.toUpperCase(),
          isFirst: false,
          isLast: false,
        ),
        ProfileInfoTile(
          icon: Icons.work_outline,
          label: 'Status',
          value: employee!.currentStatus.toUpperCase(),
          isFirst: false,
          isLast: true,
        ),
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: tiles),
    );
  }
}

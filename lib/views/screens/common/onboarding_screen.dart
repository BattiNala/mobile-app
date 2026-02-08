import 'package:batti_nala/utils/colors.dart';
import 'package:batti_nala/views/widgets/common/info_card_widget.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: height,
        padding: EdgeInsets.all(width * 0.0002),
        decoration: BoxDecoration(gradient: AppColors.welcomeGradient),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: height * 0.07),
                child: ClipRRect(
                  child: Image.asset(
                    "assets/icons/battinala_logo.png",
                    fit: BoxFit.cover,
                    height: 150,
                    width: 200,
                  ),
                ),
              ),
              Text(
                "BattiNala",
                style: TextStyle(
                  fontSize: 30,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                  color: AppColors.background,
                ),
              ),
              SizedBox(height: height * 0.02),
              Text(
                "नेपालको लागि\n Nepal's Smart Utility\n Management Platform",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: 2,
                  color: AppColors.background,
                ),
              ),
              SizedBox(height: height * 0.02),
              InfoCardWidget(
                icon: Icons.location_on_outlined,
                heading: "Real-time Reporting",
                info:
                    "Report water & electricity issues instantly with GPS tracking",
              ),
              InfoCardWidget(
                icon: Icons.route_outlined,
                heading: "Smart Route Optimization",
                info: "AI-powered maintenance routes for faster resolution",
              ),
              InfoCardWidget(
                icon: Icons.group_outlined,
                heading: "Community Driven",
                info:
                    "Citizens and staff working together for better infrastructure",
              ),
              SizedBox(height: height * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: AppColors.adminRed,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: width * 0.3,
                      ),
                      child: Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

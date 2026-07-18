import 'dart:math' as math;

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/onboarding/onboarding_notifier.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _illustrationController;
  late Animation<double> _floatAnim;

  static const _pages = [
    _OnboardingPage(
      title: 'Report Instantly',
      subtitle:
          'Spot a broken pole or clogged drain? Capture it, tag the location, and alert the municipality in seconds.',
      primaryColor: Color(0xFF1E3A8A),
      accentColor: Color(0xFF3B82F6),
      illustration: _ReportIllustration(),
    ),
    _OnboardingPage(
      title: 'AI Auto-Detection',
      subtitle:
          'Our Gemini-powered AI reads your photo and fills in the issue type and priority — so you don\'t have to.',
      primaryColor: Color(0xFF4F46E5),
      accentColor: Color(0xFF818CF8),
      illustration: _AiIllustration(),
    ),
    _OnboardingPage(
      title: 'Track Every Step',
      subtitle:
          'Follow your report from submission to resolution. Staff updates are live — you\'re never left in the dark.',
      primaryColor: Color(0xFF065F46),
      accentColor: Color(0xFF34D399),
      illustration: _TrackIllustration(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _illustrationController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      ref.read(onboardingProvider.notifier).completeOnBoarding();
    }
  }

  void _skip() => ref.read(onboardingProvider.notifier).completeOnBoarding();

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              page.primaryColor,
              page.primaryColor.withValues(alpha: 0.85),
              page.accentColor.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 12),
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _PageContent(
                      page: _pages[index],
                      floatAnim: _floatAnim,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                child: Column(
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // CTA button
                    ActionButton(
                      width: double.infinity,
                      label: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      backgroundColor: Colors.white,
                      textColor: page.primaryColor,
                      onPressed: _next,
                      borderRadius: 16,
                      verticalPadding: 16,
                      labelSize: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color accentColor;
  final Widget illustration;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.accentColor,
    required this.illustration,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  final Animation<double> floatAnim;
  final bool isActive;

  const _PageContent({
    required this.page,
    required this.floatAnim,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          AnimatedBuilder(
            animation: floatAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, isActive ? floatAnim.value : 0),
              child: child,
            ),
            child: page.illustration,
          ),

          const SizedBox(height: 52),

          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Illustrations ────────────────────────────────────────────────────────────

class _ReportIllustration extends StatelessWidget {
  const _ReportIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings
          ..._rings([120, 170, 220], 0.06),

          // Phone frame
          Container(
            width: 90,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),

          // Location pin
          Positioned(
            right: 52,
            top: 32,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.adminRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.adminRed.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rings(List<double> sizes, double opacity) {
    return sizes
        .map(
          (s) => Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: opacity),
                width: 1.5,
              ),
            ),
          ),
        )
        .toList();
  }
}

class _AiIllustration extends StatefulWidget {
  const _AiIllustration();

  @override
  State<_AiIllustration> createState() => _AiIllustrationState();
}

class _AiIllustrationState extends State<_AiIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbiting sparkles
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(5, (i) {
                  final angle =
                      _controller.value * 2 * math.pi + (i * 2 * math.pi / 5);
                  final r = 88.0 + (i % 2) * 18;
                  return Transform.translate(
                    offset: Offset(r * math.cos(angle), r * math.sin(angle)),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white.withValues(alpha: 0.5 + i * 0.1),
                      size: 10 + (i % 3) * 4.0,
                    ),
                  );
                }),
              );
            },
          ),

          // Central AI brain circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),

          // Detection box corners
          Positioned(top: 28, left: 55, child: _corner(true, true)),
          Positioned(top: 28, right: 55, child: _corner(true, false)),
          Positioned(bottom: 28, left: 55, child: _corner(false, true)),
          Positioned(bottom: 28, right: 55, child: _corner(false, false)),
        ],
      ),
    );
  }

  Widget _corner(bool top, bool left) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2)
              : BorderSide.none,
          left: left
              ? BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _TrackIllustration extends StatelessWidget {
  const _TrackIllustration();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.bolt_rounded, 'Reported', true),
      (Icons.assignment_ind_rounded, 'Assigned', true),
      (Icons.published_with_changes_rounded, 'In Progress', true),
      (Icons.check_circle_rounded, 'Resolved', false),
    ];

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(steps.length, (i) {
            final (icon, label, done) = steps[i];
            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: done
                            ? const Color(0xFF065F46)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 14,
                        color: Colors.white.withValues(
                          alpha: done ? 0.5 : 0.15,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: done ? Colors.white : Colors.white38,
                    fontSize: 14,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

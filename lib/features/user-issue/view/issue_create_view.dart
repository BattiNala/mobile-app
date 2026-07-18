import 'dart:io';
import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/gemini_analyzer.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/features/shared/issue/models/issue_type_model.dart';
import 'package:batti_nala/features/shared/issue/repository/issue_repository.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:batti_nala/features/shared/widgets/loading_indicator.dart';
import 'package:batti_nala/features/user-issue/controllers/create_issue_controller.dart';
import 'package:batti_nala/features/user-issue/controllers/create_issue_state.dart';
import 'package:batti_nala/features/user-issue/controllers/location_notifier.dart';
import 'package:batti_nala/features/user-issue/controllers/location_state.dart';
import 'package:batti_nala/features/user-issue/view/widgets/image_picker_grid.dart';
import 'package:batti_nala/features/user-issue/view/widgets/issue_selectors.dart';
import 'package:batti_nala/features/user-issue/view/widgets/location_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final issueTypesProvider = FutureProvider<List<IssueType>>((ref) async {
  final repository = ref.watch(issueRepositoryProvider);
  final typeModel = await repository.getIssueTypes();
  return typeModel.types;
});

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen>
    with SingleTickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAnalyzing = false;
  int _analysisInFlight = 0;

  late AnimationController _aiPulseController;

  @override
  void initState() {
    super.initState();
    _aiPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _aiPulseController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage(String path) async {
    _analysisInFlight++;
    if (mounted) setState(() => _isAnalyzing = true);

    try {
      final result = await GeminiAnalyzer.analyzeImage(File(path));

      if (mounted) {
        _analysisInFlight = (_analysisInFlight - 1).clamp(0, 999999);
        setState(() => _isAnalyzing = _analysisInFlight > 0);

        if (result.issueType != 'none') {
          _showAiSuggestionSheet(result);
        } else {
          String title, englishMessage, nepaliMessage;
          if (result.errorType == 'SERVER_UNAVAILABLE') {
            title = 'Server Busy';
            englishMessage =
                'AI service is currently experiencing high demand. Please try again in a few moments. You can still select issue type and priority manually.';
            nepaliMessage =
                'AI सेवा हाल व्यस्त छ। कृपया केही समयपछि फेरि प्रयास गर्नुहोस्। तपाईं issue type र priority आफैं छान्न सक्नुहुन्छ।';
          } else {
            title = 'Invalid Image';
            englishMessage = result.description.isNotEmpty
                ? result.description
                : 'Could not detect sewage, electrical or road infrastructure.';
            nepaliMessage =
                'पूर्वाधार सम्बन्धी समस्या भेटिएन। कृपया स्पष्ट फोटो अपलोड गर्नुहोस्।';
          }
          SnackbarService.showErrorDialog(
            context,
            title: title,
            englishMessage: englishMessage,
            nepaliMessage: nepaliMessage,
            buttonText: 'OK',
          );
        }
      }
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      if (mounted) {
        _analysisInFlight = (_analysisInFlight - 1).clamp(0, 999999);
        setState(() => _isAnalyzing = _analysisInFlight > 0);
        SnackbarService.showErrorDialog(
          context,
          title: 'Unexpected Error',
          englishMessage: 'An unexpected error occurred during image analysis.',
          nepaliMessage: 'तस्बिर विश्लेषण मा अप्रत्याशित त्रुटि भयो।',
          buttonText: 'Understood',
        );
      }
    }
  }

  void _showAiSuggestionSheet(GeminiAnalyzerResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _AiSuggestionDialog(
        result: result,
        onApply: () => _applyDetection(result),
      ),
    );
  }

  void _applyDetection(GeminiAnalyzerResult result) async {
    final controller = ref.read(createIssueControllerProvider.notifier);
    final typesAsync = ref.read(issueTypesProvider);

    if (typesAsync is AsyncData<List<IssueType>>) {
      final matchedType = _findBestIssueTypeMatch(typesAsync.value, result);
      if (matchedType != null) controller.updateIssueType(matchedType);
    }

    const validPriorities = {'LOW', 'NORMAL', 'HIGH'};
    controller.updatePriority(
      validPriorities.contains(result.priority) ? result.priority : 'NORMAL',
    );

    String newDesc = _descriptionController.text;
    if (newDesc.isEmpty) {
      newDesc = result.description;
    } else {
      newDesc += '\n[AI detected: ${result.description}]';
    }
    _descriptionController.text = newDesc;
    controller.updateDescription(newDesc);

    SnackbarService.showSuccess(context, 'AI suggestions applied!');
  }

  IssueType? _findBestIssueTypeMatch(
    List<IssueType> types,
    GeminiAnalyzerResult result,
  ) {
    if (types.isEmpty) return null;
    final specific = result.issueType.toLowerCase().trim();
    final directMatch = types.where((t) {
      final type = t.issueType.toLowerCase().trim();
      return type.contains(specific) || specific.contains(type);
    }).toList();
    return directMatch.isNotEmpty ? directMatch.first : types.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createIssueState = ref.watch(createIssueControllerProvider);
    final createIssueController = ref.read(
      createIssueControllerProvider.notifier,
    );
    final locationState = ref.watch(locationNotifierProvider);

    ref.listen<LocationState>(locationNotifierProvider, (previous, next) {
      if (previous?.issueLocation != next.issueLocation ||
          previous?.latitude != next.latitude ||
          previous?.longitude != next.longitude) {
        createIssueController.updateLocation(
          next.issueLocation,
          next.latitude,
          next.longitude,
        );
      }
    });

    ref.listen<CreateIssueState>(createIssueControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        SnackbarService.showError(context, next.errorMessage!);
        createIssueController.clearErrorMessage();
      }
      if (next.isSuccess && next.createdIssue != null) {
        SnackbarService.showSuccess(context, 'Issue reported successfully!');
        _descriptionController.clear();
        createIssueController.resetForm();
        ref.read(locationNotifierProvider.notifier).clear();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) context.pop(next.createdIssue);
        });
      }
    });

    if (ref.watch(issueTypesProvider).isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 100,
                  backgroundColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.welcomeGradient,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(72, 12, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Report Issue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Help us fix your community',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Body ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step 1: Photo
                        _StepCard(
                          step: 1,
                          label: 'Capture Photo',
                          isDark: isDark,
                          child: Column(
                            children: [
                              ImagePickerGrid(
                                attachments: createIssueState.attachments,
                                onImageAdded: (path) {
                                  createIssueController.addAttachment(path);
                                  _analyzeImage(path);
                                },
                                onImageRemoved: (path) {
                                  createIssueController.removeAttachment(path);
                                },
                              ),
                              if (createIssueState.attachments.isEmpty) ...[
                                const SizedBox(height: 12),
                                _AiBanner(
                                  pulseController: _aiPulseController,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Step 2: Issue Type
                        _StepCard(
                          step: 2,
                          label: 'Issue Type',
                          isDark: isDark,
                          child: ref
                              .watch(issueTypesProvider)
                              .when(
                                data: (types) {
                                  final selectedType =
                                      createIssueState.issueTypeId != null
                                      ? IssueType(
                                          issueTypeId:
                                              createIssueState.issueTypeId!,
                                          issueType: createIssueState.issueType,
                                        )
                                      : null;
                                  return IssueTypeSelector(
                                    types: types,
                                    selectedType: selectedType,
                                    onTypeSelected:
                                        createIssueController.updateIssueType,
                                  );
                                },
                                loading: () => const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                                error: (_, __) => const Text(
                                  'Failed to load issue types',
                                  style: TextStyle(color: AppColors.adminRed),
                                ),
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Step 3: Priority
                        _StepCard(
                          step: 3,
                          label: 'Priority',
                          isDark: isDark,
                          child: PrioritySelector(
                            selectedPriority: createIssueState.priority,
                            onPrioritySelected:
                                createIssueController.updatePriority,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Step 4: Description
                        _StepCard(
                          step: 4,
                          label: 'Description',
                          isDark: isDark,
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            onChanged: createIssueController.updateDescription,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextMain
                                  : AppColors.textMain,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Describe the issue in detail…',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurface2.withValues(
                                      alpha: 0.5,
                                    )
                                  : AppColors.background,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please describe the issue';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Step 5: Location
                        _StepCard(
                          step: 5,
                          label: 'Location',
                          isDark: isDark,
                          child: Column(
                            children: [
                              const LocationPicker(),
                              if (locationState.issueLocation.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          locationState.issueLocation,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AI / Submit loading overlay
          if (createIssueState.isLoading || _isAnalyzing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface.withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : AppColors.primaryBlue.withValues(
                                      alpha: 0.12,
                                    ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: _isAnalyzing
                                      ? AppColors.primaryBlue
                                      : AppColors.adminRed,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isAnalyzing
                                    ? 'Analysing with AI…'
                                    : 'Submitting…',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextMain
                                      : AppColors.textMain,
                                ),
                              ),
                              if (_isAnalyzing) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Powered by Gemini',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Submit bar
          if (!createIssueState.isLoading && !_isAnalyzing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.92),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: ActionButton(
                          width: double.infinity,
                          label: 'Submit Issue',
                          backgroundColor: AppColors.adminRed,
                          textColor: Colors.white,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              createIssueController.submitIssue();
                            }
                          },
                          borderRadius: 14,
                          verticalPadding: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Step Card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int step;
  final String label;
  final Widget child;
  final bool isDark;

  const _StepCard({
    required this.step,
    required this.label,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.primaryBlue.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue800,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextMain
                            : AppColors.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 0),
                child: Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.border,
                ),
              ),

              // Content
              Padding(padding: const EdgeInsets.all(16), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AI Banner ────────────────────────────────────────────────────────────────

class _AiBanner extends StatelessWidget {
  final AnimationController pulseController;
  final bool isDark;

  const _AiBanner({required this.pulseController, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final glow = 0.08 + pulseController.value * 0.1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: glow),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: AppColors.primaryBlue.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI auto-fills issue type & priority from your photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── AI Suggestion Dialog ─────────────────────────────────────────────────────

class _AiSuggestionDialog extends StatelessWidget {
  final GeminiAnalyzerResult result;
  final VoidCallback onApply;

  const _AiSuggestionDialog({required this.result, required this.onApply});

  Color _priorityColor(String p) {
    switch (p) {
      case 'HIGH':
        return Colors.orange.shade700;
      case 'NORMAL':
        return AppColors.primaryBlue;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.primaryBlue.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Suggestion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextMain
                              : AppColors.textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Gemini detected the following',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Detection rows
              _DetectionRow(
                icon: Icons.category_rounded,
                label: 'Issue Type',
                value: result.issueType,
                isDark: isDark,
                valueColor: AppColors.primaryBlue,
              ),
              const SizedBox(height: 12),
              _DetectionRow(
                icon: Icons.flag_rounded,
                label: 'Priority',
                value: result.priority,
                isDark: isDark,
                valueColor: _priorityColor(result.priority),
              ),

              if (result.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface2.withValues(alpha: 0.5)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Text(
                    result.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface2
                              : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          'Discard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onApply();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Apply AI Fill',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color valueColor;

  const _DetectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface2.withValues(alpha: 0.4)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: valueColor),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

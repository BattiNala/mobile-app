import 'dart:io';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/core/widgets/loading_indicator.dart';
import 'package:batti_nala/features/user-issue/controllers/create_issue_state.dart';
import 'package:batti_nala/features/shared-issue/models/issue_type_model.dart';
import 'package:batti_nala/features/shared-issue/repository/issue_repository.dart';
import 'package:batti_nala/features/user-issue/view/widgets/image_picker_grid.dart';
import 'package:batti_nala/features/user-issue/view/widgets/issue_type_selector.dart';
import 'package:batti_nala/features/user-issue/view/widgets/location_picker.dart';
import 'package:batti_nala/features/user-issue/view/widgets/priority_selector.dart';
import 'package:batti_nala/core/services/gemini_analyzer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:batti_nala/features/user-issue/controllers/location_notifier.dart';
import 'package:batti_nala/features/user-issue/controllers/location_state.dart';
import 'package:batti_nala/features/user-issue/controllers/create_issue_controller.dart';

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

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAnalyzing = false;
  int _analysisInFlight = 0;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage(String path) async {
    _analysisInFlight++;
    if (mounted) {
      setState(() => _isAnalyzing = true);
    }

    try {
      final result = await GeminiAnalyzer.analyzeImage(File(path));

      if (mounted) {
        _analysisInFlight = (_analysisInFlight - 1).clamp(0, 999999);
        setState(() => _isAnalyzing = _analysisInFlight > 0);

        if (result.issueType != 'none') {
          _showDetectionSummary(result);
        } else {
          final englishMessage = result.description.isNotEmpty
              ? result.description
              : 'Could not detect sewage, electrical or road infrastructure.';
          const nepaliMessage =
              'पूर्वाधार सम्बन्धी समस्या भेटिएन। कृपया स्पष्ट फोटो अपलोड गर्नुहोस्।';

          SnackbarService.showErrorDialog(
            context,
            title: 'Invalid Image',
            englishMessage: englishMessage,
            nepaliMessage: nepaliMessage,
            buttonText: 'OK',
          );
          debugPrint('Detection invalid: ${result.description}');
        }
      }
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      if (mounted) {
        _analysisInFlight = (_analysisInFlight - 1).clamp(0, 999999);
        setState(() => _isAnalyzing = _analysisInFlight > 0);
        SnackbarService.showErrorDialog(
          context,
          title: 'Scan Failed',
          englishMessage:
              'Image scan failed. You can still select issue type and priority manually.',
          nepaliMessage:
              'तस्बिर जाँच सफल भएन। कृपया issue type र priority आफैं छान्नुहोस्।',
          buttonText: 'Understood',
        );
      }
    }
  }

  void _showDetectionSummary(GeminiAnalyzerResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
            SizedBox(width: 12),
            Text('AI Suggestion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              'Issue Type',
              result.issueType,
              Icons.category_rounded,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Priority',
              result.priority,
              Icons.priority_high_rounded,
              color: _getPriorityColor(result.priority),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _applyDetection(result);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Apply AI Fill'),
          ),
        ],
      ),
    );
  }

  void _applyDetection(GeminiAnalyzerResult result) async {
    final controller = ref.read(createIssueControllerProvider.notifier);
    final typesAsync = ref.read(issueTypesProvider);

    if (typesAsync is AsyncData<List<IssueType>>) {
      final matchedType = _findBestIssueTypeMatch(typesAsync.value, result);
      if (matchedType != null) {
        controller.updateIssueType(matchedType);
      }
    }

    const validPriorities = {'LOW', 'NORMAL', 'HIGH'};
    final resolvedPriority = validPriorities.contains(result.priority)
        ? result.priority
        : 'NORMAL';
    controller.updatePriority(resolvedPriority);

    // Update description if it's empty or add keywords
    String newDesc = _descriptionController.text;
    final detectedTypeLabel = result.issueType;

    if (newDesc.isEmpty) {
      newDesc = 'Detected $detectedTypeLabel: ${result.description}';
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
      if (specific.isEmpty) return false;
      return type.contains(specific) || specific.contains(type);
    }).toList();
    if (directMatch.isNotEmpty) return directMatch.first;

    return types.first;
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textMain,
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String p) {
    switch (p) {
      case 'URGENT':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade700;
      case 'NORMAL':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final createIssueState = ref.watch(createIssueControllerProvider);
    final createIssueController = ref.read(
      createIssueControllerProvider.notifier,
    );
    final locationState = ref.watch(locationNotifierProvider);

    ref.listen<LocationState>(locationNotifierProvider, (previous, next) {
      final hasLocationChanged =
          previous?.issueLocation != next.issueLocation ||
          previous?.latitude != next.latitude ||
          previous?.longitude != next.longitude;

      if (!hasLocationChanged) return;

      createIssueController.updateLocation(
        next.issueLocation,
        next.latitude,
        next.longitude,
      );
    });

    ref.listen<CreateIssueState>(createIssueControllerProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        debugPrint(
          'Snackbar triggered with error message: ${next.errorMessage}',
        );
        SnackbarService.showError(context, next.errorMessage!);

        createIssueController.clearErrorMessage();
      }

      if (next.isSuccess && next.createdIssue != null) {
        debugPrint('Snackbar triggered for success message.');
        SnackbarService.showSuccess(context, 'Issue reported successfully!');

        // Reset form after success
        _descriptionController.clear();
        createIssueController.resetForm();
        ref.read(locationNotifierProvider.notifier).clear();

        // Navigate back after success
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            context.pop(next.createdIssue);
          }
        });
      }
    });

    if (ref.watch(issueTypesProvider).isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
        backgroundColor: AppColors.primaryBlue900,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Image Picker (AI Entry Point)
                  _buildSectionHeader('Step 1: Capture Photo'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ImagePickerGrid(
                            attachments: createIssueState.attachments,
                            onImageAdded: (path) {
                              createIssueController.addAttachment(path);
                              // AI Detection trigger
                              _analyzeImage(path);
                            },
                            onImageRemoved: (path) {
                              createIssueController.removeAttachment(path);
                            },
                          ),
                          if (createIssueState.attachments.isEmpty) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'AI will auto-fill details from your photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryBlue,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(
                    height: 32,
                    thickness: 1,
                    color: AppColors.border,
                  ),

                  // Step 2: Issue Type Selector
                  _buildSectionHeader('Step 2: Verify Details'),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Issue Type'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                                onTypeSelected: (selectedType) {
                                  createIssueController.updateIssueType(
                                    selectedType,
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryBlue900,
                                ),
                              ),
                            ),
                            error: (error, stack) => const Center(
                              child: Text(
                                'Failed to load issue types',
                                style: TextStyle(color: AppColors.adminRed),
                              ),
                            ),
                          ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Priority Selector
                  _buildSectionHeader('Priority'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: PrioritySelector(
                        selectedPriority: createIssueState.priority,
                        onPrioritySelected: (priority) {
                          createIssueController.updatePriority(priority);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Field
                  _buildSectionHeader('Description'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    onChanged: createIssueController.updateDescription,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    style: const TextStyle(color: AppColors.textMain),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe the issue';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Location Picker
                  _buildSectionHeader('Location'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: LocationPicker(),
                    ),
                  ),
                  if (locationState.issueLocation.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade300,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            'Selected: ${locationState.issueLocation}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Submit Button
                  ActionButton(
                    width: double.infinity,
                    label: createIssueState.isLoading
                        ? 'Submitting'
                        : 'Submit Issue',

                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        createIssueController.submitIssue();
                      }
                    },
                    isLoading: createIssueState.isLoading,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          if (createIssueState.isLoading || _isAnalyzing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoadingIndicator(),
                    if (_isAnalyzing) ...[
                      Text(
                        'Detecting issue type & priority',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
    );
  }
}

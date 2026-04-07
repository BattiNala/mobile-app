import 'dart:io';
import 'package:batti_nala/core/services/improved_image_analyzer.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/core/widgets/loading_indicator.dart';
import 'package:batti_nala/features/issue_report/controllers/create_issue_state.dart';
import 'package:batti_nala/features/issue_report/models/issue_type_model.dart';
import 'package:batti_nala/features/issue_report/repository/issue_repository.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/image_picker_grid.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/issue_type_selector.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/location_picker.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/priority_selector.dart';
import 'package:batti_nala/core/services/ml_kit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:batti_nala/features/issue_report/controllers/location_notifier.dart';
import 'package:batti_nala/features/issue_report/controllers/location_state.dart';
import 'package:batti_nala/features/issue_report/controllers/create_issue_controller.dart';

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
  final _mlKitService = MLKitService();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _mlKitService.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage(String path) async {
    setState(() => _isAnalyzing = true);

    try {
      final aiResult = await _mlKitService.processImage(path);
      // Pass the original path for color analysis
      final result = ImprovedImageAnalyzer.analyze(aiResult, imageFile: File(path));

      if (mounted) {
        setState(() => _isAnalyzing = false);

        if (result.isValid) {
          _showDetectionSummary(result);
        } else {
          String message;
          if (result.matchedKeywords.isNotEmpty) {
            final reason = result.matchedKeywords.first;
            message =
                'AI Note: We detected a $reason. Please take a clear photo of ONLY the infrastructure issue.';
          } else {
            message =
                'No specific utility issue detected. Please select details manually.';
          }

          SnackbarService.showInfo(context, message);
          debugPrint('Detection invalid: ${result.rejectionReason}');
        }
      }
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showDetectionSummary(DetectionResult result) {
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
              result.specificType ?? 'Unknown',
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

  void _applyDetection(DetectionResult result) async {
    final controller = ref.read(createIssueControllerProvider.notifier);
    final typesAsync = ref.read(issueTypesProvider);

    if (typesAsync is AsyncData<List<IssueType>>) {
      final matchedType = typesAsync.value.firstWhere(
        (t) =>
            t.issueType.toLowerCase().contains(
              result.specificType!.toLowerCase(),
            ) ||
            result.specificType!.toLowerCase().contains(
              t.issueType.toLowerCase(),
            ),
        orElse: () => typesAsync.value.first,
      );

      controller.updateIssueType(matchedType);
    }

    controller.updatePriority(result.priority);

    // Update description if it's empty or add keywords
    String newDesc = _descriptionController.text;
    if (newDesc.isEmpty) {
      newDesc =
          'Detected ${result.specificType}: ${result.matchedKeywords.join(", ")}';
    } else {
      newDesc += '\n[AI detected: ${result.matchedKeywords.join(", ")}]';
    }
    _descriptionController.text = newDesc;
    controller.updateDescription(newDesc);

    SnackbarService.showSuccess(context, 'AI suggestions applied!');
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

                  const SizedBox(height: 24),

                  // Image Picker moved to top
                  const SizedBox(height: 8),

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
                      const SizedBox(height: 16),
                      const Text(
                        'Smart Analysis Running...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
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

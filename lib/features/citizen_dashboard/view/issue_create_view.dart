import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/core/widgets/loading_indicator.dart';
import 'package:batti_nala/features/citizen_dashboard/controllers/create_issue_state.dart';
import 'package:batti_nala/features/citizen_dashboard/models/issue_type_model.dart';
import 'package:batti_nala/features/citizen_dashboard/repository/citizen_issue_repository.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/image_picker_grid.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/issue_type_selector.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/location_picker.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/priority_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:batti_nala/features/citizen_dashboard/controllers/location_notifier.dart';
import 'package:batti_nala/features/citizen_dashboard/controllers/location_state.dart';
// ignore: always_use_package_imports
import '../controllers/create_issue_controller.dart';

final issueTypesProvider = FutureProvider<List<IssueType>>((ref) async {
  final repository = ref.watch(citizenIssueRepositoryProvider);
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
                  // Issue Type Selector
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

                  // Image Picker
                  _buildSectionHeader('Attachments (Photos)'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ImagePickerGrid(
                        attachments: createIssueState.attachments,
                        onImageAdded: (path) {
                          createIssueController.addAttachment(path);
                        },
                        onImageRemoved: (path) {
                          createIssueController.removeAttachment(path);
                        },
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

          if (createIssueState.isLoading)
            Container(color: Colors.black26, child: const SizedBox.expand()),
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

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/specialized_students_step.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/supervision_step.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/task_and_ability_step.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/post_internship_enterprise_evaluation.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('EnterpriseEvaluationScreen');

Future<void> showEnterpriseEvaluationFormDialog(
  BuildContext context, {
  required String internshipId,
  int? evaluationIndex,
}) async {
  final editMode = evaluationIndex == null;
  final internships = InternshipsProvider.of(context, listen: false);
  final internship = internships.fromId(internshipId);

  if (editMode) {
    final hasLock = await internships.getLockForItem(internship);
    if (!hasLock || !context.mounted) {
      if (context.mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de modifier ce stage, car il est en cours de modification par un autre utilisateur.',
        );
      }
      return;
    }
  }

  final newEvaluation = await showDialog<PostInternshipEnterpriseEvaluation>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        Dialog(child: _EnterpriseEvaluationScreen(internshipId: internship.id)),
  );
  if (!editMode) return;
  final isSuccess = newEvaluation != null &&
      await internships.replaceWithConfirmation(
          Internship.fromSerialized(internship.serialize())
            ..enterpriseEvaluations.add(newEvaluation));
  await internships.releaseLockForItem(internship);

  if (isSuccess && context.mounted) {
    showSnackBar(context, message: 'Le stage a bien été mis à jour');
  }
  return;
}

class _EnterpriseEvaluationScreen extends StatefulWidget {
  const _EnterpriseEvaluationScreen({required this.internshipId});

  final String internshipId; // Internship id

  @override
  State<_EnterpriseEvaluationScreen> createState() =>
      _EnterpriseEvaluationScreenState();
}

class _EnterpriseEvaluationScreenState
    extends State<_EnterpriseEvaluationScreen> {
  final _scrollController = ScrollController();

  final List<StepState> _stepStatus = [
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
  ];

  final _taskAndAbilityKey = GlobalKey<TaskAndAbilityStepState>();
  final _supervisionKey = GlobalKey<SupervisionStepState>();
  final _specializedStudentsKey = GlobalKey<SpecializedStudentsStepState>();
  final double _tabHeight = 0.0;
  int _currentStep = 0;

  void _showInvalidFieldsSnakBar([String? message]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showSnackBar(
      context,
      message: message ?? 'Remplir tous les champs avec un *.',
    );
  }

  void _nextStep() async {
    _logger.finer('Next step called, current step: $_currentStep');

    bool valid = false;
    String? message;
    if (_currentStep >= 0) {
      message = await _taskAndAbilityKey.currentState!.validate();
      valid = message == null;
      _stepStatus[0] = valid ? StepState.complete : StepState.error;
    }
    if (_currentStep >= 1) {
      message = await _supervisionKey.currentState!.validate();
      valid = message == null;
      _stepStatus[1] = valid ? StepState.complete : StepState.error;
    }
    if (_currentStep >= 2) {
      message = await _specializedStudentsKey.currentState!.validate();
      valid = message == null;
      _stepStatus[2] = valid ? StepState.complete : StepState.error;
    }
    setState(() {});

    if (!valid) {
      _showInvalidFieldsSnakBar(message);
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (_currentStep == 2) {
      if ((await _taskAndAbilityKey.currentState!.validate()) != null) {
        setState(() {
          _currentStep = 0;
          _scrollToCurrentTab();
        });
        _showInvalidFieldsSnakBar(message);
        return;
      }

      if (await _supervisionKey.currentState!.validate() != null) {
        setState(() {
          _currentStep = 1;
          _scrollToCurrentTab();
        });
        _showInvalidFieldsSnakBar(message);
        return;
      }
      _submit();
    } else {
      setState(() {
        _currentStep += 1;
        _scrollToCurrentTab();
      });
    }
  }

  void _previousStep() {
    _logger.finer('Previous step called, current step: $_currentStep');

    _currentStep--;
    _scrollToCurrentTab();
    setState(() {});
  }

  void _scrollToCurrentTab() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Wait until the stepper has closed and reopened before moving
      _scrollController.jumpTo(_currentStep * _tabHeight);
    });
  }

  void _submit() {
    _logger
        .info('Submitting evaluation for internship: ${widget.internshipId}');

    Navigator.of(context).pop(PostInternshipEnterpriseEvaluation(
      date: DateTime.now(),
      internshipId: widget.internshipId,
      skillsRequired: _taskAndAbilityKey.currentState!.requiredSkills,
      taskVariety: _taskAndAbilityKey.currentState!.taskVariety!,
      trainingPlanRespect: _taskAndAbilityKey.currentState!.trainingPlan!,
      autonomyExpected: _supervisionKey.currentState!.autonomyExpected!,
      efficiencyExpected: _supervisionKey.currentState!.efficiencyExpected!,
      supervisionStyle: _supervisionKey.currentState!.supervisionStyle!,
      easeOfCommunication: _supervisionKey.currentState!.easeOfCommunication!,
      absenceAcceptance: _supervisionKey.currentState!.absenceAcceptance!,
      supervisionComments: _supervisionKey.currentState!.supervisionComments,
      acceptanceTsa: _specializedStudentsKey.currentState!.acceptanceTsa,
      acceptanceLanguageDisorder:
          _specializedStudentsKey.currentState!.acceptanceLanguageDisorder,
      acceptanceIntellectualDisability: _specializedStudentsKey
          .currentState!.acceptanceIntellectualDisability,
      acceptancePhysicalDisability:
          _specializedStudentsKey.currentState!.acceptancePhysicalDisability,
      acceptanceMentalHealthDisorder:
          _specializedStudentsKey.currentState!.acceptanceMentalHealthDisorder,
      acceptanceBehaviorDifficulties:
          _specializedStudentsKey.currentState!.acceptanceBehaviorDifficulties,
    ));
  }

  void _cancel() async {
    _logger.info('Cancel called, current step: $_currentStep');
    final navigator = Navigator.of(context);
    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
    );
    if (!mounted || !answer) return;
    _logger.fine('User confirmed exit, navigating back');
    navigator.pop(null);
  }

  @override
  Widget build(BuildContext context) {
    _logger.fine(
      'Building EnterpriseEvaluationScreen for internship: ${widget.internshipId}',
    );

    final internships = InternshipsProvider.of(context, listen: false);
    final internship =
        internships.firstWhere((e) => e.id == widget.internshipId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Évaluation post-stage'),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: PopScope(
          child: Selector<EnterprisesProvider, Job>(
            builder: (context, job, _) => ScrollableStepper(
              type: StepperType.horizontal,
              scrollController: _scrollController,
              currentStep: _currentStep,
              onTapContinue: _nextStep,
              onStepTapped: (int tapped) => setState(() {
                _scrollController.jumpTo(0);
                _currentStep = tapped;
              }),
              onTapCancel: () => Navigator.pop(context),
              steps: [
                Step(
                  state: _stepStatus[0],
                  isActive: _currentStep == 0,
                  title: const Text(
                    'Tâches et\nhabiletés',
                    textAlign: TextAlign.center,
                  ),
                  content: TaskAndAbilityStep(
                    key: _taskAndAbilityKey,
                    internship: internship,
                  ),
                ),
                Step(
                  state: _stepStatus[1],
                  isActive: _currentStep == 1,
                  title: const Text('Encadrement'),
                  content: SupervisionStep(
                      key: _supervisionKey, internship: internship),
                ),
                Step(
                  state: _stepStatus[2],
                  isActive: _currentStep == 2,
                  title: const Text('Clientèle\nspécialisée'),
                  content: SpecializedStudentsStep(
                    key: _specializedStudentsKey,
                    internship: internship,
                  ),
                ),
              ],
              controlsBuilder: _controlBuilder,
            ),
            selector: (context, enterprises) =>
                enterprises[internship.enterpriseId].jobs[internship.jobId],
          ),
        ),
      ),
    );
  }

  Widget _controlBuilder(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep != 0)
            OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Précédent'),
            ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: details.onStepContinue,
            child: _currentStep == 2
                ? const Text('Confirmer')
                : const Text('Suivant'),
          ),
        ],
      ),
    );
  }
}

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('AttitudeEvaluationScreen');

Future<void> showAttitudeEvaluationDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
}) async {
  final editMode = evaluationId == null;
  _logger.info('Showing AttitudeEvaluationDialog with editMode: $editMode');

  final internships = InternshipsProvider.of(context, listen: false);
  final internship = internships.fromId(internshipId);

  evaluationId = evaluationId ??
      (internship.attitudeEvaluations.isEmpty
          ? null
          : internship.attitudeEvaluations.last.id);
  final controller = evaluationId == null
      ? AttitudeEvaluationFormController(internshipId: internshipId)
      : AttitudeEvaluationFormController.fromInternshipId(context,
          internshipId: internshipId, evaluationId: evaluationId);

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

  final newEvaluation = await showDialog<InternshipEvaluationAttitude?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _AttitudeEvaluationScreen(
            rootContext: context,
            formController: controller,
            editMode: editMode,
          ),
        ),
      ),
    ),
  );
  if (!editMode) return;

  final isSuccess = newEvaluation != null &&
      await internships.replaceWithConfirmation(
          Internship.fromSerialized(internship.serialize())
            ..attitudeEvaluations.add(newEvaluation));

  await internships.releaseLockForItem(internship);

  if (isSuccess && context.mounted) {
    showSnackBar(context, message: 'Le stage a bien été mis à jour');
  }
  return;
}

class AttitudeEvaluationFormController {
  static const _formVersion = '1.0.0';

  AttitudeEvaluationFormController({required this.internshipId});
  final String internshipId;
  Internship internship(BuildContext context, {bool listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  factory AttitudeEvaluationFormController.fromInternshipId(
    BuildContext context, {
    required String internshipId,
    required String evaluationId,
  }) {
    Internship internship =
        InternshipsProvider.of(context, listen: false)[internshipId];
    InternshipEvaluationAttitude evaluation =
        internship.attitudeEvaluations.firstWhere((e) => e.id == evaluationId);

    final controller = AttitudeEvaluationFormController(
      internshipId: internshipId,
    );

    controller.evaluationDate = evaluation.date;

    controller.wereAtMeeting.clear();
    controller.wereAtMeeting.addAll(evaluation.presentAtEvaluation);

    controller.responses[Inattendance] = evaluation.attitude.inattendance;
    controller.responses[Ponctuality] = evaluation.attitude.ponctuality;
    controller.responses[Sociability] = evaluation.attitude.sociability;
    controller.responses[Politeness] = evaluation.attitude.politeness;
    controller.responses[Motivation] = evaluation.attitude.motivation;
    controller.responses[DressCode] = evaluation.attitude.dressCode;
    controller.responses[QualityOfWork] = evaluation.attitude.qualityOfWork;
    controller.responses[Productivity] = evaluation.attitude.productivity;
    controller.responses[Autonomy] = evaluation.attitude.autonomy;
    controller.responses[Cautiousness] = evaluation.attitude.cautiousness;
    controller.responses[GeneralAppreciation] =
        evaluation.attitude.generalAppreciation;

    controller.commentsController.text = evaluation.comments;

    return controller;
  }

  InternshipEvaluationAttitude toInternshipEvaluation() {
    return InternshipEvaluationAttitude(
      date: evaluationDate,
      presentAtEvaluation: wereAtMeeting,
      attitude: AttitudeEvaluation(
        inattendance: responses[Inattendance]! as Inattendance,
        ponctuality: responses[Ponctuality]! as Ponctuality,
        sociability: responses[Sociability]! as Sociability,
        politeness: responses[Politeness]! as Politeness,
        motivation: responses[Motivation]! as Motivation,
        dressCode: responses[DressCode]! as DressCode,
        qualityOfWork: responses[QualityOfWork]! as QualityOfWork,
        productivity: responses[Productivity]! as Productivity,
        autonomy: responses[Autonomy]! as Autonomy,
        cautiousness: responses[Cautiousness]! as Cautiousness,
        generalAppreciation:
            responses[GeneralAppreciation]! as GeneralAppreciation,
      ),
      comments: commentsController.text,
      formVersion: _formVersion,
    );
  }

  DateTime evaluationDate = DateTime.now();

  late final wereAtMeetingController = CheckboxWithOtherController(
    elements: wereAtMeetingOptions,
    initialValues: wereAtMeeting,
  );
  final List<String> wereAtMeetingOptions = [
    'Stagiaire',
    'Responsable en milieu de stage',
  ];
  final List<String> wereAtMeeting = [];
  void setWereAtMeeting() {
    wereAtMeeting.clear();
    wereAtMeeting.addAll(wereAtMeetingController.values);
  }

  Map<Type, AttitudeCategoryEnum?> responses = {};

  final commentsController = TextEditingController();

  bool get isAttitudeCompleted =>
      responses[Inattendance] != null &&
      responses[Ponctuality] != null &&
      responses[Sociability] != null &&
      responses[Politeness] != null &&
      responses[Motivation] != null &&
      responses[DressCode] != null;

  bool get isSkillCompleted =>
      responses[QualityOfWork] != null &&
      responses[Productivity] != null &&
      responses[Autonomy] != null &&
      responses[Cautiousness] != null;

  bool get isGeneralAppreciationCompleted =>
      responses[GeneralAppreciation] != null;

  bool get isCompleted =>
      isAttitudeCompleted && isSkillCompleted && isGeneralAppreciationCompleted;
}

class _AttitudeEvaluationScreen extends StatefulWidget {
  const _AttitudeEvaluationScreen({
    required this.rootContext,
    required this.formController,
    required this.editMode,
  });

  final BuildContext rootContext;
  final AttitudeEvaluationFormController formController;
  final bool editMode;

  @override
  State<_AttitudeEvaluationScreen> createState() =>
      _AttitudeEvaluationScreenState();
}

class _AttitudeEvaluationScreenState extends State<_AttitudeEvaluationScreen> {
  final _scrollController = ScrollController();

  int _currentStep = 0;
  final List<StepState> _stepStatus = [
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
  ];

  void _previousStep() {
    _logger.finer('Going back to previous step from step $_currentStep');

    if (_currentStep == 0) return;

    _currentStep -= 1;
    _scrollController.jumpTo(0);
    setState(() {});
  }

  void _nextStep() {
    _logger.finer('Going to next step from step $_currentStep');

    _stepStatus[0] = StepState.complete;
    if (_currentStep >= 1) {
      _stepStatus[1] = widget.formController.isAttitudeCompleted
          ? StepState.complete
          : StepState.error;
    }
    if (_currentStep >= 2) {
      _stepStatus[2] = widget.formController.isSkillCompleted
          ? StepState.complete
          : StepState.error;
    }
    if (_currentStep >= 3) {
      _stepStatus[3] = widget.formController.isGeneralAppreciationCompleted
          ? StepState.complete
          : StepState.error;
    }
    setState(() {});

    if (_currentStep == 3) {
      _submit();
      return;
    }

    _currentStep += 1;
    _scrollController.jumpTo(0);
    setState(() {});
  }

  void _cancel() async {
    _logger.info('Cancelling AttitudeEvaluationDialog');
    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
      isEditing: widget.editMode,
    );
    if (!mounted || !answer) return;

    _logger.fine('User confirmed cancellation, closing dialog');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  Future<void> _submit() async {
    _logger.info('Submitting attitude evaluation form');
    if (!widget.formController.isCompleted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Formulaire incomplet'),
          content: Text('Répondre à toutes les questions avec un *.'),
        ),
      );
      return;
    }

    widget.formController.setWereAtMeeting();

    _logger.fine('Attitude evaluation form submitted successfully');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext)
        .pop(widget.formController.toInternshipEvaluation());
  }

  Widget _controlBuilder(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Expanded(child: SizedBox()),
          if (_currentStep != 0)
            OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Précédent'),
            ),
          const SizedBox(width: 20),
          if (_currentStep != 3)
            TextButton(
              onPressed: details.onStepContinue,
              child: const Text('Suivant'),
            ),
          if (_currentStep == 3 && widget.editMode)
            TextButton(
              onPressed: details.onStepContinue,
              child: const Text('Soumettre'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building AttitudeEvaluationScreen for internship: ${widget.formController.internshipId}',
    );

    final internship =
        InternshipsProvider.of(context)[widget.formController.internshipId];
    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == internship.studentId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${student == null ? 'En attente des informations' : 'Évaluation de ${student.fullName}'}\nC2. Attitudes - Comportements',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: PopScope(
          child: student == null
              ? const Center(child: CircularProgressIndicator())
              : ScrollableStepper(
                  scrollController: _scrollController,
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onTapContinue: _nextStep,
                  onStepTapped: (int tapped) => setState(() {
                    _currentStep = tapped;
                    _scrollController.jumpTo(0);
                  }),
                  onTapCancel: _cancel,
                  steps: [
                    Step(
                      label: const Text('Détails'),
                      title: Container(),
                      state: _stepStatus[0],
                      isActive: _currentStep == 0,
                      content: _AttitudeGeneralDetailsStep(
                        formController: widget.formController,
                        editMode: widget.editMode,
                      ),
                    ),
                    Step(
                      label: const Text('Attitudes'),
                      title: Container(),
                      state: _stepStatus[1],
                      isActive: _currentStep == 1,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AttitudeRadioChoices(
                            title: '1. *${Inattendance.title}',
                            formController: widget.formController,
                            elements: Inattendance.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '2. *${Ponctuality.title}',
                            formController: widget.formController,
                            elements: Ponctuality.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '3. *${Sociability.title}',
                            formController: widget.formController,
                            elements: Sociability.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '4. *${Politeness.title}',
                            formController: widget.formController,
                            elements: Politeness.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '5. *${Motivation.title}',
                            formController: widget.formController,
                            elements: Motivation.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '6. *${DressCode.title}',
                            formController: widget.formController,
                            elements: DressCode.values,
                            editMode: widget.editMode,
                          ),
                        ],
                      ),
                    ),
                    Step(
                      label: const Text('Aptitudes'),
                      title: Container(),
                      state: _stepStatus[2],
                      isActive: _currentStep == 2,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AttitudeRadioChoices(
                            title: '7. *${QualityOfWork.title}',
                            formController: widget.formController,
                            elements: QualityOfWork.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '8. *${Productivity.title}',
                            formController: widget.formController,
                            elements: Productivity.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '9. *${Autonomy.title}',
                            formController: widget.formController,
                            elements: Autonomy.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '10. *${Cautiousness.title}',
                            formController: widget.formController,
                            elements: Cautiousness.values,
                            editMode: widget.editMode,
                          ),
                        ],
                      ),
                    ),
                    Step(
                      label: const Text('Commentaires'),
                      title: Container(),
                      state: _stepStatus[3],
                      isActive: _currentStep == 3,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AttitudeRadioChoices(
                            title: '11. *${GeneralAppreciation.title}',
                            formController: widget.formController,
                            elements: GeneralAppreciation.values,
                            editMode: widget.editMode,
                          ),
                          _Comments(
                            formController: widget.formController,
                            editMode: widget.editMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                  controlsBuilder: _controlBuilder,
                ),
        ),
      ),
    );
  }
}

class _AttitudeGeneralDetailsStep extends StatelessWidget {
  const _AttitudeGeneralDetailsStep({
    required this.formController,
    required this.editMode,
  });

  final AttitudeEvaluationFormController formController;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvaluationDate(formController: formController, editMode: editMode),
        _PersonAtMeeting(formController: formController, editMode: editMode),
      ],
    );
  }
}

class _EvaluationDate extends StatefulWidget {
  const _EvaluationDate({required this.formController, required this.editMode});

  final AttitudeEvaluationFormController formController;
  final bool editMode;

  @override
  State<_EvaluationDate> createState() => _EvaluationDateState();
}

class _EvaluationDateState extends State<_EvaluationDate> {
  void _promptDate(BuildContext context) async {
    final newDate = await showCustomDatePicker(
      helpText: 'Sélectionner la date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialDate: widget.formController.evaluationDate,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (newDate == null) return;

    widget.formController.evaluationDate = newDate;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Date de l\'évaluation'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                DateFormat(
                  'dd MMMM yyyy',
                  'fr_CA',
                ).format(widget.formController.evaluationDate),
              ),
              if (widget.editMode)
                IconButton(
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.blue,
                  ),
                  onPressed: () => _promptDate(context),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonAtMeeting extends StatelessWidget {
  const _PersonAtMeeting({
    required this.formController,
    required this.editMode,
  });

  final AttitudeEvaluationFormController formController;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Personnes présentes lors de l\'évaluation'),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: CheckboxWithOther(
            controller: formController.wereAtMeetingController,
            enabled: editMode,
          ),
        ),
      ],
    );
  }
}

class _AttitudeRadioChoices extends StatefulWidget {
  const _AttitudeRadioChoices({
    required this.title,
    required this.formController,
    required this.elements,
    required this.editMode,
  });

  final String title;
  final AttitudeEvaluationFormController formController;
  final List<AttitudeCategoryEnum> elements;
  final bool editMode;

  @override
  State<_AttitudeRadioChoices> createState() => _AttitudeRadioChoicesState();
}

class _AttitudeRadioChoicesState extends State<_AttitudeRadioChoices> {
  @override
  void initState() {
    super.initState();
    if (widget.editMode) {
      widget.formController.responses[widget.elements[0].runtimeType] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue:
          widget.formController.responses[widget.elements[0].runtimeType],
      onChanged: (value) => setState(
        () => widget.formController.responses[widget.elements[0].runtimeType] =
            value!,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubTitle(widget.title),
          ...widget.elements.map(
            (e) => RadioListTile<AttitudeCategoryEnum>(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                e.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: Colors.black),
              ),
              value: e,
              enabled: widget.editMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments({required this.formController, required this.editMode});

  final bool editMode;
  final AttitudeEvaluationFormController formController;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: SubTitle('12. Autres commentaires'),
        ),
        TextFormField(
          controller: formController.commentsController,
          enabled: editMode,
          maxLines: null,
        ),
      ],
    );
  }
}

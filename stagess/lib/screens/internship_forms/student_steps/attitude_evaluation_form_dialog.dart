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

final _logger = Logger('AttitudeEvaluationScreen');

Future<Internship?> showAttitudeEvaluationDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
}) async {
  final newEvaluation = await showDialog<InternshipEvaluationAttitude?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _AttitudeEvaluationScreen(
            rootContext: context,
            internshipId: internshipId,
            evaluationId: evaluationId,
          ),
        ),
      ),
    ),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final internship =
      InternshipsProvider.of(context, listen: false).fromId(internshipId);
  return Internship.fromSerialized(internship.serialize())
    ..attitudeEvaluations.add(newEvaluation);
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
    required this.internshipId,
    required this.evaluationId,
  });

  final BuildContext rootContext;
  final String internshipId;
  final String? evaluationId;

  @override
  State<_AttitudeEvaluationScreen> createState() =>
      _AttitudeEvaluationScreenState();
}

class _AttitudeEvaluationScreenState extends State<_AttitudeEvaluationScreen> {
  bool get _editMode => widget.evaluationId == null;
  final _scrollController = ScrollController();

  late final _formController = _editMode
      ? AttitudeEvaluationFormController(internshipId: widget.internshipId)
      : AttitudeEvaluationFormController.fromInternshipId(context,
          internshipId: widget.internshipId,
          evaluationId: widget.evaluationId!);

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
      _stepStatus[1] = _formController.isAttitudeCompleted
          ? StepState.complete
          : StepState.error;
    }
    if (_currentStep >= 2) {
      _stepStatus[2] = _formController.isSkillCompleted
          ? StepState.complete
          : StepState.error;
    }
    if (_currentStep >= 3) {
      _stepStatus[3] = _formController.isGeneralAppreciationCompleted
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
      isEditing: _editMode,
    );
    if (!mounted || !answer) return;

    _logger.fine('User confirmed cancellation, closing dialog');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  Future<void> _submit() async {
    _logger.info('Submitting attitude evaluation form');
    if (!_formController.isCompleted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Formulaire incomplet'),
          content: Text('Répondre à toutes les questions avec un *.'),
        ),
      );
      return;
    }

    _formController.setWereAtMeeting();

    _logger.fine('Attitude evaluation form submitted successfully');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext)
        .pop(_formController.toInternshipEvaluation());
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
          if (_currentStep == 3 && _editMode)
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
      'Building AttitudeEvaluationScreen for internship: ${_formController.internshipId}',
    );

    final internship =
        InternshipsProvider.of(context)[_formController.internshipId];
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
                        formController: _formController,
                        editMode: _editMode,
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
                            formController: _formController,
                            elements: Inattendance.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '2. *${Ponctuality.title}',
                            formController: _formController,
                            elements: Ponctuality.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '3. *${Sociability.title}',
                            formController: _formController,
                            elements: Sociability.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '4. *${Politeness.title}',
                            formController: _formController,
                            elements: Politeness.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '5. *${Motivation.title}',
                            formController: _formController,
                            elements: Motivation.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '6. *${DressCode.title}',
                            formController: _formController,
                            elements: DressCode.values,
                            editMode: _editMode,
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
                            formController: _formController,
                            elements: QualityOfWork.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '8. *${Productivity.title}',
                            formController: _formController,
                            elements: Productivity.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '9. *${Autonomy.title}',
                            formController: _formController,
                            elements: Autonomy.values,
                            editMode: _editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '10. *${Cautiousness.title}',
                            formController: _formController,
                            elements: Cautiousness.values,
                            editMode: _editMode,
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
                            formController: _formController,
                            elements: GeneralAppreciation.values,
                            editMode: _editMode,
                          ),
                          _Comments(
                            formController: _formController,
                            editMode: _editMode,
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

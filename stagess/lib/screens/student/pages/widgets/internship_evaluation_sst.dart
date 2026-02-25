import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/screens/sst_evaluation_form/sst_evaluation_form_screen.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('InternshipEvaluationSst');

class EvaluationSst extends StatelessWidget {
  const EvaluationSst({super.key, required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EvaluationSst for job: $internshipId');

    final internship = InternshipsProvider.of(context).fromId(internshipId);
    final isFilled = internship.sstEvaluation != null;

    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Text(
        'SST en entreprise',
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: Colors.black),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isFilled
                  ? 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» a '
                      'été rempli pour ce stage.\n'
                      'Dernière modification le '
                      '${DateFormat.yMMMEd('fr_CA').format(internship.sstEvaluation!.date)}'
                  : 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» n\'a '
                      'jamais été rempli pour ce stage.'),
              Visibility(
                visible: internship.supervisingTeacherIds.contains(teacherId),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () => showSstEvaluationFormDialog(context,
                            internshipId: internship.id),
                        child: Text(isFilled
                            ? 'Modifier le questionnaire'
                            : 'Remplir le questionnaire')),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

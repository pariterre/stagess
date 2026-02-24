import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
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
        width: Size.infinite.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isFilled
                  ? 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» a '
                      'été rempli pour ce poste de travail.\n'
                      'Dernière modification le '
                      '${DateFormat.yMMMEd('fr_CA').format(internship.sstEvaluation!.date)}'
                  : 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» n\'a '
                      'jamais été rempli pour ce poste de travail.'),
              _buildAnswers(context, internship: internship),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswers(BuildContext context, {required Internship internship}) {
    final enterprise =
        EnterprisesProvider.of(context).fromId(internship.enterpriseId);
    final job = enterprise.jobs.fromId(internship.jobId);

    final questionIds = [...job.specialization.questions.map((e) => e)];
    final questions =
        questionIds.map((e) => QuestionFileService.fromId(e)).toList();
    questions.sort((a, b) => int.parse(a.idSummary) - int.parse(b.idSummary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.map((q) {
        final answer = internship.sstEvaluation?.questions['Q${q.id}'];
        final answerT = internship.sstEvaluation?.questions['Q${q.id}+t'];
        if ((q.questionSummary == null && q.followUpQuestionSummary == null) ||
            (answer == null && answerT == null)) {
          return Container();
        }

        late Widget question;
        late Widget answerWidget;
        if (q.followUpQuestionSummary == null) {
          question = Text(
            q.questionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );

          switch (q.type) {
            case QuestionType.radio:
              answerWidget = Text(
                answer!.first,
                style: Theme.of(context).textTheme.bodyMedium,
              );
              break;
            case QuestionType.checkbox:
              if (answer!.isEmpty ||
                  answer[0] == '__NOT_APPLICABLE_INTERNAL__') {
                return Container();
              }
              answerWidget = ItemizedText(answer);
              break;
            case QuestionType.text:
              answerWidget = Text(answer!.first);
              break;
          }
        } else {
          if (q.type == QuestionType.checkbox || q.type == QuestionType.text) {
            throw 'Showing follow up question for Checkbox or Text '
                'is not implemented yet';
          }

          if (answer!.first == q.choices!.last) {
            // No follow up question was needed
            return Container();
          }

          question = Text(
            q.followUpQuestionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );
          answerWidget = Text(
            answerT?.first ?? 'Aucune réponse fournie',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12.0),
            question,
            answerWidget,
          ],
        );
      }).toList(),
    );
  }
}

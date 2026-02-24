import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('InternshipEvaluationPost');

class EvaluationPost extends StatelessWidget {
  const EvaluationPost({super.key, required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EvaluationPost for job: $internshipId');

    final internship = InternshipsProvider.of(
      context,
    ).fromId(internshipId);

    final evaluation = internship.enterpriseEvaluation;
    final isFilled = evaluation != null;

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Text(
        'Évaluation de l\'entreprise',
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
                      '${DateFormat.yMMMEd('fr_CA').format(internship.enterpriseEvaluation!.date)}'
                  : 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» n\'a '
                      'jamais été rempli pour ce poste de travail.'),
            ],
          ),
        ),
      ),
    );
  }
}

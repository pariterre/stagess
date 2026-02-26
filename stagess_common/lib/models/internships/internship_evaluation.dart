import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';

abstract class InternshipEvaluation extends ItemSerializable {
  InternshipEvaluation({super.id});

  InternshipEvaluation.fromSerialized(super.map) : super.fromSerialized();

  DateTime get date;
}

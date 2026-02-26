import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common/models/internships/sst_evaluation.dart';

import '../utils.dart';

void main() {
  group('SstEvaluation', () {
    test('serialization and deserialization works', () {
      final sstEvaluation = dummySstEvaluation();
      final serialized = sstEvaluation.serialize();
      final deserialized = SstEvaluation.fromSerialized(serialized);

      expect(serialized, {
        'id': sstEvaluation.id,
        'questions': sstEvaluation.questions,
        'date': DateTime(2000, 1, 1).millisecondsSinceEpoch,
      });

      expect(deserialized.id, sstEvaluation.id);
      expect(deserialized.questions, sstEvaluation.questions);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = SstEvaluation.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.questions, {});
      expect(emptyDeserialized.date.millisecondsSinceEpoch,
          DateTime(0).millisecondsSinceEpoch);
    });
  });
}

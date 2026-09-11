import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tv_studio/data/data_budget.dart';

void main() {
  group('BudgetMode', () {
    test('each mode has a distinct MB/hour target', () {
      final values = BudgetMode.values.map((m) => m.mbPerHour).toSet();
      expect(values.length, BudgetMode.values.length);
    });

    test('MB/hour increases from minimal to unlimited', () {
      expect(
        BudgetMode.minimal.mbPerHour < BudgetMode.conservative.mbPerHour,
        true,
      );
      expect(
        BudgetMode.conservative.mbPerHour < BudgetMode.moderate.mbPerHour,
        true,
      );
      expect(
        BudgetMode.moderate.mbPerHour < BudgetMode.generous.mbPerHour,
        true,
      );
    });

    test('targetKbps is consistent with mbPerHour', () {
      for (final m in BudgetMode.values) {
        if (m == BudgetMode.unlimited) continue;
        final kbps = m.targetKbps;
        final expected = (m.mbPerHour * 8 * 1024) ~/ 3600;
        expect(kbps, expected);
      }
    });

    test('quality label matches budget tier', () {
      expect(BudgetMode.unlimited.quality, '1080p');
      expect(BudgetMode.generous.quality, '720p');
      expect(BudgetMode.moderate.quality, '480p');
      expect(BudgetMode.conservative.quality, '360p');
      expect(BudgetMode.minimal.quality, '240p');
    });

    test('every mode has a non-empty label and description', () {
      for (final m in BudgetMode.values) {
        expect(m.label.isNotEmpty, true);
        expect(m.description.isNotEmpty, true);
      }
    });
  });

  group('DataBudget', () {
    test('starts empty', () {
      final b = DataBudget();
      expect(b.bytesUsed, 0);
      expect(b.megabytesUsed, 0);
      expect(b.sessionDuration, Duration.zero);
    });

    test('reports bytes accurately', () {
      final b = DataBudget();
      b.startSession();
      b.reportBytes(1024 * 1024);
      expect(b.megabytesUsed, closeTo(1.0, 0.001));

      b.reportBytes(1024 * 1024);
      expect(b.megabytesUsed, closeTo(2.0, 0.001));
    });

    test('projected MB/hour is zero when no time has passed', () {
      final b = DataBudget();
      b.startSession();
      expect(b.projectedMbPerHour, 0);
    });

    test('overBudget is false for unlimited mode regardless of rate', () {
      final b = DataBudget()..setMode(BudgetMode.unlimited);
      b.startSession();
      b.reportBytes(500 * 1024 * 1024);
      expect(b.overBudget, false);
    });

    test('reset clears bytes and session start', () {
      final b = DataBudget();
      b.startSession();
      b.reportBytes(10000);
      b.reset();
      expect(b.bytesUsed, 0);
      expect(b.sessionDuration, Duration.zero);
    });
  });

  group('BudgetMode defaults', () {
    test('DataBudget defaults to moderate', () {
      final b = DataBudget();
      expect(b.mode, BudgetMode.moderate);
    });

    test('changing mode notifies listeners', () {
      final b = DataBudget();
      var notified = false;
      b.addListener(() => notified = true);
      b.setMode(BudgetMode.minimal);
      expect(notified, true);
      expect(b.mode, BudgetMode.minimal);
    });
  });
}

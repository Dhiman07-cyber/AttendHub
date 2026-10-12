import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendhub/features/subjects/subject_detail_screen.dart';
import 'package:attendhub/shared/models/subject_model.dart';

void main() {
  final longNameSubject = SubjectModel(
    id: 'sub_long_1',
    semesterId: 'sem_1',
    name: 'Data Communication and Computer Networks and Systems Engineering',
    code: 'CSE-501-ADV',
    facultyName: 'Prof. Dr. Christopher Montgomery Alexander',
    color: '#C96E5B',
    icon: 'book',
    isActive: true,
    attended: 0,
    conducted: 0,
    status: 'NO_DATA',
    statusLabel: 'No attendance data yet',
  );

  testWidgets('SubjectDetailScreen renders without RenderFlex overflow at 320px narrow width', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SubjectDetailScreen(subject: longNameSubject),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Data Communication and Computer Networks and Systems Engineering'), findsWidgets);
    expect(find.text('No attendance data yet'), findsWidgets);
    expect(find.text('0.0%'), findsOneWidget);
  });

  testWidgets('SubjectDetailScreen renders without RenderFlex overflow at 393px width', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SubjectDetailScreen(subject: longNameSubject),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CSE-501-ADV'), findsOneWidget);
    expect(find.text('Delete Subject'), findsWidgets);
  });

  testWidgets('SubjectDetailScreen renders without RenderFlex overflow at 360px and 412px and 430px', (tester) async {
    for (final width in [360.0, 375.0, 412.0, 430.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SubjectDetailScreen(subject: longNameSubject),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at width $width');
    }
    tester.view.resetPhysicalSize();
  });
}

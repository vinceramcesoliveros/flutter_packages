// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:adaptive_scaffold/src/adaptive_layout.dart';
import 'package:adaptive_scaffold/src/breakpoints.dart';
import 'package:adaptive_scaffold/src/slot_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestBreakpoint0 extends Breakpoint {
  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width >= 0;
  }
}

class TestBreakpoint400 extends Breakpoint {
  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width > 400;
  }
}

class TestBreakpoint800 extends Breakpoint {
  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }
}

final Finder tnav = find.byKey(const Key('tnav'));
final Finder snav = find.byKey(const Key('snav'));
final Finder pnav = find.byKey(const Key('pnav'));
final Finder bnav = find.byKey(const Key('bnav'));
final Finder b = find.byKey(const Key('b'));
final Finder sb = find.byKey(const Key('sb'));

Widget on(BuildContext _) {
  return const SizedBox(width: 10, height: 10);
}

Future<MediaQuery> layout({
  required double width,
  required WidgetTester tester,
  Axis orientation = Axis.horizontal,
  TextDirection directionality = TextDirection.ltr,
  double? bodyRatio,
  bool animations = true,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: Directionality(
      textDirection: directionality,
      child: AdaptiveLayout(
        bodyOrientation: orientation,
        bodyRatio: bodyRatio,
        internalAnimations: animations,
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            TestBreakpoint0():
                SlotLayout.from(key: const Key('pnav'), builder: on),
            TestBreakpoint400():
                SlotLayout.from(key: const Key('pnav1'), builder: on),
            TestBreakpoint800():
                SlotLayout.from(key: const Key('pnav2'), builder: on),
          },
        ),
        secondaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            TestBreakpoint0():
                SlotLayout.from(key: const Key('snav'), builder: on),
            TestBreakpoint400():
                SlotLayout.from(key: const Key('snav1'), builder: on),
            TestBreakpoint800():
                SlotLayout.from(key: const Key('snav2'), builder: on),
          },
        ),
        topNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            TestBreakpoint0():
                SlotLayout.from(key: const Key('tnav'), builder: on),
            TestBreakpoint400():
                SlotLayout.from(key: const Key('tnav1'), builder: on),
            TestBreakpoint800():
                SlotLayout.from(key: const Key('tnav2'), builder: on),
          },
        ),
        bottomNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            TestBreakpoint0():
                SlotLayout.from(key: const Key('bnav'), builder: on),
            TestBreakpoint400():
                SlotLayout.from(key: const Key('bnav1'), builder: on),
            TestBreakpoint800():
                SlotLayout.from(key: const Key('bnav2'), builder: on),
          },
        ),
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            TestBreakpoint0(): SlotLayout.from(
              key: const Key('b'),
              builder: (_) => Container(color: Colors.red),
            ),
            TestBreakpoint400(): SlotLayout.from(
              key: const Key('b1'),
              builder: (_) => Container(color: Colors.red),
            ),
            TestBreakpoint800(): SlotLayout.from(
              key: const Key('b2'),
              builder: (_) => Container(color: Colors.red),
            ),
          },
        ),
        secondaryBody: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            TestBreakpoint0(): SlotLayout.from(
              key: const Key('sb'),
              builder: (_) => Container(color: Colors.blue),
            ),
            TestBreakpoint400(): SlotLayout.from(
              key: const Key('sb1'),
              builder: (_) => Container(color: Colors.blue),
            ),
            TestBreakpoint800(): SlotLayout.from(
              key: const Key('sb2'),
              builder: (_) => Container(color: Colors.blue),
            ),
          },
        ),
      ),
    ),
  );
}

AnimatedWidget leftOutIn(Widget child, Animation<double> animation) {
  return SlideTransition(
    key: Key('in-${child.key}'),
    position: Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}

AnimatedWidget leftInOut(Widget child, Animation<double> animation) {
  return SlideTransition(
    key: Key('out-${child.key}'),
    position: Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1, 0),
    ).animate(animation),
    child: child,
  );
}

MediaQuery slot(double width) {
  return MediaQuery(
    data: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
        .copyWith(size: Size(width, 800)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          TestBreakpoint0(): SlotLayout.from(
            inAnimation: leftOutIn,
            outAnimation: leftInOut,
            key: const Key('0'),
            builder: (_) => const SizedBox(width: 10, height: 10),
          ),
          TestBreakpoint400(): SlotLayout.from(
            inAnimation: leftOutIn,
            outAnimation: leftInOut,
            key: const Key('400'),
            builder: (_) => const SizedBox(width: 10, height: 10),
          ),
        },
      ),
    ),
  );
}

void main() {
  testWidgets(
      'slot layout dislays correct item of config based on screen width',
      (WidgetTester tester) async {
    MediaQuery slot(double width) {
      return MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
            .copyWith(size: Size(width, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SlotLayout(
            config: <Breakpoint, SlotLayoutConfig>{
              TestBreakpoint0(): SlotLayout.from(
                  key: const Key('0'), builder: (_) => const SizedBox()),
              TestBreakpoint400(): SlotLayout.from(
                  key: const Key('400'), builder: (_) => const SizedBox()),
              TestBreakpoint800(): SlotLayout.from(
                  key: const Key('800'), builder: (_) => const SizedBox()),
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(slot(300));
    expect(find.byKey(const Key('0')), findsOneWidget);
    expect(find.byKey(const Key('400')), findsNothing);
    expect(find.byKey(const Key('800')), findsNothing);

    await tester.pumpWidget(slot(500));
    expect(find.byKey(const Key('0')), findsNothing);
    expect(find.byKey(const Key('400')), findsOneWidget);
    expect(find.byKey(const Key('800')), findsNothing);

    await tester.pumpWidget(slot(1000));
    expect(find.byKey(const Key('0')), findsNothing);
    expect(find.byKey(const Key('400')), findsNothing);
    expect(find.byKey(const Key('800')), findsOneWidget);
  });

  testWidgets('adaptive layout displays children in correct places',
      (WidgetTester tester) async {
    await tester.pumpWidget(await layout(width: 400, tester: tester));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tnav), Offset.zero);
    expect(tester.getTopLeft(snav), const Offset(390, 10));
    expect(tester.getTopLeft(pnav), const Offset(0, 10));
    expect(tester.getTopLeft(bnav), const Offset(0, 790));
    expect(tester.getTopLeft(b), const Offset(10, 10));
    expect(tester.getBottomRight(b), const Offset(200, 790));
    expect(tester.getTopLeft(sb), const Offset(200, 10));
    expect(tester.getBottomRight(sb), const Offset(390, 790));
  });

  testWidgets('adaptive layout correct layout when body vertical',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        await layout(width: 400, tester: tester, orientation: Axis.vertical));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tnav), Offset.zero);
    expect(tester.getTopLeft(snav), const Offset(390, 10));
    expect(tester.getTopLeft(pnav), const Offset(0, 10));
    expect(tester.getTopLeft(bnav), const Offset(0, 790));
    expect(tester.getTopLeft(b), const Offset(10, 10));
    expect(tester.getBottomRight(b), const Offset(390, 400));
    expect(tester.getTopLeft(sb), const Offset(10, 400));
    expect(tester.getBottomRight(sb), const Offset(390, 790));
  });

  testWidgets('adaptive layout correct layout when rtl',
      (WidgetTester tester) async {
    await tester.pumpWidget(await layout(
        width: 400, tester: tester, directionality: TextDirection.rtl));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tnav), Offset.zero);
    expect(tester.getTopLeft(snav), const Offset(0, 10));
    expect(tester.getTopLeft(pnav), const Offset(390, 10));
    expect(tester.getTopLeft(bnav), const Offset(0, 790));
    expect(tester.getTopLeft(b), const Offset(200, 10));
    expect(tester.getBottomRight(b), const Offset(390, 790));
    expect(tester.getTopLeft(sb), const Offset(10, 10));
    expect(tester.getBottomRight(sb), const Offset(200, 790));
  });

  testWidgets('adaptive layout correct layout when body ratio not default',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(await layout(width: 400, tester: tester, bodyRatio: 1 / 3));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tnav), Offset.zero);
    expect(tester.getTopLeft(snav), const Offset(390, 10));
    expect(tester.getTopLeft(pnav), const Offset(0, 10));
    expect(tester.getTopLeft(bnav), const Offset(0, 790));
    expect(tester.getTopLeft(b), const Offset(10, 10));
    expect(tester.getBottomRight(b),
        offsetMoreOrLessEquals(const Offset(136.7, 790), epsilon: 1.0));
    expect(tester.getTopLeft(sb),
        offsetMoreOrLessEquals(const Offset(136.7, 10), epsilon: 1.0));
    expect(tester.getBottomRight(sb), const Offset(390, 790));
  });

  final Finder begin = find.byKey(const Key('0'));
  final Finder end = find.byKey(const Key('400'));
  Finder slideIn(String key) => find.byKey(Key('in-${Key(key)}'));
  Finder slideOut(String key) => find.byKey(Key('out-${Key(key)}'));
  testWidgets(
      'slot layout properly switches between items with the appropriate animation',
      (WidgetTester tester) async {
    await tester.pumpWidget(slot(300));
    expect(begin, findsOneWidget);
    expect(end, findsNothing);

    await tester.pumpWidget(slot(500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<SlideTransition>(slideOut('0')).position.value,
        const Offset(-0.5, 0));
    expect(tester.widget<SlideTransition>(slideIn('400')).position.value,
        const Offset(-0.5, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<SlideTransition>(slideOut('0')).position.value,
        const Offset(-1.0, 0));
    expect(tester.widget<SlideTransition>(slideIn('400')).position.value,
        Offset.zero);

    await tester.pumpAndSettle();
    expect(begin, findsNothing);
    expect(end, findsOneWidget);
  });
  testWidgets('slot layout can tolerate rapid changes in breakpoints',
      (WidgetTester tester) async {
    await tester.pumpWidget(slot(300));
    expect(begin, findsOneWidget);
    expect(end, findsNothing);

    await tester.pumpWidget(slot(500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<SlideTransition>(slideOut('0')).position.value,
        offsetMoreOrLessEquals(const Offset(-0.1, 0), epsilon: 0.05));
    expect(tester.widget<SlideTransition>(slideIn('400')).position.value,
        offsetMoreOrLessEquals(const Offset(-0.9, 0), epsilon: 0.05));
    await tester.pumpWidget(slot(300));
    await tester.pumpAndSettle();
    expect(begin, findsOneWidget);
    expect(end, findsNothing);
  }, skip: true);

  // This test reflects the behavior of the internal animations of both the body
  // and secondary body and also the navigational items. This is reflected in
  // the changes in LTRB offsets from all sides instead of just LR for the body
  // animations.
  testWidgets('adaptive layout handles internal animations correctly',
      (WidgetTester tester) async {
    final Finder b = find.byKey(const Key('b'));
    final Finder sb = find.byKey(const Key('sb'));

    await tester.pumpWidget(await layout(width: 400, tester: tester));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getTopLeft(b), const Offset(1, 1));
    expect(tester.getBottomRight(b),
        offsetMoreOrLessEquals(const Offset(395.8, 799), epsilon: 1.0));
    expect(tester.getTopLeft(sb),
        offsetMoreOrLessEquals(const Offset(395.8, 1.0), epsilon: 1.0));
    expect(tester.getBottomRight(sb),
        offsetMoreOrLessEquals(const Offset(594.8, 799.0), epsilon: 1.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.getTopLeft(b), const Offset(5, 5));
    expect(tester.getBottomRight(b),
        offsetMoreOrLessEquals(const Offset(294.2, 795), epsilon: 1.0));
    expect(tester.getTopLeft(sb),
        offsetMoreOrLessEquals(const Offset(294.2, 5.0), epsilon: 1.0));
    expect(tester.getBottomRight(sb),
        offsetMoreOrLessEquals(const Offset(489.2, 795.0), epsilon: 1.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.getTopLeft(b), const Offset(9, 9));
    expect(tester.getBottomRight(b),
        offsetMoreOrLessEquals(const Offset(201.7, 791), epsilon: 1.0));
    expect(tester.getTopLeft(sb),
        offsetMoreOrLessEquals(const Offset(201.7, 9.0), epsilon: 1.0));
    expect(tester.getBottomRight(sb),
        offsetMoreOrLessEquals(const Offset(392.7, 791), epsilon: 1.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getTopLeft(b), const Offset(10, 10));
    expect(tester.getBottomRight(b), const Offset(200, 790));
    expect(tester.getTopLeft(sb), const Offset(200, 10));
    expect(tester.getBottomRight(sb), const Offset(390, 790));
  }, skip: true);

  testWidgets('adaptive layout does not animate when animations off',
      (WidgetTester tester) async {
    final Finder b = find.byKey(const Key('b'));
    final Finder sb = find.byKey(const Key('sb'));

    await tester.pumpWidget(
        await layout(width: 400, tester: tester, animations: false));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getTopLeft(b), const Offset(10, 10));
    expect(tester.getBottomRight(b), const Offset(200, 790));
    expect(tester.getTopLeft(sb), const Offset(200, 10));
    expect(tester.getBottomRight(sb), const Offset(390, 790));
  }, skip: true);
}
// Some animation related tests are temporarily disabled while waiting for the
// roll to packages to be fixed.
// TODO(serenabehera): remove the skip: true from the tests once they properly
// pass.

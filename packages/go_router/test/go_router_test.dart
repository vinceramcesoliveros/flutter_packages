// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: cascade_invocations, diagnostic_describe_all_properties

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/src/delegate.dart';
import 'package:go_router/src/match.dart';
import 'package:go_router/src/misc/extensions.dart';
import 'package:go_router/src/route.dart';
import 'package:go_router/src/router.dart';
import 'package:go_router/src/state.dart';
import 'package:logging/logging.dart';

import 'test_helpers.dart';

const bool enableLogs = true;
final Logger log = Logger('GoRouter tests');

void main() {
  if (enableLogs) {
    Logger.root.onRecord.listen((LogRecord e) => debugPrint('$e'));
  }

  group('path routes', () {
    testWidgets('match home route', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const HomeScreen()),
      ];

      final GoRouter router = await createRouter(routes, tester);
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.fullpath, '/');
      expect(router.screenFor(matches.first).runtimeType, HomeScreen);
    });

    testWidgets('If there is more than one route to match, use the first match',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(path: '/', builder: dummy),
        GoRoute(path: '/', builder: dummy),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.fullpath, '/');
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
    });

    test('empty path', () {
      expect(() {
        GoRoute(path: '');
      }, throwsA(isAssertionError));
    });

    test('leading / on sub-route', () {
      expect(() {
        GoRoute(
          path: '/',
          builder: dummy,
          routes: <GoRoute>[
            GoRoute(
              path: '/foo',
              builder: dummy,
            ),
          ],
        );
      }, throwsA(isAssertionError));
    });

    test('trailing / on sub-route', () {
      expect(() {
        GoRoute(
          path: '/',
          builder: dummy,
          routes: <GoRoute>[
            GoRoute(
              path: 'foo/',
              builder: dummy,
            ),
          ],
        );
      }, throwsA(isAssertionError));
    });

    testWidgets('lack of leading / on top-level route',
        (WidgetTester tester) async {
      await expectLater(() async {
        final List<GoRoute> routes = <GoRoute>[
          GoRoute(path: 'foo', builder: dummy),
        ];
        await createRouter(routes, tester);
      }, throwsA(isAssertionError));
    });

    testWidgets('match no routes', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(path: '/', builder: dummy),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/foo');
      await tester.pumpAndSettle();
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, TestErrorScreen);
    });

    testWidgets('match 2nd top level route', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const HomeScreen()),
        GoRoute(
            path: '/login',
            builder: (BuildContext context, GoRouterState state) =>
                const LoginScreen()),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/login');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.subloc, '/login');
      expect(router.screenFor(matches.first).runtimeType, LoginScreen);
    });

    testWidgets('match 2nd top level route with subroutes',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
                path: 'page1',
                builder: (BuildContext context, GoRouterState state) =>
                    const Page1Screen())
          ],
        ),
        GoRoute(
            path: '/login',
            builder: (BuildContext context, GoRouterState state) =>
                const LoginScreen()),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/login');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.subloc, '/login');
      expect(router.screenFor(matches.first).runtimeType, LoginScreen);
    });

    testWidgets('match top level route when location has trailing /',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/login/');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.subloc, '/login');
      expect(router.screenFor(matches.first).runtimeType, LoginScreen);
    });

    testWidgets('match top level route when location has trailing / (2)',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
            path: '/profile', builder: dummy, redirect: (_) => '/profile/foo'),
        GoRoute(path: '/profile/:kind', builder: dummy),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/profile/');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.subloc, '/profile/foo');
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
    });

    testWidgets('match top level route when location has trailing / (3)',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
            path: '/profile', builder: dummy, redirect: (_) => '/profile/foo'),
        GoRoute(path: '/profile/:kind', builder: dummy),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/profile/?bar=baz');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.subloc, '/profile/foo');
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
    });

    testWidgets('match sub-route', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/login');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches.length, 2);
      expect(matches.first.subloc, '/');
      expect(router.screenFor(matches.first).runtimeType, HomeScreen);
      expect(matches[1].subloc, '/login');
      expect(router.screenFor(matches[1]).runtimeType, LoginScreen);
    });

    testWidgets('match sub-routes', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'family/:fid',
              builder: (BuildContext context, GoRouterState state) =>
                  const FamilyScreen('dummy'),
              routes: <GoRoute>[
                GoRoute(
                  path: 'person/:pid',
                  builder: (BuildContext context, GoRouterState state) =>
                      const PersonScreen('dummy', 'dummy'),
                ),
              ],
            ),
            GoRoute(
              path: 'login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      {
        final List<RouteMatch> matches = router.routerDelegate.matches.matches;
        expect(matches, hasLength(1));
        expect(matches.first.fullpath, '/');
        expect(router.screenFor(matches.first).runtimeType, HomeScreen);
      }

      router.go('/login');
      {
        final List<RouteMatch> matches = router.routerDelegate.matches.matches;
        expect(matches.length, 2);
        expect(matches.first.subloc, '/');
        expect(router.screenFor(matches.first).runtimeType, HomeScreen);
        expect(matches[1].subloc, '/login');
        expect(router.screenFor(matches[1]).runtimeType, LoginScreen);
      }

      router.go('/family/f2');
      {
        final List<RouteMatch> matches = router.routerDelegate.matches.matches;
        expect(matches.length, 2);
        expect(matches.first.subloc, '/');
        expect(router.screenFor(matches.first).runtimeType, HomeScreen);
        expect(matches[1].subloc, '/family/f2');
        expect(router.screenFor(matches[1]).runtimeType, FamilyScreen);
      }

      router.go('/family/f2/person/p1');
      {
        final List<RouteMatch> matches = router.routerDelegate.matches.matches;
        expect(matches.length, 3);
        expect(matches.first.subloc, '/');
        expect(router.screenFor(matches.first).runtimeType, HomeScreen);
        expect(matches[1].subloc, '/family/f2');
        expect(router.screenFor(matches[1]).runtimeType, FamilyScreen);
        expect(matches[2].subloc, '/family/f2/person/p1');
        expect(router.screenFor(matches[2]).runtimeType, PersonScreen);
      }
    });

    testWidgets('return first matching route if too many subroutes',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'foo/bar',
              builder: (BuildContext context, GoRouterState state) =>
                  const FamilyScreen(''),
            ),
            GoRoute(
              path: 'bar',
              builder: (BuildContext context, GoRouterState state) =>
                  const Page1Screen(),
            ),
            GoRoute(
              path: 'foo',
              builder: (BuildContext context, GoRouterState state) =>
                  const Page2Screen(),
              routes: <GoRoute>[
                GoRoute(
                  path: 'bar',
                  builder: (BuildContext context, GoRouterState state) =>
                      const LoginScreen(),
                ),
              ],
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/bar');
      List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(2));
      expect(router.screenFor(matches[1]).runtimeType, Page1Screen);

      router.go('/foo/bar');
      matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(2));
      expect(router.screenFor(matches[1]).runtimeType, FamilyScreen);

      router.go('/foo');
      matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(2));
      expect(router.screenFor(matches[1]).runtimeType, Page2Screen);
    });

    testWidgets('router state', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            expect(state.location, '/');
            expect(state.subloc, '/');
            expect(state.name, 'home');
            expect(state.path, '/');
            expect(state.fullpath, '/');
            expect(state.params, <String, String>{});
            expect(state.error, null);
            if (state.extra != null) {
              expect(state.extra! as int, 1);
            }
            return const HomeScreen();
          },
          routes: <GoRoute>[
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (BuildContext context, GoRouterState state) {
                expect(state.location, '/login');
                expect(state.subloc, '/login');
                expect(state.name, 'login');
                expect(state.path, 'login');
                expect(state.fullpath, '/login');
                expect(state.params, <String, String>{});
                expect(state.error, null);
                expect(state.extra! as int, 2);
                return const LoginScreen();
              },
            ),
            GoRoute(
              name: 'family',
              path: 'family/:fid',
              builder: (BuildContext context, GoRouterState state) {
                expect(
                  state.location,
                  anyOf(<String>['/family/f2', '/family/f2/person/p1']),
                );
                expect(state.subloc, '/family/f2');
                expect(state.name, 'family');
                expect(state.path, 'family/:fid');
                expect(state.fullpath, '/family/:fid');
                expect(state.params, <String, String>{'fid': 'f2'});
                expect(state.error, null);
                expect(state.extra! as int, 3);
                return FamilyScreen(state.params['fid']!);
              },
              routes: <GoRoute>[
                GoRoute(
                  name: 'person',
                  path: 'person/:pid',
                  builder: (BuildContext context, GoRouterState state) {
                    expect(state.location, '/family/f2/person/p1');
                    expect(state.subloc, '/family/f2/person/p1');
                    expect(state.name, 'person');
                    expect(state.path, 'person/:pid');
                    expect(state.fullpath, '/family/:fid/person/:pid');
                    expect(
                      state.params,
                      <String, String>{'fid': 'f2', 'pid': 'p1'},
                    );
                    expect(state.error, null);
                    expect(state.extra! as int, 4);
                    return PersonScreen(
                        state.params['fid']!, state.params['pid']!);
                  },
                ),
              ],
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/', extra: 1);
      await tester.pump();
      router.push('/login', extra: 2);
      await tester.pump();
      router.push('/family/f2', extra: 3);
      await tester.pump();
      router.push('/family/f2/person/p1', extra: 4);
      await tester.pump();
    });

    testWidgets('match path case insensitively', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/family/:fid',
          builder: (BuildContext context, GoRouterState state) =>
              FamilyScreen(state.params['fid']!),
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      const String loc = '/FaMiLy/f2';
      router.go(loc);
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;

      // NOTE: match the lower case, since subloc is canonicalized to match the
      // path case whereas the location can be any case; so long as the path
      // produces a match regardless of the location case, we win!
      expect(router.location.toLowerCase(), loc.toLowerCase());

      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, FamilyScreen);
    });

    testWidgets(
        'If there is more than one route to match, use the first match.',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(path: '/', builder: dummy),
        GoRoute(path: '/page1', builder: dummy),
        GoRoute(path: '/page1', builder: dummy),
        GoRoute(path: '/:ok', builder: dummy),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/user');
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
    });

    testWidgets('Handles the Android back button correctly',
        (WidgetTester tester) async {
      final List<RouteBase> routes = <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(
              body: Text('Screen A'),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'b',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: Text('Screen B'),
                );
              },
            ),
          ],
        ),
      ];

      await createRouter(routes, tester, initialLocation: '/b');
      expect(find.text('Screen A'), findsNothing);
      expect(find.text('Screen B'), findsOneWidget);

      await simulateAndroidBackButton();
      await tester.pumpAndSettle();
      expect(find.text('Screen A'), findsOneWidget);
      expect(find.text('Screen B'), findsNothing);
    });

    testWidgets('Handles the Android back button correctly with ShellRoute',
        (WidgetTester tester) async {
      final GlobalKey<NavigatorState> rootNavigatorKey =
          GlobalKey<NavigatorState>();

      final List<RouteBase> routes = <RouteBase>[
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return Scaffold(
              appBar: AppBar(title: const Text('Shell')),
              body: child,
            );
          },
          routes: <GoRoute>[
            GoRoute(
              path: '/a',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: Text('Screen A'),
                );
              },
              routes: <GoRoute>[
                GoRoute(
                  path: 'b',
                  builder: (BuildContext context, GoRouterState state) {
                    return const Scaffold(
                      body: Text('Screen B'),
                    );
                  },
                  routes: <GoRoute>[
                    GoRoute(
                      path: 'c',
                      builder: (BuildContext context, GoRouterState state) {
                        return const Scaffold(
                          body: Text('Screen C'),
                        );
                      },
                      routes: <GoRoute>[
                        GoRoute(
                          path: 'd',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (BuildContext context, GoRouterState state) {
                            return const Scaffold(
                              body: Text('Screen D'),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];

      await createRouter(routes, tester,
          initialLocation: '/a/b/c/d', navigatorKey: rootNavigatorKey);
      expect(find.text('Shell'), findsNothing);
      expect(find.text('Screen A'), findsNothing);
      expect(find.text('Screen B'), findsNothing);
      expect(find.text('Screen C'), findsNothing);
      expect(find.text('Screen D'), findsOneWidget);

      await simulateAndroidBackButton();
      await tester.pumpAndSettle();
      expect(find.text('Shell'), findsOneWidget);
      expect(find.text('Screen A'), findsNothing);
      expect(find.text('Screen B'), findsNothing);
      expect(find.text('Screen C'), findsOneWidget);
      expect(find.text('Screen D'), findsNothing);

      await simulateAndroidBackButton();
      await tester.pumpAndSettle();
      expect(find.text('Shell'), findsOneWidget);
      expect(find.text('Screen A'), findsNothing);
      expect(find.text('Screen B'), findsOneWidget);
      expect(find.text('Screen C'), findsNothing);
    });
  });

  group('named routes', () {
    testWidgets('match home route', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
            name: 'home',
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const HomeScreen()),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.goNamed('home');
    });

    testWidgets('match too many routes', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(name: 'home', path: '/', builder: dummy),
        GoRoute(name: 'home', path: '/', builder: dummy),
      ];

      await expectLater(() async {
        await createRouter(routes, tester);
      }, throwsA(isAssertionError));
    });

    test('empty name', () {
      expect(() {
        GoRoute(name: '', path: '/');
      }, throwsA(isAssertionError));
    });

    testWidgets('match no routes', (WidgetTester tester) async {
      await expectLater(() async {
        final List<GoRoute> routes = <GoRoute>[
          GoRoute(name: 'home', path: '/', builder: dummy),
        ];
        final GoRouter router = await createRouter(routes, tester);
        router.goNamed('work');
      }, throwsA(isAssertionError));
    });

    testWidgets('match 2nd top level route', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.goNamed('login');
    });

    testWidgets('match sub-route', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.goNamed('login');
    });

    testWidgets('match w/ params', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              name: 'family',
              path: 'family/:fid',
              builder: (BuildContext context, GoRouterState state) =>
                  const FamilyScreen('dummy'),
              routes: <GoRoute>[
                GoRoute(
                  name: 'person',
                  path: 'person/:pid',
                  builder: (BuildContext context, GoRouterState state) {
                    expect(state.params,
                        <String, String>{'fid': 'f2', 'pid': 'p1'});
                    return const PersonScreen('dummy', 'dummy');
                  },
                ),
              ],
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.goNamed('person',
          params: <String, String>{'fid': 'f2', 'pid': 'p1'});
    });

    testWidgets('too few params', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              name: 'family',
              path: 'family/:fid',
              builder: (BuildContext context, GoRouterState state) =>
                  const FamilyScreen('dummy'),
              routes: <GoRoute>[
                GoRoute(
                  name: 'person',
                  path: 'person/:pid',
                  builder: (BuildContext context, GoRouterState state) =>
                      const PersonScreen('dummy', 'dummy'),
                ),
              ],
            ),
          ],
        ),
      ];
      await expectLater(() async {
        final GoRouter router = await createRouter(routes, tester);
        router.goNamed('person', params: <String, String>{'fid': 'f2'});
        await tester.pump();
      }, throwsA(isAssertionError));
    });

    testWidgets('match case insensitive w/ params',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              name: 'family',
              path: 'family/:fid',
              builder: (BuildContext context, GoRouterState state) =>
                  const FamilyScreen('dummy'),
              routes: <GoRoute>[
                GoRoute(
                  name: 'PeRsOn',
                  path: 'person/:pid',
                  builder: (BuildContext context, GoRouterState state) {
                    expect(state.params,
                        <String, String>{'fid': 'f2', 'pid': 'p1'});
                    return const PersonScreen('dummy', 'dummy');
                  },
                ),
              ],
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.goNamed('person',
          params: <String, String>{'fid': 'f2', 'pid': 'p1'});
    });

    testWidgets('too few params', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'family',
          path: '/family/:fid',
          builder: (BuildContext context, GoRouterState state) =>
              const FamilyScreen('dummy'),
        ),
      ];
      await expectLater(() async {
        final GoRouter router = await createRouter(routes, tester);
        router.goNamed('family');
      }, throwsA(isAssertionError));
    });

    testWidgets('too many params', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'family',
          path: '/family/:fid',
          builder: (BuildContext context, GoRouterState state) =>
              const FamilyScreen('dummy'),
        ),
      ];
      await expectLater(() async {
        final GoRouter router = await createRouter(routes, tester);
        router.goNamed('family',
            params: <String, String>{'fid': 'f2', 'pid': 'p1'});
      }, throwsA(isAssertionError));
    });

    testWidgets('sparsely named routes', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: dummy,
          redirect: (_) => '/family/f2',
        ),
        GoRoute(
          path: '/family/:fid',
          builder: (BuildContext context, GoRouterState state) => FamilyScreen(
            state.params['fid']!,
          ),
          routes: <GoRoute>[
            GoRoute(
              name: 'person',
              path: 'person:pid',
              builder: (BuildContext context, GoRouterState state) =>
                  PersonScreen(
                state.params['fid']!,
                state.params['pid']!,
              ),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.goNamed('person',
          params: <String, String>{'fid': 'f2', 'pid': 'p1'});

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(router.screenFor(matches.last).runtimeType, PersonScreen);
    });

    testWidgets('preserve path param spaces and slashes',
        (WidgetTester tester) async {
      const String param1 = 'param w/ spaces and slashes';
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'page1',
          path: '/page1/:param1',
          builder: (BuildContext c, GoRouterState s) {
            expect(s.params['param1'], param1);
            return const DummyScreen();
          },
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      final String loc = router
          .namedLocation('page1', params: <String, String>{'param1': param1});
      log.info('loc= $loc');
      router.go(loc);

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      log.info('param1= ${matches.first.decodedParams['param1']}');
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
      expect(matches.first.decodedParams['param1'], param1);
    });

    testWidgets('preserve query param spaces and slashes',
        (WidgetTester tester) async {
      const String param1 = 'param w/ spaces and slashes';
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'page1',
          path: '/page1',
          builder: (BuildContext c, GoRouterState s) {
            expect(s.queryParams['param1'], param1);
            return const DummyScreen();
          },
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      final String loc = router.namedLocation('page1',
          queryParams: <String, String>{'param1': param1});
      router.go(loc);
      await tester.pump();
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
      expect(matches.first.queryParams['param1'], param1);
    });
  });

  group('redirects', () {
    testWidgets('top-level redirect', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
                path: 'dummy',
                builder: (BuildContext context, GoRouterState state) =>
                    const DummyScreen()),
            GoRoute(
                path: 'login',
                builder: (BuildContext context, GoRouterState state) =>
                    const LoginScreen()),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester,
          redirect: (GoRouterState state) =>
              state.subloc == '/login' ? null : '/login');

      expect(router.location, '/login');
    });

    testWidgets('top-level redirect w/ named routes',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              name: 'dummy',
              path: 'dummy',
              builder: (BuildContext context, GoRouterState state) =>
                  const DummyScreen(),
            ),
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        redirect: (GoRouterState state) =>
            state.subloc == '/login' ? null : state.namedLocation('login'),
      );
      expect(router.location, '/login');
    });

    testWidgets('route-level redirect', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'dummy',
              builder: (BuildContext context, GoRouterState state) =>
                  const DummyScreen(),
              redirect: (GoRouterState state) => '/login',
            ),
            GoRoute(
              path: 'login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/dummy');
      await tester.pump();
      expect(router.location, '/login');
    });

    testWidgets('route-level redirect w/ named routes',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              name: 'dummy',
              path: 'dummy',
              builder: (BuildContext context, GoRouterState state) =>
                  const DummyScreen(),
              redirect: (GoRouterState state) => state.namedLocation('login'),
            ),
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/dummy');
      await tester.pump();
      expect(router.location, '/login');
    });

    testWidgets('multiple mixed redirect', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'dummy1',
              builder: (BuildContext context, GoRouterState state) =>
                  const DummyScreen(),
            ),
            GoRoute(
              path: 'dummy2',
              builder: (BuildContext context, GoRouterState state) =>
                  const DummyScreen(),
              redirect: (GoRouterState state) => '/',
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester,
          redirect: (GoRouterState state) =>
              state.subloc == '/dummy1' ? '/dummy2' : null);
      router.go('/dummy1');
      await tester.pump();
      expect(router.location, '/');
    });

    testWidgets('top-level redirect loop', (WidgetTester tester) async {
      final GoRouter router = await createRouter(<GoRoute>[], tester,
          redirect: (GoRouterState state) => state.subloc == '/'
              ? '/login'
              : state.subloc == '/login'
                  ? '/'
                  : null);

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, TestErrorScreen);
      expect(
          (router.screenFor(matches.first) as TestErrorScreen).ex, isNotNull);
      log.info((router.screenFor(matches.first) as TestErrorScreen).ex);
    });

    testWidgets('route-level redirect loop', (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[
          GoRoute(
            path: '/',
            builder: dummy,
            redirect: (GoRouterState state) => '/login',
          ),
          GoRoute(
            path: '/login',
            builder: dummy,
            redirect: (GoRouterState state) => '/',
          ),
        ],
        tester,
      );

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, TestErrorScreen);
      expect(
          (router.screenFor(matches.first) as TestErrorScreen).ex, isNotNull);
      log.info((router.screenFor(matches.first) as TestErrorScreen).ex);
    });

    testWidgets('mixed redirect loop', (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[
          GoRoute(
            path: '/login',
            builder: dummy,
            redirect: (GoRouterState state) => '/',
          ),
        ],
        tester,
        redirect: (GoRouterState state) =>
            state.subloc == '/' ? '/login' : null,
      );

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, TestErrorScreen);
      expect(
          (router.screenFor(matches.first) as TestErrorScreen).ex, isNotNull);
      log.info((router.screenFor(matches.first) as TestErrorScreen).ex);
    });

    testWidgets('top-level redirect loop w/ query params',
        (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[],
        tester,
        redirect: (GoRouterState state) => state.subloc == '/'
            ? '/login?from=${state.location}'
            : state.subloc == '/login'
                ? '/'
                : null,
      );

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, TestErrorScreen);
      expect(
          (router.screenFor(matches.first) as TestErrorScreen).ex, isNotNull);
      log.info((router.screenFor(matches.first) as TestErrorScreen).ex);
    });

    testWidgets('expect null path/fullpath on top-level redirect',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/dummy',
          builder: dummy,
          redirect: (GoRouterState state) => '/',
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        initialLocation: '/dummy',
      );
      expect(router.location, '/');
    });

    testWidgets('top-level redirect state', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        initialLocation: '/login?from=/',
        redirect: (GoRouterState state) {
          expect(Uri.parse(state.location).queryParameters, isNotEmpty);
          expect(Uri.parse(state.subloc).queryParameters, isEmpty);
          expect(state.path, isNull);
          expect(state.fullpath, isNull);
          expect(state.params.length, 0);
          expect(state.queryParams.length, 1);
          expect(state.queryParams['from'], '/');
          return null;
        },
      );

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, LoginScreen);
    });

    testWidgets('route-level redirect state', (WidgetTester tester) async {
      const String loc = '/book/0';
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/book/:bookId',
          redirect: (GoRouterState state) {
            expect(state.location, loc);
            expect(state.subloc, loc);
            expect(state.path, '/book/:bookId');
            expect(state.fullpath, '/book/:bookId');
            expect(state.params, <String, String>{'bookId': '0'});
            expect(state.queryParams.length, 0);
            return null;
          },
          builder: (BuildContext c, GoRouterState s) => const HomeScreen(),
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        initialLocation: loc,
      );

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, HomeScreen);
    });

    testWidgets('sub-sub-route-level redirect params',
        (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext c, GoRouterState s) => const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'family/:fid',
              builder: (BuildContext c, GoRouterState s) =>
                  FamilyScreen(s.params['fid']!),
              routes: <GoRoute>[
                GoRoute(
                  path: 'person/:pid',
                  redirect: (GoRouterState s) {
                    expect(s.params['fid'], 'f2');
                    expect(s.params['pid'], 'p1');
                    return null;
                  },
                  builder: (BuildContext c, GoRouterState s) => PersonScreen(
                    s.params['fid']!,
                    s.params['pid']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        initialLocation: '/family/f2/person/p1',
      );

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches.length, 3);
      expect(router.screenFor(matches.first).runtimeType, HomeScreen);
      expect(router.screenFor(matches[1]).runtimeType, FamilyScreen);
      final PersonScreen page = router.screenFor(matches[2]) as PersonScreen;
      expect(page.fid, 'f2');
      expect(page.pid, 'p1');
    });

    testWidgets('redirect limit', (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[],
        tester,
        redirect: (GoRouterState state) => '/${state.location}+',
        redirectLimit: 10,
      );

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(router.screenFor(matches.first).runtimeType, TestErrorScreen);
      expect(
          (router.screenFor(matches.first) as TestErrorScreen).ex, isNotNull);
      log.info((router.screenFor(matches.first) as TestErrorScreen).ex);
    });

    testWidgets('extra not null in redirect', (WidgetTester tester) async {
      bool isCallTopRedirect = false;
      bool isCallRouteRedirect = false;

      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (BuildContext context, GoRouterState state) {
                return const LoginScreen();
              },
              redirect: (GoRouterState state) {
                isCallRouteRedirect = true;
                expect(state.extra, isNotNull);
                return null;
              },
              routes: const <GoRoute>[],
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        redirect: (GoRouterState state) {
          if (state.location == '/login') {
            isCallTopRedirect = true;
            expect(state.extra, isNotNull);
          }

          return null;
        },
      );

      router.go('/login', extra: 1);
      await tester.pump();

      expect(isCallTopRedirect, true);
      expect(isCallRouteRedirect, true);
    });
  });

  group('initial location', () {
    testWidgets('initial location', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'dummy',
              builder: (BuildContext context, GoRouterState state) =>
                  const DummyScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        initialLocation: '/dummy',
      );
      expect(router.location, '/dummy');
    });

    testWidgets('initial location w/ redirection', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/dummy',
          builder: dummy,
          redirect: (GoRouterState state) => '/',
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
        initialLocation: '/dummy',
      );
      expect(router.location, '/');
    });

    testWidgets(
        'does not take precedence over platformDispatcher.defaultRouteName',
        (WidgetTester tester) async {
      TestWidgetsFlutterBinding
          .instance.platformDispatcher.defaultRouteNameTestValue = '/dummy';

      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <GoRoute>[
            GoRoute(
              path: 'dummy',
              builder: (BuildContext context, GoRouterState state) =>
                  const DummyScreen(),
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(
        routes,
        tester,
      );
      expect(router.routeInformationProvider.value.location, '/dummy');
      TestWidgetsFlutterBinding
          .instance.platformDispatcher.defaultRouteNameTestValue = '/';
    });
  });

  group('params', () {
    testWidgets('preserve path param case', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/family/:fid',
          builder: (BuildContext context, GoRouterState state) =>
              FamilyScreen(state.params['fid']!),
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      for (final String fid in <String>['f2', 'F2']) {
        final String loc = '/family/$fid';
        router.go(loc);
        final List<RouteMatch> matches = router.routerDelegate.matches.matches;

        expect(router.location, loc);
        expect(matches, hasLength(1));
        expect(router.screenFor(matches.first).runtimeType, FamilyScreen);
        expect(matches.first.decodedParams['fid'], fid);
      }
    });

    testWidgets('preserve query param case', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/family',
          builder: (BuildContext context, GoRouterState state) => FamilyScreen(
            state.queryParams['fid']!,
          ),
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      for (final String fid in <String>['f2', 'F2']) {
        final String loc = '/family?fid=$fid';
        router.go(loc);
        final List<RouteMatch> matches = router.routerDelegate.matches.matches;

        expect(router.location, loc);
        expect(matches, hasLength(1));
        expect(router.screenFor(matches.first).runtimeType, FamilyScreen);
        expect(matches.first.queryParams['fid'], fid);
      }
    });

    testWidgets('preserve path param spaces and slashes',
        (WidgetTester tester) async {
      const String param1 = 'param w/ spaces and slashes';
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/page1/:param1',
          builder: (BuildContext c, GoRouterState s) {
            expect(s.params['param1'], param1);
            return const DummyScreen();
          },
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      final String loc = '/page1/${Uri.encodeComponent(param1)}';
      router.go(loc);

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      log.info('param1= ${matches.first.decodedParams['param1']}');
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
      expect(matches.first.decodedParams['param1'], param1);
    });

    testWidgets('preserve query param spaces and slashes',
        (WidgetTester tester) async {
      const String param1 = 'param w/ spaces and slashes';
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/page1',
          builder: (BuildContext c, GoRouterState s) {
            expect(s.queryParams['param1'], param1);
            return const DummyScreen();
          },
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      router.go('/page1?param1=$param1');

      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(router.screenFor(matches.first).runtimeType, DummyScreen);
      expect(matches.first.queryParams['param1'], param1);

      final String loc = '/page1?param1=${Uri.encodeQueryComponent(param1)}';
      router.go(loc);

      final List<RouteMatch> matches2 = router.routerDelegate.matches.matches;
      expect(router.screenFor(matches2[0]).runtimeType, DummyScreen);
      expect(matches2[0].queryParams['param1'], param1);
    });

    test('error: duplicate path param', () {
      try {
        GoRouter(
          routes: <GoRoute>[
            GoRoute(
              path: '/:id/:blah/:bam/:id/:blah',
              builder: dummy,
            ),
          ],
          errorBuilder: (BuildContext context, GoRouterState state) =>
              TestErrorScreen(state.error!),
          initialLocation: '/0/1/2/0/1',
        );
        expect(false, true);
      } on Exception catch (ex) {
        log.info(ex);
      }
    });

    testWidgets('duplicate query param', (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              log.info('id= ${state.params['id']}');
              expect(state.params.length, 0);
              expect(state.queryParams.length, 1);
              expect(state.queryParams['id'], anyOf('0', '1'));
              return const HomeScreen();
            },
          ),
        ],
        tester,
        initialLocation: '/?id=0&id=1',
      );
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.fullpath, '/');
      expect(router.screenFor(matches.first).runtimeType, HomeScreen);
    });

    testWidgets('duplicate path + query param', (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[
          GoRoute(
            path: '/:id',
            builder: (BuildContext context, GoRouterState state) {
              expect(state.params, <String, String>{'id': '0'});
              expect(state.queryParams, <String, String>{'id': '1'});
              return const HomeScreen();
            },
          ),
        ],
        tester,
      );

      router.go('/0?id=1');
      await tester.pump();
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;
      expect(matches, hasLength(1));
      expect(matches.first.fullpath, '/:id');
      expect(router.screenFor(matches.first).runtimeType, HomeScreen);
    });

    testWidgets('push + query param', (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[
          GoRoute(path: '/', builder: dummy),
          GoRoute(
            path: '/family',
            builder: (BuildContext context, GoRouterState state) =>
                FamilyScreen(
              state.queryParams['fid']!,
            ),
          ),
          GoRoute(
            path: '/person',
            builder: (BuildContext context, GoRouterState state) =>
                PersonScreen(
              state.queryParams['fid']!,
              state.queryParams['pid']!,
            ),
          ),
        ],
        tester,
      );

      router.go('/family?fid=f2');
      await tester.pump();
      router.push('/person?fid=f2&pid=p1');
      await tester.pump();
      final FamilyScreen page1 =
          router.screenFor(router.routerDelegate.matches.matches.first)
              as FamilyScreen;
      expect(page1.fid, 'f2');

      final PersonScreen page2 = router
          .screenFor(router.routerDelegate.matches.matches[1]) as PersonScreen;
      expect(page2.fid, 'f2');
      expect(page2.pid, 'p1');
    });

    testWidgets('push + extra param', (WidgetTester tester) async {
      final GoRouter router = await createRouter(
        <GoRoute>[
          GoRoute(path: '/', builder: dummy),
          GoRoute(
            path: '/family',
            builder: (BuildContext context, GoRouterState state) =>
                FamilyScreen(
              (state.extra! as Map<String, String>)['fid']!,
            ),
          ),
          GoRoute(
            path: '/person',
            builder: (BuildContext context, GoRouterState state) =>
                PersonScreen(
              (state.extra! as Map<String, String>)['fid']!,
              (state.extra! as Map<String, String>)['pid']!,
            ),
          ),
        ],
        tester,
      );

      router.go('/family', extra: <String, String>{'fid': 'f2'});
      await tester.pump();
      router.push('/person', extra: <String, String>{'fid': 'f2', 'pid': 'p1'});
      await tester.pump();
      final FamilyScreen page1 =
          router.screenFor(router.routerDelegate.matches.matches.first)
              as FamilyScreen;
      expect(page1.fid, 'f2');

      final PersonScreen page2 = router
          .screenFor(router.routerDelegate.matches.matches[1]) as PersonScreen;
      expect(page2.fid, 'f2');
      expect(page2.pid, 'p1');
    });

    testWidgets('keep param in nested route', (WidgetTester tester) async {
      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          path: '/family/:fid',
          builder: (BuildContext context, GoRouterState state) =>
              FamilyScreen(state.params['fid']!),
          routes: <GoRoute>[
            GoRoute(
              path: 'person/:pid',
              builder: (BuildContext context, GoRouterState state) {
                final String fid = state.params['fid']!;
                final String pid = state.params['pid']!;

                return PersonScreen(fid, pid);
              },
            ),
          ],
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);
      const String fid = 'f1';
      const String pid = 'p2';
      const String loc = '/family/$fid/person/$pid';

      router.push(loc);
      await tester.pump();
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;

      expect(router.location, loc);
      expect(matches, hasLength(2));
      expect(router.screenFor(matches.last).runtimeType, PersonScreen);
      expect(matches.last.decodedParams['fid'], fid);
      expect(matches.last.decodedParams['pid'], pid);
    });

    testWidgets('goNames should allow dynamics values for queryParams',
        (WidgetTester tester) async {
      const Map<String, dynamic> queryParametersAll = <String, List<dynamic>>{
        'q1': <String>['v1'],
        'q2': <String>['v2', 'v3'],
      };
      void expectLocationWithQueryParams(String location) {
        final Uri uri = Uri.parse(location);
        expect(uri.path, '/page');
        expect(uri.queryParametersAll, queryParametersAll);
      }

      final List<GoRoute> routes = <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
        GoRoute(
          name: 'page',
          path: '/page',
          builder: (BuildContext context, GoRouterState state) {
            expect(state.queryParametersAll, queryParametersAll);
            expectLocationWithQueryParams(state.location);
            return DummyScreen(
              queryParametersAll: state.queryParametersAll,
            );
          },
        ),
      ];

      final GoRouter router = await createRouter(routes, tester);

      router.goNamed('page', queryParams: const <String, dynamic>{
        'q1': 'v1',
        'q2': <String>['v2', 'v3'],
      });
      await tester.pump();
      final List<RouteMatch> matches = router.routerDelegate.matches.matches;

      expect(matches, hasLength(1));
      expectLocationWithQueryParams(router.location);
      expect(
        router.screenFor(matches.last),
        isA<DummyScreen>().having(
          (DummyScreen screen) => screen.queryParametersAll,
          'screen.queryParametersAll',
          queryParametersAll,
        ),
      );
    });
  });

  testWidgets('go should preserve the query parameters when navigating',
      (WidgetTester tester) async {
    const Map<String, dynamic> queryParametersAll = <String, List<dynamic>>{
      'q1': <String>['v1'],
      'q2': <String>['v2', 'v3'],
    };
    void expectLocationWithQueryParams(String location) {
      final Uri uri = Uri.parse(location);
      expect(uri.path, '/page');
      expect(uri.queryParametersAll, queryParametersAll);
    }

    final List<GoRoute> routes = <GoRoute>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        name: 'page',
        path: '/page',
        builder: (BuildContext context, GoRouterState state) {
          expect(state.queryParametersAll, queryParametersAll);
          expectLocationWithQueryParams(state.location);
          return DummyScreen(
            queryParametersAll: state.queryParametersAll,
          );
        },
      ),
    ];

    final GoRouter router = await createRouter(routes, tester);

    router.go('/page?q1=v1&q2=v2&q2=v3');
    await tester.pump();
    final List<RouteMatch> matches = router.routerDelegate.matches.matches;

    expect(matches, hasLength(1));
    expectLocationWithQueryParams(router.location);
    expect(
      router.screenFor(matches.last),
      isA<DummyScreen>().having(
        (DummyScreen screen) => screen.queryParametersAll,
        'screen.queryParametersAll',
        queryParametersAll,
      ),
    );
  });

  group('refresh listenable', () {
    late StreamController<int> streamController;

    setUpAll(() async {
      streamController = StreamController<int>.broadcast();
      await streamController.addStream(Stream<int>.value(0));
    });

    tearDownAll(() {
      streamController.close();
    });

    group('stream', () {
      test('no stream emits', () async {
        // Act
        final GoRouterRefreshStreamSpy notifyListener =
            GoRouterRefreshStreamSpy(
          streamController.stream,
        );

        // Assert
        expect(notifyListener.notifyCount, equals(1));

        // Cleanup
        notifyListener.dispose();
      });

      test('three stream emits', () async {
        // Arrange
        final List<int> toEmit = <int>[1, 2, 3];

        // Act
        final GoRouterRefreshStreamSpy notifyListener =
            GoRouterRefreshStreamSpy(
          streamController.stream,
        );

        await streamController.addStream(Stream<int>.fromIterable(toEmit));

        // Assert
        expect(notifyListener.notifyCount, equals(toEmit.length + 1));

        // Cleanup
        notifyListener.dispose();
      });
    });
  });

  group('GoRouterHelper extensions', () {
    final GlobalKey<DummyStatefulWidgetState> key =
        GlobalKey<DummyStatefulWidgetState>();
    final List<GoRoute> routes = <GoRoute>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            DummyStatefulWidget(key: key),
      ),
      GoRoute(
        path: '/page1',
        name: 'page1',
        builder: (BuildContext context, GoRouterState state) =>
            const Page1Screen(),
      ),
    ];

    const String name = 'page1';
    final Map<String, String> params = <String, String>{
      'a-param-key': 'a-param-value',
    };
    final Map<String, String> queryParams = <String, String>{
      'a-query-key': 'a-query-value',
    };
    const String location = '/page1';
    const String extra = 'Hello';

    testWidgets('calls [namedLocation] on closest GoRouter',
        (WidgetTester tester) async {
      final GoRouterNamedLocationSpy router =
          GoRouterNamedLocationSpy(routes: routes);
      await tester.pumpWidget(
        MaterialApp.router(
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          title: 'GoRouter Example',
        ),
      );
      key.currentContext!.namedLocation(
        name,
        params: params,
        queryParams: queryParams,
      );
      expect(router.name, name);
      expect(router.params, params);
      expect(router.queryParams, queryParams);
    });

    testWidgets('calls [go] on closest GoRouter', (WidgetTester tester) async {
      final GoRouterGoSpy router = GoRouterGoSpy(routes: routes);
      await tester.pumpWidget(
        MaterialApp.router(
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          title: 'GoRouter Example',
        ),
      );
      key.currentContext!.go(
        location,
        extra: extra,
      );
      expect(router.myLocation, location);
      expect(router.extra, extra);
    });

    testWidgets('calls [goNamed] on closest GoRouter',
        (WidgetTester tester) async {
      final GoRouterGoNamedSpy router = GoRouterGoNamedSpy(routes: routes);
      await tester.pumpWidget(
        MaterialApp.router(
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          title: 'GoRouter Example',
        ),
      );
      key.currentContext!.goNamed(
        name,
        params: params,
        queryParams: queryParams,
        extra: extra,
      );
      expect(router.name, name);
      expect(router.params, params);
      expect(router.queryParams, queryParams);
      expect(router.extra, extra);
    });

    testWidgets('calls [push] on closest GoRouter',
        (WidgetTester tester) async {
      final GoRouterPushSpy router = GoRouterPushSpy(routes: routes);
      await tester.pumpWidget(
        MaterialApp.router(
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          title: 'GoRouter Example',
        ),
      );
      key.currentContext!.push(
        location,
        extra: extra,
      );
      expect(router.myLocation, location);
      expect(router.extra, extra);
    });

    testWidgets('calls [pushNamed] on closest GoRouter',
        (WidgetTester tester) async {
      final GoRouterPushNamedSpy router = GoRouterPushNamedSpy(routes: routes);
      await tester.pumpWidget(
        MaterialApp.router(
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          title: 'GoRouter Example',
        ),
      );
      key.currentContext!.pushNamed(
        name,
        params: params,
        queryParams: queryParams,
        extra: extra,
      );
      expect(router.name, name);
      expect(router.params, params);
      expect(router.queryParams, queryParams);
      expect(router.extra, extra);
    });

    testWidgets('calls [pop] on closest GoRouter', (WidgetTester tester) async {
      final GoRouterPopSpy router = GoRouterPopSpy(routes: routes);
      await tester.pumpWidget(
        MaterialApp.router(
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          title: 'GoRouter Example',
        ),
      );
      key.currentContext!.pop();
      expect(router.popped, true);
    });
  });

  group('ShellRoute', () {
    testWidgets('defaultRoute', (WidgetTester tester) async {
      final List<RouteBase> routes = <RouteBase>[
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return Scaffold(
              body: child,
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/a',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: Text('Screen A'),
                );
              },
            ),
            GoRoute(
              path: '/b',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: Text('Screen B'),
                );
              },
            ),
          ],
        ),
      ];

      await createRouter(routes, tester, initialLocation: '/b');
      expect(find.text('Screen B'), findsOneWidget);
    });

    testWidgets(
        'Pops from the correct Navigator when the Android back button is pressed',
        (WidgetTester tester) async {
      final List<RouteBase> routes = <RouteBase>[
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return Scaffold(
              body: Column(
                children: <Widget>[
                  const Text('Screen A'),
                  Expanded(child: child),
                ],
              ),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/b',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: Text('Screen B'),
                );
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'c',
                  builder: (BuildContext context, GoRouterState state) {
                    return const Scaffold(
                      body: Text('Screen C'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ];

      await createRouter(routes, tester, initialLocation: '/b/c');
      expect(find.text('Screen A'), findsOneWidget);
      expect(find.text('Screen B'), findsNothing);
      expect(find.text('Screen C'), findsOneWidget);

      await simulateAndroidBackButton();
      await tester.pumpAndSettle();

      expect(find.text('Screen A'), findsOneWidget);
      expect(find.text('Screen B'), findsOneWidget);
      expect(find.text('Screen C'), findsNothing);
    });

    testWidgets(
        'Pops from the correct navigator when a sub-route is placed on '
        'the root Navigator', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> rootNavigatorKey =
          GlobalKey<NavigatorState>();
      final GlobalKey<NavigatorState> shellNavigatorKey =
          GlobalKey<NavigatorState>();

      final List<RouteBase> routes = <RouteBase>[
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return Scaffold(
              body: Column(
                children: <Widget>[
                  const Text('Screen A'),
                  Expanded(child: child),
                ],
              ),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/b',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: Text('Screen B'),
                );
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'c',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (BuildContext context, GoRouterState state) {
                    return const Scaffold(
                      body: Text('Screen C'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ];

      await createRouter(routes, tester,
          initialLocation: '/b/c', navigatorKey: rootNavigatorKey);
      expect(find.text('Screen A'), findsNothing);
      expect(find.text('Screen B'), findsNothing);
      expect(find.text('Screen C'), findsOneWidget);

      await simulateAndroidBackButton();
      await tester.pumpAndSettle();

      expect(find.text('Screen A'), findsOneWidget);
      expect(find.text('Screen B'), findsOneWidget);
      expect(find.text('Screen C'), findsNothing);
    });
  });

  group('Imperative navigation', () {
    testWidgets('pop triggers pop on routerDelegate',
        (WidgetTester tester) async {
      final GoRouter router = await createGoRouter(tester)
        ..push('/error');
      router.routerDelegate.addListener(expectAsync0(() {}));
      router.pop();
      await tester.pump();
    });

    testWidgets('didPush notifies listeners', (WidgetTester tester) async {
      await createGoRouter(tester)
        ..addListener(expectAsync0(() {}))
        ..didPush(
          MaterialPageRoute<void>(builder: (_) => const Text('Current route')),
          MaterialPageRoute<void>(builder: (_) => const Text('Previous route')),
        );
    });

    testWidgets('didPop notifies listeners', (WidgetTester tester) async {
      await createGoRouter(tester)
        ..addListener(expectAsync0(() {}))
        ..didPop(
          MaterialPageRoute<void>(builder: (_) => const Text('Current route')),
          MaterialPageRoute<void>(builder: (_) => const Text('Previous route')),
        );
    });

    testWidgets('didRemove notifies listeners', (WidgetTester tester) async {
      await createGoRouter(tester)
        ..addListener(expectAsync0(() {}))
        ..didRemove(
          MaterialPageRoute<void>(builder: (_) => const Text('Current route')),
          MaterialPageRoute<void>(builder: (_) => const Text('Previous route')),
        );
    });

    testWidgets('didReplace notifies listeners', (WidgetTester tester) async {
      await createGoRouter(tester)
        ..addListener(expectAsync0(() {}))
        ..didReplace(
          newRoute: MaterialPageRoute<void>(
            builder: (_) => const Text('Current route'),
          ),
          oldRoute: MaterialPageRoute<void>(
            builder: (_) => const Text('Previous route'),
          ),
        );
    });

    group('canPop', () {
      testWidgets(
        'It should return false if Navigator.canPop() returns false.',
        (WidgetTester tester) async {
          final GlobalKey<NavigatorState> navigatorKey =
              GlobalKey<NavigatorState>();
          final GoRouter router = GoRouter(
            initialLocation: '/',
            navigatorKey: navigatorKey,
            routes: <GoRoute>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, _) {
                  return Scaffold(
                    body: TextButton(
                      onPressed: () async {
                        navigatorKey.currentState!.push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return const Scaffold(
                                body: Text('pageless route'),
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('Push'),
                    ),
                  );
                },
              ),
              GoRoute(path: '/a', builder: (_, __) => const DummyScreen()),
            ],
          );

          await tester.pumpWidget(
            MaterialApp.router(
                routeInformationProvider: router.routeInformationProvider,
                routeInformationParser: router.routeInformationParser,
                routerDelegate: router.routerDelegate),
          );

          expect(router.canPop(), false);

          await tester.tap(find.text('Push'));
          await tester.pumpAndSettle();

          expect(
              find.text('pageless route', skipOffstage: false), findsOneWidget);
          expect(router.canPop(), true);
        },
      );

      testWidgets(
        'It checks if ShellRoute navigators can pop',
        (WidgetTester tester) async {
          final GlobalKey<NavigatorState> shellNavigatorKey =
              GlobalKey<NavigatorState>();
          final GoRouter router = GoRouter(
            initialLocation: '/a',
            routes: <RouteBase>[
              ShellRoute(
                navigatorKey: shellNavigatorKey,
                builder:
                    (BuildContext context, GoRouterState state, Widget child) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Shell')),
                    body: child,
                  );
                },
                routes: <GoRoute>[
                  GoRoute(
                    path: '/a',
                    builder: (BuildContext context, _) {
                      return Scaffold(
                        body: TextButton(
                          onPressed: () async {
                            shellNavigatorKey.currentState!.push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) {
                                  return const Scaffold(
                                    body: Text('pageless route'),
                                  );
                                },
                              ),
                            );
                          },
                          child: const Text('Push'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp.router(
                routeInformationProvider: router.routeInformationProvider,
                routeInformationParser: router.routeInformationParser,
                routerDelegate: router.routerDelegate),
          );

          expect(router.canPop(), false);
          expect(find.text('Push'), findsOneWidget);

          await tester.tap(find.text('Push'));
          await tester.pumpAndSettle();

          expect(
              find.text('pageless route', skipOffstage: false), findsOneWidget);
          expect(router.canPop(), true);
        },
      );

      testWidgets(
        'It checks if ShellRoute navigators can pop',
        (WidgetTester tester) async {
          final GlobalKey<NavigatorState> shellNavigatorKey =
              GlobalKey<NavigatorState>();
          final GoRouter router = GoRouter(
            initialLocation: '/a',
            routes: <RouteBase>[
              ShellRoute(
                navigatorKey: shellNavigatorKey,
                builder:
                    (BuildContext context, GoRouterState state, Widget child) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Shell')),
                    body: child,
                  );
                },
                routes: <GoRoute>[
                  GoRoute(
                    path: '/a',
                    builder: (BuildContext context, _) {
                      return Scaffold(
                        body: TextButton(
                          onPressed: () async {
                            shellNavigatorKey.currentState!.push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) {
                                  return const Scaffold(
                                    body: Text('pageless route'),
                                  );
                                },
                              ),
                            );
                          },
                          child: const Text('Push'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp.router(
                routeInformationProvider: router.routeInformationProvider,
                routeInformationParser: router.routeInformationParser,
                routerDelegate: router.routerDelegate),
          );

          expect(router.canPop(), false);
          expect(find.text('Push'), findsOneWidget);

          await tester.tap(find.text('Push'));
          await tester.pumpAndSettle();

          expect(
              find.text('pageless route', skipOffstage: false), findsOneWidget);
          expect(router.canPop(), true);
        },
      );
    });
    group('pop', () {
      testWidgets(
        'Should pop from the correct navigator when parentNavigatorKey is set',
        (WidgetTester tester) async {
          final GlobalKey<NavigatorState> root =
              GlobalKey<NavigatorState>(debugLabel: 'root');
          final GlobalKey<NavigatorState> shell =
              GlobalKey<NavigatorState>(debugLabel: 'shell');

          final GoRouter router = GoRouter(
            initialLocation: '/a/b',
            navigatorKey: root,
            routes: <GoRoute>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, _) {
                  return const Scaffold(
                    body: Text('Home'),
                  );
                },
                routes: <RouteBase>[
                  ShellRoute(
                    navigatorKey: shell,
                    builder: (BuildContext context, GoRouterState state,
                        Widget child) {
                      return Scaffold(
                        body: Center(
                          child: Column(
                            children: <Widget>[
                              const Text('Shell'),
                              Expanded(child: child),
                            ],
                          ),
                        ),
                      );
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'a',
                        builder: (_, __) => const Text('A Screen'),
                        routes: <RouteBase>[
                          GoRoute(
                            parentNavigatorKey: root,
                            path: 'b',
                            builder: (_, __) => const Text('B Screen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp.router(
                routeInformationProvider: router.routeInformationProvider,
                routeInformationParser: router.routeInformationParser,
                routerDelegate: router.routerDelegate),
          );

          expect(router.canPop(), isTrue);
          expect(find.text('B Screen'), findsOneWidget);
          expect(find.text('A Screen'), findsNothing);
          expect(find.text('Shell'), findsNothing);
          expect(find.text('Home'), findsNothing);
          router.pop();
          await tester.pumpAndSettle();
          expect(find.text('A Screen'), findsOneWidget);
          expect(find.text('Shell'), findsOneWidget);
          expect(router.canPop(), isTrue);
          router.pop();
          await tester.pumpAndSettle();
          expect(find.text('Home'), findsOneWidget);
          expect(find.text('Shell'), findsNothing);
        },
      );
    });

    testWidgets('uses navigatorBuilder when provided',
        (WidgetTester tester) async {
      final Func3<Widget, BuildContext, GoRouterState, Widget>
          navigatorBuilder = expectAsync3(fakeNavigationBuilder);
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <GoRoute>[
          GoRoute(path: '/', builder: (_, __) => const DummyStatefulWidget()),
          GoRoute(
            path: '/error',
            builder: (_, __) => TestErrorScreen(TestFailure('exception')),
          ),
        ],
        navigatorBuilder: navigatorBuilder,
      );

      final GoRouterDelegate delegate = router.routerDelegate;
      delegate.builder.builderWithNav(
        DummyBuildContext(),
        GoRouterState(router.routeConfiguration,
            location: '/foo', subloc: '/bar', name: 'baz'),
        const Navigator(),
      );
    });
  });
}

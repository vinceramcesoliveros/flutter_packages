// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'configuration.dart';
import 'logging.dart';
import 'match.dart';
import 'matching.dart';
import 'misc/error_screen.dart';
import 'pages/cupertino.dart';
import 'pages/custom_transition_page.dart';
import 'pages/material.dart';
import 'route_data.dart';
import 'typedefs.dart';

/// Builds the top-level Navigator for GoRouter.
class RouteBuilder {
  /// [RouteBuilder] constructor.
  RouteBuilder({
    required this.configuration,
    required this.builderWithNav,
    required this.errorPageBuilder,
    required this.errorBuilder,
    required this.restorationScopeId,
    required this.observers,
  });

  /// Builder function for a go router with Navigator.
  final GoRouterBuilderWithNav builderWithNav;

  /// Error page builder for the go router delegate.
  final GoRouterPageBuilder? errorPageBuilder;

  /// Error widget builder for the go router delegate.
  final GoRouterWidgetBuilder? errorBuilder;

  /// The route configuration for the app.
  final RouteConfiguration configuration;

  /// Restoration ID to save and restore the state of the navigator, including
  /// its history.
  final String? restorationScopeId;

  /// NavigatorObserver used to receive notifications when navigating in between routes.
  /// changes.
  final List<NavigatorObserver> observers;

  /// Builds the top-level Navigator for the given [RouteMatchList].
  Widget build(
    BuildContext context,
    RouteMatchList matchList,
    VoidCallback pop,
    bool routerNeglect,
  ) {
    try {
      return tryBuild(
          context, matchList, pop, routerNeglect, configuration.navigatorKey);
    } on _RouteBuilderError catch (e) {
      return _buildErrorNavigator(
          context,
          e,
          Uri.parse(matchList.location.toString()),
          pop,
          configuration.navigatorKey);
    }
  }

  /// Builds the top-level Navigator by invoking the build method on each
  /// matching route.
  ///
  /// Throws a [_RouteBuilderError].
  @visibleForTesting
  Widget tryBuild(
    BuildContext context,
    RouteMatchList matchList,
    VoidCallback pop,
    bool routerNeglect,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    return builderWithNav(
      context,
      GoRouterState(
        configuration,
        location: matchList.location.toString(),
        name: null,
        subloc: matchList.location.path,
        queryParams: matchList.location.queryParameters,
        queryParametersAll: matchList.location.queryParametersAll,
        error: matchList.isError ? matchList.error : null,
      ),
      _buildNavigator(
        pop,
        buildPages(context, matchList, pop, routerNeglect, navigatorKey),
        navigatorKey,
        observers: observers,
      ),
    );
  }

  /// Returns the top-level pages instead of the root navigator. Used for
  /// testing.
  @visibleForTesting
  List<Page<dynamic>> buildPages(
      BuildContext context,
      RouteMatchList matchList,
      VoidCallback onPop,
      bool routerNeglect,
      GlobalKey<NavigatorState> navigatorKey) {
    try {
      final Map<GlobalKey<NavigatorState>, List<Page<dynamic>>> keyToPage =
          <GlobalKey<NavigatorState>, List<Page<dynamic>>>{};
      final Map<String, String> params = <String, String>{};
      _buildRecursive(context, matchList, 0, onPop, routerNeglect, keyToPage,
          params, navigatorKey);
      return keyToPage[navigatorKey]!;
    } on _RouteBuilderError catch (e) {
      return <Page<dynamic>>[
        _buildErrorPage(context, e, matchList.location),
      ];
    }
  }

  void _buildRecursive(
    BuildContext context,
    RouteMatchList matchList,
    int startIndex,
    VoidCallback pop,
    bool routerNeglect,
    Map<GlobalKey<NavigatorState>, List<Page<dynamic>>> keyToPages,
    Map<String, String> params,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    if (startIndex >= matchList.matches.length) {
      return;
    }
    final RouteMatch match = matchList.matches[startIndex];

    if (match.error != null) {
      throw _RouteBuilderError('Match error found during build phase',
          exception: match.error);
    }

    final RouteBase route = match.route;
    final Map<String, String> newParams = <String, String>{
      ...params,
      ...match.decodedParams
    };
    final GoRouterState state = buildState(match, newParams);
    if (route is GoRoute) {
      final Page<dynamic> page = _buildPageForRoute(context, state, match);

      // If this GoRoute is for a different Navigator, add it to the
      // list of out of scope pages
      final GlobalKey<NavigatorState> goRouteNavKey =
          route.parentNavigatorKey ?? navigatorKey;

      keyToPages.putIfAbsent(goRouteNavKey, () => <Page<dynamic>>[]).add(page);

      _buildRecursive(context, matchList, startIndex + 1, pop, routerNeglect,
          keyToPages, newParams, navigatorKey);
    } else if (route is ShellRoute) {
      // The key for the Navigator that will display this ShellRoute's page.
      final GlobalKey<NavigatorState> parentNavigatorKey = navigatorKey;

      // The key to provide to the ShellRoute's Navigator.
      final GlobalKey<NavigatorState> shellNavigatorKey = route.navigatorKey;

      // Add an entry for the parent navigator if none exists.
      keyToPages.putIfAbsent(parentNavigatorKey, () => <Page<dynamic>>[]);

      // Add an entry for the shell route's navigator
      keyToPages.putIfAbsent(shellNavigatorKey, () => <Page<dynamic>>[]);

      // Calling _buildRecursive can result in adding pages to the
      // parentNavigatorKey entry's list. Store the current length so
      // that the page for this ShellRoute is placed at the right index.
      final int shellPageIdx = keyToPages[parentNavigatorKey]!.length;

      // Build the remaining pages
      _buildRecursive(context, matchList, startIndex + 1, pop, routerNeglect,
          keyToPages, newParams, shellNavigatorKey);

      // Build the Navigator
      final Widget child = _buildNavigator(
          pop, keyToPages[shellNavigatorKey]!, shellNavigatorKey);

      // Build the Page for this route
      final Page<dynamic> page =
          _buildPageForRoute(context, state, match, child: child);

      // Place the ShellRoute's Page onto the list for the parent navigator.
      keyToPages
          .putIfAbsent(parentNavigatorKey, () => <Page<dynamic>>[])
          .insert(shellPageIdx, page);
    }
  }

  Navigator _buildNavigator(
    VoidCallback pop,
    List<Page<dynamic>> pages,
    Key? navigatorKey, {
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
  }) {
    return Navigator(
      key: navigatorKey,
      restorationScopeId: restorationScopeId,
      pages: pages,
      observers: observers,
      onPopPage: (Route<dynamic> route, dynamic result) {
        if (!route.didPop(result)) {
          return false;
        }
        pop();
        return true;
      },
    );
  }

  /// Helper method that builds a [GoRouterState] object for the given [match]
  /// and [params].
  @visibleForTesting
  GoRouterState buildState(RouteMatch match, Map<String, String> params) {
    final RouteBase route = match.route;
    String? name = '';
    String path = '';
    if (route is GoRoute) {
      name = route.name;
      path = route.path;
    }
    return GoRouterState(
      configuration,
      location: match.fullUriString,
      subloc: match.subloc,
      name: name,
      path: path,
      fullpath: match.fullpath,
      params: params,
      error: match.error,
      queryParams: match.queryParams,
      queryParametersAll: match.queryParametersAll,
      extra: match.extra,
      pageKey: match.pageKey,
    );
  }

  /// Builds a [Page] for [StackedRoute]
  Page<dynamic> _buildPageForRoute(
      BuildContext context, GoRouterState state, RouteMatch match,
      {Widget? child}) {
    final RouteBase route = match.route;
    Page<dynamic>? page;

    if (route is GoRoute) {
      // Call the pageBuilder if it's non-null
      final GoRouterPageBuilder? pageBuilder = route.pageBuilder;
      if (pageBuilder != null) {
        page = pageBuilder(context, state);
      }
    } else if (route is ShellRoute) {
      final ShellRoutePageBuilder? pageBuilder = route.pageBuilder;
      assert(child != null, 'ShellRoute must contain a child route');
      if (pageBuilder != null) {
        page = pageBuilder(context, state, child!);
      }
    }

    if (page is NoOpPage) {
      page = null;
    }

    // Return the result of the route's builder() or pageBuilder()
    return page ??
        buildPage(context, state,
            _callRouteBuilder(context, state, match, childWidget: child));
  }

  /// Calls the user-provided route builder from the [RouteMatch]'s [RouteBase].
  Widget _callRouteBuilder(
      BuildContext context, GoRouterState state, RouteMatch match,
      {Widget? childWidget}) {
    final RouteBase route = match.route;

    if (route == null) {
      throw _RouteBuilderError('No route found for match: $match');
    }

    if (route is GoRoute) {
      final GoRouterWidgetBuilder? builder = route.builder;

      if (builder == null) {
        throw _RouteBuilderError('No routeBuilder provided to GoRoute: $route');
      }

      return builder(context, state);
    } else if (route is ShellRoute) {
      if (childWidget == null) {
        throw _RouteBuilderException(
            'Attempt to build ShellRoute without a child widget');
      }

      final ShellRouteBuilder? builder = route.builder;

      if (builder == null) {
        throw _RouteBuilderError('No builder provided to ShellRoute: $route');
      }

      return builder(context, state, childWidget);
    }

    throw _RouteBuilderException('Unsupported route type $route');
  }

  _PageBuilderForAppType? _pageBuilderForAppType;

  Widget Function(
    BuildContext context,
    GoRouterState state,
  )? _errorBuilderForAppType;

  void _cacheAppType(BuildContext context) {
    // cache app type-specific page and error builders
    if (_pageBuilderForAppType == null) {
      assert(_errorBuilderForAppType == null);

      // can be null during testing
      final Element? elem = context is Element ? context : null;

      if (elem != null && isMaterialApp(elem)) {
        log.info('Using MaterialApp configuration');
        _pageBuilderForAppType = pageBuilderForMaterialApp;
        _errorBuilderForAppType =
            (BuildContext c, GoRouterState s) => MaterialErrorScreen(s.error);
      } else if (elem != null && isCupertinoApp(elem)) {
        log.info('Using CupertinoApp configuration');
        _pageBuilderForAppType = pageBuilderForCupertinoApp;
        _errorBuilderForAppType =
            (BuildContext c, GoRouterState s) => CupertinoErrorScreen(s.error);
      } else {
        log.info('Using WidgetsApp configuration');
        _pageBuilderForAppType = pageBuilderForWidgetApp;
        _errorBuilderForAppType =
            (BuildContext c, GoRouterState s) => ErrorScreen(s.error);
      }
    }

    assert(_pageBuilderForAppType != null);
    assert(_errorBuilderForAppType != null);
  }

  /// builds the page based on app type, i.e. MaterialApp vs. CupertinoApp
  @visibleForTesting
  Page<dynamic> buildPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    // build the page based on app type
    _cacheAppType(context);
    return _pageBuilderForAppType!(
      key: state.pageKey,
      name: state.name ?? state.fullpath,
      arguments: <String, String>{...state.params, ...state.queryParams},
      restorationId: state.pageKey.value,
      child: child,
    );
  }

  /// Builds a page without any transitions.
  Page<void> pageBuilderForWidgetApp({
    required LocalKey key,
    required String? name,
    required Object? arguments,
    required String restorationId,
    required Widget child,
  }) =>
      NoTransitionPage<void>(
        name: name,
        arguments: arguments,
        key: key,
        restorationId: restorationId,
        child: child,
      );

  /// Builds a Navigator containing an error page.
  Widget _buildErrorNavigator(BuildContext context, _RouteBuilderError e,
      Uri uri, VoidCallback pop, GlobalKey<NavigatorState> navigatorKey) {
    return _buildNavigator(
      pop,
      <Page<dynamic>>[
        _buildErrorPage(context, e, uri),
      ],
      navigatorKey,
    );
  }

  /// Builds a an error page.
  Page<void> _buildErrorPage(
    BuildContext context,
    _RouteBuilderError error,
    Uri uri,
  ) {
    final GoRouterState state = GoRouterState(
      configuration,
      location: uri.toString(),
      subloc: uri.path,
      name: null,
      queryParams: uri.queryParameters,
      queryParametersAll: uri.queryParametersAll,
      error: Exception(error),
    );

    // If the error page builder is provided, use that, otherwise, if the error
    // builder is provided, wrap that in an app-specific page (for example,
    // MaterialPage). Finally, if nothing is provided, use a default error page
    // wrapped in the app-specific page.
    _cacheAppType(context);
    final GoRouterWidgetBuilder? errorBuilder = this.errorBuilder;
    return errorPageBuilder != null
        ? errorPageBuilder!(context, state)
        : buildPage(
            context,
            state,
            errorBuilder != null
                ? errorBuilder(context, state)
                : _errorBuilderForAppType!(context, state),
          );
  }
}

typedef _PageBuilderForAppType = Page<void> Function({
  required LocalKey key,
  required String? name,
  required Object? arguments,
  required String restorationId,
  required Widget child,
});

/// An error that occurred while building the app's UI based on the route
/// matches.
class _RouteBuilderError extends Error {
  /// Constructs a [_RouteBuilderError].
  _RouteBuilderError(this.message, {this.exception});

  /// The error message.
  final String message;

  /// The exception that occurred.
  final Exception? exception;

  @override
  String toString() {
    return '$message ${exception ?? ""}';
  }
}

/// An error that occurred while building the app's UI based on the route
/// matches.
class _RouteBuilderException implements Exception {
  /// Constructs a [_RouteBuilderException].
  //ignore: unused_element
  _RouteBuilderException(this.message, {this.exception});

  /// The error message.
  final String message;

  /// The exception that occurred.
  final Exception? exception;

  @override
  String toString() {
    return '$message ${exception ?? ""}';
  }
}

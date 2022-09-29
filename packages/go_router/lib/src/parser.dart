// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'configuration.dart';
import 'information_provider.dart';
import 'logging.dart';
import 'matching.dart';
import 'redirection.dart';

/// Converts between incoming URLs and a [RouteMatchList] using [RouteMatcher].
/// Also performs redirection using [RouteRedirector].
class GoRouteInformationParser extends RouteInformationParser<RouteMatchList> {
  /// Creates a [GoRouteInformationParser].
  GoRouteInformationParser({
    required this.configuration,
    this.debugRequireGoRouteInformationProvider = false,
  })  : matcher = RouteMatcher(configuration),
        redirector = redirect;

  /// The route configuration for the app.
  final RouteConfiguration configuration;

  /// The route matcher.
  final RouteMatcher matcher;

  /// The route redirector.
  final RouteRedirector redirector;

  /// A debug property to assert [GoRouteInformationProvider] is in use along
  /// with this parser.
  ///
  /// An assertion error will be thrown if this property set to true and the
  /// [GoRouteInformationProvider] is not in use.
  ///
  /// Defaults to false.
  final bool debugRequireGoRouteInformationProvider;

  /// The future of current route parsing.
  ///
  /// This is used for testing asynchronous redirection.
  @visibleForTesting
  Future<RouteMatchList>? debugParserFuture;

  /// Called by the [Router]. The
  @override
  Future<RouteMatchList> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) {
    assert(() {
      if (debugRequireGoRouteInformationProvider) {
        assert(
          routeInformation is DebugGoRouteInformation,
          'This GoRouteInformationParser needs to be used with '
          'GoRouteInformationProvider, did you forget to pass in '
          'GoRouter.routeInformationProvider to the Router constructor?',
        );
      }
      return true;
    }());
    late final RouteMatchList initialMatches;
    try {
      initialMatches = matcher.findMatch(routeInformation.location!,
          extra: routeInformation.state);
    } on MatcherError {
      log.info('No initial matches: ${routeInformation.location}');

      // If there is a matching error for the initial location, we should
      // still try to process the top-level redirects.
      initialMatches = RouteMatchList.empty();
    }
    Future<RouteMatchList> processRedirectorResult(RouteMatchList matches) {
      if (matches.isEmpty) {
        return SynchronousFuture<RouteMatchList>(errorScreen(
            Uri.parse(routeInformation.location!),
            MatcherError('no routes for location', routeInformation.location!)
                .toString()));
      }
      return SynchronousFuture<RouteMatchList>(matches);
    }

    final FutureOr<RouteMatchList> redirectorResult = redirector(
      context,
      SynchronousFuture<RouteMatchList>(initialMatches),
      configuration,
      matcher,
      extra: routeInformation.state,
    );
    if (redirectorResult is RouteMatchList) {
      return processRedirectorResult(redirectorResult);
    }

    return debugParserFuture = redirectorResult.then(processRedirectorResult);
  }

  @override
  Future<RouteMatchList> parseRouteInformation(
      RouteInformation routeInformation) {
    throw UnimplementedError(
        'use parseRouteInformationWithDependencies instead');
  }

  /// for use by the Router architecture as part of the RouteInformationParser
  @override
  RouteInformation restoreRouteInformation(RouteMatchList configuration) {
    return RouteInformation(
      location: configuration.location.toString(),
      state: configuration.extra,
    );
  }
}

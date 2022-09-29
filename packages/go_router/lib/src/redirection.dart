// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'configuration.dart';
import 'logging.dart';
import 'match.dart';
import 'matching.dart';

/// A GoRouter redirector function.
typedef RouteRedirector = FutureOr<RouteMatchList> Function(
    BuildContext, FutureOr<RouteMatchList>, RouteConfiguration, RouteMatcher,
    {List<RouteMatchList>? redirectHistory, Object? extra});

/// Processes redirects by returning a new [RouteMatchList] representing the new
/// location.
FutureOr<RouteMatchList> redirect(
    BuildContext context,
    FutureOr<RouteMatchList> prevMatchListFuture,
    RouteConfiguration configuration,
    RouteMatcher matcher,
    {List<RouteMatchList>? redirectHistory,
    Object? extra}) {
  FutureOr<RouteMatchList> processRedirect(RouteMatchList prevMatchList) {
    FutureOr<RouteMatchList> processTopLevelRedirect(
        String? topRedirectLocation) {
      if (topRedirectLocation != null) {
        final RouteMatchList newMatch = _getNewMatches(
          topRedirectLocation,
          prevMatchList.location,
          configuration,
          matcher,
          redirectHistory!,
        );
        if (newMatch.isError) {
          return newMatch;
        }
        return redirect(
          context,
          newMatch,
          configuration,
          matcher,
          redirectHistory: redirectHistory,
          extra: extra,
        );
      }

      // Merge new params to keep params from previously matched paths, e.g.
      // /users/:userId/book/:bookId provides userId and bookId to bookgit /:bookId
      Map<String, String> previouslyMatchedParams = <String, String>{};
      for (final RouteMatch match in prevMatchList.matches) {
        assert(
          !previouslyMatchedParams.keys.any(match.encodedParams.containsKey),
          'Duplicated parameter names',
        );
        match.encodedParams.addAll(previouslyMatchedParams);
        previouslyMatchedParams = match.encodedParams;
      }
      FutureOr<RouteMatchList> processRouteLevelRedirect(
          String? routeRedirectLocation) {
        if (routeRedirectLocation != null) {
          final RouteMatchList newMatch = _getNewMatches(
            routeRedirectLocation,
            prevMatchList.location,
            configuration,
            matcher,
            redirectHistory!,
          );

          if (newMatch.isError) {
            return newMatch;
          }
          return redirect(
            context,
            newMatch,
            configuration,
            matcher,
            redirectHistory: redirectHistory,
            extra: extra,
          );
        }
        return prevMatchList;
      }

      final FutureOr<String?> routeLevelRedirectResult =
          _getRouteLevelRedirect(context, configuration, prevMatchList, 0);
      if (routeLevelRedirectResult is String?) {
        return processRouteLevelRedirect(routeLevelRedirectResult);
      }
      return routeLevelRedirectResult
          .then<RouteMatchList>(processRouteLevelRedirect);
    }

    redirectHistory ??= <RouteMatchList>[prevMatchList];
    // Check for top-level redirect
    final Uri uri = prevMatchList.location;
    final FutureOr<String?> topRedirectResult = configuration.topRedirect(
      context,
      GoRouterState(
        configuration,
        location: prevMatchList.location.toString(),
        name: null,
        // No name available at the top level trim the query params off the
        // sub-location to match route.redirect
        subloc: uri.path,
        queryParams: uri.queryParameters,
        queryParametersAll: uri.queryParametersAll,
        extra: extra,
      ),
    );

    if (topRedirectResult is String?) {
      return processTopLevelRedirect(topRedirectResult);
    }
    return topRedirectResult.then<RouteMatchList>(processTopLevelRedirect);
  }

  if (prevMatchListFuture is RouteMatchList) {
    return processRedirect(prevMatchListFuture);
  }
  return prevMatchListFuture.then<RouteMatchList>(processRedirect);
}

FutureOr<String?> _getRouteLevelRedirect(
  BuildContext context,
  RouteConfiguration configuration,
  RouteMatchList matchList,
  int currentCheckIndex,
) {
  if (currentCheckIndex >= matchList.matches.length) {
    return null;
  }
  final RouteMatch match = matchList.matches[currentCheckIndex];
  FutureOr<String?> processRouteRedirect(String? newLocation) =>
      newLocation ??
      _getRouteLevelRedirect(
          context, configuration, matchList, currentCheckIndex + 1);
  final RouteBase route = match.route;
  FutureOr<String?> routeRedirectResult;
  if (route is GoRoute && route.redirect != null) {
    routeRedirectResult = route.redirect!(
      context,
      GoRouterState(
        configuration,
        location: matchList.location.toString(),
        subloc: match.subloc,
        name: route.name,
        path: route.path,
        fullpath: match.fullpath,
        extra: match.extra,
        params: match.decodedParams,
        queryParams: match.queryParams,
        queryParametersAll: match.queryParametersAll,
      ),
    );
  }
  if (routeRedirectResult is String?) {
    return processRouteRedirect(routeRedirectResult);
  }
  return routeRedirectResult.then<String?>(processRouteRedirect);
}

RouteMatchList _getNewMatches(
  String newLocation,
  Uri previousLocation,
  RouteConfiguration configuration,
  RouteMatcher matcher,
  List<RouteMatchList> redirectHistory,
) {
  try {
    final RouteMatchList newMatch = matcher.findMatch(newLocation);
    _addRedirect(redirectHistory, newMatch, previousLocation,
        configuration.redirectLimit);
    return newMatch;
  } on RedirectionError catch (e) {
    return _handleRedirectionError(e);
  } on MatcherError catch (e) {
    return _handleMatcherError(e);
  }
}

RouteMatchList _handleMatcherError(MatcherError error) {
  // The RouteRedirector uses the matcher to find the match, so a match
  // exception can happen during redirection. For example, the redirector
  // redirects from `/a` to `/b`, it needs to get the matches for `/b`.
  log.info('Match error: ${error.message}');
  final Uri uri = Uri.parse(error.location);
  return errorScreen(uri, error.message);
}

RouteMatchList _handleRedirectionError(RedirectionError error) {
  log.info('Redirection error: ${error.message}');
  final Uri uri = error.location;
  return errorScreen(uri, error.message);
}

/// A configuration error detected while processing redirects.
class RedirectionError extends Error implements UnsupportedError {
  /// RedirectionError constructor.
  RedirectionError(this.message, this.matches, this.location);

  /// The matches that were found while processing redirects.
  final List<RouteMatchList> matches;

  @override
  final String message;

  /// The location that was originally navigated to, before redirection began.
  final Uri location;

  @override
  String toString() => '${super.toString()} ${<String>[
        ...matches.map(
            (RouteMatchList routeMatches) => routeMatches.location.toString()),
      ].join(' => ')}';
}

/// Adds the redirect to [redirects] if it is valid.
void _addRedirect(List<RouteMatchList> redirects, RouteMatchList newMatch,
    Uri prevLocation, int redirectLimit) {
  // Verify that the redirect can be parsed and is not already
  // in the list of redirects
  assert(() {
    if (redirects.contains(newMatch)) {
      throw RedirectionError('redirect loop detected',
          <RouteMatchList>[...redirects, newMatch], prevLocation);
    }
    if (redirects.length > redirectLimit) {
      throw RedirectionError('too many redirects',
          <RouteMatchList>[...redirects, newMatch], prevLocation);
    }
    return true;
  }());

  redirects.add(newMatch);

  assert(() {
    log.info('redirecting to $newMatch');
    return true;
  }());
}

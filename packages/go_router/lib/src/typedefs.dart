// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'configuration.dart';

/// The widget builder for [GoRoute].
typedef GoRouterWidgetBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

/// The page builder for [GoRoute].
typedef GoRouterPageBuilder = Page<dynamic> Function(
  BuildContext context,
  GoRouterState state,
);

/// The widget builder for [ShellRoute].
typedef ShellRouteBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
  Widget child,
);

/// The page builder for [ShellRoute].
typedef ShellRoutePageBuilder = Page<dynamic> Function(
  BuildContext context,
  GoRouterState state,
  Widget child,
);

/// The signature of the navigatorBuilder callback.
typedef GoRouterNavigatorBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
  Widget child,
);

/// Signature of a go router builder function with navigator.
typedef GoRouterBuilderWithNav = Widget Function(
  BuildContext context,
  GoRouterState state,
  Navigator navigator,
);

/// The signature of the redirect callback.
typedef GoRouterRedirect = String? Function(GoRouterState state);

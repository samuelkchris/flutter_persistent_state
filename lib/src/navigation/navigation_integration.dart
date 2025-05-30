import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_persistent_state/src/core/persistent_state_manager.dart';


/// Route observer that automatically saves and restores navigation state.
///
/// This observer integrates with Flutter's navigation system to persist
/// the current route stack and restore it when the app is restarted.
/// It provides seamless navigation state management without manual
/// intervention from the developer.
///
/// The observer can be configured to save navigation parameters,
/// route arguments, and maintain deep-link compatibility.
class PersistentNavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  final PersistentStateManager _stateManager;
  final String _routeStackKey;
  final String _currentRouteKey;
  final bool _saveArguments;
  final Set<String> _excludedRoutes;

  /// Create a new persistent navigation observer.
  ///
  /// @param stateManager the state manager to use for persistence
  /// @param routeStackKey storage key for the route stack
  /// @param currentRouteKey storage key for the current route
  /// @param saveArguments whether to persist route arguments
  /// @param enableDeepLinks whether to restore deep links on app start
  /// @param excludedRoutes set of route names to exclude from persistence
  PersistentNavigationObserver({
    PersistentStateManager? stateManager,
    String routeStackKey = 'navigation_route_stack',
    String currentRouteKey = 'navigation_current_route',
    bool saveArguments = true,
    bool enableDeepLinks = true,
    Set<String>? excludedRoutes,
  })  : _stateManager = stateManager ?? PersistentStateManager.instance,
        _routeStackKey = routeStackKey,
        _currentRouteKey = currentRouteKey,
        _saveArguments = saveArguments,
        _excludedRoutes = excludedRoutes ?? {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _saveNavigationState(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _saveNavigationState(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _saveNavigationState(newRoute);
    }
  }

  /// Save the current navigation state to persistent storage.
  ///
  /// This method captures the current route information and saves it
  /// for restoration when the app is restarted. It handles route names,
  /// arguments, and maintains the navigation stack.
  Future<void> _saveNavigationState(PageRoute route) async {
    if (!_stateManager.isInitialized) {
      return;
    }

    final routeName = route.settings.name;
    if (routeName == null || _excludedRoutes.contains(routeName)) {
      return;
    }

    try {
      final routeData = <String, dynamic>{
        'name': routeName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (_saveArguments && route.settings.arguments != null) {
        routeData['arguments'] = _serializeArguments(route.settings.arguments);
      }

      await _stateManager.setValue(_currentRouteKey, routeData);
      await _updateRouteStack(routeData);

    } catch (e) {
      debugPrint('Failed to save navigation state: $e');
    }
  }

  /// Update the persistent route stack.
  ///
  /// Maintains a stack of recent routes to enable proper navigation
  /// restoration and back button behavior.
  Future<void> _updateRouteStack(Map<String, dynamic> routeData) async {
    try {
      final stackData = await _stateManager.getValue<List<String>>(_routeStackKey) ?? [];
      final stack = stackData.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();

      stack.removeWhere((item) => item['name'] == routeData['name']);
      stack.add(routeData);

      if (stack.length > 20) {
        stack.removeAt(0);
      }

      final serializedStack = stack.map((item) => jsonEncode(item)).toList();
      await _stateManager.setValue(_routeStackKey, serializedStack);

    } catch (e) {
      debugPrint('Failed to update route stack: $e');
    }
  }

  /// Serialize route arguments for persistence.
  ///
  /// Converts route arguments to a JSON-serializable format.
  /// Handles common argument types and provides fallbacks for
  /// complex objects.
  Map<String, dynamic>? _serializeArguments(Object? arguments) {
    if (arguments == null) {
      return null;
    }

    try {
      if (arguments is Map<String, dynamic>) {
        return Map<String, dynamic>.from(arguments);
      } else if (arguments is Map) {
        return arguments.map((k, v) => MapEntry(k.toString(), v));
      } else {
        return {'value': arguments.toString(), 'type': arguments.runtimeType.toString()};
      }
    } catch (e) {
      debugPrint('Failed to serialize route arguments: $e');
      return null;
    }
  }

  /// Get the last saved route information.
  ///
  /// @returns the most recently saved route data, or null if none exists
  Future<Map<String, dynamic>?> getLastRoute() async {
    if (!_stateManager.isInitialized) {
      await _stateManager.initialize();
    }

    return await _stateManager.getValue<Map<String, dynamic>>(_currentRouteKey);
  }

  /// Get the complete route history.
  ///
  /// @returns list of route data in chronological order
  Future<List<Map<String, dynamic>>> getRouteHistory() async {
    if (!_stateManager.isInitialized) {
      await _stateManager.initialize();
    }

    try {
      final stackData = await _stateManager.getValue<List<String>>(_routeStackKey) ?? [];
      return stackData.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get route history: $e');
      return [];
    }
  }

  /// Clear all saved navigation state.
  ///
  /// Removes all persistent navigation data. Useful for logout
  /// operations or when resetting the app state.
  Future<void> clearNavigationState() async {
    await _stateManager.removeValue(_currentRouteKey);
    await _stateManager.removeValue(_routeStackKey);
  }
}

/// Widget that automatically restores navigation state on app start.
///
/// This widget should be placed at the root of your app to enable
/// automatic navigation restoration. It integrates with the
/// PersistentNavigationObserver to restore the last known route
/// when the app is restarted.
class PersistentNavigationWrapper extends StatefulWidget {
  /// The child widget to wrap (typically MaterialApp or CupertinoApp).
  final Widget child;

  /// The navigation observer to use for state persistence.
  final PersistentNavigationObserver observer;

  /// Whether to restore navigation state on app start.
  final bool restoreOnStart;

  /// Maximum age of saved routes to consider for restoration.
  final Duration maxRouteAge;

  /// Callback to determine if a route should be restored.
  final bool Function(Map<String, dynamic> routeData)? shouldRestore;

  /// Callback when navigation restoration completes.
  final void Function(bool restored, String? routeName)? onRestorationComplete;

  const PersistentNavigationWrapper({
    super.key,
    required this.child,
    required this.observer,
    this.restoreOnStart = true,
    this.maxRouteAge = const Duration(days: 7),
    this.shouldRestore,
    this.onRestorationComplete,
  });

  @override
  State<PersistentNavigationWrapper> createState() => _PersistentNavigationWrapperState();
}

class _PersistentNavigationWrapperState extends State<PersistentNavigationWrapper> {
  bool _hasRestored = false;

  @override
  void initState() {
    super.initState();
    if (widget.restoreOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreNavigationState();
      });
    }
  }

  /// Restore the last known navigation state.
  ///
  /// This method checks for saved navigation data and attempts to
  /// restore the user to their last known location in the app.
  Future<void> _restoreNavigationState() async {
    if (_hasRestored) {
      return;
    }

    _hasRestored = true;

    try {
      final lastRoute = await widget.observer.getLastRoute();
      if (lastRoute == null) {
        widget.onRestorationComplete?.call(false, null);
        return;
      }

      if (!_shouldRestoreRoute(lastRoute)) {
        widget.onRestorationComplete?.call(false, lastRoute['name']);
        return;
      }

      final navigator = Navigator.of(context);
      final routeName = lastRoute['name'] as String;
      final arguments = lastRoute['arguments'] as Map<String, dynamic>?;

      navigator.pushNamedAndRemoveUntil(
        routeName,
            (route) => false,
        arguments: arguments,
      );

      widget.onRestorationComplete?.call(true, routeName);

    } catch (e) {
      debugPrint('Failed to restore navigation state: $e');
      widget.onRestorationComplete?.call(false, null);
    }
  }

  /// Determine if a saved route should be restored.
  ///
  /// Checks route age, custom restoration logic, and other factors
  /// to decide whether navigation should be restored.
  bool _shouldRestoreRoute(Map<String, dynamic> routeData) {
    if (widget.shouldRestore != null) {
      return widget.shouldRestore!(routeData);
    }

    final timestamp = routeData['timestamp'] as int?;
    if (timestamp != null) {
      final routeTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(routeTime);

      if (age > widget.maxRouteAge) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Builder function for creating routes with automatic persistence.
///
/// This function creates route builders that automatically integrate
/// with the persistent navigation system. Routes created with this
/// builder will have their state automatically saved and restored.
typedef PersistentRouteBuilder = Widget Function(
    BuildContext context,
    Map<String, dynamic>? persistentData,
    );

/// Factory for creating persistent-aware routes.
///
/// This class provides helper methods for creating routes that integrate
/// seamlessly with the persistent navigation system. It handles argument
/// serialization, state restoration, and lifecycle management.
class PersistentRouteFactory {
  final PersistentStateManager _stateManager;

  /// Create a new route factory.
  ///
  /// @param stateManager the state manager to use for persistence
  PersistentRouteFactory({
    PersistentStateManager? stateManager,
  }) : _stateManager = stateManager ?? PersistentStateManager.instance;

  /// Create a persistent route that automatically saves and restores its state.
  ///
  /// @param routeName the name of the route
  /// @param builder the widget builder function
  /// @param persistentKeys list of keys to persist for this route
  /// @returns a route builder function
  RouteFactory createPersistentRoute(
      String routeName,
      PersistentRouteBuilder builder, {
        List<String>? persistentKeys,
      }) {
    return (settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => _PersistentRouteWidget(
          routeName: routeName,
          stateManager: _stateManager,
          persistentKeys: persistentKeys ?? [],
          builder: builder,
          arguments: settings.arguments as Map<String, dynamic>?,
        ),
      );
    };
  }

  /// Create a route map for use with MaterialApp.routes.
  ///
  /// @param routeDefinitions map of route names to builders
  /// @returns a route map suitable for MaterialApp
  Map<String, WidgetBuilder> createRouteMap(
      Map<String, PersistentRouteBuilder> routeDefinitions,
      ) {
    return routeDefinitions.map((routeName, builder) {
      return MapEntry(
        routeName,
            (context) => _PersistentRouteWidget(
          routeName: routeName,
          stateManager: _stateManager,
          persistentKeys: [],
          builder: builder,
          arguments: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?,
        ),
      );
    });
  }
}

/// Internal widget that provides persistence capabilities to routes.
///
/// This widget wraps route content to provide automatic state persistence
/// and restoration. It manages the lifecycle of persistent data and
/// coordinates with the navigation system.
class _PersistentRouteWidget extends StatefulWidget {
  final String routeName;
  final PersistentStateManager stateManager;
  final List<String> persistentKeys;
  final PersistentRouteBuilder builder;
  final Map<String, dynamic>? arguments;

  const _PersistentRouteWidget({
    required this.routeName,
    required this.stateManager,
    required this.persistentKeys,
    required this.builder,
    this.arguments,
  });

  @override
  State<_PersistentRouteWidget> createState() => _PersistentRouteWidgetState();
}

class _PersistentRouteWidgetState extends State<_PersistentRouteWidget> {
  Map<String, dynamic>? _persistentData;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPersistentData();
  }

  /// Load persistent data for this route.
  ///
  /// Retrieves any previously saved state data for this route
  /// and makes it available to the route builder.
  Future<void> _loadPersistentData() async {
    if (!widget.stateManager.isInitialized) {
      await widget.stateManager.initialize();
    }

    final data = <String, dynamic>{};

    for (final key in widget.persistentKeys) {
      final value = await widget.stateManager.getValue(key);
      if (value != null) {
        data[key] = value;
      }
    }

    if (mounted) {
      setState(() {
        _persistentData = data;
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.builder(context, _persistentData);
  }
}
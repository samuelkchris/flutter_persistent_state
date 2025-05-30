import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_persistent_state/flutter_persistent_state.dart';

///
/// This observer integrates with Flutter's navigation system to persist
/// the current route stack and restore it when the app is restarted.
/// It provides seamless navigation state management with proper context handling.
class PersistentNavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  final PersistentStateManager _stateManager;
  final String _routeStackKey;
  final String _currentRouteKey;
  final bool _saveArguments;
  final Set<String> _excludedRoutes;

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
  Future<Map<String, dynamic>?> getLastRoute() async {
    if (!_stateManager.isInitialized) {
      await _stateManager.initialize();
    }

    return await _stateManager.getValue<Map<String, dynamic>>(_currentRouteKey);
  }

  /// Get the complete route history.
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
  Future<void> clearNavigationState() async {
    await _stateManager.removeValue(_currentRouteKey);
    await _stateManager.removeValue(_routeStackKey);
  }
}

/// Fixed widget that automatically restores navigation state on app start.
///
/// This widget properly handles the Navigator context and delays restoration
/// until the Navigator is ready.
class PersistentNavigationWrapper extends StatefulWidget {
  final Widget child;
  final PersistentNavigationObserver observer;
  final bool restoreOnStart;
  final Duration maxRouteAge;
  final bool Function(Map<String, dynamic> routeData)? shouldRestore;
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
  bool _hasAttemptedRestore = false;

  @override
  void initState() {
    super.initState();
    if (widget.restoreOnStart) {
      // Delay restoration until after the first frame to ensure Navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleRestoration();
      });
    }
  }

  /// Schedule navigation restoration with proper timing.
  void _scheduleRestoration() {
    // Add additional delay to ensure Navigator is fully initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_hasAttemptedRestore) {
        _restoreNavigationState();
      }
    });
  }

  /// Restore the last known navigation state with proper error handling.
  Future<void> _restoreNavigationState() async {
    if (_hasAttemptedRestore) {
      return;
    }

    _hasAttemptedRestore = true;

    try {
      // Ensure we have a valid Navigator context
      if (!mounted) {
        widget.onRestorationComplete?.call(false, null);
        return;
      }

      final navigator = Navigator.maybeOf(context);
      if (navigator == null) {
        debugPrint('Navigator not available for restoration');
        widget.onRestorationComplete?.call(false, null);
        return;
      }

      final lastRoute = await widget.observer.getLastRoute();
      if (lastRoute == null) {
        widget.onRestorationComplete?.call(false, null);
        return;
      }

      if (!_shouldRestoreRoute(lastRoute)) {
        widget.onRestorationComplete?.call(false, lastRoute['name']);
        return;
      }

      final routeName = lastRoute['name'] as String;
      final arguments = lastRoute['arguments'] as Map<String, dynamic>?;

      // Double-check we still have a mounted widget and valid context
      if (!mounted) {
        widget.onRestorationComplete?.call(false, routeName);
        return;
      }

      // Use pushNamedAndRemoveUntil for cleaner navigation stack
      await navigator.pushNamedAndRemoveUntil(
        routeName,
            (route) => false,
        arguments: arguments,
      );

      debugPrint('Navigation restored: true to $routeName');
      widget.onRestorationComplete?.call(true, routeName);

    } catch (e) {
      debugPrint('Failed to restore navigation state: $e');
      widget.onRestorationComplete?.call(false, null);
    }
  }

  /// Determine if a saved route should be restored.
  bool _shouldRestoreRoute(Map<String, dynamic> routeData) {
    if (widget.shouldRestore != null) {
      try {
        return widget.shouldRestore!(routeData);
      } catch (e) {
        debugPrint('Error in shouldRestore callback: $e');
        return false;
      }
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
typedef PersistentRouteBuilder = Widget Function(
    BuildContext context,
    Map<String, dynamic>? persistentData,
    );

/// Factory for creating persistent-aware routes.
class PersistentRouteFactory {
  final PersistentStateManager _stateManager;

  PersistentRouteFactory({
    PersistentStateManager? stateManager,
  }) : _stateManager = stateManager ?? PersistentStateManager.instance;

  /// Create a persistent route that automatically saves and restores its state.
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
  Future<void> _loadPersistentData() async {
    try {
      if (!widget.stateManager.isInitialized) {
        await widget.stateManager.initialize();
      }

      final data = <String, dynamic>{};

      for (final key in widget.persistentKeys) {
        try {
          final value = await widget.stateManager.getValue(key);
          if (value != null) {
            data[key] = value;
          }
        } catch (e) {
          debugPrint('Failed to load persistent data for key $key: $e');
        }
      }

      if (mounted) {
        setState(() {
          _persistentData = data;
          _isLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load persistent data for route ${widget.routeName}: $e');
      if (mounted) {
        setState(() {
          _persistentData = {};
          _isLoaded = true;
        });
      }
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
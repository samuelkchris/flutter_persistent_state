import 'package:flutter/foundation.dart';
import 'package:flutter_persistent_state/src/core/persistent_state_manager.dart';
import 'package:flutter_persistent_state/src/widgets/text_field_integration.dart';

/// Utilities for working with persistent text fields.
///
/// This class provides helper methods for common text field operations
/// in persistent applications, such as batch operations, search history,
/// and form management.
class PersistentTextUtils {
  static final PersistentStateManager _defaultManager = PersistentStateManager.instance;

  /// Save multiple text fields at once.
  ///
  /// @param controllers map of storage keys to controllers
  /// @param stateManager optional custom state manager
  static Future<void> saveAll(
      Map<String, PersistentTextController> controllers, {
        PersistentStateManager? stateManager,
      }) async {
    final manager = stateManager ?? _defaultManager;

    final futures = controllers.entries.map((entry) async {
      try {
        await manager.setValue(entry.key, entry.value.text);
      } catch (e) {
        debugPrint('Failed to save ${entry.key}: $e');
      }
    });

    await Future.wait(futures);
  }

  /// Clear multiple text fields and their persistent data.
  ///
  /// @param storageKeys list of storage keys to clear
  /// @param stateManager optional custom state manager
  static Future<void> clearAll(
      List<String> storageKeys, {
        PersistentStateManager? stateManager,
      }) async {
    final manager = stateManager ?? _defaultManager;

    final futures = storageKeys.map((key) async {
      try {
        await manager.removeValue(key);
      } catch (e) {
        debugPrint('Failed to clear $key: $e');
      }
    });

    await Future.wait(futures);
  }

  /// Add a search term to persistent search history.
  ///
  /// @param term the search term to add
  /// @param storageKey storage key for the search history
  /// @param maxHistory maximum number of terms to keep
  /// @param stateManager optional custom state manager
  static Future<void> addToSearchHistory(
      String term, {
        String storageKey = 'search_history',
        int maxHistory = 20,
        PersistentStateManager? stateManager,
      }) async {
    if (term.trim().isEmpty) {
      return;
    }

    final manager = stateManager ?? _defaultManager;

    final history = await manager.getValue<List<String>>(storageKey) ?? [];
    final updatedHistory = List<String>.from(history);

    updatedHistory.remove(term);
    updatedHistory.insert(0, term);

    if (updatedHistory.length > maxHistory) {
      updatedHistory.removeRange(maxHistory, updatedHistory.length);
    }

    await manager.setValue(storageKey, updatedHistory);
  }

  /// Get persistent search history.
  ///
  /// @param storageKey storage key for the search history
  /// @param stateManager optional custom state manager
  /// @returns list of search terms in most recent first order
  static Future<List<String>> getSearchHistory({
    String storageKey = 'search_history',
    PersistentStateManager? stateManager,
  }) async {
    final manager = stateManager ?? _defaultManager;
    return await manager.getValue<List<String>>(storageKey) ?? [];
  }

  /// Clear persistent search history.
  ///
  /// @param storageKey storage key for the search history
  /// @param stateManager optional custom state manager
  static Future<void> clearSearchHistory({
    String storageKey = 'search_history',
    PersistentStateManager? stateManager,
  }) async {
    final manager = stateManager ?? _defaultManager;
    await manager.removeValue(storageKey);
  }
}
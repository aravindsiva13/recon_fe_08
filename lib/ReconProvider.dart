// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// // ✅ NEW: ReconProvider for 5-Sheet Dashboard
// class ReconProvider extends ChangeNotifier {
//   static const String baseUrl = 'http://localhost:5000';

//   // State management
//   bool _isLoading = false;
//   String? _error;
//   String? _successMessage;

//   // Data storage for all 5 sheets
//   final Map<String, List<Map<String, dynamic>>> _sheetData = {
//     'SUMMARY': [],
//     'RAWDATA': [],
//     'RECON_SUCCESS': [],
//     'RECON_INVESTIGATE': [],
//     'MANUAL_REFUND': [],
//   };

//   // Search states
//   final Map<String, String> _searchQueries = {};

//   // Statistics
//   Map<String, dynamic>? _stats;

//   // Getters
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   String? get successMessage => _successMessage;
//   Map<String, dynamic>? get stats => _stats;

//   List<Map<String, dynamic>>? getSheetData(String sheetId) {
//     return _sheetData[sheetId];
//   }

//   String getSearchQuery(String sheetId) {
//     return _searchQueries[sheetId] ?? '';
//   }

//   // Load all sheets at once
//   Future<void> loadAllSheets() async {
//     _setLoading(true);
//     _clearError();

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/reconciliation/data?sheet=ALL'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(Duration(seconds: 30));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         if (data['status'] == 'success' && data['data'] != null) {
//           final sheetsData = data['data'] as Map<String, dynamic>;

//           // Update each sheet's data
//           for (String sheetId in _sheetData.keys) {
//             if (sheetsData.containsKey(sheetId)) {
//               final sheetInfo = sheetsData[sheetId];
//               if (sheetInfo['data'] != null) {
//                 _sheetData[sheetId] = List<Map<String, dynamic>>.from(
//                     sheetInfo['data']
//                         .map((item) => Map<String, dynamic>.from(item)));
//               }
//             }
//           }

//           _successMessage = 'Successfully loaded ${sheetsData.length} sheets';
//           print('✅ All sheets loaded successfully');
//         } else {
//           throw Exception(data['error'] ?? 'Failed to load sheets data');
//         }
//       } else {
//         throw Exception('HTTP ${response.statusCode}: ${response.body}');
//       }
//     } catch (e) {
//       print('❌ Error loading all sheets: $e');
//       _error = 'Failed to load reconciliation data: ${e.toString()}';
//     } finally {
//       _setLoading(false);
//     }
//   }

//   // Load individual sheet
//   Future<void> loadSheet(String sheetId) async {
//     if (!_sheetData.containsKey(sheetId)) {
//       _error = 'Invalid sheet ID: $sheetId';
//       notifyListeners();
//       return;
//     }

//     _setLoading(true);
//     _clearError();

//     try {
//       final searchQuery = _searchQueries[sheetId] ?? '';
//       final uri = Uri.parse('$baseUrl/api/reconciliation/sheet/$sheetId')
//           .replace(
//               queryParameters:
//                   searchQuery.isNotEmpty ? {'search': searchQuery} : null);

//       final response = await http.get(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(Duration(seconds: 30));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         if (data['status'] == 'success' && data['data'] != null) {
//           _sheetData[sheetId] = List<Map<String, dynamic>>.from(
//               data['data'].map((item) => Map<String, dynamic>.from(item)));

//           _successMessage =
//               'Successfully loaded ${_sheetData[sheetId]!.length} records for $sheetId';
//           print(
//               '✅ Sheet $sheetId loaded: ${_sheetData[sheetId]!.length} records');
//         } else {
//           throw Exception(data['error'] ?? 'Failed to load sheet data');
//         }
//       } else {
//         throw Exception('HTTP ${response.statusCode}: ${response.body}');
//       }
//     } catch (e) {
//       print('❌ Error loading sheet $sheetId: $e');
//       _error = 'Failed to load $sheetId: ${e.toString()}';
//     } finally {
//       _setLoading(false);
//     }
//   }

//   // Search within a specific sheet
//   Future<void> searchSheet(String sheetId, String query) async {
//     if (!_sheetData.containsKey(sheetId)) return;

//     _searchQueries[sheetId] = query;

//     // If query is empty, reload without search
//     if (query.trim().isEmpty) {
//       await loadSheet(sheetId);
//       return;
//     }

//     // Load sheet with search
//     await loadSheet(sheetId);
//   }

//   // Load statistics for all sheets
//   Future<void> loadStats() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/reconciliation/stats'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(Duration(seconds: 15));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         if (data['status'] == 'success' && data['stats'] != null) {
//           _stats = Map<String, dynamic>.from(data['stats']);
//           print('✅ Statistics loaded successfully');
//         }
//       }
//     } catch (e) {
//       print('⚠️ Warning: Failed to load statistics: $e');
//       // Don't set error for stats failure as it's not critical
//     }

//     notifyListeners();
//   }

//   // Refresh all data
//   Future<void> refreshAll() async {
//     await Future.wait([
//       loadAllSheets(),
//       loadStats(),
//     ]);
//   }

//   // Export sheet data
//   Future<void> exportSheet(String sheetId) async {
//     if (!_sheetData.containsKey(sheetId)) {
//       _error = 'Invalid sheet ID for export: $sheetId';
//       notifyListeners();
//       return;
//     }

//     try {
//       final response = await http
//           .post(
//             Uri.parse('$baseUrl/api/reconciliation/export'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode({
//               'format': 'excel',
//               'sheets': [sheetId],
//             }),
//           )
//           .timeout(Duration(seconds: 30));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _successMessage = 'Export completed for $sheetId';
//         print('✅ Export completed for $sheetId');
//       } else {
//         throw Exception('Export failed: HTTP ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error exporting $sheetId: $e');
//       _error = 'Failed to export $sheetId: ${e.toString()}';
//     }

//     notifyListeners();
//   }

//   // Check server health
//   Future<bool> checkServerHealth() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/health'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(Duration(seconds: 5));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['status'] == 'healthy' &&
//             data['database_connected'] == true;
//       }
//       return false;
//     } catch (e) {
//       print('❌ Health check failed: $e');
//       return false;
//     }
//   }

//   // Get sheet summary info
//   Map<String, dynamic> getSheetSummary(String sheetId) {
//     final data = _sheetData[sheetId] ?? [];
//     final stats = _stats?[sheetId] ?? {};

//     return {
//       'recordCount': data.length,
//       'sheetType': _getSheetDescription(sheetId),
//       'lastUpdated': DateTime.now().toIso8601String(),
//       'hasSearch': (_searchQueries[sheetId] ?? '').isNotEmpty,
//       'searchQuery': _searchQueries[sheetId] ?? '',
//       'serverStats': stats,
//     };
//   }

//   String _getSheetDescription(String sheetId) {
//     const descriptions = {
//       'SUMMARY': 'Transaction summary by source and type',
//       'RAWDATA': 'All raw transaction data',
//       'RECON_SUCCESS': 'Perfect reconciliation matches',
//       'RECON_INVESTIGATE': 'Transactions requiring investigation',
//       'MANUAL_REFUND': 'Manual refund transactions',
//     };
//     return descriptions[sheetId] ?? 'Unknown sheet type';
//   }

//   // Calculated properties for dashboard
//   int get totalRecords {
//     return _sheetData.values.fold(0, (sum, sheet) => sum + sheet.length);
//   }

//   int get perfectMatches {
//     return _sheetData['RECON_SUCCESS']?.length ?? 0;
//   }

//   int get investigateCount {
//     return _sheetData['RECON_INVESTIGATE']?.length ?? 0;
//   }

//   int get manualRefunds {
//     return _sheetData['MANUAL_REFUND']?.length ?? 0;
//   }

//   double get successRate {
//     final total = perfectMatches + investigateCount + manualRefunds;
//     return total > 0 ? (perfectMatches / total * 100) : 0.0;
//   }

//   // Get sheet data with filters (for advanced filtering if needed)
//   List<Map<String, dynamic>> getFilteredSheetData(
//     String sheetId, {
//     String? textFilter,
//     Map<String, dynamic>? columnFilters,
//   }) {
//     final data = _sheetData[sheetId] ?? [];

//     if (textFilter == null && columnFilters == null) {
//       return data;
//     }

//     return data.where((row) {
//       // Text filter across all columns
//       if (textFilter != null && textFilter.isNotEmpty) {
//         final searchLower = textFilter.toLowerCase();
//         final rowText = row.values.join(' ').toLowerCase();
//         if (!rowText.contains(searchLower)) {
//           return false;
//         }
//       }

//       // Column-specific filters
//       if (columnFilters != null) {
//         for (final entry in columnFilters.entries) {
//           final columnValue = row[entry.key]?.toString().toLowerCase() ?? '';
//           final filterValue = entry.value.toString().toLowerCase();
//           if (!columnValue.contains(filterValue)) {
//             return false;
//           }
//         }
//       }

//       return true;
//     }).toList();
//   }

//   // Clear methods
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }

//   void clearSuccess() {
//     _successMessage = null;
//     notifyListeners();
//   }

//   void clearAllData() {
//     for (String sheetId in _sheetData.keys) {
//       _sheetData[sheetId] = [];
//     }
//     _searchQueries.clear();
//     _stats = null;
//     _clearError();
//     notifyListeners();
//   }

//   // Private helper methods
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }

//   void _clearError() {
//     _error = null;
//     _successMessage = null;
//   }

//   // Format error message for user display
//   String _formatErrorMessage(String error) {
//     if (error.contains('Network error') ||
//         error.contains('Connection refused')) {
//       return 'Unable to connect to the server. Please check:\n'
//           '• Server is running at $baseUrl\n'
//           '• Network connection is stable';
//     } else if (error.contains('timeout')) {
//       return 'Request timed out. Please try again.';
//     } else if (error.contains('HTTP 4')) {
//       return 'Request error. Please check your input and try again.';
//     } else if (error.contains('HTTP 5')) {
//       return 'Server error. Please try again later.';
//     } else {
//       return 'Error: $error';
//     }
//   }

//   // Debug information
//   Map<String, dynamic> getDebugInfo() {
//     return {
//       'isLoading': _isLoading,
//       'hasError': _error != null,
//       'error': _error,
//       'successMessage': _successMessage,
//       'sheetCounts':
//           _sheetData.map((key, value) => MapEntry(key, value.length)),
//       'searchQueries': _searchQueries,
//       'hasStats': _stats != null,
//       'totalRecords': totalRecords,
//       'serverUrl': baseUrl,
//     };
//   }
// }

//2

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReconProvider extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:5000';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // State management
  bool _isLoading = false;
  String? _error;
  Map<String, bool> _sheetLoadingStates = {};

  // Data storage for all 5 sheets with lazy loading
  final Map<String, List<Map<String, dynamic>>> _sheetData = {
    'SUMMARY': [],
    'RAWDATA': [],
    'RECON_SUCCESS': [],
    'RECON_INVESTIGATE': [],
    'MANUAL_REFUND': [],
  };

  // Cache management
  final Map<String, DateTime> _lastLoadTime = {};
  final Duration _cacheValidityDuration = Duration(minutes: 5);

  // Search states
  final Map<String, String> _searchQueries = {};

  // Statistics
  Map<String, dynamic>? _stats;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;

  List<Map<String, dynamic>>? getSheetData(String sheetId) {
    return _sheetData[sheetId];
  }

  String getSearchQuery(String sheetId) {
    return _searchQueries[sheetId] ?? '';
  }

  bool isSheetLoading(String sheetId) {
    return _sheetLoadingStates[sheetId] ?? false;
  }

  bool isSheetCacheValid(String sheetId) {
    final lastLoad = _lastLoadTime[sheetId];
    if (lastLoad == null) return false;
    return DateTime.now().difference(lastLoad) < _cacheValidityDuration;
  }

  // Load all sheets with optimized approach
  Future<void> loadAllSheets() async {
    _setLoading(true);
    _clearError();

    try {
      // Load summary and success sheets first (usually smaller)
      await Future.wait([
        _loadSheetSilently('SUMMARY'),
        _loadSheetSilently('RECON_SUCCESS'),
      ]);

      // Then load the other sheets
      await Future.wait([
        _loadSheetSilently('RECON_INVESTIGATE'),
        _loadSheetSilently('MANUAL_REFUND'),
      ]);

      // Load RAWDATA last as it's usually the largest
      await _loadSheetSilently('RAWDATA');

      print('✅ All sheets loaded successfully');
    } catch (e) {
      print('❌ Error loading all sheets: $e');
      _error = 'Failed to load reconciliation data: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Load individual sheet with caching
  Future<void> loadSheet(String sheetId) async {
    if (!_sheetData.containsKey(sheetId)) {
      _error = 'Invalid sheet ID: $sheetId';
      notifyListeners();
      return;
    }

    // Check cache validity
    if (isSheetCacheValid(sheetId) && _sheetData[sheetId]!.isNotEmpty) {
      print('📋 Using cached data for $sheetId');
      return;
    }

    _setSheetLoading(sheetId, true);
    _clearError();

    try {
      await _loadSheetSilently(sheetId);
      print('✅ Sheet $sheetId loaded successfully');
    } catch (e) {
      print('❌ Error loading sheet $sheetId: $e');
      _error = 'Failed to load $sheetId: ${e.toString()}';
    } finally {
      _setSheetLoading(sheetId, false);
    }
  }

  // Internal method to load sheet without UI state changes
  Future<void> _loadSheetSilently(String sheetId) async {
    final searchQuery = _searchQueries[sheetId] ?? '';

    // Build URL with parameters
    final uri = Uri.parse('$baseUrl/api/reconciliation/data').replace(
      queryParameters: {
        'sheet': sheetId,
        if (searchQuery.isNotEmpty) 'search': searchQuery,
      },
    );

    print('🔄 Loading sheet: $sheetId from ${uri.toString()}');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Handle different response formats
      List<Map<String, dynamic>> sheetRecords = [];

      if (data is List) {
        // Direct array response
        sheetRecords = List<Map<String, dynamic>>.from(
            data.map((item) => Map<String, dynamic>.from(item)));
      } else if (data is Map && data['data'] != null) {
        // Wrapped response
        if (data['data'] is List) {
          sheetRecords = List<Map<String, dynamic>>.from(
              data['data'].map((item) => Map<String, dynamic>.from(item)));
        }
      }

      // Update data and cache timestamp
      _sheetData[sheetId] = sheetRecords;
      _lastLoadTime[sheetId] = DateTime.now();

      print('📊 Loaded ${sheetRecords.length} records for $sheetId');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  // Search functionality with debouncing
  Timer? _searchTimer;
  void searchSheet(String sheetId, String query) {
    _searchQueries[sheetId] = query;

    // Debounce search requests
    _searchTimer?.cancel();
    _searchTimer = Timer(Duration(milliseconds: 500), () {
      if (query.length >= 2 || query.isEmpty) {
        loadSheet(sheetId);
      }
    });
  }

  // Clear search
  void clearSearch(String sheetId) {
    _searchQueries[sheetId] = '';
    loadSheet(sheetId);
  }

  // Load statistics
  Future<void> loadStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reconciliation/stats'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _stats = data['stats'];
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Failed to load stats: $e');
    }
  }

  // Refresh specific sheet
  Future<void> refreshSheet(String sheetId) async {
    _lastLoadTime.remove(sheetId); // Invalidate cache
    await loadSheet(sheetId);
  }

  // Refresh all data
  Future<void> refreshAll() async {
    _lastLoadTime.clear(); // Invalidate all caches
    _sheetData.forEach((key, value) => value.clear());
    await loadAllSheets();
  }

  // Get sheet summary info
  Map<String, dynamic> getSheetSummary(String sheetId) {
    final data = _sheetData[sheetId] ?? [];
    final lastLoad = _lastLoadTime[sheetId];

    return {
      'record_count': data.length,
      'last_loaded': lastLoad?.toIso8601String(),
      'cache_valid': isSheetCacheValid(sheetId),
      'is_loading': isSheetLoading(sheetId),
    };
  }

  // Get all sheets summary
  Map<String, dynamic> getAllSheetsSummary() {
    return Map.fromEntries(_sheetData.keys
        .map((sheetId) => MapEntry(sheetId, getSheetSummary(sheetId))));
  }

  // State management helpers
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setSheetLoading(String sheetId, bool loading) {
    if (_sheetLoadingStates[sheetId] != loading) {
      _sheetLoadingStates[sheetId] = loading;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearError() {
    _clearError();
  }

  // Cleanup
  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  // Utility methods for filtering (client-side for better performance)
  List<Map<String, dynamic>> filterSheetData(
      String sheetId, Map<String, String> filters) {
    final data = _sheetData[sheetId] ?? [];
    if (filters.isEmpty) return data;

    return data.where((row) {
      return filters.entries.every((filter) {
        final fieldValue = _getFieldValue(row, filter.key, sheetId);
        final filterValue = filter.value.toLowerCase();
        return fieldValue?.toLowerCase().contains(filterValue) ?? false;
      });
    }).toList();
  }

  String? _getFieldValue(
      Map<String, dynamic> row, String filterKey, String sheetId) {
    switch (filterKey) {
      case 'search':
        // Search across multiple fields
        final searchFields = _getSearchFields(sheetId);
        return searchFields
            .map((field) => row[field]?.toString() ?? '')
            .join(' ');
      case 'source':
        return row['txn_source'] ?? row['Txn_Source'];
      case 'type':
        return row['Txn_type'] ?? row['Txn_Type'];
      case 'machine':
        return row['Txn_Machine'];
      case 'refNo':
        return row['Txn_RefNo'];
      case 'mid':
        return row['Txn_MID'];
      case 'remarks':
        return row['Remarks'];
      default:
        return row[filterKey]?.toString();
    }
  }

  List<String> _getSearchFields(String sheetId) {
    switch (sheetId) {
      case 'SUMMARY':
        return ['txn_source', 'Txn_type'];
      case 'RAWDATA':
        return ['Txn_RefNo', 'Txn_Source', 'Txn_Type', 'Txn_Machine'];
      case 'RECON_SUCCESS':
      case 'RECON_INVESTIGATE':
      case 'MANUAL_REFUND':
        return ['Txn_RefNo', 'Txn_Machine', 'Txn_MID', 'Remarks'];
      default:
        return [];
    }
  }

  // Performance monitoring
  void _logPerformance(String operation, Duration duration, int recordCount) {
    print(
        '⚡ $operation: ${duration.inMilliseconds}ms for $recordCount records');

    if (duration.inMilliseconds > 1000) {
      print(
          '⚠️  Slow operation detected: $operation took ${duration.inMilliseconds}ms');
    }
  }
}

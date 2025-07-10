import 'dart:convert';
import 'package:http/http.dart' as http;

// ✅ NEW: Simplified Database Service for 5-Sheet Reconciliation
class ReconDatabaseService {
  static const String baseUrl = 'http://localhost:5000';
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration healthCheckTimeout = Duration(seconds: 5);

  // Available sheet types
  static const List<String> availableSheets = [
    'SUMMARY',
    'RAWDATA',
    'RECON_SUCCESS',
    'RECON_INVESTIGATE',
    'MANUAL_REFUND',
  ];

  // Sheet descriptions
  static const Map<String, String> sheetDescriptions = {
    'SUMMARY': 'Transaction summary by source and type',
    'RAWDATA': 'All raw transaction data',
    'RECON_SUCCESS': 'Perfect reconciliation matches',
    'RECON_INVESTIGATE': 'Transactions requiring investigation',
    'MANUAL_REFUND': 'Manual refund transactions',
  };

  /// Fetch all sheets data at once
  static Future<Map<String, List<Map<String, dynamic>>>>
      fetchAllSheets() async {
    try {
      print('🔄 Fetching all reconciliation sheets...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/reconciliation/data?sheet=ALL'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          final sheetsData = data['data'] as Map<String, dynamic>;
          final result = <String, List<Map<String, dynamic>>>{};

          for (String sheetId in availableSheets) {
            if (sheetsData.containsKey(sheetId)) {
              final sheetInfo = sheetsData[sheetId];
              if (sheetInfo['data'] != null) {
                result[sheetId] = List<Map<String, dynamic>>.from(
                    sheetInfo['data']
                        .map((item) => Map<String, dynamic>.from(item)));
                print('✅ $sheetId: ${result[sheetId]!.length} records');
              }
            }
          }

          print('✅ All sheets loaded successfully');
          return result;
        } else {
          throw Exception(data['error'] ?? 'Invalid response from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching all sheets: $e');
      throw Exception('Failed to fetch reconciliation data: $e');
    }
  }

  /// Fetch specific sheet data
  static Future<List<Map<String, dynamic>>> fetchSheet(
    String sheetId, {
    String? searchQuery,
  }) async {
    try {
      if (!availableSheets.contains(sheetId)) {
        throw Exception('Invalid sheet ID: $sheetId');
      }

      print('🔄 Fetching sheet: $sheetId');

      // Build URL with search query if provided
      final uri = Uri.parse('$baseUrl/api/reconciliation/sheet/$sheetId')
          .replace(
              queryParameters: searchQuery != null && searchQuery.isNotEmpty
                  ? {'search': searchQuery}
                  : null);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          final sheetData = List<Map<String, dynamic>>.from(
              data['data'].map((item) => Map<String, dynamic>.from(item)));

          print('✅ $sheetId loaded: ${sheetData.length} records');
          return sheetData;
        } else {
          throw Exception(data['error'] ?? 'Invalid response from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching sheet $sheetId: $e');
      throw Exception('Failed to fetch $sheetId: $e');
    }
  }

  /// Get statistics for all sheets
  static Future<Map<String, dynamic>> fetchStats() async {
    try {
      print('🔄 Fetching reconciliation statistics...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/reconciliation/stats'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data['stats'] != null) {
          print('✅ Statistics loaded successfully');
          return Map<String, dynamic>.from(data['stats']);
        } else {
          throw Exception(data['error'] ?? 'Invalid stats response');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching statistics: $e');
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  /// Check server health
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(healthCheckTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' &&
            data['database_connected'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  /// Refresh data on server
  static Future<void> refreshServerData() async {
    try {
      print('🔄 Triggering server data refresh...');

      final response = await http.post(
        Uri.parse('$baseUrl/api/reconciliation/refresh'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          print('✅ Server data refreshed successfully');
        } else {
          throw Exception(data['error'] ?? 'Refresh failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error refreshing server data: $e');
      throw Exception('Failed to refresh server data: $e');
    }
  }

  /// Export sheet data
  static Future<Map<String, dynamic>> exportSheets(
    List<String> sheetIds, {
    String format = 'excel',
  }) async {
    try {
      if (sheetIds.any((id) => !availableSheets.contains(id))) {
        throw Exception('One or more invalid sheet IDs provided');
      }

      print('🔄 Exporting sheets: ${sheetIds.join(', ')}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/reconciliation/export'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'format': format,
              'sheets': sheetIds,
            }),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          print('✅ Export completed successfully');
          return Map<String, dynamic>.from(data);
        } else {
          throw Exception(data['error'] ?? 'Export failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error exporting sheets: $e');
      throw Exception('Failed to export sheets: $e');
    }
  }

  /// Get server information
  static Map<String, dynamic> getServerInfo() {
    return {
      'baseUrl': baseUrl,
      'availableSheets': availableSheets,
      'sheetDescriptions': sheetDescriptions,
      'supportedFormats': ['json', 'excel', 'csv'],
      'defaultTimeout': defaultTimeout.inSeconds,
    };
  }

  /// Validate sheet ID
  static bool isValidSheetId(String sheetId) {
    return availableSheets.contains(sheetId.toUpperCase());
  }

  /// Get sheet description
  static String getSheetDescription(String sheetId) {
    return sheetDescriptions[sheetId.toUpperCase()] ?? 'Unknown sheet type';
  }

  /// Format error message for user display
  static String formatErrorMessage(String error) {
    if (error.contains('Network error') ||
        error.contains('Connection refused')) {
      return 'Unable to connect to the server. Please check:\n'
          '• Server is running at $baseUrl\n'
          '• Network connection is stable';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('HTTP 4')) {
      return 'Request error. Please check your input and try again.';
    } else if (error.contains('HTTP 5')) {
      return 'Server error. Please try again later.';
    } else {
      return 'Error: $error';
    }
  }

  /// Get debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'serverUrl': baseUrl,
      'availableSheets': availableSheets,
      'sheetDescriptions': sheetDescriptions,
      'timeout': defaultTimeout.inSeconds,
      'healthCheckTimeout': healthCheckTimeout.inSeconds,
      'endpoints': {
        'allSheets': '$baseUrl/api/reconciliation/data?sheet=ALL',
        'singleSheet': '$baseUrl/api/reconciliation/sheet/{sheetId}',
        'stats': '$baseUrl/api/reconciliation/stats',
        'health': '$baseUrl/api/health',
        'refresh': '$baseUrl/api/reconciliation/refresh',
        'export': '$baseUrl/api/reconciliation/export',
      },
    };
  }

  /// Batch operations helper
  static Future<Map<String, dynamic>> batchOperation(
    List<Future<dynamic>> operations,
  ) async {
    final results = <String, dynamic>{};
    final errors = <String, String>{};

    for (int i = 0; i < operations.length; i++) {
      try {
        final result = await operations[i];
        results['operation_$i'] = result;
      } catch (e) {
        errors['operation_$i'] = e.toString();
      }
    }

    return {
      'results': results,
      'errors': errors,
      'successCount': results.length,
      'errorCount': errors.length,
      'totalOperations': operations.length,
    };
  }

  /// Connection test
  static Future<Map<String, dynamic>> testConnection() async {
    final stopwatch = Stopwatch()..start();

    try {
      final isHealthy = await checkServerHealth();
      stopwatch.stop();

      return {
        'isConnected': isHealthy,
        'responseTime': stopwatch.elapsedMilliseconds,
        'serverUrl': baseUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      stopwatch.stop();

      return {
        'isConnected': false,
        'error': e.toString(),
        'responseTime': stopwatch.elapsedMilliseconds,
        'serverUrl': baseUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

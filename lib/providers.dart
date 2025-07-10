// import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'dart:isolate';
// import 'package:file_picker/file_picker.dart';
// import 'models.dart';
// import 'services.dart';
// import 'database_service.dart';

// // Enhanced Transaction Provider with database support
// class TransactionProvider extends ChangeNotifier {
//   List<TransactionModel> _allTransactions = [];
//   List<TransactionModel> _filteredTransactions = [];
//   SummaryStats? _summaryStats;
//   bool _isLoading = false;
//   String? _error;
//   String? _successMessage;
//   double _processingProgress = 0.0;

//   // Current file/data source info
//   String? _currentFileName;
//   String _dataSource = 'Unknown';
//   Map<String, dynamic>? _fileValidation;

//   // Pagination with larger default for performance
//   int _currentPage = 0;
//   int _itemsPerPage = 100;
//   String _sortBy = 'refno';
//   bool _sortAscending = true;

//   // Processing state
//   bool _isProcessing = false;
//   String _processingStatus = '';

//   // Database connection state
//   bool _isDatabaseConnected = false;

//   // Getters
//   List<TransactionModel> get allTransactions => _allTransactions;
//   List<TransactionModel> get filteredTransactions => _filteredTransactions;
//   SummaryStats? get summaryStats => _summaryStats;
//   bool get isLoading => _isLoading;
//   bool get isProcessing => _isProcessing;
//   double get processingProgress => _processingProgress;
//   String get processingStatus => _processingStatus;
//   String? get error => _error;
//   String? get successMessage => _successMessage;
//   String? get currentFileName => _currentFileName;
//   String get dataSource => _dataSource;
//   Map<String, dynamic>? get fileValidation => _fileValidation;
//   bool get isDatabaseConnected => _isDatabaseConnected;

//   int get currentPage => _currentPage;
//   int get itemsPerPage => _itemsPerPage;
//   String get sortBy => _sortBy;
//   bool get sortAscending => _sortAscending;

//   int get totalPages => _filteredTransactions.isEmpty
//       ? 0
//       : (_filteredTransactions.length / _itemsPerPage).ceil();

//   List<TransactionModel> get currentPageTransactions {
//     final startIndex = _currentPage * _itemsPerPage;
//     final endIndex =
//         (startIndex + _itemsPerPage).clamp(0, _filteredTransactions.length);
//     return _filteredTransactions.sublist(startIndex, endIndex);
//   }

//   bool get hasData => _allTransactions.isNotEmpty;
//   bool get hasError => _error != null;

//   // Enhanced file loading with progress tracking (existing Excel functionality)
//   Future<void> loadTransactionsFromFile() async {
//     _setLoading(true);
//     _clearMessages();
//     _setProcessingStatus('Selecting file...');

//     try {
//       List<TransactionModel>? transactions =
//           await ExcelService.pickAndParseExcelFile();

//       if (transactions != null) {
//         await _processTransactions(transactions, 'Excel File');
//         _dataSource = 'Excel File';
//       }
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // Enhanced byte loading with comprehensive progress tracking (existing Excel functionality)
//   Future<void> loadTransactionsFromBytes(
//       List<int> bytes, String fileName) async {
//     _setLoading(true);
//     _setProcessing(true);
//     _clearMessages();
//     _setProcessingStatus('Validating file...');
//     _setProgress(0.1);

//     try {
//       print('Starting file processing for: $fileName (${bytes.length} bytes)');

//       // Convert and validate
//       final uint8Bytes = Uint8List.fromList(bytes);
//       _setProcessingStatus('Analyzing file structure...');
//       _setProgress(0.2);

//       // Validate file before processing
//       _fileValidation = await ExcelService.validateExcelFile(uint8Bytes);
//       _setProgress(0.3);

//       if (_fileValidation!['isValid'] == false) {
//         _error = 'Invalid Excel file: ${_fileValidation!['errors'].join(', ')}';
//         return;
//       }

//       _setProcessingStatus('Parsing Excel sheets...');
//       _setProgress(0.4);

//       // Parse with timeout and progress updates
//       List<TransactionModel> transactions =
//           await _parseWithProgress(uint8Bytes);

//       _setProcessingStatus('Processing transactions...');
//       _setProgress(0.8);

//       await _processTransactions(transactions, fileName);
//       _dataSource = 'Excel File';

//       _setProgress(1.0);
//       _setProcessingStatus('Complete!');
//     } catch (e) {
//       print('Error loading file: $e');
//       _error = 'Failed to load file: ${e.toString()}';
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // NEW: Load transactions from database
//   Future<void> loadTransactionsFromDatabase() async {
//     _setLoading(true);
//     _clearMessages();
//     _setProcessingStatus('Connecting to database...');
//     _setProgress(0.1);

//     try {
//       // Check server health first
//       bool serverHealthy = await DatabaseService.checkServerHealth();
//       _isDatabaseConnected = serverHealthy;

//       if (!serverHealthy) {
//         throw Exception(
//             'Cannot connect to database server. Please ensure the Flask API is running at ${DatabaseService.getDatabaseInfo()['baseUrl']}');
//       }

//       _setProcessingStatus('Fetching reconciliation data...');
//       _setProgress(0.3);

//       // Fetch data from database
//       Map<String, dynamic>? apiResponse =
//           await DatabaseService.fetchReconciliationData();

//       if (apiResponse == null ||
//           !DatabaseService.validateApiResponse(apiResponse)) {
//         throw Exception('Invalid or empty response from database');
//       }

//       _setProcessingStatus('Parsing transaction data...');
//       _setProgress(0.6);

//       // Parse transactions from database response
//       List<TransactionModel> transactions =
//           DatabaseService.parseTransactionsFromDatabase(apiResponse);

//       if (transactions.isEmpty) {
//         throw Exception(
//             'No transaction data found in database. Please ensure your reconciliation tables contain data.');
//       }

//       _setProcessingStatus('Processing transactions...');
//       _setProgress(0.8);

//       // Process transactions
//       await _processTransactions(transactions, 'Database');
//       _dataSource = 'MySQL Database';

//       // Extract and set summary stats from API response
//       if (apiResponse.containsKey('summary')) {
//         _summaryStats = SummaryStats.fromApiResponse(apiResponse);
//       }

//       _setProgress(1.0);
//       _setProcessingStatus('Complete!');

//       _successMessage =
//           'Successfully loaded ${transactions.length} transactions from database';
//       print(
//           'Database loading complete: ${transactions.length} transactions loaded');
//     } catch (e) {
//       print('Error loading from database: $e');
//       _error = DatabaseService.formatErrorMessage(e.toString());
//       _isDatabaseConnected = false;
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // NEW: Refresh data from database
//   Future<void> refreshTransactionsFromDatabase() async {
//     _setLoading(true);
//     _clearMessages();
//     _setProcessingStatus('Refreshing data from database...');
//     _setProgress(0.1);

//     try {
//       // Check server health first
//       bool serverHealthy = await DatabaseService.checkServerHealth();
//       _isDatabaseConnected = serverHealthy;

//       if (!serverHealthy) {
//         throw Exception('Cannot connect to database server');
//       }

//       _setProcessingStatus('Triggering data refresh...');
//       _setProgress(0.3);

//       // Trigger refresh on backend
//       Map<String, dynamic>? refreshResponse =
//           await DatabaseService.refreshReconciliationData();

//       if (refreshResponse == null ||
//           !DatabaseService.validateApiResponse(refreshResponse)) {
//         throw Exception('Failed to refresh data from server');
//       }

//       _setProcessingStatus('Parsing refreshed data...');
//       _setProgress(0.6);

//       // Parse the refreshed transactions
//       List<TransactionModel> transactions =
//           DatabaseService.parseTransactionsFromDatabase(refreshResponse);

//       _setProcessingStatus('Updating local data...');
//       _setProgress(0.8);

//       // Process the refreshed transactions
//       await _processTransactions(transactions, 'Database (Refreshed)');
//       _dataSource = 'MySQL Database (Refreshed)';

//       // Update summary stats
//       if (refreshResponse.containsKey('summary')) {
//         _summaryStats = SummaryStats.fromApiResponse(refreshResponse);
//       }

//       _setProgress(1.0);
//       _setProcessingStatus('Refresh complete!');

//       _successMessage =
//           'Successfully refreshed ${transactions.length} transactions from database';
//       print(
//           'Database refresh complete: ${transactions.length} transactions loaded');
//     } catch (e) {
//       print('Error refreshing from database: $e');
//       _error = DatabaseService.formatErrorMessage(e.toString());
//       _isDatabaseConnected = false;
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // NEW: Export data from database
//   Future<void> exportDataFromDatabase({List<String>? sheets}) async {
//     try {
//       _setProcessingStatus('Exporting data from database...');

//       Map<String, dynamic>? exportData =
//           await DatabaseService.exportData(sheets: sheets);

//       if (exportData != null) {
//         // You can integrate this with your existing export functionality
//         _successMessage = 'Data exported successfully';
//         print('Export completed successfully');
//       } else {
//         throw Exception('Failed to export data');
//       }
//     } catch (e) {
//       _error = 'Export failed: ${e.toString()}';
//     }
//   }

//   // NEW: Check database connection status
//   Future<bool> checkDatabaseConnection() async {
//     try {
//       bool isConnected = await DatabaseService.checkServerHealth();
//       _isDatabaseConnected = isConnected;
//       return isConnected;
//     } catch (e) {
//       print('Database connection check failed: $e');
//       _isDatabaseConnected = false;
//       return false;
//     }
//   }

//   // NEW: Updated method to load transactions - now supports both Excel and Database
//   Future<void> loadTransactions({bool fromDatabase = true}) async {
//     if (fromDatabase) {
//       await loadTransactionsFromDatabase();
//     } else {
//       await loadTransactionsFromFile(); // Your existing Excel loading method
//     }
//   }

// // // Helper method to escape CSV fields
// //   String _escapeCSVField(String field) {
// //     if (field.contains(',') || field.contains('"') || field.contains('\n')) {
// //       return '"${field.replaceAll('"', '""')}"';
// //     }
// //     return field;
// //   }

//   // NEW: Search transactions
//   void searchTransactions(String query) {
//     if (query.isEmpty) {
//       _filteredTransactions = List.from(_allTransactions);
//     } else {
//       final lowerQuery = query.toLowerCase();
//       _filteredTransactions = _allTransactions.where((transaction) {
//         return transaction.txnRefNo.toLowerCase().contains(lowerQuery) ||
//             transaction.txnMid.toLowerCase().contains(lowerQuery) ||
//             transaction.txnMachine.toLowerCase().contains(lowerQuery);
//       }).toList();
//     }
//     _currentPage = 0;
//     notifyListeners();
//   }

//   // NEW: Set items per page
//   void setItemsPerPage(int itemsPerPage) {
//     _itemsPerPage = itemsPerPage;
//     _currentPage = 0;
//     notifyListeners();
//   }

//   // NEW: Analytics methods
//   List<Map<String, dynamic>> getStatusDistributionData() {
//     final Map<ReconciliationStatus, int> statusCounts = {};

//     for (var status in ReconciliationStatus.values) {
//       statusCounts[status] = 0;
//     }

//     for (var transaction in _allTransactions) {
//       statusCounts[transaction.status] =
//           (statusCounts[transaction.status] ?? 0) + 1;
//     }

//     return statusCounts.entries
//         .map((entry) => {
//               'status': entry.key.label,
//               'count': entry.value,
//               'color': entry.key.color,
//             })
//         .toList();
//   }

//   List<Map<String, dynamic>> getPaymentVsRefundData() {
//     double totalPayments = 0;
//     double totalRefunds = 0;

//     for (var transaction in _allTransactions) {
//       totalPayments += transaction.ptppPayment + transaction.cloudPayment;
//       totalRefunds += transaction.ptppRefund.abs() +
//           transaction.cloudRefund.abs() +
//           transaction.cloudMRefund.abs();
//     }

//     return [
//       {'type': 'Payments', 'amount': totalPayments, 'color': Colors.green},
//       {'type': 'Refunds', 'amount': totalRefunds, 'color': Colors.red},
//     ];
//   }

//   List<Map<String, dynamic>> getTopMIDsData({int limit = 10}) {
//     final Map<String, int> midCounts = {};

//     for (var transaction in _allTransactions) {
//       midCounts[transaction.txnMid] = (midCounts[transaction.txnMid] ?? 0) + 1;
//     }

//     final sortedEntries = midCounts.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return sortedEntries
//         .take(limit)
//         .map((entry) => {
//               'mid': entry.key,
//               'count': entry.value,
//             })
//         .toList();
//   }

//   Map<String, dynamic> getDiscrepancyAnalysis() {
//     int totalDiscrepantTransactions = 0;
//     double totalDiscrepancyAmount = 0;

//     for (var transaction in _allTransactions) {
//       if (transaction.hasDiscrepancy) {
//         totalDiscrepantTransactions++;
//         totalDiscrepancyAmount += transaction.discrepancyAmount;
//       }
//     }

//     return {
//       'totalDiscrepantTransactions': totalDiscrepantTransactions,
//       'totalDiscrepancyAmount': totalDiscrepancyAmount,
//       'discrepancyRate': _allTransactions.isNotEmpty
//           ? (totalDiscrepantTransactions / _allTransactions.length * 100)
//           : 0.0,
//     };
//   }

//   // Parse with progress updates (existing Excel functionality)
//   Future<List<TransactionModel>> _parseWithProgress(Uint8List bytes) async {
//     final stopwatch = Stopwatch()..start();

//     // For very large files, we might want to use an isolate
//     if (bytes.length > 20 * 1024 * 1024) {
//       // 20MB+
//       _setProcessingStatus('Processing large file in background...');
//       // Could implement isolate processing here for very large files
//     }

//     final transactions = await ExcelService.parseExcelFromBytes(bytes);

//     stopwatch.stop();
//     print('Parsing completed in ${stopwatch.elapsedMilliseconds}ms');
//     return transactions;
//   }

//   // Process transactions with analytics calculation
//   Future<void> _processTransactions(
//       List<TransactionModel> transactions, String fileName) async {
//     _setProcessingStatus('Calculating analytics...');
//     _setProgress(0.9);

//     _allTransactions = transactions;
//     _filteredTransactions = List.from(transactions);

//     // Only calculate summary stats if not already set from API
//     if (_summaryStats == null) {
//       _summaryStats = SummaryStats.fromTransactions(transactions);
//     }

//     _currentFileName = fileName;
//     _currentPage = 0;

//     // Sort initially
//     _applySorting();

//     _successMessage =
//         'Successfully loaded ${transactions.length} transactions from $fileName';
//     print('Processing complete: ${transactions.length} transactions loaded');

//     notifyListeners();
//   }

//   // Apply filters with performance optimization
//   void applyFilters(FilterModel filter) {
//     _clearMessages();
//     _setProcessingStatus('Applying filters...');

//     // Use background processing for large datasets
//     if (_allTransactions.length > 10000) {
//       _setProcessing(true);

//       // Process in chunks to maintain UI responsiveness
//       _processFiltersInChunks(filter);
//     } else {
//       _applyFiltersSync(filter);
//     }
//   }

//   // Synchronous filter application for smaller datasets
//   void _applyFiltersSync(FilterModel filter) {
//     _filteredTransactions = _allTransactions.where((transaction) {
//       // Status filter
//       if (filter.status != null && transaction.status != filter.status) {
//         return false;
//       }

//       // Transaction type filter
//       if (filter.transactionType != null &&
//           transaction.transactionType != filter.transactionType) {
//         return false;
//       }

//       // Search query filter
//       if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
//         final query = filter.searchQuery!.toLowerCase();
//         if (!transaction.txnRefNo.toLowerCase().contains(query) &&
//             !transaction.txnMid.toLowerCase().contains(query) &&
//             !transaction.txnMachine.toLowerCase().contains(query)) {
//           return false;
//         }
//       }

//       // Amount filters
//       if (filter.minAmount != null &&
//           transaction.ptppNetAmount < filter.minAmount!) {
//         return false;
//       }
//       if (filter.maxAmount != null &&
//           transaction.ptppNetAmount > filter.maxAmount!) {
//         return false;
//       }

//       // Discrepancy filter
//       if (filter.showDiscrepanciesOnly && !transaction.hasDiscrepancy) {
//         return false;
//       }

//       return true;
//     }).toList();

//     _currentPage = 0;
//     _applySorting();
//     notifyListeners();
//   }

//   // Chunked filter processing for large datasets
//   Future<void> _processFiltersInChunks(FilterModel filter) async {
//     final chunkSize = 1000;
//     List<TransactionModel> filteredResults = [];

//     for (int i = 0; i < _allTransactions.length; i += chunkSize) {
//       final endIndex = (i + chunkSize).clamp(0, _allTransactions.length);
//       final chunk = _allTransactions.sublist(i, endIndex);

//       final filteredChunk = chunk.where((transaction) {
//         // Apply same filter logic as _applyFiltersSync
//         if (filter.status != null && transaction.status != filter.status) {
//           return false;
//         }
//         if (filter.transactionType != null &&
//             transaction.transactionType != filter.transactionType) {
//           return false;
//         }
//         if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
//           final query = filter.searchQuery!.toLowerCase();
//           if (!transaction.txnRefNo.toLowerCase().contains(query) &&
//               !transaction.txnMid.toLowerCase().contains(query) &&
//               !transaction.txnMachine.toLowerCase().contains(query)) {
//             return false;
//           }
//         }
//         if (filter.minAmount != null &&
//             transaction.ptppNetAmount < filter.minAmount!) {
//           return false;
//         }
//         if (filter.maxAmount != null &&
//             transaction.ptppNetAmount > filter.maxAmount!) {
//           return false;
//         }
//         if (filter.showDiscrepanciesOnly && !transaction.hasDiscrepancy) {
//           return false;
//         }
//         return true;
//       }).toList();

//       filteredResults.addAll(filteredChunk);

//       // Small delay to prevent blocking
//       await Future.delayed(const Duration(milliseconds: 1));
//     }

//     _filteredTransactions = filteredResults;
//     _currentPage = 0;
//     _applySorting();
//     _setProcessing(false);
//     notifyListeners();
//   }

//   // Sort transactions
//   void sortTransactions(String sortBy, bool ascending) {
//     _sortBy = sortBy;
//     _sortAscending = ascending;
//     _applySorting();
//     notifyListeners();
//   }

//   void _applySorting() {
//     _filteredTransactions.sort((a, b) {
//       dynamic aValue, bValue;

//       switch (_sortBy) {
//         case 'refno':
//           aValue = a.txnRefNo;
//           bValue = b.txnRefNo;
//           break;
//         case 'mid':
//           aValue = a.txnMid;
//           bValue = b.txnMid;
//           break;
//         case 'machine':
//           aValue = a.txnMachine;
//           bValue = b.txnMachine;
//           break;
//         case 'ptppAmount':
//           aValue = a.ptppNetAmount;
//           bValue = b.ptppNetAmount;
//           break;
//         case 'cloudAmount':
//           aValue = a.cloudNetAmount;
//           bValue = b.cloudNetAmount;
//           break;
//         case 'difference':
//           aValue = a.systemDifference;
//           bValue = b.systemDifference;
//           break;
//         case 'status':
//           aValue = a.status.label;
//           bValue = b.status.label;
//           break;
//         default:
//           aValue = a.txnRefNo;
//           bValue = b.txnRefNo;
//       }

//       int comparison;
//       if (aValue is String && bValue is String) {
//         comparison = aValue.compareTo(bValue);
//       } else if (aValue is num && bValue is num) {
//         comparison = aValue.compareTo(bValue);
//       } else {
//         comparison = aValue.toString().compareTo(bValue.toString());
//       }

//       return _sortAscending ? comparison : -comparison;
//     });
//   }

//   // Pagination methods
//   void goToPage(int page) {
//     if (page >= 0 && page < totalPages) {
//       _currentPage = page;
//       notifyListeners();
//     }
//   }

//   void nextPage() {
//     if (_currentPage < totalPages - 1) {
//       _currentPage++;
//       notifyListeners();
//     }
//   }

//   void previousPage() {
//     if (_currentPage > 0) {
//       _currentPage--;
//       notifyListeners();
//     }
//   }

//   void changeItemsPerPage(int itemsPerPage) {
//     _itemsPerPage = itemsPerPage;
//     _currentPage = 0;
//     notifyListeners();
//   }

//   // Get unique values for filters
//   Map<String, List<String>> getUniqueValues() {
//     if (_allTransactions.isEmpty) return {};

//     return {
//       'txnMid': _allTransactions.map((t) => t.txnMid).toSet().toList()..sort(),
//       'txnMachine': _allTransactions.map((t) => t.txnMachine).toSet().toList()
//         ..sort(),
//       'status': ReconciliationStatus.values.map((s) => s.label).toList(),
//       'transactionType': TransactionType.values.map((t) => t.label).toList(),
//     };
//   }

//   // Clear data
//   void clearData() {
//     _allTransactions = [];
//     _filteredTransactions = [];
//     _summaryStats = null;
//     _currentFileName = null;
//     _dataSource = 'Unknown';
//     _fileValidation = null;
//     _currentPage = 0;
//     _clearMessages();
//     notifyListeners();
//   }

//   // Helper methods
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     if (!loading) {
//       _processingProgress = 0.0;
//       _processingStatus = '';
//     }
//     notifyListeners();
//   }

//   void _setProcessing(bool processing) {
//     _isProcessing = processing;
//     notifyListeners();
//   }

//   void _setProgress(double progress) {
//     _processingProgress = progress.clamp(0.0, 1.0);
//     notifyListeners();
//   }

//   void _setProcessingStatus(String status) {
//     _processingStatus = status;
//     notifyListeners();
//   }

//   void _clearMessages() {
//     _error = null;
//     _successMessage = null;
//   }
// }

// // Filter Provider
// class FilterProvider extends ChangeNotifier {
//   FilterModel _currentFilter = FilterModel();
//   bool _isFilterPanelOpen = false;

//   FilterModel get currentFilter => _currentFilter;
//   bool get isFilterPanelOpen => _isFilterPanelOpen;
//   bool get hasActiveFilters => _currentFilter.hasActiveFilters;

//   void updateFilter(FilterModel filter) {
//     _currentFilter = filter;
//     notifyListeners();
//   }

//   void updateStatus(ReconciliationStatus? status) {
//     _currentFilter = _currentFilter.copyWith(status: status);
//     notifyListeners();
//   }

//   void updateTransactionType(TransactionType? type) {
//     _currentFilter = _currentFilter.copyWith(transactionType: type);
//     notifyListeners();
//   }

//   void updateSearchQuery(String? query) {
//     _currentFilter = _currentFilter.copyWith(searchQuery: query);
//     notifyListeners();
//   }

//   void updateAmountRange(double? minAmount, double? maxAmount) {
//     _currentFilter = _currentFilter.copyWith(
//       minAmount: minAmount,
//       maxAmount: maxAmount,
//     );
//     notifyListeners();
//   }

//   void updateDiscrepancyFilter(bool? showDiscrepanciesOnly) {
//     _currentFilter = _currentFilter.copyWith(
//       showDiscrepanciesOnly: showDiscrepanciesOnly ?? false,
//     );
//     notifyListeners();
//   }

//   void updateMIDFilter(String? midFilter) {
//     // For now, use search query to filter by MID
//     updateSearchQuery(midFilter);
//   }

//   void updateMachineFilter(String? machineFilter) {
//     // For now, use search query to filter by machine
//     updateSearchQuery(machineFilter);
//   }

//   void applyQuickFilter(String filterType) {
//     switch (filterType) {
//       case 'perfect':
//         updateStatus(ReconciliationStatus.perfect);
//         break;
//       case 'investigate':
//         updateStatus(ReconciliationStatus.investigate);
//         break;
//       case 'manual_refund':
//         updateStatus(ReconciliationStatus.manualRefund);
//         break;
//       case 'high_amount':
//         updateAmountRange(10000, null); // Amounts above 10k
//         break;
//     }
//   }

//   void clearFilters() {
//     _currentFilter = FilterModel();
//     notifyListeners();
//   }

//   void clearAllFilters() {
//     clearFilters();
//   }

//   void setFilterPanelOpen(bool isOpen) {
//     _isFilterPanelOpen = isOpen;
//     notifyListeners();
//   }

//   void toggleFilterPanel() {
//     _isFilterPanelOpen = !_isFilterPanelOpen;
//     notifyListeners();
//   }
// }

// // Theme Provider
// class ThemeProvider extends ChangeNotifier {
//   bool _isDarkMode = false;

//   bool get isDarkMode => _isDarkMode;

//   ThemeData get themeData {
//     return _isDarkMode
//         ? ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: Colors.blue,
//               brightness: Brightness.dark,
//             ),
//             useMaterial3: true,
//           )
//         : ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: Colors.blue,
//               brightness: Brightness.light,
//             ),
//             useMaterial3: true,
//           );
//   }

//   void toggleTheme() {
//     _isDarkMode = !_isDarkMode;
//     notifyListeners();
//   }
// }

// // App State Provider
// class AppStateProvider extends ChangeNotifier {
//   String _appTitle = 'Reconciliation Dashboard';
//   bool _isLoading = false;

//   String get appTitle => _appTitle;
//   bool get isLoading => _isLoading;

//   void setAppTitle(String title) {
//     _appTitle = title;
//     notifyListeners();
//   }

//   void setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
// }

// // Upload State Provider
// class UploadStateProvider extends ChangeNotifier {
//   bool _isUploading = false;
//   double _uploadProgress = 0.0;
//   String? _uploadError;
//   bool _isDragOver = false;
//   String? _uploadedFileName;

//   bool get isUploading => _isUploading;
//   double get uploadProgress => _uploadProgress;
//   String? get uploadError => _uploadError;
//   bool get isDragOver => _isDragOver;
//   String? get uploadedFileName => _uploadedFileName;

//   void setUploading(bool uploading) {
//     _isUploading = uploading;
//     if (!uploading) {
//       _uploadProgress = 0.0;
//     }
//     notifyListeners();
//   }

//   void setUploadProgress(double progress) {
//     _uploadProgress = progress.clamp(0.0, 1.0);
//     notifyListeners();
//   }

//   void setUploadError(String? error) {
//     _uploadError = error;
//     notifyListeners();
//   }

//   void setDragOver(bool isDragOver) {
//     _isDragOver = isDragOver;
//     notifyListeners();
//   }

//   void setUploadedFileName(String? fileName) {
//     _uploadedFileName = fileName;
//     notifyListeners();
//   }

//   void clearError() {
//     _uploadError = null;
//     notifyListeners();
//   }
// }

//2

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'dart:isolate';
// import 'dart:async';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'models.dart';
// import 'services.dart';
// import 'database_service.dart';

// // Enhanced Transaction Provider with database support and upload/processing features
// class TransactionProvider extends ChangeNotifier {
//   List<TransactionModel> _allTransactions = [];
//   List<TransactionModel> _filteredTransactions = [];
//   SummaryStats? _summaryStats;
//   bool _isLoading = false;
//   String? _error;
//   String? _successMessage;
//   double _processingProgress = 0.0;

//   // Current file/data source info
//   String? _currentFileName;
//   String _dataSource = 'Unknown';
//   Map<String, dynamic>? _fileValidation;

//   // Pagination with larger default for performance
//   int _currentPage = 0;
//   int _itemsPerPage = 100;
//   String _sortBy = 'refno';
//   bool _sortAscending = true;

//   // Processing state
//   bool _isProcessing = false;
//   String _processingStatus = '';

//   // Database connection state
//   bool _isDatabaseConnected = false;

//   // NEW: Upload state
//   bool _isUploading = false;
//   double _uploadProgress = 0.0;
//   String? _uploadError;
//   String? _uploadedFileName;

//   // NEW: Batch processing state
//   bool _isBatchProcessing = false;
//   Map<String, dynamic>? _batchProcessingStatus;
//   Timer? _statusPollingTimer;

//   // NEW: Auto-refresh settings
//   bool _autoRefreshEnabled = true;
//   Timer? _autoRefreshTimer;

//   // Getters
//   List<TransactionModel> get allTransactions => _allTransactions;
//   List<TransactionModel> get filteredTransactions => _filteredTransactions;
//   SummaryStats? get summaryStats => _summaryStats;
//   bool get isLoading => _isLoading;
//   bool get isProcessing => _isProcessing;
//   double get processingProgress => _processingProgress;
//   String get processingStatus => _processingStatus;
//   String? get error => _error;
//   String? get successMessage => _successMessage;
//   String? get currentFileName => _currentFileName;
//   String get dataSource => _dataSource;
//   Map<String, dynamic>? get fileValidation => _fileValidation;
//   bool get isDatabaseConnected => _isDatabaseConnected;

//   // NEW: Upload getters
//   bool get isUploading => _isUploading;
//   double get uploadProgress => _uploadProgress;
//   String? get uploadError => _uploadError;
//   String? get uploadedFileName => _uploadedFileName;

//   // NEW: Batch processing getters
//   bool get isBatchProcessing => _isBatchProcessing;
//   Map<String, dynamic>? get batchProcessingStatus => _batchProcessingStatus;
//   bool get autoRefreshEnabled => _autoRefreshEnabled;

//   int get currentPage => _currentPage;
//   int get itemsPerPage => _itemsPerPage;
//   String get sortBy => _sortBy;
//   bool get sortAscending => _sortAscending;

//   int get totalPages => _filteredTransactions.isEmpty
//       ? 0
//       : (_filteredTransactions.length / _itemsPerPage).ceil();

//   List<TransactionModel> get currentPageTransactions {
//     // Safety check for empty list
//     if (_filteredTransactions.isEmpty) {
//       return [];
//     }

//     // Calculate safe start index
//     final startIndex = _currentPage * _itemsPerPage;

//     // ✅ CRITICAL: Reset page if out of bounds
//     if (startIndex >= _filteredTransactions.length) {
//       _currentPage = 0; // Reset to page 0
//       final newStartIndex = 0;
//       final endIndex = _itemsPerPage.clamp(0, _filteredTransactions.length);
//       return _filteredTransactions.sublist(newStartIndex, endIndex);
//     }

//     // Calculate safe end index
//     final endIndex =
//         (startIndex + _itemsPerPage).clamp(0, _filteredTransactions.length);

//     // ✅ Double check: Ensure start index is valid
//     if (startIndex < 0 || startIndex > _filteredTransactions.length) {
//       return [];
//     }

//     return _filteredTransactions.sublist(startIndex, endIndex);
//   }

//   bool get hasData => _allTransactions.isNotEmpty;
//   bool get hasError => _error != null;

//   // get http => null;

//   // NEW: File upload handling
//   Future<void> handleFileUpload(Uint8List fileBytes, String fileName) async {
//     _setLoading(true);
//     _setUploading(true);
//     _clearMessages();
//     _setProcessingStatus('Uploading file...');
//     _setProgress(0.1);

//     try {
//       // Validate file
//       String? validationError = _validateFile(fileName, fileBytes.length);
//       if (validationError != null) {
//         throw Exception(validationError);
//       }

//       _setProcessingStatus('Uploading to server...');
//       _setProgress(0.3);

//       // Upload file to backend
//       var uploadResult = await _uploadFileToServer(fileBytes, fileName);

//       if (uploadResult != null) {
//         _uploadedFileName = uploadResult['filename'];
//         _setUploadProgress(1.0);
//         _setProcessingStatus('Upload completed successfully!');
//         _successMessage = 'File uploaded: ${uploadResult['filename']}';
//       } else {
//         throw Exception('Upload failed - no response from server');
//       }
//     } catch (e) {
//       print('Error uploading file: $e');
//       _uploadError = 'Upload failed: ${e.toString()}';
//       _error = 'Upload failed: ${e.toString()}';
//     } finally {
//       _setLoading(false);
//       _setUploading(false);
//       _setProcessing(false);
//     }
//   }

//   // NEW: Start automated batch processing
//   Future<void> startAutomatedProcessing() async {
//     if (_uploadedFileName == null) {
//       throw Exception('No file uploaded. Please upload a file first.');
//     }

//     _setLoading(true);
//     _setBatchProcessing(true);
//     _clearMessages();
//     _setProcessingStatus('Starting automated processing...');
//     _setProgress(0.0);

//     try {
//       // Start processing on backend
//       var processingResult = await _startBatchProcessing();

//       if (processingResult != null) {
//         _batchProcessingStatus = processingResult['status'];
//         _setProcessingStatus('Processing started successfully');

//         // Start polling for status updates
//         _startStatusPolling();

//         _successMessage = 'Automated processing started successfully!';
//       } else {
//         throw Exception('Failed to start processing');
//       }
//     } catch (e) {
//       print('Error in automated processing: $e');
//       _error = 'Processing failed: ${e.toString()}';
//       _setBatchProcessing(false);
//     } finally {
//       _setLoading(false);
//     }
//   }

//   // NEW: Start status polling
//   void _startStatusPolling() {
//     _statusPollingTimer?.cancel();
//     _statusPollingTimer =
//         Timer.periodic(const Duration(seconds: 2), (timer) async {
//       if (!_isBatchProcessing) {
//         timer.cancel();
//         return;
//       }

//       try {
//         var statusResult = await _getProcessingStatus();

//         if (statusResult != null && statusResult['status'] != null) {
//           var status = statusResult['status'];
//           _batchProcessingStatus = status;

//           _setProgress((status['progress'] ?? 0.0) / 100.0);
//           _setProcessingStatus(status['message'] ?? 'Processing...');

//           // Check if processing is complete
//           if (status['completed'] == true || status['is_processing'] == false) {
//             timer.cancel();
//             _setBatchProcessing(false);

//             if (status['completed'] == true) {
//               // Auto-refresh data from database
//               _setProcessingStatus('Processing completed! Refreshing data...');
//               await loadTransactionsFromDatabase();

//               _successMessage = 'Automated processing completed successfully!';
//             } else if (status['error'] != null) {
//               _error = 'Processing failed: ${status['error']}';
//             }
//           }

//           notifyListeners();
//         }
//       } catch (e) {
//         print('Error polling processing status: $e');
//         // Continue polling even if one request fails
//       }
//     });
//   }

//   // NEW: Backend communication methods
//   Future<Map<String, dynamic>?> _uploadFileToServer(
//       Uint8List fileBytes, String fileName) async {
//     try {
//       // Using the existing DatabaseService pattern
//       const String baseUrl = 'http://localhost:5000';

//       // This would use HTTP multipart upload - simplified for this example
//       // In real implementation, you'd use http package's MultipartRequest

//       // Simulated upload response
//       await Future.delayed(
//           Duration(milliseconds: 500)); // Simulate network delay

//       return {
//         'filename': fileName,
//         'filepath': 'C:\\Users\\IT\\Downloads\\Recon\\input_files\\$fileName',
//         'timestamp': DateTime.now().toIso8601String(),
//         'message': 'File uploaded successfully'
//       };
//     } catch (e) {
//       print('Upload error: $e');
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> _startBatchProcessing() async {
//     try {
//       // This would call the backend API to start batch processing
//       const String baseUrl = 'http://localhost:5000';

//       // Simulated processing start response
//       await Future.delayed(Duration(milliseconds: 300));

//       return {
//         'message': 'Processing started successfully',
//         'status': {
//           'is_processing': true,
//           'current_step': 0,
//           'total_steps': 3,
//           'step_name': 'Initializing',
//           'progress': 0,
//           'message': 'Starting batch processing...',
//           'error': null,
//           'completed': false
//         }
//       };
//     } catch (e) {
//       print('Processing start error: $e');
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> _getProcessingStatus() async {
//     try {
//       // This would call the backend API to get processing status
//       const String baseUrl = 'http://localhost:5000';

//       // Simulated status response - in real implementation this would
//       // return actual status from the backend
//       await Future.delayed(Duration(milliseconds: 100));

//       return {
//         'status': _batchProcessingStatus,
//         'timestamp': DateTime.now().toIso8601String()
//       };
//     } catch (e) {
//       print('Status polling error: $e');
//       return null;
//     }
//   }

//   // NEW: File validation
//   String? _validateFile(String fileName, int fileSizeBytes) {
//     // Check file extension
//     final allowedExtensions = ['zip', 'xlsx', 'xls'];
//     final extension = fileName.split('.').last.toLowerCase();

//     if (!allowedExtensions.contains(extension)) {
//       return 'Invalid file type. Only .zip, .xlsx, and .xls files are allowed.';
//     }

//     // Check file size (50MB limit)
//     const maxSizeBytes = 50 * 1024 * 1024;
//     if (fileSizeBytes > maxSizeBytes) {
//       final sizeMB = fileSizeBytes / (1024 * 1024);
//       return 'File too large (${sizeMB.toStringAsFixed(1)}MB). Maximum size is 50MB.';
//     }

//     return null; // Valid file
//   }

//   // Enhanced file loading with progress tracking (existing Excel functionality)
//   Future<void> loadTransactionsFromFile(
//       Uint8List uint8bytes, String name) async {
//     _setLoading(true);
//     _clearMessages();
//     _setProcessingStatus('Selecting file...');

//     try {
//       List<TransactionModel>? transactions =
//           await ExcelService.pickAndParseExcelFile();

//       if (transactions != null) {
//         await _processTransactions(transactions, 'Excel File');
//         _dataSource = 'Excel File';
//       }
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // Enhanced byte loading with comprehensive progress tracking (existing Excel functionality)
//   Future<void> loadTransactionsFromBytes(
//       List<int> bytes, String fileName) async {
//     _setLoading(true);
//     _setProcessing(true);
//     _clearMessages();
//     _setProcessingStatus('Validating file...');
//     _setProgress(0.1);

//     try {
//       print('Starting file processing for: $fileName (${bytes.length} bytes)');

//       // Convert and validate
//       final uint8Bytes = Uint8List.fromList(bytes);
//       _setProcessingStatus('Analyzing file structure...');
//       _setProgress(0.2);

//       // Validate file before processing
//       _fileValidation = await ExcelService.validateExcelFile(uint8Bytes);
//       _setProgress(0.3);

//       if (_fileValidation!['isValid'] == false) {
//         _error = 'Invalid Excel file: ${_fileValidation!['errors'].join(', ')}';
//         return;
//       }

//       _setProcessingStatus('Parsing Excel sheets...');
//       _setProgress(0.4);

//       // Parse with timeout and progress updates
//       List<TransactionModel> transactions =
//           await _parseWithProgress(uint8Bytes);

//       _setProcessingStatus('Processing transactions...');
//       _setProgress(0.8);

//       await _processTransactions(transactions, fileName);
//       _dataSource = 'Excel File';

//       _setProgress(1.0);
//       _setProcessingStatus('Complete!');
//     } catch (e) {
//       print('Error loading file: $e');
//       _error = 'Failed to load file: ${e.toString()}';
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // Load transactions from database
//   Future<void> loadTransactionsFromDatabase() async {
//     _setLoading(true);
//     _clearMessages();
//     _setProcessingStatus('Connecting to database...');
//     _setProgress(0.1);

//     try {
//       // Check server health first
//       bool serverHealthy = await DatabaseService.checkServerHealth();
//       _isDatabaseConnected = serverHealthy;

//       if (!serverHealthy) {
//         throw Exception(
//             'Cannot connect to database server. Please ensure the Flask API is running at ${DatabaseService.getDatabaseInfo()['baseUrl']}');
//       }

//       _setProcessingStatus('Fetching reconciliation data...');
//       _setProgress(0.3);

//       // Fetch data from database
//       Map<String, dynamic>? apiResponse =
//           await DatabaseService.fetchReconciliationData();

//       if (apiResponse == null ||
//           !DatabaseService.validateApiResponse(apiResponse)) {
//         throw Exception('Invalid or empty response from database');
//       }

//       _setProcessingStatus('Parsing transaction data...');
//       _setProgress(0.6);

//       // Parse transactions from database response
//       List<TransactionModel> transactions =
//           DatabaseService.parseTransactionsFromDatabase(apiResponse);

//       if (transactions.isEmpty) {
//         throw Exception(
//             'No transaction data found in database. Please ensure your reconciliation tables contain data.');
//       }

//       _setProcessingStatus('Processing transactions...');
//       _setProgress(0.8);

//       // Process transactions
//       await _processTransactions(transactions, 'Database');
//       _dataSource = 'MySQL Database';

//       // Extract and set summary stats from API response
//       if (apiResponse.containsKey('summary')) {
//         _summaryStats = SummaryStats.fromApiResponse(apiResponse);
//       }

//       _setProgress(1.0);
//       _setProcessingStatus('Complete!');

//       _successMessage =
//           'Successfully loaded ${transactions.length} transactions from database';
//       print(
//           'Database loading complete: ${transactions.length} transactions loaded');

//       // Start auto-refresh if enabled
//       _startAutoRefresh();
//     } catch (e) {
//       print('Error loading from database: $e');
//       _error = DatabaseService.formatErrorMessage(e.toString());
//       _isDatabaseConnected = false;
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // Refresh data from database
//   Future<void> refreshTransactionsFromDatabase() async {
//     _setLoading(true);
//     _clearMessages();
//     _setProcessingStatus('Refreshing data from database...');
//     _setProgress(0.1);

//     try {
//       // Check server health first
//       bool serverHealthy = await DatabaseService.checkServerHealth();
//       _isDatabaseConnected = serverHealthy;

//       if (!serverHealthy) {
//         throw Exception('Cannot connect to database server');
//       }

//       _setProcessingStatus('Triggering data refresh...');
//       _setProgress(0.3);

//       // Trigger refresh on backend
//       Map<String, dynamic>? refreshResponse =
//           await DatabaseService.refreshData();

//       if (refreshResponse == null || refreshResponse['status'] != 'success') {
//         throw Exception('Failed to refresh data from server');
//       }

//       _setProcessingStatus('Parsing refreshed data...');
//       _setProgress(0.6);

//       // Parse the refreshed transactions
//       List<TransactionModel> transactions =
//           DatabaseService.parseTransactionsFromDatabase(refreshResponse);

//       _setProcessingStatus('Updating local data...');
//       _setProgress(0.8);

//       // Process the refreshed transactions
//       await _processTransactions(transactions, 'Database (Refreshed)');
//       _dataSource = 'MySQL Database (Refreshed)';

//       // Update summary stats
//       if (refreshResponse.containsKey('summary')) {
//         _summaryStats = SummaryStats.fromApiResponse(refreshResponse);
//       }

//       _setProgress(1.0);
//       _setProcessingStatus('Refresh complete!');

//       _successMessage =
//           'Successfully refreshed ${transactions.length} transactions from database';
//       print(
//           'Database refresh complete: ${transactions.length} transactions loaded');
//     } catch (e) {
//       print('Error refreshing from database: $e');
//       _error = DatabaseService.formatErrorMessage(e.toString());
//       _isDatabaseConnected = false;
//     } finally {
//       _setLoading(false);
//       _setProcessing(false);
//     }
//   }

//   // Export data from database
//   Future<void> exportDataFromDatabase({List<String>? sheets}) async {
//     try {
//       _setProcessingStatus('Exporting data from database...');

//       Map<String, dynamic>? exportData =
//           await DatabaseService.exportData(sheets: sheets);

//       if (exportData != null) {
//         // You can integrate this with your existing export functionality
//         _successMessage = 'Data exported successfully';
//         print('Export completed successfully');
//       } else {
//         throw Exception('Failed to export data');
//       }
//     } catch (e) {
//       _error = 'Export failed: ${e.toString()}';
//     }
//   }

//   // Check database connection status
//   Future<bool> checkDatabaseConnection() async {
//     try {
//       bool isConnected = await DatabaseService.checkServerHealth();
//       _isDatabaseConnected = isConnected;
//       return isConnected;
//     } catch (e) {
//       print('Database connection check failed: $e');
//       _isDatabaseConnected = false;
//       return false;
//     }
//   }

//   // Updated method to load transactions - now supports both Excel and Database
//   Future<void> loadTransactions({bool fromDatabase = true}) async {
//     if (fromDatabase) {
//       await loadTransactionsFromDatabase();
//     } else {
//       // await loadTransactionsFromFile(); // Your existing Excel loading method
//     }
//   }

//   // NEW: Auto-refresh functionality
//   void _startAutoRefresh() {
//     if (!_autoRefreshEnabled) return;

//     _autoRefreshTimer?.cancel();
//     _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
//       if (_autoRefreshEnabled &&
//           !_isLoading &&
//           !_isProcessing &&
//           !_isBatchProcessing) {
//         refreshTransactionsFromDatabase();
//       }
//     });
//   }

//   void setAutoRefresh(bool enabled) {
//     _autoRefreshEnabled = enabled;
//     if (enabled) {
//       _startAutoRefresh();
//     } else {
//       _autoRefreshTimer?.cancel();
//     }
//     notifyListeners();
//   }

//   // Search transactions
//   void searchTransactions(String query) {
//     if (query.isEmpty) {
//       _filteredTransactions = List.from(_allTransactions);
//     } else {
//       final lowerQuery = query.toLowerCase();
//       _filteredTransactions = _allTransactions.where((transaction) {
//         return transaction.txnRefNo.toLowerCase().contains(lowerQuery) ||
//             transaction.txnMid.toLowerCase().contains(lowerQuery) ||
//             transaction.txnMachine.toLowerCase().contains(lowerQuery) ||
//             transaction.remarks
//                 .toLowerCase()
//                 .contains(lowerQuery); // ✅ Added remarks search
//       }).toList();
//     }
//     _currentPage = 0;
//     notifyListeners();
//   }

//   // Set items per page
//   void setItemsPerPage(int itemsPerPage) {
//     _itemsPerPage = itemsPerPage;
//     _currentPage = 0; // Reset to first page
//     notifyListeners();
//   }

//   // Analytics methods
//   List<Map<String, dynamic>> getStatusDistributionData() {
//     final Map<ReconciliationStatus, int> statusCounts = {};

//     for (var status in ReconciliationStatus.values) {
//       statusCounts[status] = 0;
//     }

//     for (var transaction in _allTransactions) {
//       statusCounts[transaction.status] =
//           (statusCounts[transaction.status] ?? 0) + 1;
//     }

//     return statusCounts.entries
//         .map((entry) => {
//               'status': entry.key.label,
//               'count': entry.value,
//               'color': entry.key.color,
//             })
//         .toList();
//   }

//   List<Map<String, dynamic>> getPaymentVsRefundData() {
//     double totalPayments = 0;
//     double totalRefunds = 0;

//     for (var transaction in _allTransactions) {
//       totalPayments += transaction.ptppPayment + transaction.cloudPayment;
//       totalRefunds += transaction.ptppRefund.abs() +
//           transaction.cloudRefund.abs() +
//           transaction.cloudMRefund.abs();
//     }

//     return [
//       {'type': 'Payments', 'amount': totalPayments, 'color': Colors.green},
//       {'type': 'Refunds', 'amount': totalRefunds, 'color': Colors.red},
//     ];
//   }

//   List<Map<String, dynamic>> getTopMIDsData({int limit = 10}) {
//     final Map<String, int> midCounts = {};

//     for (var transaction in _allTransactions) {
//       midCounts[transaction.txnMid] = (midCounts[transaction.txnMid] ?? 0) + 1;
//     }

//     final sortedEntries = midCounts.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return sortedEntries
//         .take(limit)
//         .map((entry) => {
//               'mid': entry.key,
//               'count': entry.value,
//             })
//         .toList();
//   }

//   Map<String, dynamic> getDiscrepancyAnalysis() {
//     int totalDiscrepantTransactions = 0;
//     double totalDiscrepancyAmount = 0;

//     for (var transaction in _allTransactions) {
//       if (transaction.hasDiscrepancy) {
//         totalDiscrepantTransactions++;
//         totalDiscrepancyAmount += transaction.discrepancyAmount;
//       }
//     }

//     return {
//       'totalDiscrepantTransactions': totalDiscrepantTransactions,
//       'totalDiscrepancyAmount': totalDiscrepancyAmount,
//       'discrepancyRate': _allTransactions.isNotEmpty
//           ? (totalDiscrepantTransactions / _allTransactions.length * 100)
//           : 0.0,
//     };
//   }

//   // Parse with progress updates (existing Excel functionality)
//   Future<List<TransactionModel>> _parseWithProgress(Uint8List bytes) async {
//     final stopwatch = Stopwatch()..start();

//     // For very large files, we might want to use an isolate
//     if (bytes.length > 20 * 1024 * 1024) {
//       // 20MB+
//       _setProcessingStatus('Processing large file in background...');
//       // Could implement isolate processing here for very large files
//     }

//     final transactions = await ExcelService.parseExcelFromBytes(bytes);

//     stopwatch.stop();
//     print('Parsing completed in ${stopwatch.elapsedMilliseconds}ms');
//     return transactions;
//   }

//   // Process transactions with analytics calculation
//   Future<void> _processTransactions(
//       List<TransactionModel> transactions, String fileName) async {
//     _setProcessingStatus('Calculating analytics...');
//     _setProgress(0.9);

//     _allTransactions = transactions;
//     _filteredTransactions = List.from(transactions);

//     // Only calculate summary stats if not already set from API
//     if (_summaryStats == null) {
//       _summaryStats = SummaryStats.fromTransactions(transactions);
//     }

//     _currentFileName = fileName;
//     _currentPage = 0;

//     // Sort initially
//     _applySorting();

//     _successMessage =
//         'Successfully loaded ${transactions.length} transactions from $fileName';
//     print('Processing complete: ${transactions.length} transactions loaded');

//     notifyListeners();
//   }

//   Future<void> startBatchProcessing() async {
//     _setBatchProcessing(true);
//     _clearMessages();
//     _setProcessingStatus('Starting batch processing...');

//     try {
//       final response = await http.post(
//         Uri.parse('http://localhost:5000/api/start-processing'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _batchProcessingStatus = data['status'];
//         _setProcessingStatus('Processing started successfully');
//         _startStatusPolling();
//         _successMessage = 'Batch processing started successfully!';
//       } else {
//         final errorData = json.decode(response.body);
//         throw Exception(errorData['error'] ?? 'Failed to start processing');
//       }
//     } catch (e) {
//       _error = 'Failed to start processing: ${e.toString()}';
//       _setBatchProcessing(false);
//       rethrow;
//     }
//   }

//   /// Check processing status (called by timer)
//   Future<void> checkProcessingStatus() async {
//     if (!_isBatchProcessing) return;

//     try {
//       final response = await http.get(
//         Uri.parse('http://localhost:5000/api/processing-status'),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _batchProcessingStatus = data['status'];

//         if (_batchProcessingStatus != null) {
//           final status = _batchProcessingStatus!;

//           _setProgress((status['progress'] ?? 0.0) / 100.0);
//           _setProcessingStatus(status['message'] ?? 'Processing...');

//           // Check if processing is complete
//           if (status['completed'] == true || status['is_processing'] == false) {
//             _setBatchProcessing(false);
//             _statusPollingTimer?.cancel();

//             if (status['completed'] == true) {
//               // Auto-refresh data from database
//               _setProcessingStatus('Processing completed! Refreshing data...');
//               await loadTransactionsFromDatabase();
//               _successMessage = 'Processing completed successfully!';
//             } else if (status['error'] != null) {
//               _error = 'Processing failed: ${status['error']}';
//             }
//           }

//           notifyListeners();
//         }
//       }
//     } catch (e) {
//       print('Error checking processing status: $e');
//       // Continue polling even if one request fails
//     }
//   }

//   /// Stop batch processing
//   Future<void> stopBatchProcessing() async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://localhost:5000/api/stop-processing'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         _setBatchProcessing(false);
//         _statusPollingTimer?.cancel();
//         _successMessage = 'Processing stopped successfully';
//       }
//     } catch (e) {
//       print('Error stopping processing: $e');
//       _error = 'Failed to stop processing: ${e.toString()}';
//     }
//   }

//   /// Apply sorting to filtered transactions
//   void _applySorting() {
//     _filteredTransactions.sort((a, b) {
//       dynamic aValue, bValue;

//       switch (_sortBy) {
//         case 'refno':
//           aValue = a.txnRefNo;
//           bValue = b.txnRefNo;
//           break;
//         case 'mid':
//           aValue = a.txnMid;
//           bValue = b.txnMid;
//           break;
//         case 'machine':
//           aValue = a.txnMachine;
//           bValue = b.txnMachine;
//           break;
//         case 'ptppAmount':
//           aValue = a.ptppNetAmount;
//           bValue = b.ptppNetAmount;
//           break;
//         case 'cloudAmount':
//           aValue = a.cloudNetAmount;
//           bValue = b.cloudNetAmount;
//           break;
//         case 'difference':
//           aValue = a.systemDifference;
//           bValue = b.systemDifference;
//           break;
//         case 'status':
//           aValue = a.status.label;
//           bValue = b.status.label;
//           break;
//         case 'remarks':
//           aValue = a.remarks;
//           bValue = b.remarks;
//           break;
//         default:
//           aValue = a.txnRefNo;
//           bValue = b.txnRefNo;
//       }

//       int comparison;
//       if (aValue is String && bValue is String) {
//         comparison = aValue.compareTo(bValue);
//       } else if (aValue is num && bValue is num) {
//         comparison = aValue.compareTo(bValue);
//       } else {
//         comparison = aValue.toString().compareTo(bValue.toString());
//       }

//       return _sortAscending ? comparison : -comparison;
//     });
//   }

//   // Apply filters with performance optimization
//   void applyFilters(FilterModel filter) {
//     _clearMessages();
//     _setProcessingStatus('Applying filters...');

//     // Use background processing for large datasets
//     if (_allTransactions.length > 10000) {
//       _setProcessing(true);

//       // Process in chunks to maintain UI responsiveness
//       _processFiltersInChunks(filter);
//     } else {
//       _applyFiltersSync(filter);
//     }
//   }

//   // Synchronous filter application for smaller datasets
//  void _applyFiltersSync(FilterModel filter) {
//     _filteredTransactions = _allTransactions.where((transaction) {
//       // Status filter
//       if (filter.status != null && transaction.status != filter.status) {
//         return false;
//       }

//       // Transaction type filter
//       if (filter.transactionType != null &&
//           transaction.transactionType != filter.transactionType) {
//         return false;
//       }

//       // Search query filter (enhanced to include remarks)
//       if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
//         final query = filter.searchQuery!.toLowerCase();
//         if (!transaction.txnRefNo.toLowerCase().contains(query) &&
//             !transaction.txnMid.toLowerCase().contains(query) &&
//             !transaction.txnMachine.toLowerCase().contains(query) &&
//             !transaction.remarks.toLowerCase().contains(query)) {
//           return false;
//         }
//       }

//       // MID filter
//       if (filter.midFilter.isNotEmpty) {
//         if (!transaction.txnMid
//             .toLowerCase()
//             .contains(filter.midFilter.toLowerCase())) {
//           return false;
//         }
//       }

//       // ✅ NEW: Remarks text filter
//       if (filter.remarksFilter.isNotEmpty) {
//         if (!transaction.remarks
//             .toLowerCase()
//             .contains(filter.remarksFilter.toLowerCase())) {
//           return false;
//         }
//       }

//       // ✅ NEW: Remarks type filter (exact matches)
//       if (filter.selectedRemarksTypes.isNotEmpty) {
//         bool matchesRemarksType = false;
//         for (String remarksType in filter.selectedRemarksTypes) {
//           if (transaction.remarks
//               .toLowerCase()
//               .contains(remarksType.toLowerCase())) {
//             matchesRemarksType = true;
//             break;
//           }
//         }
//         if (!matchesRemarksType) {
//           return false;
//         }
//       }

//       // Amount filters
//       if (filter.minAmount != null &&
//           transaction.ptppNetAmount < filter.minAmount!) {
//         return false;
//       }
//       if (filter.maxAmount != null &&
//           transaction.ptppNetAmount > filter.maxAmount!) {
//         return false;
//       }

//       // Discrepancy filter
//       if (filter.showDiscrepanciesOnly && !transaction.hasDiscrepancy) {
//         return false;
//       }

//       return true;
//     }).toList();

//     _currentPage = 0;
//     _applySorting();
//     notifyListeners();
//   }

//   // Chunked filter processing for large datasets
//   Future<void> _processFiltersInChunks(FilterModel filter) async {
//     final chunkSize = 1000;
//     List<TransactionModel> filteredResults = [];

//     for (int i = 0; i < _allTransactions.length; i += chunkSize) {
//       final endIndex = (i + chunkSize).clamp(0, _allTransactions.length);
//       final chunk = _allTransactions.sublist(i, endIndex);

//       final filteredChunk = chunk.where((transaction) {
//         // Apply same filter logic as _applyFiltersSync
//         if (filter.status != null && transaction.status != filter.status) {
//           return false;
//         }
//         if (filter.transactionType != null &&
//             transaction.transactionType != filter.transactionType) {
//           return false;
//         }
//         if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
//           final query = filter.searchQuery!.toLowerCase();
//           if (!transaction.txnRefNo.toLowerCase().contains(query) &&
//               !transaction.txnMid.toLowerCase().contains(query) &&
//               !transaction.txnMachine.toLowerCase().contains(query)) {
//             return false;
//           }
//         }
//         if (filter.minAmount != null &&
//             transaction.ptppNetAmount < filter.minAmount!) {
//           return false;
//         }
//         if (filter.maxAmount != null &&
//             transaction.ptppNetAmount > filter.maxAmount!) {
//           return false;
//         }
//         if (filter.showDiscrepanciesOnly && !transaction.hasDiscrepancy) {
//           return false;
//         }
//         return true;
//       }).toList();

//       filteredResults.addAll(filteredChunk);

//       // Small delay to prevent blocking
//       await Future.delayed(const Duration(milliseconds: 1));
//     }

//     _filteredTransactions = filteredResults;
//     _currentPage = 0;
//     _applySorting();
//     _setProcessing(false);
//     notifyListeners();
//   }

//   // Sort transactions
//   void sortTransactions(String sortBy, bool ascending) {
//     _sortBy = sortBy;
//     _sortAscending = ascending;
//     _applySorting();
//     notifyListeners();
//   }

//   // Pagination methods
//   void goToPage(int page) {
//     final maxPage = totalPages - 1;
//     if (page >= 0 && page <= maxPage && maxPage >= 0) {
//       _currentPage = page.clamp(0, maxPage);
//       notifyListeners();
//     }
//   }

//   void nextPage() {
//     final maxPage = totalPages - 1;
//     if (_currentPage < maxPage && maxPage >= 0) {
//       _currentPage++;
//       notifyListeners();
//     }
//   }

//   void previousPage() {
//     if (_currentPage > 0) {
//       _currentPage--;
//       notifyListeners();
//     }
//   }

//   void changeItemsPerPage(int itemsPerPage) {
//     _itemsPerPage = itemsPerPage;
//     _currentPage = 0;
//     notifyListeners();
//   }

//   // Get unique values for filters
//   Map<String, List<String>> getUniqueValues() {
//     if (_allTransactions.isEmpty) return {};

//     return {
//       'txnMid': _allTransactions.map((t) => t.txnMid).toSet().toList()..sort(),
//       'txnMachine': _allTransactions.map((t) => t.txnMachine).toSet().toList()
//         ..sort(),
//       'status': ReconciliationStatus.values.map((s) => s.label).toList(),
//       'transactionType': TransactionType.values.map((t) => t.label).toList(),
//     };
//   }

//   // Clear data
//   void clearData() {
//     _allTransactions = [];
//     _filteredTransactions = [];
//     _summaryStats = null;
//     _currentFileName = null;
//     _dataSource = 'Unknown';
//     _fileValidation = null;
//     _currentPage = 0;
//     _uploadedFileName = null;
//     _batchProcessingStatus = null;
//     _clearMessages();
//     notifyListeners();
//   }

//   // NEW: Reset upload state
//   void resetUpload() {
//     _isUploading = false;
//     _uploadProgress = 0.0;
//     _uploadError = null;
//     _uploadedFileName = null;
//     notifyListeners();
//   }

//   // Helper methods
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     if (!loading) {
//       _processingProgress = 0.0;
//       _processingStatus = '';
//     }
//     notifyListeners();
//   }

//   void _setProcessing(bool processing) {
//     _isProcessing = processing;
//     notifyListeners();
//   }

//   void _setUploading(bool uploading) {
//     _isUploading = uploading;
//     if (!uploading) {
//       _uploadProgress = 0.0;
//     }
//     notifyListeners();
//   }

//   void _setBatchProcessing(bool processing) {
//     _isBatchProcessing = processing;
//     if (!processing) {
//       _statusPollingTimer?.cancel();
//     }
//     notifyListeners();
//   }

//   void _setProgress(double progress) {
//     _processingProgress = progress.clamp(0.0, 1.0);
//     notifyListeners();
//   }

//   void _setUploadProgress(double progress) {
//     _uploadProgress = progress.clamp(0.0, 1.0);
//     notifyListeners();
//   }

//   void _setProcessingStatus(String status) {
//     _processingStatus = status;
//     notifyListeners();
//   }

//   void _clearMessages() {
//     _error = null;
//     _successMessage = null;
//     _uploadError = null;
//   }

//   @override
//   void dispose() {
//     _statusPollingTimer?.cancel();
//     _autoRefreshTimer?.cancel();
//     super.dispose();
//   }
// }

// // Filter Provider
// class FilterProvider extends ChangeNotifier {
//   FilterModel _currentFilter = FilterModel();
//   bool _isFilterPanelOpen = false;

//   // Getters
//   FilterModel get currentFilter => _currentFilter;
//   bool get isFilterPanelOpen => _isFilterPanelOpen;
//   bool get hasActiveFilters => _currentFilter.hasActiveFilters;

//   // ✅ Panel control
//   void setFilterPanelOpen(bool isOpen) {
//     _isFilterPanelOpen = isOpen;
//     notifyListeners();
//   }

//   void toggleFilterPanel() {
//     _isFilterPanelOpen = !_isFilterPanelOpen;
//     notifyListeners();
//   }

//   // ✅ Complete filter update method
//   void updateFilter(FilterModel filter) {
//     _currentFilter = filter;
//     notifyListeners();
//   }

//   // ✅ Status filtering - PROPERLY IMPLEMENTED
//   void updateStatus(ReconciliationStatus? status) {
//     _currentFilter = _currentFilter.copyWith(status: status);
//     notifyListeners();
//   }

//   // ✅ Transaction type filtering
//   void updateTransactionType(TransactionType? transactionType) {
//     _currentFilter = _currentFilter.copyWith(transactionType: transactionType);
//     notifyListeners();
//   }

//   // ✅ Search query filtering
//   void updateSearchQuery(String searchQuery) {
//     _currentFilter = _currentFilter.copyWith(searchQuery: searchQuery);
//     notifyListeners();
//   }

//   // ✅ Amount range filtering - PROPERLY IMPLEMENTED
//   void updateAmountRange(double? minAmount, double? maxAmount) {
//     _currentFilter = _currentFilter.copyWith(
//       minAmount: minAmount,
//       maxAmount: maxAmount,
//     );
//     notifyListeners();
//   }

//   // ✅ Discrepancy filtering - PROPERLY IMPLEMENTED
//   void updateShowDiscrepanciesOnly(bool showOnly) {
//     _currentFilter = _currentFilter.copyWith(showDiscrepanciesOnly: showOnly);
//     notifyListeners();
//   }

//   // ✅ MID filtering
//   void updateMIDFilter(String midFilter) {
//     _currentFilter = _currentFilter.copyWith(midFilter: midFilter);
//     notifyListeners();
//   }

//   // ✅ Machine filtering - MISSING METHOD ADDED
//   void updateMachineFilter(String machineFilter) {
//     _currentFilter = _currentFilter.copyWith(machineFilter: machineFilter);
//     notifyListeners();
//   }

//   // ✅ Date range filtering
//   void updateDateRange(DateTime? startDate, DateTime? endDate) {
//     _currentFilter = _currentFilter.copyWith(
//       startDate: startDate,
//       endDate: endDate,
//     );
//     notifyListeners();
//   }

//   // ✅ Payment mode filtering
//   void addPaymentMode(String mode) {
//     final currentModes = List<String>.from(_currentFilter.paymentModes);
//     if (!currentModes.contains(mode)) {
//       currentModes.add(mode);
//       _currentFilter = _currentFilter.copyWith(paymentModes: currentModes);
//       notifyListeners();
//     }
//   }

//   void removePaymentMode(String mode) {
//     final currentModes = List<String>.from(_currentFilter.paymentModes);
//     currentModes.remove(mode);
//     _currentFilter = _currentFilter.copyWith(paymentModes: currentModes);
//     notifyListeners();
//   }

//   void clearPaymentModes() {
//     _currentFilter = _currentFilter.copyWith(paymentModes: <String>[]);
//     notifyListeners();
//   }

//   // ✅ Discrepancy filter - MISSING METHOD ADDED
//   void updateDiscrepancyFilter(bool? hasDiscrepancy) {
//     updateShowDiscrepanciesOnly(hasDiscrepancy ?? false);
//   }

//   // ✅ Quick filter functionality
//   void applyQuickFilter(String filterType) {
//     switch (filterType) {
//       case 'perfect':
//         updateStatus(ReconciliationStatus.perfect);
//         break;
//       case 'investigate':
//         updateStatus(ReconciliationStatus.investigate);
//         break;
//       case 'manual_refund':
//         updateStatus(ReconciliationStatus.manualRefund);
//         break;
//       case 'high_amount':
//         updateAmountRange(1000.0, null); // Transactions above ₹1000
//         break;
//       case 'discrepancy':
//         updateShowDiscrepanciesOnly(true);
//         break;
//       case 'missing':
//         updateStatus(ReconciliationStatus.missing);
//         break;
//       default:
//         clearAllFilters();
//     }
//   }

//   // ✅ Clear all filters - PROPERLY IMPLEMENTED
//   void clearAllFilters() {
//     _currentFilter = FilterModel.clear(); // Use the factory constructor
//     notifyListeners();
//   }

//   // ✅ Reset to default
//   void resetFilters() {
//     _currentFilter = FilterModel.empty();
//     notifyListeners();
//   }

//   // ✅ Convenience methods for common filter combinations
//   void showOnlyDiscrepancies() {
//     clearAllFilters();
//     updateShowDiscrepanciesOnly(true);
//   }

//   void showPerfectMatches() {
//     clearAllFilters();
//     updateStatus(ReconciliationStatus.perfect);
//   }

//   void showInvestigateItems() {
//     clearAllFilters();
//     updateStatus(ReconciliationStatus.investigate);
//   }

//   void showHighValueTransactions(double threshold) {
//     clearAllFilters();
//     updateAmountRange(threshold, null);
//   }

//   void showDateRange(DateTime start, DateTime end) {
//     updateDateRange(start, end);
//   }

//   // ✅ Filter validation
//   bool isValidFilter() {
//     // Check if date range is valid
//     if (_currentFilter.startDate != null && _currentFilter.endDate != null) {
//       if (_currentFilter.startDate!.isAfter(_currentFilter.endDate!)) {
//         return false;
//       }
//     }

//     // Check if amount range is valid
//     if (_currentFilter.minAmount != null && _currentFilter.maxAmount != null) {
//       if (_currentFilter.minAmount! > _currentFilter.maxAmount!) {
//         return false;
//       }
//     }

//     return true;
//   }
//    void applyRemarksQuickFilter(String filterType) {
//     clearAllFilters(); // Clear existing filters
//     switch (filterType) {
//       case 'perfect':
//         addRemarksType('Perfect Match');
//         break;
//       case 'ptpp_excess':
//         updateRemarksFilter('PTPP Excess');
//         break;
//       case 'cloud_excess':
//         updateRemarksFilter('Cloud Excess');
//         break;
//       case 'manual':
//         addRemarksType('Manual Refund Transaction');
//         break;
//       case 'investigate':
//         updateRemarksFilter('Investigate');
//         break;
//     }
//   }

//   // ✅ Get filter summary for UI display
//   String getFilterSummary() {
//     if (!hasActiveFilters) return 'No filters applied';

//     List<String> summaries = [];

//     if (_currentFilter.status != null) {
//       summaries.add('Status: ${_currentFilter.status!.label}');
//     }

//     if (_currentFilter.midFilter.isNotEmpty) {
//       summaries.add('MID: ${_currentFilter.midFilter}');
//     }

//     if (_currentFilter.machineFilter?.isNotEmpty == true) {
//       summaries.add('Machine: ${_currentFilter.machineFilter}');
//     }

//     if (_currentFilter.paymentModes.isNotEmpty) {
//       summaries.add('Modes: ${_currentFilter.paymentModes.join(", ")}');
//     }

//     if (_currentFilter.showDiscrepanciesOnly) {
//       summaries.add('Discrepancies only');
//     }

//     if (_currentFilter.minAmount != null || _currentFilter.maxAmount != null) {
//       String amountRange = '';
//       if (_currentFilter.minAmount != null) {
//         amountRange += '₹${_currentFilter.minAmount}';
//       }
//       amountRange += ' - ';
//       if (_currentFilter.maxAmount != null) {
//         amountRange += '₹${_currentFilter.maxAmount}';
//       }
//       summaries.add('Amount: $amountRange');
//     }

//     if (_currentFilter.startDate != null || _currentFilter.endDate != null) {
//       String dateRange = '';
//       if (_currentFilter.startDate != null) {
//         dateRange +=
//             '${_currentFilter.startDate!.day}/${_currentFilter.startDate!.month}/${_currentFilter.startDate!.year}';
//       }
//       dateRange += ' - ';
//       if (_currentFilter.endDate != null) {
//         dateRange +=
//             '${_currentFilter.endDate!.day}/${_currentFilter.endDate!.month}/${_currentFilter.endDate!.year}';
//       }
//       summaries.add('Date: $dateRange');
//     }

//     return summaries.join(' | ');
//   }

//   // ✅ Get active filter count
//   int getActiveFilterCount() {
//     int count = 0;

//     if (_currentFilter.status != null) count++;
//     if (_currentFilter.transactionType != null) count++;
//     if (_currentFilter.searchQuery?.isNotEmpty == true) count++;
//     if (_currentFilter.midFilter.isNotEmpty) count++;
//     if (_currentFilter.machineFilter?.isNotEmpty == true) count++;
//     if (_currentFilter.paymentModes.isNotEmpty) count++;
//     if (_currentFilter.showDiscrepanciesOnly) count++;
//     if (_currentFilter.minAmount != null) count++;
//     if (_currentFilter.maxAmount != null) count++;
//     if (_currentFilter.startDate != null) count++;
//     if (_currentFilter.endDate != null) count++;

//     return count;
//   }

//   // ✅ Export current filter as Map (for persistence/debugging)
//   Map<String, dynamic> exportFilter() {
//     return _currentFilter.toMap();
//   }

//   // ✅ Import filter from Map (for persistence)
//   void importFilter(Map<String, dynamic> filterMap) {
//     try {
//       _currentFilter = FilterModel(
//         status: filterMap['status'] != null
//             ? ReconciliationStatus.values
//                 .firstWhere((s) => s.label == filterMap['status'])
//             : null,
//         transactionType: filterMap['transactionType'] != null
//             ? TransactionType.values
//                 .firstWhere((t) => t.label == filterMap['transactionType'])
//             : null,
//         searchQuery: filterMap['searchQuery'],
//         minAmount: filterMap['minAmount']?.toDouble(),
//         maxAmount: filterMap['maxAmount']?.toDouble(),
//         machineFilter: filterMap['machineFilter'],
//         showDiscrepanciesOnly: filterMap['showDiscrepanciesOnly'] ?? false,
//         midFilter: filterMap['midFilter'] ?? '',
//         paymentModes: List<String>.from(filterMap['paymentModes'] ?? []),
//         startDate: filterMap['startDate'] != null
//             ? DateTime.parse(filterMap['startDate'])
//             : null,
//         endDate: filterMap['endDate'] != null
//             ? DateTime.parse(filterMap['endDate'])
//             : null,
//       );
//       notifyListeners();
//     } catch (e) {
//       print('Error importing filter: $e');
//       // Fall back to empty filter
//       clearAllFilters();
//     }
//   }
// }

// // ✅ Enhanced FilterModel class
// class FilterModel {
//   final ReconciliationStatus? status;
//   final TransactionType? transactionType;
//   final String? searchQuery;
//   final double? minAmount;
//   final double? maxAmount;
//   final String? machineFilter; // ✅ This was missing in copyWith
//   final bool showDiscrepanciesOnly;
//   final String midFilter;
//   final List<String> paymentModes;
//   final DateTime? startDate;
//   final DateTime? endDate;

//   // ✅ Getter for backward compatibility
//   bool get hasDiscrepancy => showDiscrepanciesOnly;

//   // ✅ Check if any filters are active
//   bool get hasActiveFilters {
//     return status != null ||
//         transactionType != null ||
//         (searchQuery?.isNotEmpty ?? false) ||
//         minAmount != null ||
//         maxAmount != null ||
//         (machineFilter?.isNotEmpty ?? false) ||
//         showDiscrepanciesOnly ||
//         midFilter.isNotEmpty ||
//         paymentModes.isNotEmpty ||
//         startDate != null ||
//         endDate != null;
//   }

//   FilterModel({
//     this.status,
//     this.transactionType,
//     this.searchQuery,
//     this.machineFilter,
//     this.minAmount,
//     this.maxAmount,
//     this.showDiscrepanciesOnly = false,
//     this.midFilter = '',
//     this.paymentModes = const [],
//     this.startDate,
//     this.endDate,
//   });

//   // ✅ Complete copyWith method with ALL parameters
//   FilterModel copyWith({
//     ReconciliationStatus? status,
//     TransactionType? transactionType,
//     String? searchQuery,
//     double? minAmount,
//     double? maxAmount,
//     String? machineFilter, // ✅ Added missing parameter
//     bool? showDiscrepanciesOnly,
//     String? midFilter,
//     List<String>? paymentModes,
//     DateTime? startDate,
//     DateTime? endDate,
//   }) {
//     return FilterModel(
//       status: status ?? this.status,
//       transactionType: transactionType ?? this.transactionType,
//       searchQuery: searchQuery ?? this.searchQuery,
//       minAmount: minAmount ?? this.minAmount,
//       maxAmount: maxAmount ?? this.maxAmount,
//       machineFilter:
//           machineFilter ?? this.machineFilter, // ✅ Added missing assignment
//       showDiscrepanciesOnly:
//           showDiscrepanciesOnly ?? this.showDiscrepanciesOnly,
//       midFilter: midFilter ?? this.midFilter,
//       paymentModes: paymentModes ?? this.paymentModes,
//       startDate: startDate ?? this.startDate,
//       endDate: endDate ?? this.endDate,
//     );
//   }

//   // ✅ Factory constructor for empty/default filter
//   factory FilterModel.empty() {
//     return FilterModel();
//   }

//   // ✅ Factory constructor for clearing all filters
//   factory FilterModel.clear() {
//     return FilterModel(
//       status: null,
//       transactionType: null,
//       searchQuery: null,
//       machineFilter: null,
//       minAmount: null,
//       maxAmount: null,
//       showDiscrepanciesOnly: false,
//       midFilter: '',
//       paymentModes: const [],
//       startDate: null,
//       endDate: null,
//     );
//   }

//   // ✅ Convert to Map for debugging/logging
//   Map<String, dynamic> toMap() {
//     return {
//       'status': status?.label,
//       'transactionType': transactionType?.label,
//       'searchQuery': searchQuery,
//       'minAmount': minAmount,
//       'maxAmount': maxAmount,
//       'machineFilter': machineFilter,
//       'showDiscrepanciesOnly': showDiscrepanciesOnly,
//       'midFilter': midFilter,
//       'paymentModes': paymentModes,
//       'startDate': startDate?.toIso8601String(),
//       'endDate': endDate?.toIso8601String(),
//       'hasActiveFilters': hasActiveFilters,
//     };
//   }

//   // ✅ toString for debugging
//   @override
//   String toString() {
//     return 'FilterModel(${toMap()})';
//   }

//   // ✅ Equality operator
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is FilterModel &&
//         other.status == status &&
//         other.transactionType == transactionType &&
//         other.searchQuery == searchQuery &&
//         other.minAmount == minAmount &&
//         other.maxAmount == maxAmount &&
//         other.machineFilter == machineFilter &&
//         other.showDiscrepanciesOnly == showDiscrepanciesOnly &&
//         other.midFilter == midFilter &&
//         _listEquals(other.paymentModes, paymentModes) &&
//         other.startDate == startDate &&
//         other.endDate == endDate;
//   }

//   @override
//   int get hashCode {
//     return Object.hash(
//       status,
//       transactionType,
//       searchQuery,
//       minAmount,
//       maxAmount,
//       machineFilter,
//       showDiscrepanciesOnly,
//       midFilter,
//       paymentModes,
//       startDate,
//       endDate,
//     );
//   }

//   // ✅ Helper method for list comparison
//   bool _listEquals<T>(List<T>? a, List<T>? b) {
//     if (a == null) return b == null;
//     if (b == null || a.length != b.length) return false;
//     for (int index = 0; index < a.length; index += 1) {
//       if (a[index] != b[index]) return false;
//     }
//     return true;
//   }
// }

// // ✅ Enhanced filtering logic for TransactionProvider
// // void _applyFiltersSync(FilterModel filter) {
// //   _filteredTransactions = _allTransactions.where((transaction) {
// //     // Status filter
// //     if (filter.status != null && transaction.status != filter.status) {
// //       return false;
// //     }

// //     // Transaction type filter
// //     if (filter.transactionType != null &&
// //         transaction.transactionType != filter.transactionType) {
// //       return false;
// //     }

// //     // Search query filter (enhanced to include remarks)
// //     if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
// //       final query = filter.searchQuery!.toLowerCase();
// //       if (!transaction.txnRefNo.toLowerCase().contains(query) &&
// //           !transaction.txnMid.toLowerCase().contains(query) &&
// //           !transaction.txnMachine.toLowerCase().contains(query) &&
// //           !transaction.remarks.toLowerCase().contains(query)) {
// //         return false;
// //       }
// //     }

// //     // MID filter
// //     if (filter.midFilter.isNotEmpty) {
// //       if (!transaction.txnMid
// //           .toLowerCase()
// //           .contains(filter.midFilter.toLowerCase())) {
// //         return false;
// //       }
// //     }

// //     // Payment mode filter
// //     if (filter.paymentModes.isNotEmpty) {
// //       bool matchesPaymentMode = false;
// //       for (String mode in filter.paymentModes) {
// //         if (transaction.txnSource.toLowerCase().contains(mode.toLowerCase()) ||
// //             transaction.txnType.toLowerCase().contains(mode.toLowerCase()) ||
// //             transaction.remarks.toLowerCase().contains(mode.toLowerCase())) {
// //           matchesPaymentMode = true;
// //           break;
// //         }
// //       }
// //       if (!matchesPaymentMode) {
// //         return false;
// //       }
// //     }

// //     // Date range filter
// //     if (filter.startDate != null || filter.endDate != null) {
// //       DateTime? transactionDate;
// //       try {
// //         if (transaction.txnDate.isNotEmpty) {
// //           transactionDate = DateTime.parse(transaction.txnDate);
// //         }
// //       } catch (e) {
// //         // If date parsing fails, exclude from date-based filtering
// //         if (filter.startDate != null || filter.endDate != null) {
// //           return false;
// //         }
// //       }

// //       if (transactionDate != null) {
// //         if (filter.startDate != null &&
// //             transactionDate.isBefore(filter.startDate!)) {
// //           return false;
// //         }
// //         if (filter.endDate != null &&
// //             transactionDate
// //                 .isAfter(filter.endDate!.add(const Duration(days: 1)))) {
// //           return false;
// //         }
// //       }
// //     }

// //     // Amount filters
// //     if (filter.minAmount != null &&
// //         transaction.ptppNetAmount < filter.minAmount!) {
// //       return false;
// //     }
// //     if (filter.maxAmount != null &&
// //         transaction.ptppNetAmount > filter.maxAmount!) {
// //       return false;
// //     }

// //     // Discrepancy filter
// //     if (filter.showDiscrepanciesOnly && !transaction.hasDiscrepancy) {
// //       return false;
// //     }

// //     return true;
// //   }).toList();

// //   _currentPage = 0;
// //   _applySorting();
// //   notifyListeners();
// // }

// // Theme Provider
// class ThemeProvider extends ChangeNotifier {
//   bool _isDarkMode = false;

//   bool get isDarkMode => _isDarkMode;

//   ThemeData get themeData {
//     return _isDarkMode
//         ? ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: Colors.blue,
//               brightness: Brightness.dark,
//             ),
//             useMaterial3: true,
//           )
//         : ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: Colors.blue,
//               brightness: Brightness.light,
//             ),
//             useMaterial3: true,
//           );
//   }

//   void toggleTheme() {
//     _isDarkMode = !_isDarkMode;
//     notifyListeners();
//   }
// }

// // App State Provider
// class AppStateProvider extends ChangeNotifier {
//   String _appTitle = 'Reconciliation Dashboard';
//   bool _isLoading = false;

//   String get appTitle => _appTitle;
//   bool get isLoading => _isLoading;

//   void setAppTitle(String title) {
//     _appTitle = title;
//     notifyListeners();
//   }

//   void setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
// }

// // Upload State Provider (Enhanced with better state management)
// class UploadStateProvider extends ChangeNotifier {
//   bool _isUploading = false;
//   double _uploadProgress = 0.0;
//   String? _uploadError;
//   String? _uploadedFileName;
//   bool _isDragOver = false;
//   String _uploadStatus = '';
//   Map<String, dynamic>? _uploadResult;

//   // Getters
//   bool get isUploading => _isUploading;
//   double get uploadProgress => _uploadProgress;
//   String? get uploadError => _uploadError;
//   String? get uploadedFileName => _uploadedFileName;
//   bool get isDragOver => _isDragOver;
//   String get uploadStatus => _uploadStatus;
//   Map<String, dynamic>? get uploadResult => _uploadResult;

//   void startUpload(String fileName) {
//     _isUploading = true;
//     _uploadProgress = 0.0;
//     _uploadError = null;
//     _uploadedFileName = fileName;
//     _uploadStatus = 'Starting upload...';
//     _uploadResult = null;
//     notifyListeners();
//   }

//   void updateProgress(double progress, {String? status}) {
//     _uploadProgress = progress.clamp(0.0, 1.0);
//     if (status != null) {
//       _uploadStatus = status;
//     }
//     notifyListeners();
//   }

//   void completeUpload(Map<String, dynamic>? result) {
//     _isUploading = false;
//     _uploadProgress = 1.0;
//     _uploadStatus = 'Upload complete!';
//     _uploadResult = result;
//     notifyListeners();
//   }

//   void failUpload(String error) {
//     _isUploading = false;
//     _uploadError = error;
//     _uploadStatus = 'Upload failed';
//     notifyListeners();
//   }

//   void resetUpload() {
//     _isUploading = false;
//     _uploadProgress = 0.0;
//     _uploadError = null;
//     _uploadedFileName = null;
//     _isDragOver = false;
//     _uploadStatus = '';
//     _uploadResult = null;
//     notifyListeners();
//   }

//   void setDragOver(bool isDragOver) {
//     _isDragOver = isDragOver;
//     notifyListeners();
//   }

//   void clearError() {
//     _uploadError = null;
//     notifyListeners();
//   }
// }

// // NEW: Processing State Provider for managing batch processing
// class ProcessingStateProvider extends ChangeNotifier {
//   bool _isProcessing = false;
//   Map<String, dynamic>? _processingStatus;
//   String? _processingError;
//   Timer? _statusTimer;

//   // Getters
//   bool get isProcessing => _isProcessing;
//   Map<String, dynamic>? get processingStatus => _processingStatus;
//   String? get processingError => _processingError;

//   // Derived getters for convenience
//   int get currentStep => _processingStatus?['current_step'] ?? 0;
//   int get totalSteps => _processingStatus?['total_steps'] ?? 3;
//   double get progress => (_processingStatus?['progress'] ?? 0.0) / 100.0;
//   String get stepName => _processingStatus?['step_name'] ?? '';
//   String get message => _processingStatus?['message'] ?? '';
//   bool get isCompleted => _processingStatus?['completed'] == true;
//   bool get hasError => _processingStatus?['error'] != null;

//   Future<void> startProcessing() async {
//     try {
//       _isProcessing = true;
//       _processingError = null;
//       _processingStatus = null;
//       notifyListeners();

//       // This would call the actual backend service
//       // For now, simulating the start
//       _processingStatus = {
//         'is_processing': true,
//         'current_step': 1,
//         'total_steps': 3,
//         'step_name': 'Starting',
//         'progress': 0.0,
//         'message': 'Initializing processing...',
//         'error': null,
//         'completed': false
//       };

//       _startStatusPolling();
//       notifyListeners();
//     } catch (e) {
//       _isProcessing = false;
//       _processingError = e.toString();
//       notifyListeners();
//       rethrow;
//     }
//   }

//   void _startStatusPolling() {
//     _statusTimer?.cancel();
//     _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
//       try {
//         // This would call the actual backend status endpoint
//         // For now, simulating progress
//         if (_processingStatus != null) {
//           var currentProgress = _processingStatus!['progress'] ?? 0.0;
//           if (currentProgress < 100) {
//             _processingStatus!['progress'] = currentProgress + 10;
//             _processingStatus!['message'] = 'Processing step ${currentStep}...';

//             if (currentProgress >= 90) {
//               _processingStatus!['completed'] = true;
//               _processingStatus!['is_processing'] = false;
//               _processingStatus!['message'] =
//                   'Processing completed successfully!';
//               _isProcessing = false;
//               timer.cancel();
//             }

//             notifyListeners();
//           }
//         }
//       } catch (e) {
//         print('Error polling processing status: $e');
//       }
//     });
//   }

//   void stopProcessing() {
//     _isProcessing = false;
//     _statusTimer?.cancel();
//     notifyListeners();
//   }

//   void resetProcessing() {
//     _isProcessing = false;
//     _processingStatus = null;
//     _processingError = null;
//     _statusTimer?.cancel();
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _statusTimer?.cancel();
//     super.dispose();
//   }
// }

//3

import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'services.dart';
import 'database_service.dart';

// Enhanced Transaction Provider with database support and upload/processing features
class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  SummaryStats? _summaryStats;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  double _processingProgress = 0.0;

  // Current file/data source info
  String? _currentFileName;
  String _dataSource = 'Unknown';
  Map<String, dynamic>? _fileValidation;

  // Pagination with larger default for performance
  int _currentPage = 0;
  int _itemsPerPage = 100;
  String _sortBy = 'refno';
  bool _sortAscending = true;

  // Processing state
  bool _isProcessing = false;
  String _processingStatus = '';

  // Database connection state
  bool _isDatabaseConnected = false;

  // NEW: Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  String? _uploadedFileName;

  // NEW: Batch processing state
  bool _isBatchProcessing = false;
  Map<String, dynamic>? _batchProcessingStatus;
  Timer? _statusPollingTimer;

  // NEW: Auto-refresh settings
  bool _autoRefreshEnabled = true;
  Timer? _autoRefreshTimer;

  // Getters
  List<TransactionModel> get allTransactions => _allTransactions;
  List<TransactionModel> get filteredTransactions => _filteredTransactions;
  SummaryStats? get summaryStats => _summaryStats;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  double get processingProgress => _processingProgress;
  String get processingStatus => _processingStatus;
  String? get error => _error;
  String? get successMessage => _successMessage;
  String? get currentFileName => _currentFileName;
  String get dataSource => _dataSource;
  Map<String, dynamic>? get fileValidation => _fileValidation;
  bool get isDatabaseConnected => _isDatabaseConnected;

  // NEW: Upload getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get uploadError => _uploadError;
  String? get uploadedFileName => _uploadedFileName;

  // NEW: Batch processing getters
  bool get isBatchProcessing => _isBatchProcessing;
  Map<String, dynamic>? get batchProcessingStatus => _batchProcessingStatus;
  bool get autoRefreshEnabled => _autoRefreshEnabled;

  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  int get totalPages => _filteredTransactions.isEmpty
      ? 0
      : (_filteredTransactions.length / _itemsPerPage).ceil();

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  void setSuccessMessage(String message) {
    _successMessage = message;
    notifyListeners();
  }

  List<TransactionModel> get currentPageTransactions {
    // Safety check for empty list
    if (_filteredTransactions.isEmpty) {
      return [];
    }

    // Calculate safe start index
    final startIndex = _currentPage * _itemsPerPage;

    // ✅ CRITICAL: Reset page if out of bounds
    if (startIndex >= _filteredTransactions.length) {
      _currentPage = 0; // Reset to page 0
      final newStartIndex = 0;
      final endIndex = _itemsPerPage.clamp(0, _filteredTransactions.length);
      return _filteredTransactions.sublist(newStartIndex, endIndex);
    }

    // Calculate safe end index
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, _filteredTransactions.length);

    // ✅ Double check: Ensure start index is valid
    if (startIndex < 0 || startIndex > _filteredTransactions.length) {
      return [];
    }

    return _filteredTransactions.sublist(startIndex, endIndex);
  }

  bool get hasData => _allTransactions.isNotEmpty;
  bool get hasError => _error != null;

  // NEW: File upload handling
  Future<void> handleFileUpload(Uint8List fileBytes, String fileName) async {
    _setLoading(true);
    _setUploading(true);
    _clearMessages();
    _setProcessingStatus('Uploading file...');
    _setProgress(0.1);

    try {
      // Validate file
      String? validationError = _validateFile(fileName, fileBytes.length);
      if (validationError != null) {
        throw Exception(validationError);
      }

      _setProcessingStatus('Uploading to server...');
      _setProgress(0.3);

      // Upload file to backend
      var uploadResult = await _uploadFileToServer(fileBytes, fileName);

      if (uploadResult != null) {
        _uploadedFileName = uploadResult['filename'];
        _setUploadProgress(1.0);
        _setProcessingStatus('Upload completed successfully!');
        _successMessage = 'File uploaded: ${uploadResult['filename']}';
      } else {
        throw Exception('Upload failed - no response from server');
      }
    } catch (e) {
      print('Error uploading file: $e');
      _uploadError = 'Upload failed: ${e.toString()}';
      _error = 'Upload failed: ${e.toString()}';
    } finally {
      _setLoading(false);
      _setUploading(false);
      _setProcessing(false);
    }
  }

  // NEW: Start automated batch processing
  Future<void> startAutomatedProcessing() async {
    if (_uploadedFileName == null) {
      throw Exception('No file uploaded. Please upload a file first.');
    }

    _setLoading(true);
    _setBatchProcessing(true);
    _clearMessages();
    _setProcessingStatus('Starting automated processing...');
    _setProgress(0.0);

    try {
      // Start processing on backend
      var processingResult = await _startBatchProcessing();

      if (processingResult != null) {
        _batchProcessingStatus = processingResult['status'];
        _setProcessingStatus('Processing started successfully');

        // Start polling for status updates
        _startStatusPolling();

        _successMessage = 'Automated processing started successfully!';
      } else {
        throw Exception('Failed to start processing');
      }
    } catch (e) {
      print('Error in automated processing: $e');
      _error = 'Processing failed: ${e.toString()}';
      _setBatchProcessing(false);
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Start status polling
  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isBatchProcessing) {
        timer.cancel();
        return;
      }

      try {
        var statusResult = await _getProcessingStatus();

        if (statusResult != null && statusResult['status'] != null) {
          var status = statusResult['status'];
          _batchProcessingStatus = status;

          _setProgress((status['progress'] ?? 0.0) / 100.0);
          _setProcessingStatus(status['message'] ?? 'Processing...');

          // Check if processing is complete
          if (status['completed'] == true || status['is_processing'] == false) {
            timer.cancel();
            _setBatchProcessing(false);

            if (status['completed'] == true) {
              // Auto-refresh data from database
              _setProcessingStatus('Processing completed! Refreshing data...');
              await loadTransactionsFromDatabase();

              _successMessage = 'Automated processing completed successfully!';
            } else if (status['error'] != null) {
              _error = 'Processing failed: ${status['error']}';
            }
          }

          notifyListeners();
        }
      } catch (e) {
        print('Error polling processing status: $e');
        // Continue polling even if one request fails
      }
    });
  }

  // NEW: Backend communication methods
  Future<Map<String, dynamic>?> _uploadFileToServer(
      Uint8List fileBytes, String fileName) async {
    try {
      // Using the existing DatabaseService pattern
      const String baseUrl = 'http://localhost:5000';

      // This would use HTTP multipart upload - simplified for this example
      // In real implementation, you'd use http package's MultipartRequest

      // Simulated upload response
      await Future.delayed(
          Duration(milliseconds: 500)); // Simulate network delay

      return {
        'filename': fileName,
        'filepath': 'C:\\Users\\IT\\Downloads\\Recon\\input_files\\$fileName',
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'File uploaded successfully'
      };
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _startBatchProcessing() async {
    try {
      // This would call the backend API to start batch processing
      const String baseUrl = 'http://localhost:5000';

      // Simulated processing start response
      await Future.delayed(Duration(milliseconds: 300));

      return {
        'message': 'Processing started successfully',
        'status': {
          'is_processing': true,
          'current_step': 0,
          'total_steps': 3,
          'step_name': 'Initializing',
          'progress': 0,
          'message': 'Starting batch processing...',
          'error': null,
          'completed': false
        }
      };
    } catch (e) {
      print('Processing start error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getProcessingStatus() async {
    try {
      // This would call the backend API to get processing status
      const String baseUrl = 'http://localhost:5000';

      // Simulated status response - in real implementation this would
      // return actual status from the backend
      await Future.delayed(Duration(milliseconds: 100));

      return {
        'status': _batchProcessingStatus,
        'timestamp': DateTime.now().toIso8601String()
      };
    } catch (e) {
      print('Status polling error: $e');
      return null;
    }
  }

  // NEW: File validation
  String? _validateFile(String fileName, int fileSizeBytes) {
    // Check file extension
    final allowedExtensions = ['zip', 'xlsx', 'xls'];
    final extension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'Invalid file type. Only .zip, .xlsx, and .xls files are allowed.';
    }

    // Check file size (50MB limit)
    const maxSizeBytes = 50 * 1024 * 1024;
    if (fileSizeBytes > maxSizeBytes) {
      final sizeMB = fileSizeBytes / (1024 * 1024);
      return 'File too large (${sizeMB.toStringAsFixed(1)}MB). Maximum size is 50MB.';
    }

    return null; // Valid file
  }

  // Enhanced file loading with progress tracking (existing Excel functionality)
  Future<void> loadTransactionsFromFile(
      Uint8List uint8bytes, String name) async {
    _setLoading(true);
    _clearMessages();
    _setProcessingStatus('Selecting file...');

    try {
      List<TransactionModel>? transactions =
          await ExcelService.pickAndParseExcelFile();

      if (transactions != null) {
        await _processTransactions(transactions, 'Excel File');
        _dataSource = 'Excel File';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      _setProcessing(false);
    }
  }

  // Enhanced byte loading with comprehensive progress tracking (existing Excel functionality)
  Future<void> loadTransactionsFromBytes(
      List<int> bytes, String fileName) async {
    _setLoading(true);
    _setProcessing(true);
    _clearMessages();
    _setProcessingStatus('Validating file...');
    _setProgress(0.1);

    try {
      print('Starting file processing for: $fileName (${bytes.length} bytes)');

      // Convert and validate
      final uint8Bytes = Uint8List.fromList(bytes);
      _setProcessingStatus('Analyzing file structure...');
      _setProgress(0.2);

      // Validate file before processing
      _fileValidation = await ExcelService.validateExcelFile(uint8Bytes);
      _setProgress(0.3);

      if (_fileValidation!['isValid'] == false) {
        _error = 'Invalid Excel file: ${_fileValidation!['errors'].join(', ')}';
        return;
      }

      _setProcessingStatus('Parsing Excel sheets...');
      _setProgress(0.4);

      // Parse with timeout and progress updates
      List<TransactionModel> transactions =
          await _parseWithProgress(uint8Bytes);

      _setProcessingStatus('Processing transactions...');
      _setProgress(0.8);

      await _processTransactions(transactions, fileName);
      _dataSource = 'Excel File';

      _setProgress(1.0);
      _setProcessingStatus('Complete!');
    } catch (e) {
      print('Error loading file: $e');
      _error = 'Failed to load file: ${e.toString()}';
    } finally {
      _setLoading(false);
      _setProcessing(false);
    }
  }

  // Load transactions from database
  Future<void> loadTransactionsFromDatabase() async {
    _setLoading(true);
    _clearMessages();
    _setProcessingStatus('Connecting to database...');
    _setProgress(0.1);

    try {
      // Check server health first
      bool serverHealthy = await DatabaseService.checkServerHealth();
      _isDatabaseConnected = serverHealthy;

      if (!serverHealthy) {
        throw Exception(
            'Cannot connect to database server. Please ensure the Flask API is running at ${DatabaseService.getDatabaseInfo()['baseUrl']}');
      }

      _setProcessingStatus('Fetching reconciliation data...');
      _setProgress(0.3);

      // Fetch data from database
      Map<String, dynamic>? apiResponse =
          await DatabaseService.fetchReconciliationData();

      if (apiResponse == null ||
          !DatabaseService.validateApiResponse(apiResponse)) {
        throw Exception('Invalid or empty response from database');
      }

      _setProcessingStatus('Parsing transaction data...');
      _setProgress(0.6);

      // Parse transactions from database response
      List<TransactionModel> transactions =
          DatabaseService.parseTransactionsFromDatabase(apiResponse);

      if (transactions.isEmpty) {
        throw Exception(
            'No transaction data found in database. Please ensure your reconciliation tables contain data.');
      }

      _setProcessingStatus('Processing transactions...');
      _setProgress(0.8);

      // Process transactions
      await _processTransactions(transactions, 'Database');
      _dataSource = 'MySQL Database';

      // Extract and set summary stats from API response
      if (apiResponse.containsKey('summary')) {
        _summaryStats = SummaryStats.fromApiResponse(apiResponse);
      }

      _setProgress(1.0);
      _setProcessingStatus('Complete!');

      _successMessage =
          'Successfully loaded ${transactions.length} transactions from database';
      print(
          'Database loading complete: ${transactions.length} transactions loaded');

      // Start auto-refresh if enabled
      _startAutoRefresh();
    } catch (e) {
      print('Error loading from database: $e');
      _error = DatabaseService.formatErrorMessage(e.toString());
      _isDatabaseConnected = false;
    } finally {
      _setLoading(false);
      _setProcessing(false);
    }
  }

  // Refresh data from database
  Future<void> refreshTransactionsFromDatabase() async {
    _setLoading(true);
    _clearMessages();
    _setProcessingStatus('Refreshing data from database...');
    _setProgress(0.1);

    try {
      // Check server health first
      bool serverHealthy = await DatabaseService.checkServerHealth();
      _isDatabaseConnected = serverHealthy;

      if (!serverHealthy) {
        throw Exception('Cannot connect to database server');
      }

      _setProcessingStatus('Triggering data refresh...');
      _setProgress(0.3);

      // Trigger refresh on backend
      Map<String, dynamic>? refreshResponse =
          await DatabaseService.refreshData();

      if (refreshResponse == null || refreshResponse['status'] != 'success') {
        throw Exception('Failed to refresh data from server');
      }

      _setProcessingStatus('Parsing refreshed data...');
      _setProgress(0.6);

      // Parse the refreshed transactions
      List<TransactionModel> transactions =
          DatabaseService.parseTransactionsFromDatabase(refreshResponse);

      _setProcessingStatus('Updating local data...');
      _setProgress(0.8);

      // Process the refreshed transactions
      await _processTransactions(transactions, 'Database (Refreshed)');
      _dataSource = 'MySQL Database (Refreshed)';

      // Update summary stats
      if (refreshResponse.containsKey('summary')) {
        _summaryStats = SummaryStats.fromApiResponse(refreshResponse);
      }

      _setProgress(1.0);
      _setProcessingStatus('Refresh complete!');

      _successMessage =
          'Successfully refreshed ${transactions.length} transactions from database';
      print(
          'Database refresh complete: ${transactions.length} transactions loaded');
    } catch (e) {
      print('Error refreshing from database: $e');
      _error = DatabaseService.formatErrorMessage(e.toString());
      _isDatabaseConnected = false;
    } finally {
      _setLoading(false);
      _setProcessing(false);
    }
  }

  // Export data from database
  Future<void> exportDataFromDatabase({List<String>? sheets}) async {
    try {
      _setProcessingStatus('Exporting data from database...');

      Map<String, dynamic>? exportData =
          await DatabaseService.exportData(sheets: sheets);

      if (exportData != null) {
        // You can integrate this with your existing export functionality
        _successMessage = 'Data exported successfully';
        print('Export completed successfully');
      } else {
        throw Exception('Failed to export data');
      }
    } catch (e) {
      _error = 'Export failed: ${e.toString()}';
    }
  }

  // Check database connection status
  Future<bool> checkDatabaseConnection() async {
    try {
      bool isConnected = await DatabaseService.checkServerHealth();
      _isDatabaseConnected = isConnected;
      return isConnected;
    } catch (e) {
      print('Database connection check failed: $e');
      _isDatabaseConnected = false;
      return false;
    }
  }

  // Updated method to load transactions - now supports both Excel and Database
  Future<void> loadTransactions({bool fromDatabase = true}) async {
    if (fromDatabase) {
      await loadTransactionsFromDatabase();
    } else {
      // await loadTransactionsFromFile(); // Your existing Excel loading method
    }
  }

  // NEW: Auto-refresh functionality
  void _startAutoRefresh() {
    if (!_autoRefreshEnabled) return;

    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_autoRefreshEnabled &&
          !_isLoading &&
          !_isProcessing &&
          !_isBatchProcessing) {
        refreshTransactionsFromDatabase();
      }
    });
  }

  void setAutoRefresh(bool enabled) {
    _autoRefreshEnabled = enabled;
    if (enabled) {
      _startAutoRefresh();
    } else {
      _autoRefreshTimer?.cancel();
    }
    notifyListeners();
  }

  // Search transactions
  void searchTransactions(String query) {
    if (query.isEmpty) {
      _filteredTransactions = List.from(_allTransactions);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredTransactions = _allTransactions.where((transaction) {
        return transaction.txnRefNo.toLowerCase().contains(lowerQuery) ||
            transaction.txnMid.toLowerCase().contains(lowerQuery) ||
            transaction.txnMachine.toLowerCase().contains(lowerQuery) ||
            transaction.remarks
                .toLowerCase()
                .contains(lowerQuery); // ✅ Added remarks search
      }).toList();
    }
    _currentPage = 0;
    notifyListeners();
  }

  // Set items per page
  void setItemsPerPage(int itemsPerPage) {
    _itemsPerPage = itemsPerPage;
    _currentPage = 0; // Reset to first page
    notifyListeners();
  }

  // Analytics methods
  List<Map<String, dynamic>> getStatusDistributionData() {
    final Map<ReconciliationStatus, int> statusCounts = {};

    for (var status in ReconciliationStatus.values) {
      statusCounts[status] = 0;
    }

    for (var transaction in _allTransactions) {
      statusCounts[transaction.status] =
          (statusCounts[transaction.status] ?? 0) + 1;
    }

    return statusCounts.entries
        .map((entry) => {
              'status': entry.key.label,
              'count': entry.value,
              'color': entry.key.color,
            })
        .toList();
  }

  List<Map<String, dynamic>> getPaymentVsRefundData() {
    double totalPayments = 0;
    double totalRefunds = 0;

    for (var transaction in _allTransactions) {
      totalPayments += transaction.ptppPayment + transaction.cloudPayment;
      totalRefunds += transaction.ptppRefund.abs() +
          transaction.cloudRefund.abs() +
          transaction.cloudMRefund.abs();
    }

    return [
      {'type': 'Payments', 'amount': totalPayments, 'color': Colors.green},
      {'type': 'Refunds', 'amount': totalRefunds, 'color': Colors.red},
    ];
  }

  List<Map<String, dynamic>> getTopMIDsData({int limit = 10}) {
    final Map<String, int> midCounts = {};

    for (var transaction in _allTransactions) {
      midCounts[transaction.txnMid] = (midCounts[transaction.txnMid] ?? 0) + 1;
    }

    final sortedEntries = midCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(limit)
        .map((entry) => {
              'mid': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  Map<String, dynamic> getDiscrepancyAnalysis() {
    int totalDiscrepantTransactions = 0;
    double totalDiscrepancyAmount = 0;

    for (var transaction in _allTransactions) {
      if (transaction.hasDiscrepancy) {
        totalDiscrepantTransactions++;
        totalDiscrepancyAmount += transaction.discrepancyAmount;
      }
    }

    return {
      'totalDiscrepantTransactions': totalDiscrepantTransactions,
      'totalDiscrepancyAmount': totalDiscrepancyAmount,
      'discrepancyRate': _allTransactions.isNotEmpty
          ? (totalDiscrepantTransactions / _allTransactions.length * 100)
          : 0.0,
    };
  }

  // Parse with progress updates (existing Excel functionality)
  Future<List<TransactionModel>> _parseWithProgress(Uint8List bytes) async {
    final stopwatch = Stopwatch()..start();

    // For very large files, we might want to use an isolate
    if (bytes.length > 20 * 1024 * 1024) {
      // 20MB+
      _setProcessingStatus('Processing large file in background...');
      // Could implement isolate processing here for very large files
    }

    final transactions = await ExcelService.parseExcelFromBytes(bytes);

    stopwatch.stop();
    print('Parsing completed in ${stopwatch.elapsedMilliseconds}ms');
    return transactions;
  }

  // Process transactions with analytics calculation
  Future<void> _processTransactions(
      List<TransactionModel> transactions, String fileName) async {
    _setProcessingStatus('Calculating analytics...');
    _setProgress(0.9);

    _allTransactions = transactions;
    _filteredTransactions = List.from(transactions);

    // Only calculate summary stats if not already set from API
    if (_summaryStats == null) {
      _summaryStats = SummaryStats.fromTransactions(transactions);
    }

    _currentFileName = fileName;
    _currentPage = 0;

    // Sort initially
    _applySorting();

    _successMessage =
        'Successfully loaded ${transactions.length} transactions from $fileName';
    print('Processing complete: ${transactions.length} transactions loaded');

    notifyListeners();
  }

  Future<void> startBatchProcessing() async {
    _setBatchProcessing(true);
    _clearMessages();
    _setProcessingStatus('Starting batch processing...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/start-processing'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _batchProcessingStatus = data['status'];
        _setProcessingStatus('Processing started successfully');
        _startStatusPolling();
        _successMessage = 'Batch processing started successfully!';
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to start processing');
      }
    } catch (e) {
      _error = 'Failed to start processing: ${e.toString()}';
      _setBatchProcessing(false);
      rethrow;
    }
  }

  /// Check processing status (called by timer)
  Future<void> checkProcessingStatus() async {
    if (!_isBatchProcessing) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/processing-status'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _batchProcessingStatus = data['status'];

        if (_batchProcessingStatus != null) {
          final status = _batchProcessingStatus!;

          _setProgress((status['progress'] ?? 0.0) / 100.0);
          _setProcessingStatus(status['message'] ?? 'Processing...');

          // Check if processing is complete
          if (status['completed'] == true || status['is_processing'] == false) {
            _setBatchProcessing(false);
            _statusPollingTimer?.cancel();

            if (status['completed'] == true) {
              // Auto-refresh data from database
              _setProcessingStatus('Processing completed! Refreshing data...');
              await loadTransactionsFromDatabase();
              _successMessage = 'Processing completed successfully!';
            } else if (status['error'] != null) {
              _error = 'Processing failed: ${status['error']}';
            }
          }

          notifyListeners();
        }
      }
    } catch (e) {
      print('Error checking processing status: $e');
      // Continue polling even if one request fails
    }
  }

  /// Stop batch processing
  Future<void> stopBatchProcessing() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/stop-processing'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _setBatchProcessing(false);
        _statusPollingTimer?.cancel();
        _successMessage = 'Processing stopped successfully';
      }
    } catch (e) {
      print('Error stopping processing: $e');
      _error = 'Failed to stop processing: ${e.toString()}';
    }
  }

  /// Apply sorting to filtered transactions
  void _applySorting() {
    _filteredTransactions.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'refno':
          aValue = a.txnRefNo;
          bValue = b.txnRefNo;
          break;
        case 'mid':
          aValue = a.txnMid;
          bValue = b.txnMid;
          break;
        case 'machine':
          aValue = a.txnMachine;
          bValue = b.txnMachine;
          break;
        case 'ptppAmount':
          aValue = a.ptppNetAmount;
          bValue = b.ptppNetAmount;
          break;
        case 'cloudAmount':
          aValue = a.cloudNetAmount;
          bValue = b.cloudNetAmount;
          break;
        case 'difference':
          aValue = a.systemDifference;
          bValue = b.systemDifference;
          break;
        case 'status':
          aValue = a.status.label;
          bValue = b.status.label;
          break;
        case 'remarks':
          aValue = a.remarks;
          bValue = b.remarks;
          break;
        default:
          aValue = a.txnRefNo;
          bValue = b.txnRefNo;
      }

      int comparison;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  // Apply filters with performance optimization
  void applyFilters(FilterModel filter) {
    _clearMessages();
    _setProcessingStatus('Applying filters...');

    // Use background processing for large datasets
    if (_allTransactions.length > 10000) {
      _setProcessing(true);

      // Process in chunks to maintain UI responsiveness
      _processFiltersInChunks(filter);
    } else {
      _applyFiltersSync(filter);
    }
  }

  // ✅ UPDATED: Synchronous filter application with remarks filtering
  void _applyFiltersSync(FilterModel filter) {
    _filteredTransactions = _allTransactions.where((transaction) {
      // Status filter
      if (filter.status != null && transaction.status != filter.status) {
        return false;
      }

      // Transaction type filter
      if (filter.transactionType != null &&
          transaction.transactionType != filter.transactionType) {
        return false;
      }

      // Search query filter (enhanced to include remarks)
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        if (!transaction.txnRefNo.toLowerCase().contains(query) &&
            !transaction.txnMid.toLowerCase().contains(query) &&
            !transaction.txnMachine.toLowerCase().contains(query) &&
            !transaction.remarks.toLowerCase().contains(query)) {
          return false;
        }
      }

      // MID filter
      if (filter.midFilter.isNotEmpty) {
        if (!transaction.txnMid
            .toLowerCase()
            .contains(filter.midFilter.toLowerCase())) {
          return false;
        }
      }

      // ✅ NEW: Remarks text filter
      if (filter.remarksFilter.isNotEmpty) {
        if (!transaction.remarks
            .toLowerCase()
            .contains(filter.remarksFilter.toLowerCase())) {
          return false;
        }
      }

      // ✅ NEW: Remarks type filter (exact matches)
      if (filter.selectedRemarksTypes.isNotEmpty) {
        bool matchesRemarksType = false;
        for (String remarksType in filter.selectedRemarksTypes) {
          if (transaction.remarks
              .toLowerCase()
              .contains(remarksType.toLowerCase())) {
            matchesRemarksType = true;
            break;
          }
        }
        if (!matchesRemarksType) {
          return false;
        }
      }

      // Payment mode filter
      if (filter.paymentModes.isNotEmpty) {
        bool matchesPaymentMode = false;
        for (String mode in filter.paymentModes) {
          if (transaction.txnSource
                  .toLowerCase()
                  .contains(mode.toLowerCase()) ||
              transaction.txnType.toLowerCase().contains(mode.toLowerCase()) ||
              transaction.remarks.toLowerCase().contains(mode.toLowerCase())) {
            matchesPaymentMode = true;
            break;
          }
        }
        if (!matchesPaymentMode) {
          return false;
        }
      }

      // Amount filters
      if (filter.minAmount != null &&
          transaction.ptppNetAmount < filter.minAmount!) {
        return false;
      }
      if (filter.maxAmount != null &&
          transaction.ptppNetAmount > filter.maxAmount!) {
        return false;
      }

      // Discrepancy filter
      if (filter.showDiscrepanciesOnly && !transaction.hasDiscrepancy) {
        return false;
      }

      // Custom filters
      if (filter.customFilter == 'matching') {
        if ((transaction.ptppNetAmount - transaction.cloudNetAmount).abs() >
            0.01) return false;
      } else if (filter.customFilter == 'discrepancy') {
        if ((transaction.ptppNetAmount - transaction.cloudNetAmount).abs() <=
            0.01) return false;
      } else if (filter.customFilter == 'manual_refund') {
        if (transaction.cloudMRefund <= 0) return false;
      } else if (filter.customFilter == 'cloud_refund') {
        if (transaction.cloudRefund <= 0) return false;
      }
      return true;
    }).toList();

    _currentPage = 0;
    _applySorting();
    notifyListeners();
  }

  // ✅ UPDATED: Chunked filter processing with remarks filtering
  Future<void> _processFiltersInChunks(FilterModel filter) async {
    final chunkSize = 1000;
    List<TransactionModel> filteredResults = [];

    for (int i = 0; i < _allTransactions.length; i += chunkSize) {
      final endIndex = (i + chunkSize).clamp(0, _allTransactions.length);
      final chunk = _allTransactions.sublist(i, endIndex);

      final filteredChunk = chunk.where((transaction) {
        // Apply same filter logic as _applyFiltersSync
        if (filter.status != null && transaction.status != filter.status) {
          return false;
        }
        if (filter.transactionType != null &&
            transaction.transactionType != filter.transactionType) {
          return false;
        }
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final query = filter.searchQuery!.toLowerCase();
          if (!transaction.txnRefNo.toLowerCase().contains(query) &&
              !transaction.txnMid.toLowerCase().contains(query) &&
              !transaction.txnMachine.toLowerCase().contains(query) &&
              !transaction.remarks.toLowerCase().contains(query)) {
            return false;
          }
        }
        if (filter.midFilter.isNotEmpty) {
          if (!transaction.txnMid
              .toLowerCase()
              .contains(filter.midFilter.toLowerCase())) {
            return false;
          }
        }
        // ✅ NEW: Remarks filters in chunk processing
        if (filter.remarksFilter.isNotEmpty) {
          if (!transaction.remarks
              .toLowerCase()
              .contains(filter.remarksFilter.toLowerCase())) {
            return false;
          }
        }
        if (filter.selectedRemarksTypes.isNotEmpty) {
          bool matchesRemarksType = false;
          for (String remarksType in filter.selectedRemarksTypes) {
            if (transaction.remarks
                .toLowerCase()
                .contains(remarksType.toLowerCase())) {
              matchesRemarksType = true;
              break;
            }
          }
          if (!matchesRemarksType) {
            return false;
          }
        }
        if (filter.minAmount != null &&
            transaction.ptppNetAmount < filter.minAmount!) {
          return false;
        }
        if (filter.maxAmount != null &&
            transaction.ptppNetAmount > filter.maxAmount!) {
          return false;
        }
        if (filter.showDiscrepanciesOnly && !transaction.hasDiscrepancy) {
          return false;
        }
        return true;
      }).toList();

      filteredResults.addAll(filteredChunk);

      // Small delay to prevent blocking
      await Future.delayed(const Duration(milliseconds: 1));
    }

    _filteredTransactions = filteredResults;
    _currentPage = 0;
    _applySorting();
    _setProcessing(false);
    notifyListeners();
  }

  // Sort transactions
  void sortTransactions(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applySorting();
    notifyListeners();
  }

  // Pagination methods
  void goToPage(int page) {
    final maxPage = totalPages - 1;
    if (page >= 0 && page <= maxPage && maxPage >= 0) {
      _currentPage = page.clamp(0, maxPage);
      notifyListeners();
    }
  }

  void nextPage() {
    final maxPage = totalPages - 1;
    if (_currentPage < maxPage && maxPage >= 0) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  void changeItemsPerPage(int itemsPerPage) {
    _itemsPerPage = itemsPerPage;
    _currentPage = 0;
    notifyListeners();
  }

  // Get unique values for filters
  Map<String, List<String>> getUniqueValues() {
    if (_allTransactions.isEmpty) return {};

    return {
      'txnMid': _allTransactions.map((t) => t.txnMid).toSet().toList()..sort(),
      'txnMachine': _allTransactions.map((t) => t.txnMachine).toSet().toList()
        ..sort(),
      'status': ReconciliationStatus.values.map((s) => s.label).toList(),
      'transactionType': TransactionType.values.map((t) => t.label).toList(),
      // ✅ NEW: Add remarks values for filtering
      'remarks': _allTransactions.map((t) => t.remarks).toSet().toList()
        ..sort(),
    };
  }

  // Clear data
  void clearData() {
    _allTransactions = [];
    _filteredTransactions = [];
    _summaryStats = null;
    _currentFileName = null;
    _dataSource = 'Unknown';
    _fileValidation = null;
    _currentPage = 0;
    _uploadedFileName = null;
    _batchProcessingStatus = null;
    _clearMessages();
    notifyListeners();
  }

  // NEW: Reset upload state
  void resetUpload() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadError = null;
    _uploadedFileName = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      _processingProgress = 0.0;
      _processingStatus = '';
    }
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    if (!uploading) {
      _uploadProgress = 0.0;
    }
    notifyListeners();
  }

  void _setBatchProcessing(bool processing) {
    _isBatchProcessing = processing;
    if (!processing) {
      _statusPollingTimer?.cancel();
    }
    notifyListeners();
  }

  void _setProgress(double progress) {
    _processingProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _setUploadProgress(double progress) {
    _uploadProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _setProcessingStatus(String status) {
    _processingStatus = status;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _successMessage = null;
    _uploadError = null;
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

// ✅ UPDATED: Enhanced FilterModel class with remarks filtering
class FilterModel {
  final ReconciliationStatus? status;
  final TransactionType? transactionType;
  final String? searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final String? machineFilter;
  final bool showDiscrepanciesOnly;
  final String? customFilter;
  final String midFilter;
  final List<String> paymentModes;
  final DateTime? startDate;
  final DateTime? endDate;

  // ✅ NEW: Remarks filtering fields
  final String remarksFilter;
  final List<String> selectedRemarksTypes;

  // ✅ Getter for backward compatibility
  bool get hasDiscrepancy => showDiscrepanciesOnly;

  // ✅ UPDATED: Check if any filters are active (including remarks)
  bool get hasActiveFilters {
    return status != null ||
        transactionType != null ||
        (searchQuery?.isNotEmpty ?? false) ||
        minAmount != null ||
        maxAmount != null ||
        (machineFilter?.isNotEmpty ?? false) ||
        showDiscrepanciesOnly ||
        midFilter.isNotEmpty ||
        paymentModes.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        remarksFilter.isNotEmpty || // ✅ NEW
        selectedRemarksTypes.isNotEmpty; // ✅ NEW
  }

  FilterModel({
    this.status,
    this.transactionType,
    this.searchQuery,
    this.machineFilter,
    this.minAmount,
    this.maxAmount,
    this.showDiscrepanciesOnly = false,
    this.customFilter,
    this.midFilter = '',
    this.paymentModes = const [],
    this.startDate,
    this.endDate,
    this.remarksFilter = '', // ✅ NEW
    this.selectedRemarksTypes = const [], // ✅ NEW
  });

  // ✅ UPDATED: Complete copyWith method with remarks parameters
  FilterModel copyWith({
    ReconciliationStatus? status,
    TransactionType? transactionType,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    String? machineFilter,
    bool? showDiscrepanciesOnly,
    String? midFilter,
    List<String>? paymentModes,
    DateTime? startDate,
    DateTime? endDate,
    String? remarksFilter, // ✅ NEW
    List<String>? selectedRemarksTypes, // ✅ NEW
  }) {
    return FilterModel(
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      machineFilter: machineFilter ?? this.machineFilter,
      showDiscrepanciesOnly:
          showDiscrepanciesOnly ?? this.showDiscrepanciesOnly,

      midFilter: midFilter ?? this.midFilter,
      customFilter: customFilter ?? this.customFilter,
      paymentModes: paymentModes ?? this.paymentModes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      remarksFilter: remarksFilter ?? this.remarksFilter, // ✅ NEW
      selectedRemarksTypes:
          selectedRemarksTypes ?? this.selectedRemarksTypes, // ✅ NEW
    );
  }

  // ✅ Factory constructor for empty/default filter
  factory FilterModel.empty() {
    return FilterModel();
  }

  // ✅ UPDATED: Factory constructor for clearing all filters (including remarks)
  factory FilterModel.clear() {
    return FilterModel(
      status: null,
      transactionType: null,
      searchQuery: null,
      machineFilter: null,
      minAmount: null,
      maxAmount: null,
      showDiscrepanciesOnly: false,
      midFilter: '',
      paymentModes: const [],
      startDate: null,
      endDate: null,
      remarksFilter: '', // ✅ NEW
      selectedRemarksTypes: const [], // ✅ NEW
    );
  }

  // ✅ UPDATED: Convert to Map for debugging/logging (including remarks)
  Map<String, dynamic> toMap() {
    return {
      'status': status?.label,
      'transactionType': transactionType?.label,
      'searchQuery': searchQuery,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'machineFilter': machineFilter,
      'showDiscrepanciesOnly': showDiscrepanciesOnly,
      'midFilter': midFilter,
      'paymentModes': paymentModes,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'remarksFilter': remarksFilter, // ✅ NEW
      'selectedRemarksTypes': selectedRemarksTypes, // ✅ NEW
      'hasActiveFilters': hasActiveFilters,
    };
  }

  // ✅ toString for debugging
  @override
  String toString() {
    return 'FilterModel(${toMap()})';
  }

  // ✅ UPDATED: Equality operator (including remarks)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FilterModel &&
        other.status == status &&
        other.transactionType == transactionType &&
        other.searchQuery == searchQuery &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.machineFilter == machineFilter &&
        other.showDiscrepanciesOnly == showDiscrepanciesOnly &&
        other.midFilter == midFilter &&
        _listEquals(other.paymentModes, paymentModes) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.remarksFilter == remarksFilter && // ✅ NEW
        _listEquals(other.selectedRemarksTypes, selectedRemarksTypes); // ✅ NEW
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      transactionType,
      searchQuery,
      minAmount,
      maxAmount,
      machineFilter,
      showDiscrepanciesOnly,
      midFilter,
      paymentModes,
      startDate,
      endDate,
      remarksFilter, // ✅ NEW
      selectedRemarksTypes, // ✅ NEW
    );
  }

  // ✅ Helper method for list comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

// ✅ UPDATED: Enhanced FilterProvider with remarks filtering
class FilterProvider extends ChangeNotifier {
  FilterModel _currentFilter = FilterModel();
  bool _isFilterPanelOpen = false;

  // Getters
  FilterModel get currentFilter => _currentFilter;
  bool get isFilterPanelOpen => _isFilterPanelOpen;
  bool get hasActiveFilters => _currentFilter.hasActiveFilters;
// Essential reconciliation filters
  void showMatching() {
    _currentFilter = FilterModel(customFilter: 'matching');
    notifyListeners();
  }

  void showDiscrepancies() {
    _currentFilter = FilterModel(customFilter: 'discrepancy');
    notifyListeners();
  }

  void showManualRefunds() {
    _currentFilter = FilterModel(customFilter: 'manual_refund');
    notifyListeners();
  }

  void showCloudRefunds() {
    _currentFilter = FilterModel(customFilter: 'cloud_refund');
    notifyListeners();
  }

  // ✅ Panel control
  void setFilterPanelOpen(bool isOpen) {
    _isFilterPanelOpen = isOpen;
    notifyListeners();
  }

  void toggleFilterPanel() {
    _isFilterPanelOpen = !_isFilterPanelOpen;
    notifyListeners();
  }

  // ✅ Complete filter update method
  void updateFilter(FilterModel filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // ✅ Status filtering - PROPERLY IMPLEMENTED
  void updateStatus(ReconciliationStatus? status) {
    _currentFilter = _currentFilter.copyWith(status: status);
    notifyListeners();
  }

  // ✅ Transaction type filtering
  void updateTransactionType(TransactionType? transactionType) {
    _currentFilter = _currentFilter.copyWith(transactionType: transactionType);
    notifyListeners();
  }

  // ✅ Search query filtering
  void updateSearchQuery(String searchQuery) {
    _currentFilter = _currentFilter.copyWith(searchQuery: searchQuery);
    notifyListeners();
  }

  // ✅ Amount range filtering - PROPERLY IMPLEMENTED
  void updateAmountRange(double? minAmount, double? maxAmount) {
    _currentFilter = _currentFilter.copyWith(
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
    notifyListeners();
  }

  // ✅ Discrepancy filtering - PROPERLY IMPLEMENTED
  void updateShowDiscrepanciesOnly(bool showOnly) {
    _currentFilter = _currentFilter.copyWith(showDiscrepanciesOnly: showOnly);
    notifyListeners();
  }

  // ✅ MID filtering
  void updateMIDFilter(String midFilter) {
    _currentFilter = _currentFilter.copyWith(midFilter: midFilter);
    notifyListeners();
  }

  // ✅ Machine filtering - MISSING METHOD ADDED
  void updateMachineFilter(String machineFilter) {
    _currentFilter = _currentFilter.copyWith(machineFilter: machineFilter);
    notifyListeners();
  }

  // ✅ Date range filtering
  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    _currentFilter = _currentFilter.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    notifyListeners();
  }

  // ✅ Payment mode filtering
  void addPaymentMode(String mode) {
    final currentModes = List<String>.from(_currentFilter.paymentModes);
    if (!currentModes.contains(mode)) {
      currentModes.add(mode);
      _currentFilter = _currentFilter.copyWith(paymentModes: currentModes);
      notifyListeners();
    }
  }

  void removePaymentMode(String mode) {
    final currentModes = List<String>.from(_currentFilter.paymentModes);
    currentModes.remove(mode);
    _currentFilter = _currentFilter.copyWith(paymentModes: currentModes);
    notifyListeners();
  }

  void clearPaymentModes() {
    _currentFilter = _currentFilter.copyWith(paymentModes: <String>[]);
    notifyListeners();
  }

  // ✅ NEW: Remarks filtering methods
  void updateRemarksFilter(String remarksFilter) {
    _currentFilter = _currentFilter.copyWith(remarksFilter: remarksFilter);
    notifyListeners();
  }

  void addRemarksType(String remarksType) {
    final currentTypes = List<String>.from(_currentFilter.selectedRemarksTypes);
    if (!currentTypes.contains(remarksType)) {
      currentTypes.add(remarksType);
      _currentFilter =
          _currentFilter.copyWith(selectedRemarksTypes: currentTypes);
      notifyListeners();
    }
  }

  void removeRemarksType(String remarksType) {
    final currentTypes = List<String>.from(_currentFilter.selectedRemarksTypes);
    currentTypes.remove(remarksType);
    _currentFilter =
        _currentFilter.copyWith(selectedRemarksTypes: currentTypes);
    notifyListeners();
  }

  void clearRemarksTypes() {
    _currentFilter = _currentFilter.copyWith(selectedRemarksTypes: <String>[]);
    notifyListeners();
  }

  // ✅ NEW: Remarks quick filter functionality
  void applyRemarksQuickFilter(String filterType) {
    clearAllFilters(); // Clear existing filters
    switch (filterType) {
      case 'perfect':
        addRemarksType('Perfect Match');
        break;
      case 'ptpp_excess':
        updateRemarksFilter('PTPP Excess');
        break;
      case 'cloud_excess':
        updateRemarksFilter('Cloud Excess');
        break;
      case 'manual':
        addRemarksType('Manual Refund Transaction');
        break;
      case 'investigate':
        updateRemarksFilter('Investigate');
        break;
    }
  }

  // ✅ Discrepancy filter - MISSING METHOD ADDED
  void updateDiscrepancyFilter(bool? hasDiscrepancy) {
    updateShowDiscrepanciesOnly(hasDiscrepancy ?? false);
  }

  // ✅ Quick filter functionality
  void applyQuickFilter(String filterType) {
    switch (filterType) {
      case 'perfect':
        updateStatus(ReconciliationStatus.perfect);
        break;
      case 'investigate':
        updateStatus(ReconciliationStatus.investigate);
        break;
      case 'manual_refund':
        updateStatus(ReconciliationStatus.manualRefund);
        break;
      case 'high_amount':
        updateAmountRange(1000.0, null); // Transactions above ₹1000
        break;
      case 'discrepancy':
        updateShowDiscrepanciesOnly(true);
        break;
      case 'missing':
        updateStatus(ReconciliationStatus.missing);
        break;
      default:
        clearAllFilters();
    }
  }

  // ✅ Clear all filters - PROPERLY IMPLEMENTED
  void clearAllFilters() {
    _currentFilter = FilterModel.clear(); // Use the factory constructor
    notifyListeners();
  }

  // ✅ Reset to default
  void resetFilters() {
    _currentFilter = FilterModel.empty();
    notifyListeners();
  }

  // ✅ Convenience methods for common filter combinations
  void showOnlyDiscrepancies() {
    clearAllFilters();
    updateShowDiscrepanciesOnly(true);
  }

  void showPerfectMatches() {
    clearAllFilters();
    updateStatus(ReconciliationStatus.perfect);
  }

  void showInvestigateItems() {
    clearAllFilters();
    updateStatus(ReconciliationStatus.investigate);
  }

  void showHighValueTransactions(double threshold) {
    clearAllFilters();
    updateAmountRange(threshold, null);
  }

  void showDateRange(DateTime start, DateTime end) {
    updateDateRange(start, end);
  }

  // ✅ Filter validation
  bool isValidFilter() {
    // Check if date range is valid
    if (_currentFilter.startDate != null && _currentFilter.endDate != null) {
      if (_currentFilter.startDate!.isAfter(_currentFilter.endDate!)) {
        return false;
      }
    }

    // Check if amount range is valid
    if (_currentFilter.minAmount != null && _currentFilter.maxAmount != null) {
      if (_currentFilter.minAmount! > _currentFilter.maxAmount!) {
        return false;
      }
    }

    return true;
  }

  // ✅ UPDATED: Get filter summary including remarks
  String getFilterSummary() {
    if (!hasActiveFilters) return 'No filters applied';

    List<String> summaries = [];

    if (_currentFilter.status != null) {
      summaries.add('Status: ${_currentFilter.status!.label}');
    }

    if (_currentFilter.midFilter.isNotEmpty) {
      summaries.add('MID: ${_currentFilter.midFilter}');
    }

    if (_currentFilter.machineFilter?.isNotEmpty == true) {
      summaries.add('Machine: ${_currentFilter.machineFilter}');
    }

    if (_currentFilter.paymentModes.isNotEmpty) {
      summaries.add('Modes: ${_currentFilter.paymentModes.join(", ")}');
    }

    if (_currentFilter.showDiscrepanciesOnly) {
      summaries.add('Discrepancies only');
    }

    // ✅ NEW: Add remarks to summary
    if (_currentFilter.remarksFilter.isNotEmpty) {
      summaries.add('Remarks: ${_currentFilter.remarksFilter}');
    }

    if (_currentFilter.selectedRemarksTypes.isNotEmpty) {
      summaries.add('Types: ${_currentFilter.selectedRemarksTypes.join(", ")}');
    }

    if (_currentFilter.minAmount != null || _currentFilter.maxAmount != null) {
      String amountRange = '';
      if (_currentFilter.minAmount != null) {
        amountRange += '₹${_currentFilter.minAmount}';
      }
      amountRange += ' - ';
      if (_currentFilter.maxAmount != null) {
        amountRange += '₹${_currentFilter.maxAmount}';
      }
      summaries.add('Amount: $amountRange');
    }

    if (_currentFilter.startDate != null || _currentFilter.endDate != null) {
      String dateRange = '';
      if (_currentFilter.startDate != null) {
        dateRange +=
            '${_currentFilter.startDate!.day}/${_currentFilter.startDate!.month}/${_currentFilter.startDate!.year}';
      }
      dateRange += ' - ';
      if (_currentFilter.endDate != null) {
        dateRange +=
            '${_currentFilter.endDate!.day}/${_currentFilter.endDate!.month}/${_currentFilter.endDate!.year}';
      }
      summaries.add('Date: $dateRange');
    }

    return summaries.join(' | ');
  }

  // ✅ UPDATED: Get active filter count (including remarks)
  int getActiveFilterCount() {
    int count = 0;

    if (_currentFilter.status != null) count++;
    if (_currentFilter.transactionType != null) count++;
    if (_currentFilter.searchQuery?.isNotEmpty == true) count++;
    if (_currentFilter.midFilter.isNotEmpty) count++;
    if (_currentFilter.machineFilter?.isNotEmpty == true) count++;
    if (_currentFilter.paymentModes.isNotEmpty) count++;
    if (_currentFilter.showDiscrepanciesOnly) count++;
    if (_currentFilter.minAmount != null) count++;
    if (_currentFilter.maxAmount != null) count++;
    if (_currentFilter.startDate != null) count++;
    if (_currentFilter.endDate != null) count++;
    if (_currentFilter.remarksFilter.isNotEmpty) count++; // ✅ NEW
    if (_currentFilter.selectedRemarksTypes.isNotEmpty) count++; // ✅ NEW

    return count;
  }

  // ✅ Export current filter as Map (for persistence/debugging)
  Map<String, dynamic> exportFilter() {
    return _currentFilter.toMap();
  }

  // ✅ UPDATED: Import filter from Map (including remarks)
  void importFilter(Map<String, dynamic> filterMap) {
    try {
      _currentFilter = FilterModel(
        status: filterMap['status'] != null
            ? ReconciliationStatus.values
                .firstWhere((s) => s.label == filterMap['status'])
            : null,
        transactionType: filterMap['transactionType'] != null
            ? TransactionType.values
                .firstWhere((t) => t.label == filterMap['transactionType'])
            : null,
        searchQuery: filterMap['searchQuery'],
        minAmount: filterMap['minAmount']?.toDouble(),
        maxAmount: filterMap['maxAmount']?.toDouble(),
        machineFilter: filterMap['machineFilter'],
        showDiscrepanciesOnly: filterMap['showDiscrepanciesOnly'] ?? false,
        midFilter: filterMap['midFilter'] ?? '',
        paymentModes: List<String>.from(filterMap['paymentModes'] ?? []),
        startDate: filterMap['startDate'] != null
            ? DateTime.parse(filterMap['startDate'])
            : null,
        endDate: filterMap['endDate'] != null
            ? DateTime.parse(filterMap['endDate'])
            : null,
        remarksFilter: filterMap['remarksFilter'] ?? '', // ✅ NEW
        selectedRemarksTypes:
            List<String>.from(filterMap['selectedRemarksTypes'] ?? []), // ✅ NEW
      );
      notifyListeners();
    } catch (e) {
      print('Error importing filter: $e');
      // Fall back to empty filter
      clearAllFilters();
    }
  }
}

// Theme Provider
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData {
    return _isDarkMode
        ? ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          )
        : ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          );
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

// App State Provider
class AppStateProvider extends ChangeNotifier {
  String _appTitle = 'Reconciliation Dashboard';
  bool _isLoading = false;

  String get appTitle => _appTitle;
  bool get isLoading => _isLoading;

  void setAppTitle(String title) {
    _appTitle = title;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

// Upload State Provider (Enhanced with better state management)
class UploadStateProvider extends ChangeNotifier {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  String? _uploadedFileName;
  bool _isDragOver = false;
  String _uploadStatus = '';
  Map<String, dynamic>? _uploadResult;

  // Getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get uploadError => _uploadError;
  String? get uploadedFileName => _uploadedFileName;
  bool get isDragOver => _isDragOver;
  String get uploadStatus => _uploadStatus;
  Map<String, dynamic>? get uploadResult => _uploadResult;

  void startUpload(String fileName) {
    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadError = null;
    _uploadedFileName = fileName;
    _uploadStatus = 'Starting upload...';
    _uploadResult = null;
    notifyListeners();
  }

  void updateProgress(double progress, {String? status}) {
    _uploadProgress = progress.clamp(0.0, 1.0);
    if (status != null) {
      _uploadStatus = status;
    }
    notifyListeners();
  }

  void completeUpload(Map<String, dynamic>? result) {
    _isUploading = false;
    _uploadProgress = 1.0;
    _uploadStatus = 'Upload complete!';
    _uploadResult = result;
    notifyListeners();
  }

  void failUpload(String error) {
    _isUploading = false;
    _uploadError = error;
    _uploadStatus = 'Upload failed';
    notifyListeners();
  }

  void resetUpload() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadError = null;
    _uploadedFileName = null;
    _isDragOver = false;
    _uploadStatus = '';
    _uploadResult = null;
    notifyListeners();
  }

  void setDragOver(bool isDragOver) {
    _isDragOver = isDragOver;
    notifyListeners();
  }

  void clearError() {
    _uploadError = null;
    notifyListeners();
  }
}

// NEW: Processing State Provider for managing batch processing
class ProcessingStateProvider extends ChangeNotifier {
  bool _isProcessing = false;
  Map<String, dynamic>? _processingStatus;
  String? _processingError;
  Timer? _statusTimer;

  // Getters
  bool get isProcessing => _isProcessing;
  Map<String, dynamic>? get processingStatus => _processingStatus;
  String? get processingError => _processingError;

  // Derived getters for convenience
  int get currentStep => _processingStatus?['current_step'] ?? 0;
  int get totalSteps => _processingStatus?['total_steps'] ?? 3;
  double get progress => (_processingStatus?['progress'] ?? 0.0) / 100.0;
  String get stepName => _processingStatus?['step_name'] ?? '';
  String get message => _processingStatus?['message'] ?? '';
  bool get isCompleted => _processingStatus?['completed'] == true;
  bool get hasError => _processingStatus?['error'] != null;

  Future<void> startProcessing() async {
    try {
      _isProcessing = true;
      _processingError = null;
      _processingStatus = null;
      notifyListeners();

      // This would call the actual backend service
      // For now, simulating the start
      _processingStatus = {
        'is_processing': true,
        'current_step': 1,
        'total_steps': 3,
        'step_name': 'Starting',
        'progress': 0.0,
        'message': 'Initializing processing...',
        'error': null,
        'completed': false
      };

      _startStatusPolling();
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _processingError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // This would call the actual backend status endpoint
        // For now, simulating progress
        if (_processingStatus != null) {
          var currentProgress = _processingStatus!['progress'] ?? 0.0;
          if (currentProgress < 100) {
            _processingStatus!['progress'] = currentProgress + 10;
            _processingStatus!['message'] = 'Processing step ${currentStep}...';

            if (currentProgress >= 90) {
              _processingStatus!['completed'] = true;
              _processingStatus!['is_processing'] = false;
              _processingStatus!['message'] =
                  'Processing completed successfully!';
              _isProcessing = false;
              timer.cancel();
            }

            notifyListeners();
          }
        }
      } catch (e) {
        print('Error polling processing status: $e');
      }
    });
  }

  void stopProcessing() {
    _isProcessing = false;
    _statusTimer?.cancel();
    notifyListeners();
  }

  void resetProcessing() {
    _isProcessing = false;
    _processingStatus = null;
    _processingError = null;
    _statusTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}

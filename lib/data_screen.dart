// import 'dart:core';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:data_table_2/data_table_2.dart';
// import 'package:intl/intl.dart';
// import 'package:reconciliation_app/ReconProvider.dart';
// import 'models.dart';
// import 'providers.dart';
// import 'widgets.dart';

// class DataScreen extends StatefulWidget {
//   const DataScreen({super.key});

//   @override
//   State<DataScreen> createState() => _DataScreenState();
// }

// class _DataScreenState extends State<DataScreen>
//     with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
//   @override
//   bool get wantKeepAlive => true;

//   late TabController _tabController;
//   final Map<String, TextEditingController> _searchControllers = {};

//   // Sheet configurations
//   final List<SheetConfig> sheets = [
//     SheetConfig(
//       id: 'SUMMARY',
//       name: 'Summary',
//       icon: Icons.summarize,
//       description: 'Transaction summary by source and type',
//     ),
//     SheetConfig(
//       id: 'RAWDATA',
//       name: 'Raw Data',
//       icon: Icons.data_array,
//       description: 'All raw transaction data',
//     ),
//     SheetConfig(
//       id: 'RECON_SUCCESS',
//       name: 'Perfect Matches',
//       icon: Icons.check_circle,
//       description: 'Perfect reconciliation matches',
//     ),
//     SheetConfig(
//       id: 'RECON_INVESTIGATE',
//       name: 'Investigate',
//       icon: Icons.warning,
//       description: 'Transactions requiring investigation',
//     ),
//     SheetConfig(
//       id: 'MANUAL_REFUND',
//       name: 'Manual Refunds',
//       icon: Icons.edit,
//       description: 'Manual refund transactions',
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: sheets.length, vsync: this);

//     // Initialize search controllers
//     for (var sheet in sheets) {
//       _searchControllers[sheet.id] = TextEditingController();
//     }

//     // Load initial data
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ReconProvider>().loadAllSheets();
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     for (var controller in _searchControllers.values) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Consumer<ReconProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           appBar: AppBar(
//             title: Text('Reconciliation Dashboard'),
//             backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//             elevation: 0,
//             actions: [
//               // Refresh button
//               IconButton(
//                 onPressed:
//                     provider.isLoading ? null : () => provider.loadAllSheets(),
//                 icon: provider.isLoading
//                     ? SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : Icon(Icons.refresh),
//                 tooltip: 'Refresh Data',
//               ),
//               SizedBox(width: 8),
//             ],
//             bottom: TabBar(
//               controller: _tabController,
//               isScrollable: true,
//               tabs: sheets
//                   .map((sheet) => Tab(
//                         icon: Icon(sheet.icon, size: 20),
//                         text: sheet.name,
//                       ))
//                   .toList(),
//             ),
//           ),
//           body: Column(
//             children: [
//               // Error/Success Messages
//               if (provider.error != null)
//                 Container(
//                   width: double.infinity,
//                   color: Colors.red.shade50,
//                   padding: EdgeInsets.all(12),
//                   child: Row(
//                     children: [
//                       Icon(Icons.error, color: Colors.red),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           provider.error!,
//                           style: TextStyle(color: Colors.red.shade700),
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () => provider.clearError(),
//                         icon: Icon(Icons.close, color: Colors.red),
//                       ),
//                     ],
//                   ),
//                 ),

//               if (provider.successMessage != null)
//                 Container(
//                   width: double.infinity,
//                   color: Colors.green.shade50,
//                   padding: EdgeInsets.all(12),
//                   child: Row(
//                     children: [
//                       Icon(Icons.check_circle, color: Colors.green),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           provider.successMessage!,
//                           style: TextStyle(color: Colors.green.shade700),
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () => provider.clearSuccess(),
//                         icon: Icon(Icons.close, color: Colors.green),
//                       ),
//                     ],
//                   ),
//                 ),

//               // Tab Content
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: sheets
//                       .map((sheet) => _buildSheetTab(context, provider, sheet))
//                       .toList(),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSheetTab(
//       BuildContext context, ReconProvider provider, SheetConfig sheet) {
//     final sheetData = provider.getSheetData(sheet.id);
//     final isLoading = provider.isLoading;

//     return Column(
//       children: [
//         // Sheet Header with Search
//         Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 4,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Sheet title and description
//               Row(
//                 children: [
//                   Icon(sheet.icon, size: 24),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           sheet.name,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           sheet.description,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color:
//                                 Theme.of(context).colorScheme.onSurfaceVariant,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Record count
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Text(
//                       '${sheetData?.length ?? 0} records',
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.primary,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 12),

//               // Search bar for applicable sheets
//               if (_shouldShowSearch(sheet.id))
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _searchControllers[sheet.id],
//                         decoration: InputDecoration(
//                           hintText: 'Search ${sheet.name.toLowerCase()}...',
//                           prefixIcon: Icon(Icons.search),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 12,
//                           ),
//                         ),
//                         onChanged: (value) => _onSearchChanged(sheet.id, value),
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     ElevatedButton.icon(
//                       onPressed: () => _clearSearch(sheet.id),
//                       icon: Icon(Icons.clear, size: 18),
//                       label: Text('Clear'),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ),

//         // Sheet Content
//         Expanded(
//           child: _buildSheetContent(
//               context, provider, sheet, sheetData, isLoading),
//         ),
//       ],
//     );
//   }

//   Widget _buildSheetContent(
//       BuildContext context,
//       ReconProvider provider,
//       SheetConfig sheet,
//       List<Map<String, dynamic>>? sheetData,
//       bool isLoading) {
//     if (isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading ${sheet.name.toLowerCase()}...'),
//           ],
//         ),
//       );
//     }

//     if (sheetData == null || sheetData.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.inbox, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               'No data available for ${sheet.name}',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//             SizedBox(height: 8),
//             ElevatedButton.icon(
//               onPressed: () => provider.loadSheet(sheet.id),
//               icon: Icon(Icons.refresh),
//               label: Text('Reload'),
//             ),
//           ],
//         ),
//       );
//     }

//     // Build appropriate table based on sheet type
//     switch (sheet.id) {
//       case 'SUMMARY':
//         return _buildSummaryTable(context, sheetData);
//       case 'RAWDATA':
//         return _buildRawDataTable(context, sheetData);
//       case 'RECON_SUCCESS':
//       case 'RECON_INVESTIGATE':
//       case 'MANUAL_REFUND':
//         return _buildReconTable(context, sheetData, sheet);
//       default:
//         return _buildGenericTable(context, sheetData);
//     }
//   }

//   // Summary Table
//   Widget _buildSummaryTable(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       margin: EdgeInsets.all(16),
//       child: DataTable2(
//         columnSpacing: 12,
//         horizontalMargin: 12,
//         minWidth: 600,
//         headingRowHeight: 56,
//         dataRowHeight: 48,
//         headingRowColor: MaterialStateProperty.all(
//           Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         ),
//         columns: [
//           DataColumn2(label: Text('Transaction Source'), size: ColumnSize.L),
//           DataColumn2(label: Text('Transaction Type'), size: ColumnSize.L),
//           DataColumn2(
//               label: Text('Total Amount'), size: ColumnSize.M, numeric: true),
//         ],
//         rows: data
//             .map((row) => DataRow2(
//                   cells: [
//                     DataCell(Text(row['txn_source']?.toString() ?? '')),
//                     DataCell(Text(row['Txn_type']?.toString() ?? '')),
//                     DataCell(Text(
//                       currencyFormat.format(double.tryParse(
//                               row['sum(Txn_Amount)']?.toString() ?? '0') ??
//                           0),
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                     )),
//                   ],
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   // Raw Data Table
//   Widget _buildRawDataTable(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       margin: EdgeInsets.all(16),
//       child: DataTable2(
//         columnSpacing: 12,
//         horizontalMargin: 12,
//         minWidth: 800,
//         headingRowHeight: 56,
//         dataRowHeight: 48,
//         headingRowColor: MaterialStateProperty.all(
//           Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         ),
//         columns: [
//           DataColumn2(label: Text('Ref No'), size: ColumnSize.M),
//           DataColumn2(label: Text('Source'), size: ColumnSize.S),
//           DataColumn2(label: Text('Type'), size: ColumnSize.S),
//           DataColumn2(label: Text('Amount'), size: ColumnSize.S, numeric: true),
//           DataColumn2(label: Text('Date'), size: ColumnSize.S),
//           DataColumn2(label: Text('MID'), size: ColumnSize.M),
//         ],
//         rows: data
//             .map((row) => DataRow2(
//                   cells: [
//                     DataCell(Text(row['Txn_RefNo']?.toString() ?? '')),
//                     DataCell(Text(row['Txn_Source']?.toString() ?? '')),
//                     DataCell(Text(row['Txn_Type']?.toString() ?? '')),
//                     DataCell(Text(
//                       currencyFormat.format(double.tryParse(
//                               row['Txn_Amount']?.toString() ?? '0') ??
//                           0),
//                     )),
//                     DataCell(Text(row['Txn_Date']?.toString() ?? '')),
//                     DataCell(Text(row['Txn_MID']?.toString() ?? '')),
//                   ],
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   // Reconciliation Tables (Success/Investigate/Manual)
//   Widget _buildReconTable(BuildContext context, List<Map<String, dynamic>> data,
//       SheetConfig sheet) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       margin: EdgeInsets.all(16),
//       child: DataTable2(
//         columnSpacing: 12,
//         horizontalMargin: 12,
//         minWidth: 1200,
//         headingRowHeight: 56,
//         dataRowHeight: 60,
//         headingRowColor: MaterialStateProperty.all(
//           Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         ),
//         columns: [
//           DataColumn2(label: Text('Ref No'), size: ColumnSize.M),
//           DataColumn2(label: Text('MID'), size: ColumnSize.M),
//           DataColumn2(label: Text('Machine'), size: ColumnSize.S),
//           DataColumn2(
//               label: Text('PTPP Payment'), size: ColumnSize.S, numeric: true),
//           DataColumn2(
//               label: Text('PTPP Refund'), size: ColumnSize.S, numeric: true),
//           DataColumn2(
//               label: Text('Cloud Payment'), size: ColumnSize.S, numeric: true),
//           DataColumn2(
//               label: Text('Cloud Refund'), size: ColumnSize.S, numeric: true),
//           DataColumn2(
//               label: Text('Cloud M-Refund'), size: ColumnSize.S, numeric: true),
//           DataColumn2(label: Text('Remarks'), size: ColumnSize.M),
//           DataColumn2(label: Text('Actions'), size: ColumnSize.S),
//         ],
//         rows: data.map((row) {
//           final ptppTotal =
//               (double.tryParse(row['PTPP_Payment']?.toString() ?? '0') ?? 0) +
//                   (double.tryParse(row['PTPP_Refund']?.toString() ?? '0') ?? 0);
//           final cloudTotal =
//               (double.tryParse(row['Cloud_Payment']?.toString() ?? '0') ?? 0) +
//                   (double.tryParse(row['Cloud_Refund']?.toString() ?? '0') ??
//                       0) +
//                   (double.tryParse(row['Cloud_MRefund']?.toString() ?? '0') ??
//                       0);
//           final hasDiscrepancy = (ptppTotal - cloudTotal).abs() > 0.01;

//           return DataRow2(
//             color: MaterialStateProperty.resolveWith((states) {
//               if (hasDiscrepancy) {
//                 return Colors.red.withOpacity(0.05);
//               } else if (sheet.id == 'RECON_SUCCESS') {
//                 return Colors.green.withOpacity(0.05);
//               }
//               return null;
//             }),
//             cells: [
//               DataCell(
//                 SelectableText(
//                   row['Txn_RefNo']?.toString() ?? '',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ),
//               DataCell(Text(row['Txn_MID']?.toString() ?? '')),
//               DataCell(Text(row['Txn_Machine']?.toString() ?? '')),
//               DataCell(Text(currencyFormat.format(
//                   double.tryParse(row['PTPP_Payment']?.toString() ?? '0') ??
//                       0))),
//               DataCell(Text(currencyFormat.format(
//                   double.tryParse(row['PTPP_Refund']?.toString() ?? '0') ??
//                       0))),
//               DataCell(Text(currencyFormat.format(
//                   double.tryParse(row['Cloud_Payment']?.toString() ?? '0') ??
//                       0))),
//               DataCell(Text(currencyFormat.format(
//                   double.tryParse(row['Cloud_Refund']?.toString() ?? '0') ??
//                       0))),
//               DataCell(Text(currencyFormat.format(
//                   double.tryParse(row['Cloud_MRefund']?.toString() ?? '0') ??
//                       0))),
//               DataCell(
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: _getRemarksColor(row['Remarks']?.toString() ?? ''),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     row['Remarks']?.toString() ?? '',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//               DataCell(
//                 PopupMenuButton<String>(
//                   icon: Icon(Icons.more_vert),
//                   onSelected: (value) => _handleRowAction(context, row, value),
//                   itemBuilder: (context) => [
//                     PopupMenuItem(
//                       value: 'copy',
//                       child: Row(
//                         children: [
//                           Icon(Icons.copy, size: 16),
//                           SizedBox(width: 8),
//                           Text('Copy Ref No'),
//                         ],
//                       ),
//                     ),
//                     PopupMenuItem(
//                       value: 'details',
//                       child: Row(
//                         children: [
//                           Icon(Icons.info, size: 16),
//                           SizedBox(width: 8),
//                           Text('View Details'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // Generic table for unknown sheet types
//   Widget _buildGenericTable(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     if (data.isEmpty) return Center(child: Text('No data available'));

//     final columns = data.first.keys.toList();

//     return Card(
//       margin: EdgeInsets.all(16),
//       child: DataTable2(
//         columnSpacing: 12,
//         horizontalMargin: 12,
//         minWidth: columns.length * 120.0,
//         headingRowHeight: 56,
//         dataRowHeight: 48,
//         headingRowColor: MaterialStateProperty.all(
//           Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         ),
//         columns: columns
//             .map((column) => DataColumn2(
//                   label: Text(column),
//                   size: ColumnSize.M,
//                 ))
//             .toList(),
//         rows: data
//             .map((row) => DataRow2(
//                   cells: columns
//                       .map((column) => DataCell(
//                             Text(row[column]?.toString() ?? ''),
//                           ))
//                       .toList(),
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   // Helper methods
//   bool _shouldShowSearch(String sheetId) {
//     return ['RECON_SUCCESS', 'RECON_INVESTIGATE', 'MANUAL_REFUND', 'RAWDATA']
//         .contains(sheetId);
//   }

//   void _onSearchChanged(String sheetId, String value) {
//     // Debounce search to avoid too many API calls
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (_searchControllers[sheetId]?.text == value) {
//         context.read<ReconProvider>().searchSheet(sheetId, value);
//       }
//     });
//   }

//   void _clearSearch(String sheetId) {
//     _searchControllers[sheetId]?.clear();
//     context.read<ReconProvider>().searchSheet(sheetId, '');
//   }

//   Color _getRemarksColor(String remarks) {
//     if (remarks.toLowerCase().contains('perfect')) {
//       return Colors.green;
//     } else if (remarks.toLowerCase().contains('investigate')) {
//       return Colors.orange;
//     } else if (remarks.toLowerCase().contains('manual')) {
//       return Colors.purple;
//     }
//     return Colors.blue;
//   }

//   void _handleRowAction(
//       BuildContext context, Map<String, dynamic> row, String action) {
//     switch (action) {
//       case 'copy':
//         Clipboard.setData(
//             ClipboardData(text: row['Txn_RefNo']?.toString() ?? ''));
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Reference number copied to clipboard')),
//         );
//         break;
//       case 'details':
//         _showTransactionDetails(context, row);
//         break;
//     }
//   }

//   void _showTransactionDetails(BuildContext context, Map<String, dynamic> row) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Transaction Details'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: row.entries
//                 .map((entry) => Padding(
//                       padding: EdgeInsets.symmetric(vertical: 4),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             width: 120,
//                             child: Text(
//                               '${entry.key}:',
//                               style: TextStyle(fontWeight: FontWeight.w500),
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(entry.value?.toString() ?? ''),
//                           ),
//                         ],
//                       ),
//                     ))
//                 .toList(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Sheet configuration model
// class SheetConfig {
//   final String id;
//   final String name;
//   final IconData icon;
//   final String description;

//   SheetConfig({
//     required this.id,
//     required this.name,
//     required this.icon,
//     required this.description,
//   });
// }

//2

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:data_table_2/data_table_2.dart';
// import 'package:intl/intl.dart';
// import 'ReconProvider.dart';

// class DataScreen extends StatefulWidget {
//   @override
//   _DataScreenState createState() => _DataScreenState();
// }

// class _DataScreenState extends State<DataScreen>
//     with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
//   late TabController _tabController;

//   // Search controllers with debouncing
//   final Map<String, TextEditingController> _searchControllers = {};
//   final Map<String, bool> _isSearching = {};

//   // Pagination for large datasets
//   final Map<String, int> _currentPage = {};
//   final int _itemsPerPage = 50; // Reduced from 100 for better performance

//   // Filter controllers
//   final Map<String, Map<String, TextEditingController>> _filterControllers = {};

//   final List<SheetConfig> _sheets = [
//     SheetConfig('SUMMARY', 'Summary', Icons.summarize,
//         'Transaction summary by source and type'),
//     SheetConfig('RECON_SUCCESS', 'Perfect Matches', Icons.check_circle,
//         'Transactions with perfect reconciliation'),
//     SheetConfig('RECON_INVESTIGATE', 'Investigate', Icons.warning,
//         'Transactions requiring investigation'),
//     SheetConfig('MANUAL_REFUND', 'Manual Refunds', Icons.settings,
//         'Manual refund transactions'),
//     SheetConfig(
//         'RAWDATA', 'Raw Data', Icons.table_rows, 'All raw transaction data'),
//   ];

//   @override
//   bool get wantKeepAlive => true; // Keep state when switching tabs

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: _sheets.length, vsync: this);

//     // Initialize controllers for each sheet
//     for (var sheet in _sheets) {
//       _searchControllers[sheet.id] = TextEditingController();
//       _isSearching[sheet.id] = false;
//       _currentPage[sheet.id] = 0;
//       _filterControllers[sheet.id] = _initializeFiltersForSheet(sheet.id);
//     }

//     // Load initial data
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<ReconProvider>(context, listen: false).loadAllSheets();
//     });
//   }

//   Map<String, TextEditingController> _initializeFiltersForSheet(
//       String sheetId) {
//     switch (sheetId) {
//       case 'SUMMARY':
//         return {
//           'source': TextEditingController(),
//           'type': TextEditingController(),
//         };
//       case 'RAWDATA':
//         return {
//           'source': TextEditingController(),
//           'type': TextEditingController(),
//           'machine': TextEditingController(),
//         };
//       case 'RECON_SUCCESS':
//       case 'RECON_INVESTIGATE':
//       case 'MANUAL_REFUND':
//         return {
//           'refNo': TextEditingController(),
//           'machine': TextEditingController(),
//           'mid': TextEditingController(),
//           'remarks': TextEditingController(),
//         };
//       default:
//         return {};
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchControllers.values.forEach((controller) => controller.dispose());
//     _filterControllers.values.forEach((filterMap) {
//       filterMap.values.forEach((controller) => controller.dispose());
//     });
//     super.dispose();
//   }

//   @override

//   Widget _buildSheetTab(
//       BuildContext context, ReconProvider provider, SheetConfig sheet) {
//     final sheetData = provider.getSheetData(sheet.id);
//     final isLoading = provider.isLoading;

//     return Column(
//       children: [
//         // Sheet Header with Info and Filters
//         Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             border: Border(
//               bottom: BorderSide(color: Colors.grey.shade200),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Sheet info row
//               Row(
//                 children: [
//                   Icon(sheet.icon, color: Theme.of(context).primaryColor),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           sheet.name,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           sheet.description,
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Record count
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Text(
//                       '${_getDisplayedRecordCount(sheetData)} records',
//                       style: TextStyle(
//                         color: Theme.of(context).primaryColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 12),

//               // Filters Row
//               _buildFiltersRow(context, sheet, provider),
//             ],
//           ),
//         ),

//         // Sheet Content
//         Expanded(
//           child: _buildSheetContent(
//               context, provider, sheet, sheetData, isLoading),
//         ),
//       ],
//     );
//   }

//   Widget _buildFiltersRow(
//       BuildContext context, SheetConfig sheet, ReconProvider provider) {
//     final filters = _filterControllers[sheet.id] ?? {};

//     if (filters.isEmpty) {
//       return SizedBox.shrink();
//     }

//     return Wrap(
//       spacing: 12,
//       runSpacing: 8,
//       children: [
//         // Search field (always present)
//         SizedBox(
//           width: 250,
//           child: TextField(
//             controller: _searchControllers[sheet.id],
//             decoration: InputDecoration(
//               hintText: 'Search ${sheet.name.toLowerCase()}...',
//               prefixIcon: Icon(Icons.search, size: 20),
//               suffixIcon: _searchControllers[sheet.id]!.text.isNotEmpty
//                   ? IconButton(
//                       icon: Icon(Icons.clear, size: 20),
//                       onPressed: () => _clearSearch(sheet.id),
//                     )
//                   : null,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               isDense: true,
//             ),
//             onChanged: (value) => _onSearchChanged(sheet.id, value),
//           ),
//         ),

//         // Sheet-specific filters
//         ...filters.entries
//             .map(
//               (entry) => SizedBox(
//                 width: 150,
//                 child: TextField(
//                   controller: entry.value,
//                   decoration: InputDecoration(
//                     hintText: _getFilterHint(entry.key),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                     contentPadding:
//                         EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     isDense: true,
//                   ),
//                   onChanged: (value) =>
//                       _onFilterChanged(sheet.id, entry.key, value),
//                 ),
//               ),
//             )
//             .toList(),

//         // Clear all filters button
//         TextButton.icon(
//           onPressed: () => _clearAllFilters(sheet.id),
//           icon: Icon(Icons.clear_all, size: 18),
//           label: Text('Clear All'),
//         ),
//       ],
//     );
//   }

//   String _getFilterHint(String filterKey) {
//     switch (filterKey) {
//       case 'source':
//         return 'Filter by source';
//       case 'type':
//         return 'Filter by type';
//       case 'machine':
//         return 'Filter by machine';
//       case 'refNo':
//         return 'Filter by ref no';
//       case 'mid':
//         return 'Filter by MID';
//       case 'remarks':
//         return 'Filter by remarks';
//       default:
//         return 'Filter';
//     }
//   }

//   Widget _buildSheetContent(
//       BuildContext context,
//       ReconProvider provider,
//       SheetConfig sheet,
//       List<Map<String, dynamic>>? sheetData,
//       bool isLoading) {
//     if (isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading ${sheet.name.toLowerCase()}...'),
//           ],
//         ),
//       );
//     }

//     if (sheetData == null || sheetData.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.inbox, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               'No data available for ${sheet.name}',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//             SizedBox(height: 8),
//             ElevatedButton.icon(
//               onPressed: () => provider.loadSheet(sheet.id),
//               icon: Icon(Icons.refresh),
//               label: Text('Reload'),
//             ),
//           ],
//         ),
//       );
//     }

//     // Apply filters and pagination
//     final filteredData = _applyFilters(sheetData, sheet.id);
//     final paginatedData = _getPaginatedData(filteredData, sheet.id);

//     return Column(
//       children: [
//         // Pagination info
//         if (filteredData.length > _itemsPerPage)
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Showing ${_getStartIndex(sheet.id) + 1}-${(_getStartIndex(sheet.id) + paginatedData.length).clamp(0, filteredData.length)} of ${filteredData.length}',
//                   style: TextStyle(color: Colors.grey.shade600),
//                 ),
//                 _buildPaginationControls(sheet.id, filteredData.length),
//               ],
//             ),
//           ),

//         // FIXED: Properly constrained data table
//         Expanded(
//           child: _buildConstrainedDataTable(context, paginatedData, sheet),
//         ),
//       ],
//     );
//   }

//   Widget _buildConstrainedDataTable(BuildContext context,
//       List<Map<String, dynamic>> data, SheetConfig sheet) {
//     if (data.isEmpty) {
//       return Center(
//         child: Text(
//           'No data matches the current filters',
//           style: TextStyle(color: Colors.grey.shade600),
//         ),
//       );
//     }

//     // Use LayoutBuilder to get available space
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // Ensure we have valid constraints
//         if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
//           return Container(
//             child: Center(
//               child: Text('Loading layout...'),
//             ),
//           );
//         }

//         return SingleChildScrollView(
//           padding: EdgeInsets.all(16),
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: 0,
//               maxHeight: constraints.maxHeight - 32, // Account for padding
//               minWidth: constraints.maxWidth - 32,
//               maxWidth: double.infinity,
//             ),
//             child: _buildDataTableForSheet(context, data, sheet),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDataTableForSheet(BuildContext context,
//       List<Map<String, dynamic>> data, SheetConfig sheet) {
//     switch (sheet.id) {
//       case 'SUMMARY':
//         return _buildSummaryTableFixed(context, data);
//       case 'RAWDATA':
//         return _buildRawDataTableFixed(context, data);
//       case 'RECON_SUCCESS':
//       case 'RECON_INVESTIGATE':
//       case 'MANUAL_REFUND':
//         return _buildReconTableFixed(context, data, sheet);
//       default:
//         return _buildGenericTableFixed(context, data);
//     }
//   }

//   Widget _buildSummaryTableFixed(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal, // Allow horizontal scrolling
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minWidth: 600, // Minimum width
//           ),
//           child: DataTable(
//             columnSpacing: 12,
//             headingRowHeight: 48,
//             dataRowHeight: 40,
//             headingRowColor: MaterialStateProperty.all(
//               Theme.of(context).colorScheme.primary.withOpacity(0.1),
//             ),
//             columns: [
//               DataColumn(
//                 label: Expanded(
//                   child: Text(
//                     'Source',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               DataColumn(
//                 label: Expanded(
//                   child: Text(
//                     'Type',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               DataColumn(
//                 label: Expanded(
//                   child: Text(
//                     'Amount',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 numeric: true,
//               ),
//             ],
//             rows: data
//                 .map((row) => DataRow(
//                       cells: [
//                         DataCell(
//                           Container(
//                             constraints: BoxConstraints(maxWidth: 150),
//                             child: Text(
//                               row['txn_source']?.toString() ?? '',
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             constraints: BoxConstraints(maxWidth: 150),
//                             child: Text(
//                               row['Txn_type']?.toString() ?? '',
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Text(
//                             currencyFormat.format(double.tryParse(
//                                     row['sum(Txn_Amount)']?.toString() ??
//                                         '0') ??
//                                 0),
//                           ),
//                         ),
//                       ],
//                     ))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRawDataTableFixed(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minWidth: 800,
//           ),
//           child: DataTable(
//             columnSpacing: 8,
//             headingRowHeight: 48,
//             dataRowHeight: 40,
//             headingRowColor: MaterialStateProperty.all(
//               Theme.of(context).colorScheme.primary.withOpacity(0.1),
//             ),
//             columns: [
//               DataColumn(
//                 label: Container(
//                   width: 120,
//                   child: Text(
//                     'Ref No',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 100,
//                   child: Text(
//                     'Source',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 100,
//                   child: Text(
//                     'Type',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 100,
//                   child: Text(
//                     'Machine',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 100,
//                   child: Text(
//                     'Amount',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 numeric: true,
//               ),
//             ],
//             rows: data
//                 .map((row) => DataRow(
//                       cells: [
//                         DataCell(
//                           Container(
//                             width: 120,
//                             child: Text(
//                               row['Txn_RefNo']?.toString() ?? '',
//                               style: TextStyle(fontSize: 12),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 100,
//                             child: Text(
//                               row['Txn_Source']?.toString() ?? '',
//                               style: TextStyle(fontSize: 12),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 100,
//                             child: Text(
//                               row['Txn_Type']?.toString() ?? '',
//                               style: TextStyle(fontSize: 12),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 100,
//                             child: Text(
//                               row['Txn_Machine']?.toString() ?? '',
//                               style: TextStyle(fontSize: 12),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 100,
//                             child: Text(
//                               currencyFormat.format(double.tryParse(
//                                       row['Txn_Amount']?.toString() ?? '0') ??
//                                   0),
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildReconTableFixed(BuildContext context,
//       List<Map<String, dynamic>> data, SheetConfig sheet) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minWidth: 1000,
//           ),
//           child: DataTable(
//             columnSpacing: 8,
//             headingRowHeight: 48,
//             dataRowHeight: 40,
//             headingRowColor: MaterialStateProperty.all(
//               Theme.of(context).colorScheme.primary.withOpacity(0.1),
//             ),
//             columns: [
//               DataColumn(
//                 label: Container(
//                   width: 120,
//                   child: Text('Ref No',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 100,
//                   child: Text('Machine',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 80,
//                   child: Text('PTPP Pay',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//                 numeric: true,
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 80,
//                   child: Text('PTPP Ref',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//                 numeric: true,
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 80,
//                   child: Text('Cloud Pay',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//                 numeric: true,
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 80,
//                   child: Text('Cloud Ref',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//                 numeric: true,
//               ),
//               DataColumn(
//                 label: Container(
//                   width: 100,
//                   child: Text('Remarks',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ),
//             ],
//             rows: data
//                 .map((row) => DataRow(
//                       cells: [
//                         DataCell(
//                           Container(
//                             width: 120,
//                             child: Text(
//                               row['Txn_RefNo']?.toString() ?? '',
//                               style: TextStyle(fontSize: 12),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 100,
//                             child: Text(
//                               row['Txn_Machine']?.toString() ?? '',
//                               style: TextStyle(fontSize: 12),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 80,
//                             child: Text(
//                               currencyFormat.format(double.tryParse(
//                                       row['PTPP_Payment']?.toString() ?? '0') ??
//                                   0),
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 80,
//                             child: Text(
//                               currencyFormat.format(double.tryParse(
//                                       row['PTPP_Refund']?.toString() ?? '0') ??
//                                   0),
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 80,
//                             child: Text(
//                               currencyFormat.format(double.tryParse(
//                                       row['Cloud_Payment']?.toString() ??
//                                           '0') ??
//                                   0),
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 80,
//                             child: Text(
//                               currencyFormat.format(double.tryParse(
//                                       row['Cloud_Refund']?.toString() ?? '0') ??
//                                   0),
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           Container(
//                             width: 100,
//                             constraints: BoxConstraints(maxHeight: 40),
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: _getRemarksColor(
//                                     row['Remarks']?.toString() ?? ''),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 row['Remarks']?.toString() ?? '',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }

// // 7. FIXED: Generic Table with constraints
//   Widget _buildGenericTableFixed(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     if (data.isEmpty) return Center(child: Text('No data available'));

//     final columns =
//         data.first.keys.take(6).toList(); // Limit columns for performance

//     return Card(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minWidth: columns.length * 120.0,
//           ),
//           child: DataTable(
//             columnSpacing: 12,
//             headingRowHeight: 48,
//             dataRowHeight: 40,
//             headingRowColor: MaterialStateProperty.all(
//               Theme.of(context).colorScheme.primary.withOpacity(0.1),
//             ),
//             columns: columns
//                 .map((column) => DataColumn(
//                       label: Container(
//                         width: 120,
//                         child: Text(
//                           column,
//                           style: TextStyle(
//                               fontSize: 13, fontWeight: FontWeight.bold),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ))
//                 .toList(),
//             rows: data
//                 .map((row) => DataRow(
//                       cells: columns
//                           .map((column) => DataCell(
//                                 Container(
//                                   width: 120,
//                                   child: Text(
//                                     _formatCellValue(row[column]),
//                                     style: TextStyle(fontSize: 12),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ))
//                           .toList(),
//                     ))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }

// // 8. ADDITIONAL FIX: Wrap your main TabBarView with proper constraints
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Consumer<ReconProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           appBar: AppBar(
//             title: Text('Reconciliation Data'),
//             elevation: 0,
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.refresh),
//                 onPressed:
//                     provider.isLoading ? null : () => provider.loadAllSheets(),
//                 tooltip: 'Refresh All Data',
//               ),
//             ],
//             bottom: TabBar(
//               controller: _tabController,
//               isScrollable: true,
//               indicatorWeight: 3,
//               labelStyle: TextStyle(fontWeight: FontWeight.w600),
//               tabs: _sheets
//                   .map((sheet) => Tab(
//                         icon: Icon(sheet.icon, size: 20),
//                         text: sheet.name,
//                       ))
//                   .toList(),
//             ),
//           ),
//           body: Column(
//             children: [
//               // Error/Loading states
//               if (provider.error != null)
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(16),
//                   color: Colors.red.shade50,
//                   child: Row(
//                     children: [
//                       Icon(Icons.error, color: Colors.red),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           provider.error!,
//                           style: TextStyle(color: Colors.red.shade700),
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: () => provider.clearError(),
//                         child: Text('Dismiss'),
//                       ),
//                     ],
//                   ),
//                 ),

//               // Linear progress indicator for loading
//               if (provider.isLoading)
//                 LinearProgressIndicator(
//                   backgroundColor: Colors.grey.shade200,
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     Theme.of(context).primaryColor,
//                   ),
//                 ),

//               // FIXED: Properly constrained TabBarView
//               Expanded(
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     return TabBarView(
//                       controller: _tabController,
//                       children: _sheets
//                           .map((sheet) => Container(
//                                 constraints: BoxConstraints(
//                                   maxHeight: constraints.maxHeight,
//                                   maxWidth: constraints.maxWidth,
//                                 ),
//                                 child: _buildSheetTab(context, provider, sheet),
//                               ))
//                           .toList(),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPaginationControls(String sheetId, int totalItems) {
//     final totalPages = (totalItems / _itemsPerPage).ceil();
//     final currentPage = _currentPage[sheetId] ?? 0;

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         IconButton(
//           onPressed: currentPage > 0
//               ? () => _changePage(sheetId, currentPage - 1)
//               : null,
//           icon: Icon(Icons.chevron_left),
//         ),
//         Text('${currentPage + 1} / $totalPages'),
//         IconButton(
//           onPressed: currentPage < totalPages - 1
//               ? () => _changePage(sheetId, currentPage + 1)
//               : null,
//           icon: Icon(Icons.chevron_right),
//         ),
//       ],
//     );
//   }

//   Widget _buildDataTable(BuildContext context, List<Map<String, dynamic>> data,
//       SheetConfig sheet) {
//     if (data.isEmpty) {
//       return Center(child: Text('No data matches the current filters'));
//     }

//     // Build appropriate table based on sheet type
//     switch (sheet.id) {
//       case 'SUMMARY':
//         return _buildSummaryTable(context, data);
//       case 'RAWDATA':
//         return _buildRawDataTable(context, data);
//       case 'RECON_SUCCESS':
//       case 'RECON_INVESTIGATE':
//       case 'MANUAL_REFUND':
//         return _buildReconTable(context, data, sheet);
//       default:
//         return _buildGenericTable(context, data);
//     }
//   }

//   // Summary Table - Optimized
//   Widget _buildSummaryTable(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16),
//       child: Card(
//         child: DataTable2(
//           columnSpacing: 12,
//           horizontalMargin: 12,
//           minWidth: 600,
//           headingRowHeight: 48,
//           dataRowHeight: 40,
//           headingRowColor: MaterialStateProperty.all(
//             Theme.of(context).colorScheme.primary.withOpacity(0.1),
//           ),
//           columns: [
//             DataColumn2(label: Text('Source'), size: ColumnSize.L),
//             DataColumn2(label: Text('Type'), size: ColumnSize.L),
//             DataColumn2(
//                 label: Text('Amount'), size: ColumnSize.M, numeric: true),
//           ],
//           rows: data
//               .map((row) => DataRow2(
//                     cells: [
//                       DataCell(Text(row['txn_source']?.toString() ?? '')),
//                       DataCell(Text(row['Txn_type']?.toString() ?? '')),
//                       DataCell(Text(currencyFormat.format(double.tryParse(
//                               row['sum(Txn_Amount)']?.toString() ?? '0') ??
//                           0))),
//                     ],
//                   ))
//               .toList(),
//         ),
//       ),
//     );
//   }

//   // Raw Data Table - Optimized with virtual scrolling
//   Widget _buildRawDataTable(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       margin: EdgeInsets.all(16),
//       child: DataTable2(
//         columnSpacing: 8,
//         horizontalMargin: 8,
//         minWidth: 800,
//         headingRowHeight: 48,
//         dataRowHeight: 40,
//         headingRowColor: MaterialStateProperty.all(
//           Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         ),
//         columns: [
//           DataColumn2(label: Text('Ref No'), size: ColumnSize.S),
//           DataColumn2(label: Text('Source'), size: ColumnSize.S),
//           DataColumn2(label: Text('Type'), size: ColumnSize.S),
//           DataColumn2(label: Text('Machine'), size: ColumnSize.S),
//           DataColumn2(label: Text('Amount'), size: ColumnSize.S, numeric: true),
//         ],
//         rows: data
//             .map((row) => DataRow2(
//                   cells: [
//                     DataCell(Text(row['Txn_RefNo']?.toString() ?? '',
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(row['Txn_Source']?.toString() ?? '',
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(row['Txn_Type']?.toString() ?? '',
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(row['Txn_Machine']?.toString() ?? '',
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(
//                         currencyFormat.format(double.tryParse(
//                                 row['Txn_Amount']?.toString() ?? '0') ??
//                             0),
//                         style: TextStyle(fontSize: 12))),
//                   ],
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   // Recon Table - Optimized
//   Widget _buildReconTable(BuildContext context, List<Map<String, dynamic>> data,
//       SheetConfig sheet) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return Card(
//       margin: EdgeInsets.all(16),
//       child: DataTable2(
//         columnSpacing: 8,
//         horizontalMargin: 8,
//         minWidth: 1000,
//         headingRowHeight: 48,
//         dataRowHeight: 40,
//         headingRowColor: MaterialStateProperty.all(
//           Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         ),
//         columns: [
//           DataColumn2(label: Text('Ref No'), size: ColumnSize.S),
//           DataColumn2(label: Text('Machine'), size: ColumnSize.S),
//           DataColumn2(
//               label: Text('PTPP Pay'), size: ColumnSize.S, numeric: true),
//           DataColumn2(
//               label: Text('PTPP Ref'), size: ColumnSize.S, numeric: true),
//           DataColumn2(
//               label: Text('Cloud Pay'), size: ColumnSize.S, numeric: true),
//           DataColumn2(
//               label: Text('Cloud Ref'), size: ColumnSize.S, numeric: true),
//           DataColumn2(label: Text('Remarks'), size: ColumnSize.M),
//         ],
//         rows: data
//             .map((row) => DataRow2(
//                   cells: [
//                     DataCell(Text(row['Txn_RefNo']?.toString() ?? '',
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(row['Txn_Machine']?.toString() ?? '',
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(
//                         currencyFormat.format(double.tryParse(
//                                 row['PTPP_Payment']?.toString() ?? '0') ??
//                             0),
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(
//                         currencyFormat.format(double.tryParse(
//                                 row['PTPP_Refund']?.toString() ?? '0') ??
//                             0),
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(
//                         currencyFormat.format(double.tryParse(
//                                 row['Cloud_Payment']?.toString() ?? '0') ??
//                             0),
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(Text(
//                         currencyFormat.format(double.tryParse(
//                                 row['Cloud_Refund']?.toString() ?? '0') ??
//                             0),
//                         style: TextStyle(fontSize: 12))),
//                     DataCell(
//                       Container(
//                         padding:
//                             EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: _getRemarksColor(
//                               row['Remarks']?.toString() ?? ''),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           row['Remarks']?.toString() ?? '',
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: Colors.white,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   // Generic table for unknown sheet types
//   Widget _buildGenericTable(
//       BuildContext context, List<Map<String, dynamic>> data) {
//     if (data.isEmpty) return Center(child: Text('No data available'));

//     final columns =
//         data.first.keys.take(6).toList(); // Limit columns for performance

//     return Card(
//       margin: EdgeInsets.all(16),
//       child: DataTable2(
//         columnSpacing: 12,
//         horizontalMargin: 12,
//         minWidth: columns.length * 120.0,
//         headingRowHeight: 48,
//         dataRowHeight: 40,
//         headingRowColor: MaterialStateProperty.all(
//           Theme.of(context).colorScheme.primary.withOpacity(0.1),
//         ),
//         columns: columns
//             .map((column) => DataColumn2(
//                   label: Text(column, style: TextStyle(fontSize: 13)),
//                   size: ColumnSize.M,
//                 ))
//             .toList(),
//         rows: data
//             .map((row) => DataRow2(
//                   cells: columns
//                       .map((column) => DataCell(
//                             Text(
//                               _formatCellValue(row[column]),
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ))
//                       .toList(),
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   // Helper methods
//   Color _getRemarksColor(String remarks) {
//     switch (remarks.toLowerCase()) {
//       case 'perfect':
//         return Colors.green;
//       case 'investigate':
//         return Colors.orange;
//       default:
//         return Colors.blue;
//     }
//   }

//   String _formatCellValue(dynamic value) {
//     if (value == null) return '';
//     if (value is num && value > 1000) {
//       return NumberFormat('#,##0.00').format(value);
//     }
//     return value.toString();
//   }

//   int _getDisplayedRecordCount(List<Map<String, dynamic>>? data) {
//     if (data == null) return 0;
//     return data.length;
//   }

//   List<Map<String, dynamic>> _applyFilters(
//       List<Map<String, dynamic>> data, String sheetId) {
//     final searchQuery = _searchControllers[sheetId]?.text.toLowerCase() ?? '';
//     final filters = _filterControllers[sheetId] ?? {};

//     return data.where((row) {
//       // Apply search filter
//       if (searchQuery.isNotEmpty) {
//         bool matchesSearch = row.values.any((value) =>
//             value?.toString().toLowerCase().contains(searchQuery) ?? false);
//         if (!matchesSearch) return false;
//       }

//       // Apply specific filters
//       for (var filterEntry in filters.entries) {
//         final filterValue = filterEntry.value.text.toLowerCase();
//         if (filterValue.isNotEmpty) {
//           final fieldValue =
//               _getFieldValue(row, filterEntry.key, sheetId)?.toLowerCase() ??
//                   '';
//           if (!fieldValue.contains(filterValue)) {
//             return false;
//           }
//         }
//       }

//       return true;
//     }).toList();
//   }

//   String? _getFieldValue(
//       Map<String, dynamic> row, String filterKey, String sheetId) {
//     switch (filterKey) {
//       case 'source':
//         return row['txn_source'] ?? row['Txn_Source'];
//       case 'type':
//         return row['Txn_type'] ?? row['Txn_Type'];
//       case 'machine':
//         return row['Txn_Machine'];
//       case 'refNo':
//         return row['Txn_RefNo'];
//       case 'mid':
//         return row['Txn_MID'];
//       case 'remarks':
//         return row['Remarks'];
//       default:
//         return null;
//     }
//   }

//   List<Map<String, dynamic>> _getPaginatedData(
//       List<Map<String, dynamic>> data, String sheetId) {
//     final startIndex = _getStartIndex(sheetId);
//     final endIndex = (startIndex + _itemsPerPage).clamp(0, data.length);
//     return data.sublist(startIndex, endIndex);
//   }

//   int _getStartIndex(String sheetId) {
//     return (_currentPage[sheetId] ?? 0) * _itemsPerPage;
//   }

//   void _changePage(String sheetId, int newPage) {
//     setState(() {
//       _currentPage[sheetId] = newPage;
//     });
//   }

//   void _onSearchChanged(String sheetId, String value) {
//     setState(() {
//       _currentPage[sheetId] = 0; // Reset to first page when searching
//     });
//   }

//   void _onFilterChanged(String sheetId, String filterKey, String value) {
//     setState(() {
//       _currentPage[sheetId] = 0; // Reset to first page when filtering
//     });
//   }

//   void _clearSearch(String sheetId) {
//     setState(() {
//       _searchControllers[sheetId]?.clear();
//       _currentPage[sheetId] = 0;
//     });
//   }

//   void _clearAllFilters(String sheetId) {
//     setState(() {
//       _searchControllers[sheetId]?.clear();
//       _filterControllers[sheetId]
//           ?.values
//           .forEach((controller) => controller.clear());
//       _currentPage[sheetId] = 0;
//     });
//   }
// }

// class SheetConfig {
//   final String id;
//   final String name;
//   final IconData icon;
//   final String description;

//   SheetConfig(this.id, this.name, this.icon, this.description);
// }

//3

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:data_table_2/data_table_2.dart';
// import 'package:intl/intl.dart';
// import 'ReconProvider.dart';

// class DataScreen extends StatefulWidget {
//   @override
//   _DataScreenState createState() => _DataScreenState();
// }

// class _DataScreenState extends State<DataScreen>
//     with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
//   late TabController _tabController;
//   late AnimationController _filterAnimationController;
//   late Animation<double> _filterAnimation;

//   // Search and filter controllers
//   final Map<String, TextEditingController> _searchControllers = {};
//   final Map<String, TextEditingController> _minAmountControllers = {};
//   final Map<String, TextEditingController> _maxAmountControllers = {};
//   final Map<String, TextEditingController> _remarksControllers = {};
//   final Map<String, String> _selectedTransactionModes = {};
//   final Map<String, String> _selectedQuickStatuses = {};
//   final Map<String, bool> _isFilterExpanded = {};

//   // Pagination
//   final Map<String, int> _currentPage = {};
//   final int _itemsPerPage = 50;

//   // Active filters tracking
//   final Map<String, List<String>> _activeFilters = {};

//   final List<SheetConfig> _sheets = [
//     SheetConfig('SUMMARY', 'Summary', Icons.dashboard_outlined,
//         'Transaction summary overview', Colors.blue),
//     SheetConfig('RECON_SUCCESS', 'Perfect Matches', Icons.check_circle_outline,
//         'Successfully reconciled transactions', Colors.green),
//     SheetConfig('RECON_INVESTIGATE', 'Investigate', Icons.warning_outlined,
//         'Transactions requiring investigation', Colors.orange),
//     SheetConfig('MANUAL_REFUND', 'Manual Refunds', Icons.edit_outlined,
//         'Manual refund transactions', Colors.purple),
//     SheetConfig('RAWDATA', 'Raw Data', Icons.table_rows_outlined,
//         'All raw transaction data', Colors.grey),
//   ];

//   @override
//   bool get wantKeepAlive => true;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: _sheets.length, vsync: this);
//     _filterAnimationController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _filterAnimation = CurvedAnimation(
//       parent: _filterAnimationController,
//       curve: Curves.easeInOut,
//     );

//     // Initialize controllers
//     for (var sheet in _sheets) {
//       _searchControllers[sheet.id] = TextEditingController();
//       _minAmountControllers[sheet.id] = TextEditingController();
//       _maxAmountControllers[sheet.id] = TextEditingController();
//       _remarksControllers[sheet.id] = TextEditingController();
//       _selectedTransactionModes[sheet.id] = 'All';
//       _selectedQuickStatuses[sheet.id] = 'All';
//       _isFilterExpanded[sheet.id] = false;
//       _currentPage[sheet.id] = 0;
//       _activeFilters[sheet.id] = [];
//     }

//     // Load initial data
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<ReconProvider>(context, listen: false).loadAllSheets();
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _filterAnimationController.dispose();
//     _searchControllers.values.forEach((controller) => controller.dispose());
//     _minAmountControllers.values.forEach((controller) => controller.dispose());
//     _maxAmountControllers.values.forEach((controller) => controller.dispose());
//     _remarksControllers.values.forEach((controller) => controller.dispose());
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Consumer<ReconProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           backgroundColor: Colors.grey[50],
//           appBar: _buildAppBar(provider),
//           body: Column(
//             children: [
//               if (provider.error != null) _buildErrorBanner(provider),
//               if (provider.isLoading) _buildLoadingIndicator(),
//               _buildTabBar(),
//               Expanded(child: _buildTabBarView(provider)),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   PreferredSizeWidget _buildAppBar(ReconProvider provider) {
//     return AppBar(
//       elevation: 0,
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.black87,
//       title: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.blue[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(Icons.analytics_outlined, color: Colors.blue[700]),
//           ),
//           SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Reconciliation Dashboard',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
//               Text('Real-time transaction analysis',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//             ],
//           ),
//         ],
//       ),
//       actions: [
//         _buildStatsChips(provider),
//         SizedBox(width: 16),
//         Container(
//           margin: EdgeInsets.symmetric(vertical: 8),
//           child: ElevatedButton.icon(
//             onPressed:
//                 provider.isLoading ? null : () => provider.loadAllSheets(),
//             icon: Icon(Icons.refresh, size: 18),
//             label: Text('Refresh'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue[600],
//               foregroundColor: Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         ),
//         SizedBox(width: 16),
//       ],
//     );
//   }

//   Widget _buildStatsChips(ReconProvider provider) {
//     return Row(
//       children: [
//         _buildStatChip('Total Records', _getTotalRecords(provider).toString(),
//             Colors.blue),
//         SizedBox(width: 8),
//         _buildStatChip(
//             'Success Rate', '${_getSuccessRate(provider)}%', Colors.green),
//       ],
//     );
//   }

//   Widget _buildStatChip(String label, String value, Color color) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(value,
//               style: TextStyle(
//                   fontSize: 14, fontWeight: FontWeight.bold, color: color)),
//           Text(label, style: TextStyle(fontSize: 10, color: color)),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorBanner(ReconProvider provider) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(16),
//       color: Colors.red[50],
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red[700]),
//           SizedBox(width: 12),
//           Expanded(
//             child:
//                 Text(provider.error!, style: TextStyle(color: Colors.red[700])),
//           ),
//           TextButton.icon(
//             onPressed: () => provider.clearError(),
//             icon: Icon(Icons.close, size: 18),
//             label: Text('Dismiss'),
//             style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return Container(
//       height: 4,
//       child: LinearProgressIndicator(
//         backgroundColor: Colors.grey[200],
//         valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
//       ),
//     );
//   }

//   Widget _buildTabBar() {
//     return Container(
//       color: Colors.white,
//       child: TabBar(
//         controller: _tabController,
//         isScrollable: true,
//         labelColor: Colors.blue[700],
//         unselectedLabelColor: Colors.grey[600],
//         indicatorColor: Colors.blue[600],
//         indicatorWeight: 3,
//         labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//         unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
//         tabs: _sheets
//             .map((sheet) => Tab(
//                   child: Container(
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(sheet.icon, size: 20, color: sheet.color),
//                         SizedBox(width: 8),
//                         Text(sheet.name),
//                         SizedBox(width: 8),
//                         _buildRecordCountBadge(sheet),
//                       ],
//                     ),
//                   ),
//                 ))
//             .toList(),
//       ),
//     );
//   }

//   Widget _buildRecordCountBadge(SheetConfig sheet) {
//     return Consumer<ReconProvider>(
//       builder: (context, provider, child) {
//         final data = provider.getSheetData(sheet.id);
//         final count = data?.length ?? 0;

//         if (count == 0) return SizedBox.shrink();

//         return Container(
//           padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//           decoration: BoxDecoration(
//             color: sheet.color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Text(
//             count.toString(),
//             style: TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//               color: sheet.color,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTabBarView(ReconProvider provider) {
//     return TabBarView(
//       controller: _tabController,
//       children:
//           _sheets.map((sheet) => _buildSheetView(provider, sheet)).toList(),
//     );
//   }

//   Widget _buildSheetView(ReconProvider provider, SheetConfig sheet) {
//     final data = provider.getSheetData(sheet.id);

//     return Container(
//       margin: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           _buildSheetHeader(sheet, data?.length ?? 0),
//           SizedBox(height: 16),
//           _buildFilterPanel(sheet),
//           SizedBox(height: 16),
//           _buildActiveFiltersChips(sheet),
//           SizedBox(height: 16),
//           Expanded(child: _buildDataContent(provider, sheet, data)),
//         ],
//       ),
//     );
//   }

//   Widget _buildSheetHeader(SheetConfig sheet, int recordCount) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(20),
//         child: Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: sheet.color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(sheet.icon, color: sheet.color, size: 24),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(sheet.name,
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[800],
//                       )),
//                   SizedBox(height: 4),
//                   Text(sheet.description,
//                       style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                 ],
//               ),
//             ),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: sheet.color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 '$recordCount Records',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: sheet.color,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterPanel(SheetConfig sheet) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         children: [
//           // Filter header
//           InkWell(
//             onTap: () => _toggleFilterExpansion(sheet.id),
//             child: Container(
//               padding: EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Icon(Icons.filter_alt_outlined, color: Colors.grey[600]),
//                   SizedBox(width: 8),
//                   Text('Filters & Search',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[800],
//                       )),
//                   Spacer(),
//                   AnimatedRotation(
//                     turns: _isFilterExpanded[sheet.id]! ? 0.5 : 0,
//                     duration: Duration(milliseconds: 300),
//                     child: Icon(Icons.expand_more, color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Expandable filter content
//           AnimatedContainer(
//             duration: Duration(milliseconds: 300),
//             height: _isFilterExpanded[sheet.id]! ? null : 0,
//             child: _isFilterExpanded[sheet.id]!
//                 ? _buildFilterContent(sheet)
//                 : SizedBox.shrink(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterContent(SheetConfig sheet) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // Main search bar
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: TextField(
//               controller: _searchControllers[sheet.id],
//               decoration: InputDecoration(
//                 hintText: 'Search in ${sheet.name.toLowerCase()}...',
//                 prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
//                 suffixIcon: _searchControllers[sheet.id]!.text.isNotEmpty
//                     ? IconButton(
//                         icon: Icon(Icons.clear, color: Colors.grey[600]),
//                         onPressed: () => _clearSearch(sheet.id),
//                       )
//                     : null,
//                 border: InputBorder.none,
//                 contentPadding:
//                     EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               ),
//               onChanged: (value) => _onSearchChanged(sheet.id, value),
//             ),
//           ),

//           SizedBox(height: 16),

//           // Filter grid
//           GridView.count(
//             shrinkWrap: true,
//             physics: NeverScrollableScrollPhysics(),
//             crossAxisCount: 3,
//             crossAxisSpacing: 12,
//             mainAxisSpacing: 12,
//             childAspectRatio: 3,
//             children: [
//               // Amount range filters
//               _buildAmountRangeFilter(sheet),

//               // Transaction mode filter
//               _buildTransactionModeFilter(sheet),

//               // Remarks filter
//               _buildRemarksFilter(sheet),

//               // Quick status filter
//               _buildQuickStatusFilter(sheet),

//               // Clear all button
//               _buildClearAllButton(sheet),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAmountRangeFilter(SheetConfig sheet) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: _minAmountControllers[sheet.id],
//             decoration: InputDecoration(
//               labelText: 'Min Amount',
//               prefixText: '₹',
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               isDense: true,
//             ),
//             keyboardType: TextInputType.number,
//             onChanged: (value) => _onFilterChanged(sheet.id),
//           ),
//         ),
//         SizedBox(width: 8),
//         Expanded(
//           child: TextField(
//             controller: _maxAmountControllers[sheet.id],
//             decoration: InputDecoration(
//               labelText: 'Max Amount',
//               prefixText: '₹',
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               isDense: true,
//             ),
//             keyboardType: TextInputType.number,
//             onChanged: (value) => _onFilterChanged(sheet.id),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTransactionModeFilter(SheetConfig sheet) {
//     final modes = ['All', 'Paytm', 'PhonePe', 'Cloud', 'PTPP', 'Manual'];

//     return DropdownButtonFormField<String>(
//       value: _selectedTransactionModes[sheet.id],
//       decoration: InputDecoration(
//         labelText: 'Transaction Mode',
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         isDense: true,
//       ),
//       items: modes
//           .map((mode) => DropdownMenuItem(
//                 value: mode,
//                 child: Text(mode),
//               ))
//           .toList(),
//       onChanged: (value) {
//         setState(() {
//           _selectedTransactionModes[sheet.id] = value!;
//         });
//         _onFilterChanged(sheet.id);
//       },
//     );
//   }

//   Widget _buildRemarksFilter(SheetConfig sheet) {
//     return TextField(
//       controller: _remarksControllers[sheet.id],
//       decoration: InputDecoration(
//         labelText: 'Contains in Remarks',
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         isDense: true,
//       ),
//       onChanged: (value) => _onFilterChanged(sheet.id),
//     );
//   }

//   Widget _buildQuickStatusFilter(SheetConfig sheet) {
//     final statuses = ['All', 'Perfect', 'Investigate', 'Manual'];

//     return DropdownButtonFormField<String>(
//       value: _selectedQuickStatuses[sheet.id],
//       decoration: InputDecoration(
//         labelText: 'Quick Status',
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         isDense: true,
//       ),
//       items: statuses
//           .map((status) => DropdownMenuItem(
//                 value: status,
//                 child: Text(status),
//               ))
//           .toList(),
//       onChanged: (value) {
//         setState(() {
//           _selectedQuickStatuses[sheet.id] = value!;
//         });
//         _onFilterChanged(sheet.id);
//       },
//     );
//   }

//   Widget _buildClearAllButton(SheetConfig sheet) {
//     return Container(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: () => _clearAllFilters(sheet.id),
//         icon: Icon(Icons.clear_all, size: 18),
//         label: Text('Clear All'),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.grey[100],
//           foregroundColor: Colors.grey[700],
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActiveFiltersChips(SheetConfig sheet) {
//     final activeFilters = _activeFilters[sheet.id] ?? [];

//     if (activeFilters.isEmpty) return SizedBox.shrink();

//     return Container(
//       alignment: Alignment.centerLeft,
//       child: Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         children: [
//           Text('Active Filters: ',
//               style: TextStyle(
//                   fontWeight: FontWeight.w600, color: Colors.grey[600])),
//           ...activeFilters.map((filter) => Chip(
//                 label: Text(filter, style: TextStyle(fontSize: 12)),
//                 backgroundColor: Colors.blue[50],
//                 deleteIcon: Icon(Icons.close, size: 16),
//                 onDeleted: () => _removeFilter(sheet.id, filter),
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               )),
//         ],
//       ),
//     );
//   }

//   Widget _buildDataContent(ReconProvider provider, SheetConfig sheet,
//       List<Map<String, dynamic>>? data) {
//     if (provider.isLoading) {
//       return _buildLoadingState(sheet);
//     }

//     if (data == null || data.isEmpty) {
//       return _buildEmptyState(sheet, provider);
//     }

//     final filteredData = _applyFilters(data, sheet.id);
//     final paginatedData = _getPaginatedData(filteredData, sheet.id);

//     if (filteredData.isEmpty) {
//       return _buildNoResultsState(sheet);
//     }

//     return Column(
//       children: [
//         if (filteredData.length > _itemsPerPage)
//           _buildPaginationInfo(sheet, filteredData.length),
//         Expanded(child: _buildDataTable(sheet, paginatedData)),
//         if (filteredData.length > _itemsPerPage)
//           _buildPaginationControls(sheet, filteredData.length),
//       ],
//     );
//   }

//   Widget _buildLoadingState(SheetConfig sheet) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(color: sheet.color),
//           SizedBox(height: 16),
//           Text('Loading ${sheet.name.toLowerCase()}...',
//               style: TextStyle(color: Colors.grey[600])),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState(SheetConfig sheet, ReconProvider provider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(50),
//             ),
//             child:
//                 Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
//           ),
//           SizedBox(height: 16),
//           Text('No data available',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
//           SizedBox(height: 8),
//           Text('No records found for ${sheet.name}',
//               style: TextStyle(color: Colors.grey[600])),
//           SizedBox(height: 16),
//           ElevatedButton.icon(
//             onPressed: () => provider.loadSheet(sheet.id),
//             icon: Icon(Icons.refresh),
//             label: Text('Reload Data'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: sheet.color,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNoResultsState(SheetConfig sheet) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.orange[50],
//               borderRadius: BorderRadius.circular(50),
//             ),
//             child: Icon(Icons.search_off, size: 48, color: Colors.orange[400]),
//           ),
//           SizedBox(height: 16),
//           Text('No results found',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
//           SizedBox(height: 8),
//           Text('Try adjusting your filters or search criteria',
//               style: TextStyle(color: Colors.grey[600])),
//           SizedBox(height: 16),
//           TextButton.icon(
//             onPressed: () => _clearAllFilters(sheet.id),
//             icon: Icon(Icons.clear_all),
//             label: Text('Clear All Filters'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDataTable(SheetConfig sheet, List<Map<String, dynamic>> data) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: _buildDataTableForSheet(sheet, data),
//       ),
//     );
//   }

//   Widget _buildDataTableForSheet(
//       SheetConfig sheet, List<Map<String, dynamic>> data) {
//     switch (sheet.id) {
//       case 'SUMMARY':
//         return _buildSummaryTable(data);
//       case 'RAWDATA':
//         return _buildRawDataTable(data);
//       case 'RECON_SUCCESS':
//       case 'RECON_INVESTIGATE':
//       case 'MANUAL_REFUND':
//         return _buildReconTable(data, sheet);
//       default:
//         return _buildGenericTable(data);
//     }
//   }

//   Widget _buildSummaryTable(List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return DataTable2(
//       columnSpacing: 12,
//       horizontalMargin: 12,
//       minWidth: 600,
//       headingRowHeight: 56,
//       dataRowHeight: 48,
//       headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
//       columns: [
//         DataColumn2(
//           label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.L,
//         ),
//         DataColumn2(
//           label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.L,
//         ),
//         DataColumn2(
//           label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.M,
//           numeric: true,
//         ),
//       ],
//       rows: data
//           .map((row) => DataRow2(
//                 cells: [
//                   DataCell(
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(row['txn_source']?.toString() ?? ''),
//                     ),
//                   ),
//                   DataCell(Text(row['Txn_type']?.toString() ?? '')),
//                   DataCell(
//                     Text(
//                       currencyFormat.format(
//                         double.tryParse(
//                                 row['sum(Txn_Amount)']?.toString() ?? '0') ??
//                             0,
//                       ),
//                       style: TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildRawDataTable(List<Map<String, dynamic>> data) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return DataTable2(
//       columnSpacing: 8,
//       horizontalMargin: 8,
//       minWidth: 800,
//       headingRowHeight: 56,
//       dataRowHeight: 48,
//       headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
//       columns: [
//         DataColumn2(
//           label: Text('Ref No', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.M,
//         ),
//         DataColumn2(
//           label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//         ),
//         DataColumn2(
//           label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//         ),
//         DataColumn2(
//           label: Text('Machine', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//         ),
//         DataColumn2(
//           label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//           numeric: true,
//         ),
//       ],
//       rows: data
//           .map((row) => DataRow2(
//                 cells: [
//                   DataCell(
//                     SelectableText(
//                       row['Txn_RefNo']?.toString() ?? '',
//                       style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
//                     ),
//                   ),
//                   DataCell(
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: _getSourceColor(row['Txn_Source']?.toString()),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         row['Txn_Source']?.toString() ?? '',
//                         style: TextStyle(fontSize: 11, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                   DataCell(Text(row['Txn_Type']?.toString() ?? '',
//                       style: TextStyle(fontSize: 12))),
//                   DataCell(Text(row['Txn_Machine']?.toString() ?? '',
//                       style: TextStyle(fontSize: 12))),
//                   DataCell(
//                     Text(
//                       currencyFormat.format(
//                         double.tryParse(row['Txn_Amount']?.toString() ?? '0') ??
//                             0,
//                       ),
//                       style:
//                           TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildReconTable(List<Map<String, dynamic>> data, SheetConfig sheet) {
//     final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

//     return DataTable2(
//       columnSpacing: 8,
//       horizontalMargin: 8,
//       minWidth: 1000,
//       headingRowHeight: 56,
//       dataRowHeight: 48,
//       headingRowColor: MaterialStateProperty.all(sheet.color.withOpacity(0.1)),
//       columns: [
//         DataColumn2(
//           label: Text('Ref No', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.M,
//         ),
//         DataColumn2(
//           label: Text('Machine', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//         ),
//         DataColumn2(
//           label:
//               Text('PTPP Pay', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//           numeric: true,
//         ),
//         DataColumn2(
//           label:
//               Text('PTPP Ref', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//           numeric: true,
//         ),
//         DataColumn2(
//           label:
//               Text('Cloud Pay', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//           numeric: true,
//         ),
//         DataColumn2(
//           label:
//               Text('Cloud Ref', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.S,
//           numeric: true,
//         ),
//         DataColumn2(
//           label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold)),
//           size: ColumnSize.M,
//         ),
//       ],
//       rows: data
//           .map((row) => DataRow2(
//                 cells: [
//                   DataCell(
//                     SelectableText(
//                       row['Txn_RefNo']?.toString() ?? '',
//                       style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
//                     ),
//                   ),
//                   DataCell(Text(row['Txn_Machine']?.toString() ?? '',
//                       style: TextStyle(fontSize: 12))),
//                   DataCell(
//                     Text(
//                       currencyFormat.format(
//                         double.tryParse(
//                                 row['PTPP_Payment']?.toString() ?? '0') ??
//                             0,
//                       ),
//                       style:
//                           TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   DataCell(
//                     Text(
//                       currencyFormat.format(
//                         double.tryParse(
//                                 row['PTPP_Refund']?.toString() ?? '0') ??
//                             0,
//                       ),
//                       style:
//                           TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   DataCell(
//                     Text(
//                       currencyFormat.format(
//                         double.tryParse(
//                                 row['Cloud_Payment']?.toString() ?? '0') ??
//                             0,
//                       ),
//                       style:
//                           TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   DataCell(
//                     Text(
//                       currencyFormat.format(
//                         double.tryParse(
//                                 row['Cloud_Refund']?.toString() ?? '0') ??
//                             0,
//                       ),
//                       style:
//                           TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   DataCell(
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color:
//                             _getRemarksColor(row['Remarks']?.toString() ?? ''),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         row['Remarks']?.toString() ?? '',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildGenericTable(List<Map<String, dynamic>> data) {
//     if (data.isEmpty) return Center(child: Text('No data available'));

//     final columns = data.first.keys.take(6).toList();

//     return DataTable2(
//       columnSpacing: 12,
//       horizontalMargin: 12,
//       minWidth: columns.length * 120.0,
//       headingRowHeight: 56,
//       dataRowHeight: 48,
//       headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
//       columns: columns
//           .map((column) => DataColumn2(
//                 label:
//                     Text(column, style: TextStyle(fontWeight: FontWeight.bold)),
//                 size: ColumnSize.M,
//               ))
//           .toList(),
//       rows: data
//           .map((row) => DataRow2(
//                 cells: columns
//                     .map((column) => DataCell(
//                           Text(
//                             _formatCellValue(row[column]),
//                             style: TextStyle(fontSize: 12),
//                           ),
//                         ))
//                     .toList(),
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildPaginationInfo(SheetConfig sheet, int totalItems) {
//     final currentPage = _currentPage[sheet.id] ?? 0;
//     final startIndex = currentPage * _itemsPerPage + 1;
//     final endIndex = ((currentPage + 1) * _itemsPerPage).clamp(0, totalItems);

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'Showing $startIndex-$endIndex of $totalItems records',
//             style: TextStyle(color: Colors.grey[600], fontSize: 14),
//           ),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: sheet.color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Text(
//               'Page ${currentPage + 1} of ${(totalItems / _itemsPerPage).ceil()}',
//               style: TextStyle(
//                 color: sheet.color,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPaginationControls(SheetConfig sheet, int totalItems) {
//     final totalPages = (totalItems / _itemsPerPage).ceil();
//     final currentPage = _currentPage[sheet.id] ?? 0;

//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ElevatedButton.icon(
//             onPressed: currentPage > 0 ? () => _changePage(sheet.id, 0) : null,
//             icon: Icon(Icons.first_page, size: 18),
//             label: Text('First'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.grey[100],
//               foregroundColor: Colors.grey[700],
//               elevation: 0,
//             ),
//           ),
//           SizedBox(width: 8),
//           ElevatedButton.icon(
//             onPressed: currentPage > 0
//                 ? () => _changePage(sheet.id, currentPage - 1)
//                 : null,
//             icon: Icon(Icons.chevron_left, size: 18),
//             label: Text('Previous'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.grey[100],
//               foregroundColor: Colors.grey[700],
//               elevation: 0,
//             ),
//           ),
//           SizedBox(width: 16),
//           Text(
//             '${currentPage + 1} / $totalPages',
//             style: TextStyle(fontWeight: FontWeight.w600),
//           ),
//           SizedBox(width: 16),
//           ElevatedButton.icon(
//             onPressed: currentPage < totalPages - 1
//                 ? () => _changePage(sheet.id, currentPage + 1)
//                 : null,
//             icon: Icon(Icons.chevron_right, size: 18),
//             label: Text('Next'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: sheet.color,
//               foregroundColor: Colors.white,
//               elevation: 0,
//             ),
//           ),
//           SizedBox(width: 8),
//           ElevatedButton.icon(
//             onPressed: currentPage < totalPages - 1
//                 ? () => _changePage(sheet.id, totalPages - 1)
//                 : null,
//             icon: Icon(Icons.last_page, size: 18),
//             label: Text('Last'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: sheet.color,
//               foregroundColor: Colors.white,
//               elevation: 0,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper Methods
//   Color _getRemarksColor(String remarks) {
//     switch (remarks.toLowerCase()) {
//       case 'perfect':
//         return Colors.green[600]!;
//       case 'investigate':
//         return Colors.orange[600]!;
//       case 'manual':
//         return Colors.purple[600]!;
//       default:
//         return Colors.blue[600]!;
//     }
//   }

//   Color _getSourceColor(String? source) {
//     switch (source?.toLowerCase()) {
//       case 'paytm':
//         return Colors.blue[600]!;
//       case 'phonepe':
//         return Colors.purple[600]!;
//       case 'cloud':
//         return Colors.green[600]!;
//       case 'ptpp':
//         return Colors.orange[600]!;
//       default:
//         return Colors.grey[600]!;
//     }
//   }

//   String _formatCellValue(dynamic value) {
//     if (value == null) return '';
//     if (value is num && value > 1000) {
//       return NumberFormat('#,##0.00').format(value);
//     }
//     return value.toString();
//   }

//   int _getTotalRecords(ReconProvider provider) {
//     int total = 0;
//     for (String sheetId in [
//       'SUMMARY',
//       'RAWDATA',
//       'RECON_SUCCESS',
//       'RECON_INVESTIGATE',
//       'MANUAL_REFUND'
//     ]) {
//       final data = provider.getSheetData(sheetId);
//       if (data != null) total += data.length;
//     }
//     return total;
//   }

//   int _getSuccessRate(ReconProvider provider) {
//     final successData = provider.getSheetData('RECON_SUCCESS');
//     final investigateData = provider.getSheetData('RECON_INVESTIGATE');
//     final totalRecon =
//         (successData?.length ?? 0) + (investigateData?.length ?? 0);

//     if (totalRecon == 0) return 0;
//     return ((successData?.length ?? 0) * 100 / totalRecon).round();
//   }

//   List<Map<String, dynamic>> _applyFilters(
//       List<Map<String, dynamic>> data, String sheetId) {
//     final searchQuery = _searchControllers[sheetId]?.text.toLowerCase() ?? '';
//     final minAmount =
//         double.tryParse(_minAmountControllers[sheetId]?.text ?? '');
//     final maxAmount =
//         double.tryParse(_maxAmountControllers[sheetId]?.text ?? '');
//     final remarksFilter =
//         _remarksControllers[sheetId]?.text.toLowerCase() ?? '';
//     final modeFilter = _selectedTransactionModes[sheetId] ?? 'All';
//     final statusFilter = _selectedQuickStatuses[sheetId] ?? 'All';

//     return data.where((row) {
//       // Search filter
//       if (searchQuery.isNotEmpty) {
//         bool matchesSearch = row.values.any((value) =>
//             value?.toString().toLowerCase().contains(searchQuery) ?? false);
//         if (!matchesSearch) return false;
//       }

//       // Amount range filter
//       if (minAmount != null || maxAmount != null) {
//         final amount = _getAmountFromRow(row);
//         if (amount != null) {
//           if (minAmount != null && amount < minAmount) return false;
//           if (maxAmount != null && amount > maxAmount) return false;
//         }
//       }

//       // Remarks filter
//       if (remarksFilter.isNotEmpty) {
//         final remarks = row['Remarks']?.toString().toLowerCase() ?? '';
//         if (!remarks.contains(remarksFilter)) return false;
//       }

//       // Transaction mode filter
//       if (modeFilter != 'All') {
//         final source = row['Txn_Source']?.toString() ?? '';
//         if (!source.toLowerCase().contains(modeFilter.toLowerCase()))
//           return false;
//       }

//       // Quick status filter
//       if (statusFilter != 'All') {
//         final remarks = row['Remarks']?.toString().toLowerCase() ?? '';
//         if (!remarks.contains(statusFilter.toLowerCase())) return false;
//       }

//       return true;
//     }).toList();
//   }

//   double? _getAmountFromRow(Map<String, dynamic> row) {
//     // Try different amount field names
//     final amountFields = [
//       'Txn_Amount',
//       'PTPP_Payment',
//       'Cloud_Payment',
//       'sum(Txn_Amount)'
//     ];

//     for (String field in amountFields) {
//       if (row.containsKey(field)) {
//         return double.tryParse(row[field]?.toString() ?? '0');
//       }
//     }
//     return null;
//   }

//   List<Map<String, dynamic>> _getPaginatedData(
//       List<Map<String, dynamic>> data, String sheetId) {
//     final startIndex = (_currentPage[sheetId] ?? 0) * _itemsPerPage;
//     final endIndex = (startIndex + _itemsPerPage).clamp(0, data.length);
//     return data.sublist(startIndex, endIndex);
//   }

//   void _toggleFilterExpansion(String sheetId) {
//     setState(() {
//       _isFilterExpanded[sheetId] = !_isFilterExpanded[sheetId]!;
//     });

//     if (_isFilterExpanded[sheetId]!) {
//       _filterAnimationController.forward();
//     } else {
//       _filterAnimationController.reverse();
//     }
//   }

//   void _onSearchChanged(String sheetId, String value) {
//     setState(() {
//       _currentPage[sheetId] = 0;
//     });
//     _updateActiveFilters(sheetId);
//   }

//   void _onFilterChanged(String sheetId) {
//     setState(() {
//       _currentPage[sheetId] = 0;
//     });
//     _updateActiveFilters(sheetId);
//   }

//   void _updateActiveFilters(String sheetId) {
//     List<String> filters = [];

//     final searchQuery = _searchControllers[sheetId]?.text ?? '';
//     if (searchQuery.isNotEmpty) {
//       filters.add('Search: "$searchQuery"');
//     }

//     final minAmount = _minAmountControllers[sheetId]?.text ?? '';
//     final maxAmount = _maxAmountControllers[sheetId]?.text ?? '';
//     if (minAmount.isNotEmpty || maxAmount.isNotEmpty) {
//       filters.add('Amount: ₹$minAmount - ₹$maxAmount');
//     }

//     final remarks = _remarksControllers[sheetId]?.text ?? '';
//     if (remarks.isNotEmpty) {
//       filters.add('Remarks: "$remarks"');
//     }

//     final mode = _selectedTransactionModes[sheetId] ?? 'All';
//     if (mode != 'All') {
//       filters.add('Mode: $mode');
//     }

//     final status = _selectedQuickStatuses[sheetId] ?? 'All';
//     if (status != 'All') {
//       filters.add('Status: $status');
//     }

//     setState(() {
//       _activeFilters[sheetId] = filters;
//     });
//   }

//   void _removeFilter(String sheetId, String filter) {
//     if (filter.startsWith('Search:')) {
//       _searchControllers[sheetId]?.clear();
//     } else if (filter.startsWith('Amount:')) {
//       _minAmountControllers[sheetId]?.clear();
//       _maxAmountControllers[sheetId]?.clear();
//     } else if (filter.startsWith('Remarks:')) {
//       _remarksControllers[sheetId]?.clear();
//     } else if (filter.startsWith('Mode:')) {
//       _selectedTransactionModes[sheetId] = 'All';
//     } else if (filter.startsWith('Status:')) {
//       _selectedQuickStatuses[sheetId] = 'All';
//     }

//     _onFilterChanged(sheetId);
//   }

//   void _clearSearch(String sheetId) {
//     setState(() {
//       _searchControllers[sheetId]?.clear();
//       _currentPage[sheetId] = 0;
//     });
//     _updateActiveFilters(sheetId);
//   }

//   void _clearAllFilters(String sheetId) {
//     setState(() {
//       _searchControllers[sheetId]?.clear();
//       _minAmountControllers[sheetId]?.clear();
//       _maxAmountControllers[sheetId]?.clear();
//       _remarksControllers[sheetId]?.clear();
//       _selectedTransactionModes[sheetId] = 'All';
//       _selectedQuickStatuses[sheetId] = 'All';
//       _currentPage[sheetId] = 0;
//       _activeFilters[sheetId] = [];
//     });
//   }

//   void _changePage(String sheetId, int newPage) {
//     setState(() {
//       _currentPage[sheetId] = newPage;
//     });
//   }
// }

// class SheetConfig {
//   final String id;
//   final String name;
//   final IconData icon;
//   final String description;
//   final Color color;

//   SheetConfig(this.id, this.name, this.icon, this.description, this.color);
// }

//4

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'ReconProvider.dart';

class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  // Search and filter controllers
  final Map<String, TextEditingController> _searchControllers = {};
  final Map<String, TextEditingController> _minAmountControllers = {};
  final Map<String, TextEditingController> _maxAmountControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, String> _selectedTransactionModes = {};
  final Map<String, String> _selectedQuickStatuses = {};
  final Map<String, bool> _isFilterExpanded = {};

  // Pagination
  final Map<String, int> _currentPage = {};
  final int _itemsPerPage = 50;

  // Active filters tracking
  final Map<String, List<String>> _activeFilters = {};

  final List<SheetConfig> _sheets = [
    SheetConfig('SUMMARY', 'Summary', Icons.dashboard_outlined,
        'Transaction summary overview', Colors.blue),
    SheetConfig('RECON_SUCCESS', 'Perfect Matches', Icons.check_circle_outline,
        'Successfully reconciled transactions', Colors.green),
    SheetConfig('RECON_INVESTIGATE', 'Investigate', Icons.warning_outlined,
        'Transactions requiring investigation', Colors.orange),
    SheetConfig('MANUAL_REFUND', 'Manual Refunds', Icons.edit_outlined,
        'Manual refund transactions', Colors.purple),
    SheetConfig('RAWDATA', 'Raw Data', Icons.table_rows_outlined,
        'All raw transaction data', Colors.grey),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sheets.length, vsync: this);
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialize controllers
    for (var sheet in _sheets) {
      _searchControllers[sheet.id] = TextEditingController();
      _minAmountControllers[sheet.id] = TextEditingController();
      _maxAmountControllers[sheet.id] = TextEditingController();
      _remarksControllers[sheet.id] = TextEditingController();
      _selectedTransactionModes[sheet.id] = 'All';
      _selectedQuickStatuses[sheet.id] = 'All';
      _isFilterExpanded[sheet.id] = false;
      _currentPage[sheet.id] = 0;
      _activeFilters[sheet.id] = [];
    }

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReconProvider>(context, listen: false).loadAllSheets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterAnimationController.dispose();
    _searchControllers.values.forEach((controller) => controller.dispose());
    _minAmountControllers.values.forEach((controller) => controller.dispose());
    _maxAmountControllers.values.forEach((controller) => controller.dispose());
    _remarksControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ReconProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(provider),
          body: Column(
            children: [
              if (provider.error != null) _buildErrorBanner(provider),
              if (provider.isLoading) _buildLoadingIndicator(),
              _buildTabBar(),
              Expanded(child: _buildTabBarView(provider)),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ReconProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.analytics_outlined, color: Colors.blue[700]),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reconciliation Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Real-time transaction analysis',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
      actions: [
        _buildStatsChips(provider),
        SizedBox(width: 16),
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            onPressed:
                provider.isLoading ? null : () => provider.loadAllSheets(),
            icon: Icon(Icons.refresh, size: 18),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatsChips(ReconProvider provider) {
    return Row(
      children: [
        _buildStatChip('Total Records', _getTotalRecords(provider).toString(),
            Colors.blue),
        SizedBox(width: 8),
        _buildStatChip(
            'Success Rate', '${_getSuccessRate(provider)}%', Colors.green),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ReconProvider provider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Colors.red[50],
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          SizedBox(width: 12),
          Expanded(
            child:
                Text(provider.error!, style: TextStyle(color: Colors.red[700])),
          ),
          TextButton.icon(
            onPressed: () => provider.clearError(),
            icon: Icon(Icons.close, size: 18),
            label: Text('Dismiss'),
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 4,
      child: LinearProgressIndicator(
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[600],
        indicatorWeight: 3,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        tabs: _sheets
            .map((sheet) => Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sheet.icon, size: 20, color: sheet.color),
                        SizedBox(width: 8),
                        Text(sheet.name),
                        SizedBox(width: 8),
                        _buildRecordCountBadge(sheet),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRecordCountBadge(SheetConfig sheet) {
    return Consumer<ReconProvider>(
      builder: (context, provider, child) {
        final data = provider.getSheetData(sheet.id);
        final count = data?.length ?? 0;

        if (count == 0) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: sheet.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: sheet.color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBarView(ReconProvider provider) {
    return TabBarView(
      controller: _tabController,
      children:
          _sheets.map((sheet) => _buildSheetView(provider, sheet)).toList(),
    );
  }

  Widget _buildSheetView(ReconProvider provider, SheetConfig sheet) {
    final data = provider.getSheetData(sheet.id);

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSheetHeader(sheet, data?.length ?? 0),
          SizedBox(height: 16),
          _buildFilterPanel(sheet),
          SizedBox(height: 16),
          _buildActiveFiltersChips(sheet),
          SizedBox(height: 16),
          Expanded(child: _buildDataContent(provider, sheet, data)),
        ],
      ),
    );
  }

  Widget _buildSheetHeader(SheetConfig sheet, int recordCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sheet.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(sheet.icon, color: sheet.color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sheet.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      )),
                  SizedBox(height: 4),
                  Text(sheet.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sheet.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$recordCount Records',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: sheet.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(SheetConfig sheet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Filter header
          InkWell(
            onTap: () => _toggleFilterExpansion(sheet.id),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_outlined, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Filters & Search',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      )),
                  Spacer(),
                  AnimatedRotation(
                    turns: _isFilterExpanded[sheet.id]! ? 0.5 : 0,
                    duration: Duration(milliseconds: 300),
                    child: Icon(Icons.expand_more, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Expandable filter content
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _isFilterExpanded[sheet.id]! ? null : 0,
            child: _isFilterExpanded[sheet.id]!
                ? _buildFilterContent(sheet)
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent(SheetConfig sheet) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main search bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchControllers[sheet.id],
              decoration: InputDecoration(
                hintText: 'Search in ${sheet.name.toLowerCase()}...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchControllers[sheet.id]!.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () => _clearSearch(sheet.id),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => _onSearchChanged(sheet.id, value),
            ),
          ),

          SizedBox(height: 16),

          // Filter section with proper layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive layout based on available width
              final isWideScreen = constraints.maxWidth > 800;
              final isTablet = constraints.maxWidth > 600;

              if (isWideScreen) {
                return _buildWideScreenFilters(sheet);
              } else if (isTablet) {
                return _buildTabletFilters(sheet);
              } else {
                return _buildMobileFilters(sheet);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWideScreenFilters(SheetConfig sheet) {
    return Column(
      children: [
        // First row: Amount range and Transaction mode
        Row(
          children: [
            Expanded(flex: 2, child: _buildAmountRangeFilter(sheet)),
            SizedBox(width: 12),
            Expanded(flex: 1, child: _buildTransactionModeFilter(sheet)),
            SizedBox(width: 12),
            Expanded(flex: 1, child: _buildQuickStatusFilter(sheet)),
          ],
        ),
        SizedBox(height: 12),
        // Second row: Remarks and Clear button
        Row(
          children: [
            Expanded(flex: 2, child: _buildRemarksFilter(sheet)),
            SizedBox(width: 12),
            Expanded(flex: 1, child: _buildClearAllButton(sheet)),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletFilters(SheetConfig sheet) {
    return Column(
      children: [
        // First row: Amount range
        _buildAmountRangeFilter(sheet),
        SizedBox(height: 12),
        // Second row: Transaction mode and Quick status
        Row(
          children: [
            Expanded(child: _buildTransactionModeFilter(sheet)),
            SizedBox(width: 12),
            Expanded(child: _buildQuickStatusFilter(sheet)),
          ],
        ),
        SizedBox(height: 12),
        // Third row: Remarks and Clear button
        Row(
          children: [
            Expanded(flex: 2, child: _buildRemarksFilter(sheet)),
            SizedBox(width: 12),
            Expanded(flex: 1, child: _buildClearAllButton(sheet)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFilters(SheetConfig sheet) {
    return Column(
      children: [
        _buildAmountRangeFilter(sheet),
        SizedBox(height: 12),
        _buildTransactionModeFilter(sheet),
        SizedBox(height: 12),
        _buildQuickStatusFilter(sheet),
        SizedBox(height: 12),
        _buildRemarksFilter(sheet),
        SizedBox(height: 12),
        _buildClearAllButton(sheet),
      ],
    );
  }

  Widget _buildAmountRangeFilter(SheetConfig sheet) {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              child: TextField(
                controller: _minAmountControllers[sheet.id],
                decoration: InputDecoration(
                  labelText: 'Min Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _onFilterChanged(sheet.id),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              child: TextField(
                controller: _maxAmountControllers[sheet.id],
                decoration: InputDecoration(
                  labelText: 'Max Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _onFilterChanged(sheet.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionModeFilter(SheetConfig sheet) {
    final modes = ['All', 'Paytm', 'PhonePe', 'Cloud', 'PTPP', 'Manual'];

    return Container(
      height: 48,
      child: DropdownButtonFormField<String>(
        value: _selectedTransactionModes[sheet.id],
        decoration: InputDecoration(
          labelText: 'Transaction Mode',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: modes
            .map((mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode, style: TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedTransactionModes[sheet.id] = value!;
          });
          _onFilterChanged(sheet.id);
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildRemarksFilter(SheetConfig sheet) {
    return Container(
      height: 48,
      child: TextField(
        controller: _remarksControllers[sheet.id],
        decoration: InputDecoration(
          labelText: 'Contains in Remarks',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (value) => _onFilterChanged(sheet.id),
      ),
    );
  }

  Widget _buildQuickStatusFilter(SheetConfig sheet) {
    final statuses = ['All', 'Perfect', 'Investigate', 'Manual'];

    return Container(
      height: 48,
      child: DropdownButtonFormField<String>(
        value: _selectedQuickStatuses[sheet.id],
        decoration: InputDecoration(
          labelText: 'Quick Status',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: statuses
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status, style: TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedQuickStatuses[sheet.id] = value!;
          });
          _onFilterChanged(sheet.id);
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildClearAllButton(SheetConfig sheet) {
    return Container(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _clearAllFilters(sheet.id),
        icon: Icon(Icons.clear_all, size: 18),
        label: Text('Clear All'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.grey[700],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips(SheetConfig sheet) {
    final activeFilters = _activeFilters[sheet.id] ?? [];

    if (activeFilters.isEmpty) return SizedBox.shrink();

    return Container(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Text('Active Filters: ',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey[600])),
          ...activeFilters.map((filter) => Chip(
                label: Text(filter, style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.blue[50],
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () => _removeFilter(sheet.id, filter),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )),
        ],
      ),
    );
  }

  Widget _buildDataContent(ReconProvider provider, SheetConfig sheet,
      List<Map<String, dynamic>>? data) {
    if (provider.isLoading) {
      return _buildLoadingState(sheet);
    }

    if (data == null || data.isEmpty) {
      return _buildEmptyState(sheet, provider);
    }

    final filteredData = _applyFilters(data, sheet.id);
    final paginatedData = _getPaginatedData(filteredData, sheet.id);

    if (filteredData.isEmpty) {
      return _buildNoResultsState(sheet);
    }

    return Column(
      children: [
        if (filteredData.length > _itemsPerPage)
          _buildPaginationInfo(sheet, filteredData.length),
        Expanded(child: _buildDataTable(sheet, paginatedData)),
        if (filteredData.length > _itemsPerPage)
          _buildPaginationControls(sheet, filteredData.length),
      ],
    );
  }

  Widget _buildLoadingState(SheetConfig sheet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: sheet.color),
          SizedBox(height: 16),
          Text('Loading ${sheet.name.toLowerCase()}...',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SheetConfig sheet, ReconProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child:
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          ),
          SizedBox(height: 16),
          Text('No data available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('No records found for ${sheet.name}',
              style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => provider.loadSheet(sheet.id),
            icon: Icon(Icons.refresh),
            label: Text('Reload Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: sheet.color,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(SheetConfig sheet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(Icons.search_off, size: 48, color: Colors.orange[400]),
          ),
          SizedBox(height: 16),
          Text('No results found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Try adjusting your filters or search criteria',
              style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _clearAllFilters(sheet.id),
            icon: Icon(Icons.clear_all),
            label: Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(SheetConfig sheet, List<Map<String, dynamic>> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildDataTableForSheet(sheet, data),
      ),
    );
  }

  Widget _buildDataTableForSheet(
      SheetConfig sheet, List<Map<String, dynamic>> data) {
    switch (sheet.id) {
      case 'SUMMARY':
        return _buildSummaryTable(data);
      case 'RAWDATA':
        return _buildRawDataTable(data);
      case 'RECON_SUCCESS':
      case 'RECON_INVESTIGATE':
      case 'MANUAL_REFUND':
        return _buildReconTable(data, sheet);
      default:
        return _buildGenericTable(data);
    }
  }

  Widget _buildSummaryTable(List<Map<String, dynamic>> data) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 600,
      headingRowHeight: 56,
      dataRowHeight: 48,
      headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
      columns: [
        DataColumn2(
          label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.M,
          numeric: true,
        ),
      ],
      rows: data
          .map((row) => DataRow2(
                cells: [
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(row['txn_source']?.toString() ?? ''),
                    ),
                  ),
                  DataCell(Text(row['Txn_type']?.toString() ?? '')),
                  DataCell(
                    Text(
                      currencyFormat.format(
                        double.tryParse(
                                row['sum(Txn_Amount)']?.toString() ?? '0') ??
                            0,
                      ),
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }

  Widget _buildRawDataTable(List<Map<String, dynamic>> data) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return DataTable2(
      columnSpacing: 8,
      horizontalMargin: 8,
      minWidth: 800,
      headingRowHeight: 56,
      dataRowHeight: 48,
      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
      columns: [
        DataColumn2(
          label: Text('Ref No', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Machine', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
          numeric: true,
        ),
      ],
      rows: data
          .map((row) => DataRow2(
                cells: [
                  DataCell(
                    SelectableText(
                      row['Txn_RefNo']?.toString() ?? '',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSourceColor(row['Txn_Source']?.toString()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        row['Txn_Source']?.toString() ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
                  DataCell(Text(row['Txn_Type']?.toString() ?? '',
                      style: TextStyle(fontSize: 12))),
                  DataCell(Text(row['Txn_Machine']?.toString() ?? '',
                      style: TextStyle(fontSize: 12))),
                  DataCell(
                    Text(
                      currencyFormat.format(
                        double.tryParse(row['Txn_Amount']?.toString() ?? '0') ??
                            0,
                      ),
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }

  Widget _buildReconTable(List<Map<String, dynamic>> data, SheetConfig sheet) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return DataTable2(
      columnSpacing: 8,
      horizontalMargin: 8,
      minWidth: 1000,
      headingRowHeight: 56,
      dataRowHeight: 48,
      headingRowColor: MaterialStateProperty.all(sheet.color.withOpacity(0.1)),
      columns: [
        DataColumn2(
          label: Text('Ref No', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text('Machine', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
        ),
        DataColumn2(
          label:
              Text('PTPP Pay', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label:
              Text('PTPP Ref', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label:
              Text('Cloud Pay', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label:
              Text('Cloud Ref', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold)),
          size: ColumnSize.M,
        ),
      ],
      rows: data
          .map((row) => DataRow2(
                cells: [
                  DataCell(
                    SelectableText(
                      row['Txn_RefNo']?.toString() ?? '',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  DataCell(Text(row['Txn_Machine']?.toString() ?? '',
                      style: TextStyle(fontSize: 12))),
                  DataCell(
                    Text(
                      currencyFormat.format(
                        double.tryParse(
                                row['PTPP_Payment']?.toString() ?? '0') ??
                            0,
                      ),
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      currencyFormat.format(
                        double.tryParse(
                                row['PTPP_Refund']?.toString() ?? '0') ??
                            0,
                      ),
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      currencyFormat.format(
                        double.tryParse(
                                row['Cloud_Payment']?.toString() ?? '0') ??
                            0,
                      ),
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      currencyFormat.format(
                        double.tryParse(
                                row['Cloud_Refund']?.toString() ?? '0') ??
                            0,
                      ),
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getRemarksColor(row['Remarks']?.toString() ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        row['Remarks']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }

  Widget _buildGenericTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return Center(child: Text('No data available'));

    final columns = data.first.keys.take(6).toList();

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: columns.length * 120.0,
      headingRowHeight: 56,
      dataRowHeight: 48,
      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
      columns: columns
          .map((column) => DataColumn2(
                label:
                    Text(column, style: TextStyle(fontWeight: FontWeight.bold)),
                size: ColumnSize.M,
              ))
          .toList(),
      rows: data
          .map((row) => DataRow2(
                cells: columns
                    .map((column) => DataCell(
                          Text(
                            _formatCellValue(row[column]),
                            style: TextStyle(fontSize: 12),
                          ),
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }

  Widget _buildPaginationInfo(SheetConfig sheet, int totalItems) {
    final currentPage = _currentPage[sheet.id] ?? 0;
    final startIndex = currentPage * _itemsPerPage + 1;
    final endIndex = ((currentPage + 1) * _itemsPerPage).clamp(0, totalItems);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startIndex-$endIndex of $totalItems records',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sheet.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Page ${currentPage + 1} of ${(totalItems / _itemsPerPage).ceil()}',
              style: TextStyle(
                color: sheet.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(SheetConfig sheet, int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final currentPage = _currentPage[sheet.id] ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: currentPage > 0 ? () => _changePage(sheet.id, 0) : null,
            icon: Icon(Icons.first_page, size: 18),
            label: Text('First'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
              elevation: 0,
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: currentPage > 0
                ? () => _changePage(sheet.id, currentPage - 1)
                : null,
            icon: Icon(Icons.chevron_left, size: 18),
            label: Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
              elevation: 0,
            ),
          ),
          SizedBox(width: 16),
          Text(
            '${currentPage + 1} / $totalPages',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: currentPage < totalPages - 1
                ? () => _changePage(sheet.id, currentPage + 1)
                : null,
            icon: Icon(Icons.chevron_right, size: 18),
            label: Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: sheet.color,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: currentPage < totalPages - 1
                ? () => _changePage(sheet.id, totalPages - 1)
                : null,
            icon: Icon(Icons.last_page, size: 18),
            label: Text('Last'),
            style: ElevatedButton.styleFrom(
              backgroundColor: sheet.color,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getRemarksColor(String remarks) {
    switch (remarks.toLowerCase()) {
      case 'perfect':
        return Colors.green[600]!;
      case 'investigate':
        return Colors.orange[600]!;
      case 'manual':
        return Colors.purple[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  Color _getSourceColor(String? source) {
    switch (source?.toLowerCase()) {
      case 'paytm':
        return Colors.blue[600]!;
      case 'phonepe':
        return Colors.purple[600]!;
      case 'cloud':
        return Colors.green[600]!;
      case 'ptpp':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '';
    if (value is num && value > 1000) {
      return NumberFormat('#,##0.00').format(value);
    }
    return value.toString();
  }

  int _getTotalRecords(ReconProvider provider) {
    int total = 0;
    for (String sheetId in [
      'SUMMARY',
      'RAWDATA',
      'RECON_SUCCESS',
      'RECON_INVESTIGATE',
      'MANUAL_REFUND'
    ]) {
      final data = provider.getSheetData(sheetId);
      if (data != null) total += data.length;
    }
    return total;
  }

  int _getSuccessRate(ReconProvider provider) {
    final successData = provider.getSheetData('RECON_SUCCESS');
    final investigateData = provider.getSheetData('RECON_INVESTIGATE');
    final totalRecon =
        (successData?.length ?? 0) + (investigateData?.length ?? 0);

    if (totalRecon == 0) return 0;
    return ((successData?.length ?? 0) * 100 / totalRecon).round();
  }

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> data, String sheetId) {
    final searchQuery = _searchControllers[sheetId]?.text.toLowerCase() ?? '';
    final minAmount =
        double.tryParse(_minAmountControllers[sheetId]?.text ?? '');
    final maxAmount =
        double.tryParse(_maxAmountControllers[sheetId]?.text ?? '');
    final remarksFilter =
        _remarksControllers[sheetId]?.text.toLowerCase() ?? '';
    final modeFilter = _selectedTransactionModes[sheetId] ?? 'All';
    final statusFilter = _selectedQuickStatuses[sheetId] ?? 'All';

    return data.where((row) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        bool matchesSearch = row.values.any((value) =>
            value?.toString().toLowerCase().contains(searchQuery) ?? false);
        if (!matchesSearch) return false;
      }

      // Amount range filter
      if (minAmount != null || maxAmount != null) {
        final amount = _getAmountFromRow(row);
        if (amount != null) {
          if (minAmount != null && amount < minAmount) return false;
          if (maxAmount != null && amount > maxAmount) return false;
        }
      }

      // Remarks filter
      if (remarksFilter.isNotEmpty) {
        final remarks = row['Remarks']?.toString().toLowerCase() ?? '';
        if (!remarks.contains(remarksFilter)) return false;
      }

      // Transaction mode filter
      if (modeFilter != 'All') {
        final source = row['Txn_Source']?.toString() ?? '';
        if (!source.toLowerCase().contains(modeFilter.toLowerCase()))
          return false;
      }

      // Quick status filter
      if (statusFilter != 'All') {
        final remarks = row['Remarks']?.toString().toLowerCase() ?? '';
        if (!remarks.contains(statusFilter.toLowerCase())) return false;
      }

      return true;
    }).toList();
  }

  double? _getAmountFromRow(Map<String, dynamic> row) {
    // Try different amount field names
    final amountFields = [
      'Txn_Amount',
      'PTPP_Payment',
      'Cloud_Payment',
      'sum(Txn_Amount)'
    ];

    for (String field in amountFields) {
      if (row.containsKey(field)) {
        return double.tryParse(row[field]?.toString() ?? '0');
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _getPaginatedData(
      List<Map<String, dynamic>> data, String sheetId) {
    final startIndex = (_currentPage[sheetId] ?? 0) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, data.length);
    return data.sublist(startIndex, endIndex);
  }

  void _toggleFilterExpansion(String sheetId) {
    setState(() {
      _isFilterExpanded[sheetId] = !_isFilterExpanded[sheetId]!;
    });

    if (_isFilterExpanded[sheetId]!) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _onSearchChanged(String sheetId, String value) {
    setState(() {
      _currentPage[sheetId] = 0;
    });
    _updateActiveFilters(sheetId);
  }

  void _onFilterChanged(String sheetId) {
    setState(() {
      _currentPage[sheetId] = 0;
    });
    _updateActiveFilters(sheetId);
  }

  void _updateActiveFilters(String sheetId) {
    List<String> filters = [];

    final searchQuery = _searchControllers[sheetId]?.text ?? '';
    if (searchQuery.isNotEmpty) {
      filters.add('Search: "$searchQuery"');
    }

    final minAmount = _minAmountControllers[sheetId]?.text ?? '';
    final maxAmount = _maxAmountControllers[sheetId]?.text ?? '';
    if (minAmount.isNotEmpty || maxAmount.isNotEmpty) {
      filters.add('Amount: ₹$minAmount - ₹$maxAmount');
    }

    final remarks = _remarksControllers[sheetId]?.text ?? '';
    if (remarks.isNotEmpty) {
      filters.add('Remarks: "$remarks"');
    }

    final mode = _selectedTransactionModes[sheetId] ?? 'All';
    if (mode != 'All') {
      filters.add('Mode: $mode');
    }

    final status = _selectedQuickStatuses[sheetId] ?? 'All';
    if (status != 'All') {
      filters.add('Status: $status');
    }

    setState(() {
      _activeFilters[sheetId] = filters;
    });
  }

  void _removeFilter(String sheetId, String filter) {
    if (filter.startsWith('Search:')) {
      _searchControllers[sheetId]?.clear();
    } else if (filter.startsWith('Amount:')) {
      _minAmountControllers[sheetId]?.clear();
      _maxAmountControllers[sheetId]?.clear();
    } else if (filter.startsWith('Remarks:')) {
      _remarksControllers[sheetId]?.clear();
    } else if (filter.startsWith('Mode:')) {
      _selectedTransactionModes[sheetId] = 'All';
    } else if (filter.startsWith('Status:')) {
      _selectedQuickStatuses[sheetId] = 'All';
    }

    _onFilterChanged(sheetId);
  }

  void _clearSearch(String sheetId) {
    setState(() {
      _searchControllers[sheetId]?.clear();
      _currentPage[sheetId] = 0;
    });
    _updateActiveFilters(sheetId);
  }

  void _clearAllFilters(String sheetId) {
    setState(() {
      _searchControllers[sheetId]?.clear();
      _minAmountControllers[sheetId]?.clear();
      _maxAmountControllers[sheetId]?.clear();
      _remarksControllers[sheetId]?.clear();
      _selectedTransactionModes[sheetId] = 'All';
      _selectedQuickStatuses[sheetId] = 'All';
      _currentPage[sheetId] = 0;
      _activeFilters[sheetId] = [];
    });
  }

  void _changePage(String sheetId, int newPage) {
    setState(() {
      _currentPage[sheetId] = newPage;
    });
  }
}

class SheetConfig {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final Color color;

  SheetConfig(this.id, this.name, this.icon, this.description, this.color);
}

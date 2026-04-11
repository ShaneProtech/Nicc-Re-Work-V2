import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_service.dart';
import '../services/goldblack_import_service.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_wrapper.dart';

class GoldBlackScreen extends StatefulWidget {
  const GoldBlackScreen({super.key});

  @override
  State<GoldBlackScreen> createState() => _GoldBlackScreenState();
}

class _GoldBlackScreenState extends State<GoldBlackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _loadingMessage;
  String _searchQuery = '';
  int _goldCount = 0;
  int _blackCount = 0;
  List<Map<String, dynamic>> _goldDTCs = [];
  List<Map<String, dynamic>> _blackDTCs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = context.read<DatabaseService>();
      _goldCount = await dbService.getGoldListCount();
      _blackCount = await dbService.getBlackListCount();
      _goldDTCs = await dbService.getGoldListDTCs();
      _blackDTCs = await dbService.getBlackListDTCs();
    } catch (e) {
      _showError('Error loading data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _importGoldList() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Importing Gold List...';
    });

    try {
      final dbService = context.read<DatabaseService>();
      final importService = GoldBlackImportService(dbService);
      final filePath = result.files.first.path!;
      
      final importResult = await importService.importGoldList(filePath);
      
      if (importResult['success'] == true) {
        final sheets = importResult['sheets'] ?? 1;
        final mapping = importResult['column_mapping'] ?? '';
        _showImportSuccess(
          'Gold List Imported',
          '${importResult['count']} DTCs from $sheets sheet(s)',
          mapping,
        );
        await _loadData();
      } else {
        final error = importResult['error']?.toString() ?? 'Unknown error';
        _showErrorDetails('Gold List Import Failed', error);
      }
    } catch (e) {
      _showErrorDetails('Gold List Import Error', e.toString());
    }

    setState(() {
      _isLoading = false;
      _loadingMessage = null;
    });
  }

  Future<void> _importBlackList() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Importing Black List...';
    });

    try {
      final dbService = context.read<DatabaseService>();
      final importService = GoldBlackImportService(dbService);
      final filePath = result.files.first.path!;
      
      final importResult = await importService.importBlackList(filePath);
      
      if (importResult['success'] == true) {
        final sheets = importResult['sheets'] ?? 1;
        final mapping = importResult['column_mapping'] ?? '';
        _showImportSuccess(
          'Black List Imported',
          '${importResult['count']} DTCs from $sheets sheet(s)',
          mapping,
        );
        await _loadData();
      } else {
        final error = importResult['error']?.toString() ?? 'Unknown error';
        _showErrorDetails('Black List Import Failed', error);
      }
    } catch (e) {
      _showErrorDetails('Black List Import Error', e.toString());
    }

    setState(() {
      _isLoading = false;
      _loadingMessage = null;
    });
  }

  void _showErrorDetails(String title, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  details,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Workaround:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Open the Excel file manually\n'
                '2. File → Save As → CSV (Comma delimited)\n'
                '3. Import the CSV file instead',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearList(String listType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        title: Text('Clear ${listType == 'gold' ? 'Gold' : 'Black'} List?'),
        content: Text('This will delete all DTCs from the ${listType == 'gold' ? 'Gold' : 'Black'} list. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final dbService = context.read<DatabaseService>();
      await dbService.clearGoldBlackDTCs(listType: listType);
      _showSuccess('${listType == 'gold' ? 'Gold' : 'Black'} List cleared');
      await _loadData();
    } catch (e) {
      _showError('Error clearing list: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showImportSuccess(String title, String message, String columnMapping) {
    // Just show a simple success snackbar now
    _showSuccess('$title: $message');
  }
  
  void _showImportDetails(Map<String, dynamic> result) {
    final headers = result['headers']?.toString() ?? '';
    final mapping = result['column_mapping']?.toString() ?? '';
    final unmapped = result['unmapped']?.toString() ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundMedium,
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Import Details', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Excel Headers Found:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                child: Text(headers, style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(height: 12),
              const Text('Mapped Columns:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(mapping.isNotEmpty ? mapping : 'None', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
              ),
              if (unmapped.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Unmapped Columns:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(unmapped, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredGoldDTCs {
    if (_searchQuery.isEmpty) return _goldDTCs;
    final query = _searchQuery.toLowerCase();
    return _goldDTCs.where((dtc) {
      return (dtc['dtc_code']?.toString().toLowerCase().contains(query) ?? false) ||
          (dtc['description']?.toString().toLowerCase().contains(query) ?? false) ||
          (dtc['module']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredBlackDTCs {
    if (_searchQuery.isEmpty) return _blackDTCs;
    final query = _searchQuery.toLowerCase();
    return _blackDTCs.where((dtc) {
      return (dtc['dtc_code']?.toString().toLowerCase().contains(query) ?? false) ||
          (dtc['description']?.toString().toLowerCase().contains(query) ?? false) ||
          (dtc['module']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      title: 'Gold/Black Lists',
      subtitle: 'Manage DTC lists for analysis',
      accentColor: AppColors.warning,
      actions: [
        NeumorphicIconButton(
          icon: Icons.refresh_rounded,
          onPressed: _loadData,
          tooltip: 'Refresh',
          color: AppColors.primaryBlue,
        ),
      ],
      child: Column(
        children: [
          _buildStatsBar(),
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        if (_loadingMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _loadingMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Converting file format if needed...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoldListTab(),
                      _buildBlackListTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecoration.flat(radius: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              label: 'Gold List',
              value: _goldCount.toString(),
              color: Colors.amber,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.shadowLight),
          Expanded(
            child: _buildStatItem(
              icon: Icons.block_rounded,
              label: 'Black List',
              value: _blackCount.toString(),
              color: AppColors.textMuted,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.shadowLight),
          Expanded(
            child: _buildStatItem(
              icon: Icons.analytics_rounded,
              label: 'Total DTCs',
              value: (_goldCount + _blackCount).toString(),
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      child: NeumorphicSearchBar(
        hintText: 'Search DTCs...',
        accentColor: AppColors.warning,
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      decoration: NeumorphicDecoration.concave(radius: 14),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primaryBlue.withOpacity(0.2),
        ),
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor: AppColors.textMuted,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text('Gold List ($_goldCount)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Text('Black List ($_blackCount)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldListTab() {
    return Column(
      children: [
        _buildImportButtons('gold'),
        Expanded(
          child: _filteredGoldDTCs.isEmpty
              ? _buildEmptyState('Gold', Colors.amber)
              : _buildDTCList(_filteredGoldDTCs, Colors.amber),
        ),
      ],
    );
  }

  Widget _buildBlackListTab() {
    return Column(
      children: [
        _buildImportButtons('black'),
        Expanded(
          child: _filteredBlackDTCs.isEmpty
              ? _buildEmptyState('Black', AppColors.textMuted)
              : _buildDTCList(_filteredBlackDTCs, AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildImportButtons(String listType) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.upload_file_rounded,
              label: 'Import ${listType == 'gold' ? 'Gold' : 'Black'} List',
              color: listType == 'gold' ? Colors.amber : AppColors.textSecondary,
              onPressed: listType == 'gold' ? _importGoldList : _importBlackList,
            ),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Clear',
            color: AppColors.error,
            onPressed: () => _clearList(listType),
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: 12,
        ),
        decoration: NeumorphicDecoration.flat(radius: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String listName, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            listName == 'Gold' ? Icons.star_outline_rounded : Icons.block_outlined,
            size: 64,
            color: color.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No DTCs in $listName List',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import an Excel file to add DTCs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDTCList(List<Map<String, dynamic>> dtcs, Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      itemCount: dtcs.length,
      itemBuilder: (context, index) {
        final dtc = dtcs[index];
        return _buildDTCCard(dtc, accentColor, index);
      },
    );
  }

  Widget _buildDTCCard(Map<String, dynamic> dtc, Color accentColor, int index) {
    final description = dtc['description']?.toString() ?? '';
    final module = dtc['module']?.toString() ?? '';
    final system = dtc['system']?.toString() ?? '';
    final category = dtc['category']?.toString() ?? '';
    final make = dtc['make']?.toString() ?? '';
    final model = dtc['model']?.toString() ?? '';
    final year = dtc['year']?.toString() ?? '';
    final notes = dtc['notes']?.toString() ?? '';
    final additionalData = dtc['additional_data']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecoration.flat(radius: 14, intensity: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with DTC code
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Text(
                  dtc['dtc_code'] ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description.isNotEmpty ? description : 'No description',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Details section
          if (module.isNotEmpty || system.isNotEmpty || category.isNotEmpty ||
              make.isNotEmpty || model.isNotEmpty || year.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (module.isNotEmpty)
                  _buildDetailChip('Module', module, Icons.memory, accentColor),
                if (system.isNotEmpty)
                  _buildDetailChip('System', system, Icons.settings, accentColor),
                if (category.isNotEmpty)
                  _buildDetailChip('Category', category, Icons.category, accentColor),
                if (make.isNotEmpty)
                  _buildDetailChip('Make', make, Icons.directions_car, accentColor),
                if (model.isNotEmpty)
                  _buildDetailChip('Model', model, Icons.car_repair, accentColor),
                if (year.isNotEmpty)
                  _buildDetailChip('Year', year, Icons.calendar_today, accentColor),
              ],
            ),
          ],
          
          // Notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Additional data
          if (additionalData.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              additionalData,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 20).ms).fadeIn(duration: 250.ms);
  }

  Widget _buildDetailChip(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

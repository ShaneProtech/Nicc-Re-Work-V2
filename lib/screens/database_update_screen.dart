import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/excel_import_service.dart';
import '../widgets/animated_background.dart';

class DatabaseUpdateScreen extends StatefulWidget {
  const DatabaseUpdateScreen({super.key});

  @override
  State<DatabaseUpdateScreen> createState() => _DatabaseUpdateScreenState();
}

class _DatabaseUpdateScreenState extends State<DatabaseUpdateScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  Map<String, dynamic>? _importResult;
  ImportProgress? _currentProgress;

  Future<void> _selectDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder containing Excel files',
      );

      if (result != null) {
        setState(() {
          _selectedPath = result;
          _importResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Excel file',
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedPath = result.files.first.path;
          _importResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    if (_selectedPath == null) return;

    setState(() {
      _isProcessing = true;
      _importResult = null;
      _currentProgress = null;
    });

    try {
      final dbService = context.read<DatabaseService>();
      final database = dbService.databaseSync;

      if (database == null) {
        throw Exception('Database not initialized');
      }

      final importService = ExcelImportService(database);

      Stream<ImportProgress> progressStream;
      
      // Check if it's a file or directory
      if (_selectedPath!.endsWith('.xlsx') || _selectedPath!.endsWith('.xls')) {
        // Import single file
        progressStream = importService.importFromFileWithProgress(_selectedPath!);
      } else {
        // Import from directory
        progressStream = importService.importFromDirectoryWithProgress(_selectedPath!);
      }

      // Listen to progress stream
      ImportProgress? lastProgress;
      await for (final progress in progressStream) {
        if (mounted) {
          setState(() {
            _currentProgress = progress;
          });
        }
        lastProgress = progress;
        
        // Minimal delay to allow UI to update
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Import successful
      final result = {
        'success': true,
        'message': 'Successfully imported ${lastProgress?.recordsImported ?? 0} records from ${lastProgress?.totalFiles ?? 0} files',
        'totalRecords': lastProgress?.recordsImported ?? 0,
        'filesProcessed': lastProgress?.totalFiles ?? 0,
      };

      setState(() {
        _importResult = result;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Import successful'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _importResult = {
          'success': false,
          'message': 'Error: ${e.toString()}',
        };
        _isProcessing = false;
        _currentProgress = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        _buildSelectionSection(),
                        if (_selectedPath != null) ...[
                          const SizedBox(height: 24),
                          _buildSelectedPathCard(),
                        ],
                        const SizedBox(height: 24),
                        _buildImportButton(),
                        if (_importResult != null) ...[
                          const SizedBox(height: 24),
                          _buildResultCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.2),
            Colors.purple.withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Database',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Import ADAS data from Excel files',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.cyan.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blueAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'How it works',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            '1',
            'Select a folder containing Excel files or a single Excel file',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            '2',
            'The app will read all .xlsx and .xls files',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            '3',
            'First row (header) determines the table structure',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            '4',
            'ADAS systems will be imported or updated in the database',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      children: [
        _buildSelectButton(
          icon: Icons.folder_outlined,
          label: 'Select Folder',
          subtitle: 'Import all Excel files from a folder',
          onPressed: _selectDirectory,
          color: Colors.purple,
        ),
        const SizedBox(height: 16),
        _buildSelectButton(
          icon: Icons.insert_drive_file_outlined,
          label: 'Select File',
          subtitle: 'Import a single Excel file',
          onPressed: _selectFile,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildSelectButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPathCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.greenAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPath!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    final canImport = _selectedPath != null && !_isProcessing;

    return ElevatedButton(
      onPressed: canImport ? _importData : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canImport ? Colors.blueAccent : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            canImport ? Icons.cloud_upload : Icons.cloud_off,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            canImport ? 'Import Data' : 'Select a path first',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isSuccess = _importResult?['success'] == true;
    final color = isSuccess ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSuccess ? 'Import Successful' : 'Import Failed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _importResult?['message']?.toString() ?? 'No message',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          if (_importResult?['totalRecords'] != null) ...[
            const SizedBox(height: 12),
            _buildResultItem(
              'Records Imported',
              _importResult?['totalRecords'].toString() ?? '0',
            ),
          ],
          if (_importResult?['filesProcessed'] != null) ...[
            const SizedBox(height: 8),
            _buildResultItem(
              'Files Processed',
              _importResult?['filesProcessed'].toString() ?? '0',
            ),
          ],
          if (_importResult?['fileResults'] != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text(
              'File Details:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...(_importResult!['fileResults'] as Map<String, int>)
                .entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildResultItem(entry.key, '${entry.value} records'),
                    )),
          ],
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    final progress = _currentProgress;
    final percentage = progress?.percentage ?? 0.0;
    final percentageText = '${(percentage * 100).toStringAsFixed(1)}%';

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress != null ? percentage : null,
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                  Text(
                    percentageText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Importing Excel Files',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Progress bar
              if (progress != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 12,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 16),
                
                // File info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildProgressRow(
                        'Files',
                        '${progress.processedFiles}/${progress.totalFiles}',
                        Icons.insert_drive_file,
                      ),
                      const SizedBox(height: 8),
                      _buildProgressRow(
                        'Records',
                        '${progress.recordsImported}',
                        Icons.dataset,
                      ),
                      const SizedBox(height: 8),
                      _buildProgressRow(
                        'Size',
                        '${_formatBytes(progress.processedBytes)}/${_formatBytes(progress.totalBytes)}',
                        Icons.storage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Current file
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          progress.currentFileName,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing import...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Large files with many rows may take 30-60 seconds each',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please wait, do not close the app',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}


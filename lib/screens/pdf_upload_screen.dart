import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/calibration_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/calibration_system_card.dart';

class PDFUploadScreen extends StatefulWidget {
  const PDFUploadScreen({super.key});

  @override
  State<PDFUploadScreen> createState() => _PDFUploadScreenState();
}

class _PDFUploadScreenState extends State<PDFUploadScreen> {
  String? _estimatePath;
  String? _scanReportPath;
  String? _estimateFileName;
  String? _scanReportFileName;
  bool _hasAnalyzed = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalibrationProvider>();

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
                        _buildUploadCards(),
                        const SizedBox(height: 24),
                        if (_estimatePath != null) _buildAnalyzeButton(provider),
                        const SizedBox(height: 24),
                        if (provider.isLoading)
                          _buildLoadingIndicator()
                        else if (_hasAnalyzed && provider.requiredSystems.isNotEmpty)
                          ...[
                            _buildResultsHeader(provider),
                            const SizedBox(height: 16),
                            _buildResultsList(provider),
                            const SizedBox(height: 24),
                            _buildSummaryCard(provider),
                          ]
                        else if (_hasAnalyzed)
                          _buildNoResultsCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.picture_as_pdf,
            color: const Color(0xFF00B4D8),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'PDF Upload',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ).animate().fadeIn().slideX(begin: -0.2, end: 0),
    );
  }

  Widget _buildUploadCards() {
    return Column(
      children: [
        _buildUploadCard(
          title: 'Estimate PDF',
          subtitle: 'Upload repair estimate (read-only analysis)',
          fileName: _estimateFileName,
          icon: Icons.description,
          color: const Color(0xFF00B4D8),
          onTap: () => _pickPDF(isEstimate: true),
          onClear: _estimatePath != null
              ? () => setState(() {
                    _estimatePath = null;
                    _estimateFileName = null;
                    _hasAnalyzed = false;
                  })
              : null,
        ),
        const SizedBox(height: 16),
        _buildUploadCard(
          title: 'Scan Report PDF (Optional)',
          subtitle: 'Upload scan report for comparison (read-only)',
          fileName: _scanReportFileName,
          icon: Icons.scanner,
          color: const Color(0xFF0077B6),
          onTap: () => _pickPDF(isEstimate: false),
          onClear: _scanReportPath != null
              ? () => setState(() {
                    _scanReportPath = null;
                    _scanReportFileName = null;
                  })
              : null,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required String? fileName,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileName ?? subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: fileName != null
                                  ? color
                                  : Colors.white60,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                    color: Colors.white60,
                  )
                else
                  Icon(Icons.upload_file, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPDF({required bool isEstimate}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isEstimate) {
          _estimatePath = result.files.single.path;
          _estimateFileName = result.files.single.name;
        } else {
          _scanReportPath = result.files.single.path;
          _scanReportFileName = result.files.single.name;
        }
        _hasAnalyzed = false;
      });
    }
  }

  Widget _buildAnalyzeButton(CalibrationProvider provider) {
    return ElevatedButton.icon(
      onPressed: provider.isLoading ? null : _analyzePDFs,
      icon: const Icon(Icons.auto_fix_high),
      label: const Text('Analyze PDFs with AI'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00B4D8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    ).animate().fadeIn(delay: 300.ms).scale();
  }

  Future<void> _analyzePDFs() async {
    final provider = context.read<CalibrationProvider>();
    await provider.analyzePDFs(
      estimatePath: _estimatePath!,
      scanReportPath: _scanReportPath,
    );

    setState(() {
      _hasAnalyzed = true;
    });

    if (provider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: const Color(0xFF00B4D8),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                  duration: 1000.ms,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2)),
          const SizedBox(height: 24),
          Text(
            'Analyzing PDFs...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Comparing document with calibration database',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Identifying required calibrations and programmings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(CalibrationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Complete',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green,
                      ),
                ),
                Text(
                  '${provider.requiredSystems.length} calibration(s)/programming(s) required',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildResultsList(CalibrationProvider provider) {
    return Column(
      children: provider.requiredSystems.map((system) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CalibrationSystemCard(system: system),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(CalibrationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0077B6).withOpacity(0.2),
            const Color(0xFF023E8A).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0077B6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            icon: Icons.attach_money,
            label: 'Estimated Cost',
            value: '\$${provider.getTotalEstimatedCost().toStringAsFixed(0)}+',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            icon: Icons.access_time,
            label: 'Estimated Time',
            value: provider.getTotalEstimatedTime(),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            icon: Icons.build,
            label: 'Systems',
            value: '${provider.requiredSystems.length}',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF90E0EF), size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF00B4D8),
              ),
        ),
      ],
    );
  }

  Widget _buildNoResultsCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'No Calibrations Required',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Based on the documents compared with the database, no ADAS calibrations or programmings appear to be necessary.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}




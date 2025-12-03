import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/calibration_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/calibration_system_card.dart';

class EstimateAnalyzerScreen extends StatefulWidget {
  const EstimateAnalyzerScreen({super.key});

  @override
  State<EstimateAnalyzerScreen> createState() => _EstimateAnalyzerScreenState();
}

class _EstimateAnalyzerScreenState extends State<EstimateAnalyzerScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasAnalyzed = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInputCard(),
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
          Text(
            'Estimate Analyzer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ).animate().fadeIn().slideX(begin: -0.2, end: 0),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00B4D8).withOpacity(0.1),
            const Color(0xFF0077B6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00B4D8).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.document_scanner,
                color: const Color(0xFF00B4D8),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Paste Estimate Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Paste estimate text here...\n\nExample:\n- Windshield replacement\n- Front bumper repair\n- Right mirror replacement\n- Wheel alignment',
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _analyzeEstimate,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Analyze with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Future<void> _analyzeEstimate() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter estimate details')),
      );
      return;
    }

    final provider = context.read<CalibrationProvider>();
    await provider.analyzeEstimate(_textController.text);
    
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

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _textController.text = data!.text!;
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
              .scale(duration: 1000.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
          const SizedBox(height: 24),
          Text(
            'Analyzing estimate...',
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
            'Based on the estimate compared with the database, no ADAS calibrations or programmings appear to be necessary.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}




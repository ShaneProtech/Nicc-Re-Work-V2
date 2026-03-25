import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/calibration_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/feature_card.dart';
import 'estimate_analyzer_screen.dart';
import 'ai_assistant_screen.dart';
import 'systems_library_screen.dart';
import 'history_screen.dart';
import 'pdf_upload_screen.dart';
import 'database_update_screen.dart';
import 'database_manager_screen.dart';
import 'json_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                _buildContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'NICC Calibration',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00B4D8).withOpacity(0.3),
                const Color(0xFF0077B6).withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.car_repair,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final provider = context.watch<CalibrationProvider>();

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildWelcomeCard(provider),
          const SizedBox(height: 24),
          _buildStatusBanner(provider),
          const SizedBox(height: 32),
          _buildFeatureGrid(),
          const SizedBox(height: 32),
          _buildQuickStats(provider),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildWelcomeCard(CalibrationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00B4D8).withOpacity(0.2),
            const Color(0xFF0077B6).withOpacity(0.1),
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
                Icons.waving_hand,
                color: Colors.amber,
                size: 32,
              ).animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 2000.ms, begin: -0.05, end: 0.05),
              const SizedBox(width: 12),
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your intelligent ADAS calibration assistant is ready to help you identify required calibrations quickly and accurately.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: const Color(0xFF90E0EF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.allSystems.length} Calibration Systems Available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF90E0EF),
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildStatusBanner(CalibrationProvider provider) {
    final isConnected = provider.ollamaAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? Colors.green.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isConnected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConnected
                  ? 'AI Assistant Connected'
                  : 'AI Assistant Offline - Using Fallback Analysis',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isConnected ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildFeatureGrid() {
    final features = [
      {
        'icon': Icons.picture_as_pdf,
        'title': 'PDF Upload',
        'description': 'Upload estimate PDFs and scan reports for analysis',
        'color': const Color(0xFFFF6B6B),
        'route': const PDFUploadScreen(),
      },
      {
        'icon': Icons.document_scanner,
        'title': 'Text Estimate',
        'description': 'Paste text estimate to identify calibrations',
        'color': const Color(0xFF00B4D8),
        'route': const EstimateAnalyzerScreen(),
      },
      {
        'icon': Icons.psychology,
        'title': 'AI Assistant',
        'description': 'Ask questions about calibration requirements',
        'color': const Color(0xFF0077B6),
        'route': const AIAssistantScreen(),
      },
      {
        'icon': Icons.library_books,
        'title': 'Systems Library',
        'description': 'Browse all available calibration systems',
        'color': const Color(0xFF023E8A),
        'route': const SystemsLibraryScreen(),
      },
      {
        'icon': Icons.history,
        'title': 'History',
        'description': 'View recent calibration analyses',
        'color': const Color(0xFF03045E),
        'route': const HistoryScreen(),
      },
      {
        'icon': Icons.cloud_upload,
        'title': 'Update Database',
        'description': 'Import ADAS data from Excel files',
        'color': const Color(0xFF4CAF50),
        'route': const DatabaseUpdateScreen(),
        'refreshOnReturn': true,
      },
      {
        'icon': Icons.storage,
        'title': 'Database Manager',
        'description': 'Browse imported calibration data',
        'color': const Color(0xFF9C27B0),
        'route': const DatabaseManagerScreen(),
        'refreshOnReturn': true,
      },
      {
        'icon': Icons.data_object,
        'title': 'ID3 JSON',
        'description': 'Import calibration data from JSON/Text files',
        'color': const Color(0xFFFF9800),
        'route': const JsonImportScreen(),
      },
    ];

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: FeatureCard(
                  icon: feature['icon'] as IconData,
                  title: feature['title'] as String,
                  description: feature['description'] as String,
                  color: feature['color'] as Color,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => feature['route'] as Widget,
                      ),
                    );
                    // Refresh data if returning from database-related screens
                    if (feature['refreshOnReturn'] == true && mounted) {
                      context.read<CalibrationProvider>().refreshData();
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(CalibrationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate().fadeIn(delay: 400.ms),
            IconButton(
              icon: provider.isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh database stats',
              onPressed: provider.isLoading 
                  ? null 
                  : () async {
                      await provider.refreshData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Database refreshed'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.system_update_alt,
                value: provider.allSystems.length.toString(),
                label: 'Systems',
                color: const Color(0xFF00B4D8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.history,
                value: provider.recentResults.length.toString(),
                label: 'Recent',
                color: const Color(0xFF0077B6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ).animate().scale(delay: 600.ms, duration: 600.ms);
  }
}


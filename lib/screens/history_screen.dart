import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/calibration_provider.dart';
import '../widgets/animated_background.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
                _buildAppBar(context),
                Expanded(
                  child: provider.recentResults.isEmpty
                      ? _buildEmptyState(context)
                      : _buildHistoryList(context, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
            Icons.history,
            color: const Color(0xFF00B4D8),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Analysis History',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ).animate().fadeIn().slideX(begin: -0.2, end: 0),
    );
  }

  Widget _buildHistoryList(BuildContext context, CalibrationProvider provider) {
    // Group results by date
    final groupedResults = <String, List<dynamic>>{};
    for (var result in provider.recentResults) {
      final dateKey = DateFormat('MMM d, yyyy').format(result.analyzedAt);
      groupedResults.putIfAbsent(dateKey, () => []);
      groupedResults[dateKey]!.add(result);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final dateKey = groupedResults.keys.elementAt(index);
        final results = groupedResults[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 8),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF00B4D8),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...results.map((result) => _buildHistoryItem(context, result)),
            const SizedBox(height: 24),
          ],
        ).animate().fadeIn(delay: (index * 100).ms);
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, dynamic result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00B4D8).withOpacity(0.1),
            const Color(0xFF0077B6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00B4D8).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.required
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              result.required ? Icons.warning_amber : Icons.check_circle,
              color: result.required ? Colors.amber : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.systemName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  result.reason,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('HH:mm').format(result.analyzedAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF00B4D8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.white24,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 3000.ms),
          const SizedBox(height: 16),
          Text(
            'No History Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Analyze estimates to build your history',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}




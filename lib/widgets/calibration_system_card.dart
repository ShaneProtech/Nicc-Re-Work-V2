import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/calibration_system.dart';

class CalibrationSystemCard extends StatelessWidget {
  final CalibrationSystem system;

  const CalibrationSystemCard({
    super.key,
    required this.system,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor().withOpacity(0.15),
            _getCategoryColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIcon(),
            color: _getCategoryColor(),
            size: 28,
          ),
        ),
        title: Text(
          system.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
              ),
        ),
        subtitle: Text(
          system.category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getCategoryColor(),
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  system.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  Icons.access_time,
                  'Time',
                  system.estimatedTime,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  Icons.attach_money,
                  'Cost',
                  system.estimatedCost,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  Icons.build,
                  'Equipment',
                  system.equipmentNeeded.join(', '),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Required For:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.amber,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: system.requiredFor.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getCategoryColor().withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              item,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Pre-Qualifications Section
                if (system.preQualifications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.greenAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pre-Qualifications:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...system.preQualifications.map((preQual) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.arrow_right,
                                  color: Colors.greenAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    preQual,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
                // Hyperlink Section
                if (system.hyperlink != null && system.hyperlink!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _launchURL(system.hyperlink!),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor().withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: _getCategoryColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'View Calibration Guide',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _getCategoryColor(),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: _getCategoryColor(),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _getCategoryColor(), size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getCategoryColor(),
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (system.category) {
      case 'Camera Systems':
        return const Color(0xFF00B4D8);
      case 'Radar Systems':
        return const Color(0xFF0077B6);
      case 'Sensor Systems':
        return const Color(0xFF023E8A);
      case 'Lighting Systems':
        return const Color(0xFFCAF0F8);
      case 'Chassis Systems':
        return const Color(0xFF90E0EF);
      case 'Safety Systems':
        return const Color(0xFF48CAE4);
      default:
        return const Color(0xFF00B4D8);
    }
  }

  IconData _getIcon() {
    switch (system.iconName) {
      case 'camera':
        return Icons.camera_alt;
      case 'radar':
        return Icons.radar;
      case 'lanes':
        return Icons.straighten;
      case 'visibility':
        return Icons.visibility;
      case 'sensors':
        return Icons.sensors;
      case '360':
        return Icons.threed_rotation;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'steering':
        return Icons.settings_input_composite;
      case 'nightlight':
        return Icons.nightlight;
      case 'person':
        return Icons.person;
      default:
        return Icons.settings;
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../screens/estimate_analyzer_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/systems_library_screen.dart';
import '../screens/history_screen.dart';
import '../screens/pdf_upload_screen.dart';
import '../screens/database_update_screen.dart';
import '../screens/database_manager_screen.dart';
import '../screens/json_import_screen.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  final Color accentColor;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
    required this.accentColor,
  });
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExpanded = true;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Dashboard',
      screen: const _DashboardPlaceholder(),
      accentColor: AppColors.primaryBlue,
    ),
    NavItem(
      icon: Icons.picture_as_pdf_outlined,
      activeIcon: Icons.picture_as_pdf_rounded,
      label: 'PDF Upload',
      screen: const PDFUploadScreen(),
      accentColor: AppColors.cardPDF,
    ),
    NavItem(
      icon: Icons.document_scanner_outlined,
      activeIcon: Icons.document_scanner_rounded,
      label: 'Text Estimate',
      screen: const EstimateAnalyzerScreen(),
      accentColor: AppColors.cardEstimate,
    ),
    NavItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology_rounded,
      label: 'AI Assistant',
      screen: const AIAssistantScreen(),
      accentColor: AppColors.cardAI,
    ),
    NavItem(
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books_rounded,
      label: 'Systems Library',
      screen: const SystemsLibraryScreen(),
      accentColor: AppColors.cardLibrary,
    ),
    NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'History',
      screen: const HistoryScreen(),
      accentColor: AppColors.cardHistory,
    ),
    NavItem(
      icon: Icons.cloud_upload_outlined,
      activeIcon: Icons.cloud_upload_rounded,
      label: 'Update Database',
      screen: const DatabaseUpdateScreen(),
      accentColor: AppColors.cardDatabase,
    ),
    NavItem(
      icon: Icons.storage_outlined,
      activeIcon: Icons.storage_rounded,
      label: 'Database Manager',
      screen: const DatabaseManagerScreen(),
      accentColor: AppColors.cardManager,
    ),
    NavItem(
      icon: Icons.data_object_outlined,
      activeIcon: Icons.data_object_rounded,
      label: 'ID3 JSON',
      screen: const JsonImportScreen(),
      accentColor: AppColors.cardJSON,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
    _expandController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: _isExpanded ? 260 : 76,
      child: Container(
        margin: EdgeInsets.all(_isExpanded ? 12 : 6),
        decoration: NeumorphicDecoration.flat(
          color: AppColors.backgroundMedium,
          radius: _isExpanded ? 24 : 16,
        ),
        child: Column(
          children: [
            _buildLogo(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildNavList(),
            ),
            _buildCollapseButton(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: EdgeInsets.all(_isExpanded ? 20 : 10),
      child: Row(
        mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_isExpanded ? 10 : 8),
            decoration: NeumorphicDecoration.glowingBorder(
              glowColor: AppColors.primaryBlue,
              radius: _isExpanded ? 14 : 10,
            ),
            child: Icon(
              Icons.car_repair_rounded,
              color: AppColors.primaryBlue,
              size: _isExpanded ? 28 : 22,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          if (_isExpanded) ...[
            const SizedBox(width: 14),
            FadeTransition(
              opacity: _expandAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NICC',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Calibration Suite',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 12 : 4,
        vertical: 8,
      ),
      itemCount: _navItems.length,
      itemBuilder: (context, index) {
        final item = _navItems[index];
        final isSelected = _selectedIndex == index;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _NavItemWidget(
            item: item,
            isSelected: isSelected,
            isExpanded: _isExpanded,
            expandAnimation: _expandAnimation,
            onTap: () => setState(() => _selectedIndex = index),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildCollapseButton() {
    return GestureDetector(
      onTap: _toggleSidebar,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: NeumorphicDecoration.concave(radius: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: _isExpanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textMuted,
                size: 24,
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(width: 8),
              FadeTransition(
                opacity: _expandAnimation,
                child: Text(
                  'Collapse',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
      decoration: NeumorphicDecoration.flat(
        color: AppColors.backgroundDark,
        radius: 24,
        intensity: 0.4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: _selectedIndex == 0
                ? _buildDashboardContent()
                : _navItems[_selectedIndex].screen,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return const _DashboardContent();
  }
}

class _NavItemWidget extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final bool isExpanded;
  final Animation<double> expandAnimation;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.expandAnimation,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 16 : 0,
            vertical: widget.isExpanded ? 12 : 8,
          ),
          decoration: widget.isSelected
              ? NeumorphicDecoration.glowingBorder(
                  glowColor: widget.item.accentColor,
                  radius: widget.isExpanded ? 14 : 12,
                  glowIntensity: 0.4,
                )
              : _isHovered
                  ? NeumorphicDecoration.pressed(radius: widget.isExpanded ? 14 : 12)
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.isExpanded ? 14 : 12),
                      color: Colors.transparent,
                    ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(widget.isExpanded ? 8 : 6),
                decoration: widget.isSelected
                    ? BoxDecoration(
                        color: widget.item.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(widget.isExpanded ? 10 : 8),
                      )
                    : null,
                child: Icon(
                  widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                  color: widget.isSelected
                      ? widget.item.accentColor
                      : _isHovered
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                  size: widget.isExpanded ? 22 : 20,
                ),
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FadeTransition(
                    opacity: widget.expandAnimation,
                    child: Text(
                      widget.item.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: widget.isSelected
                            ? AppColors.textPrimary
                            : _isHovered
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.item.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.item.accentColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms, color: Colors.white24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _DashboardContent();
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return const _DashboardView();
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _AnimatedDashboardBackground(),
        SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildRecentActivity(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    greetingIcon,
                    color: AppColors.warning,
                    size: 28,
                  ).animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 3000.ms, begin: -0.02, end: 0.02),
                  const SizedBox(width: 12),
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                'Your ADAS calibration assistant is ready to help',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            ],
          ),
        ),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: NeumorphicDecoration.glowingBorder(
        glowColor: AppColors.success,
        radius: 30,
        glowIntensity: 0.3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms)
              .then()
              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 1000.ms),
          const SizedBox(width: 10),
          Text(
            'System Online',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'icon': Icons.precision_manufacturing_rounded,
        'value': '247',
        'label': 'Total Systems',
        'change': '+12 this week',
        'color': AppColors.primaryBlue,
      },
      {
        'icon': Icons.check_circle_rounded,
        'value': '89%',
        'label': 'Analysis Accuracy',
        'change': '+3% improvement',
        'color': AppColors.success,
      },
      {
        'icon': Icons.timer_rounded,
        'value': '1.2s',
        'label': 'Avg Response',
        'change': '50% faster',
        'color': AppColors.warning,
      },
      {
        'icon': Icons.trending_up_rounded,
        'value': '156',
        'label': 'Analyses Today',
        'change': 'Peak performance',
        'color': AppColors.cardAI,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _StatCard(
              icon: stat['icon'] as IconData,
              value: stat['value'] as String,
              label: stat['label'] as String,
              change: stat['change'] as String,
              color: stat['color'] as Color,
            ).animate(delay: (600 + index * 100).ms)
                .fadeIn()
                .scale(begin: const Offset(0.9, 0.9));
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.flat(radius: 20),
          child: Column(
            children: [
              _ActivityItem(
                icon: Icons.analytics_rounded,
                title: 'Calibration Analysis Complete',
                subtitle: '2024 Toyota Camry - Forward Collision Warning',
                time: '2 minutes ago',
                color: AppColors.success,
              ),
              const Divider(height: 32),
              _ActivityItem(
                icon: Icons.cloud_upload_rounded,
                title: 'Database Updated',
                subtitle: 'Honda ADAS systems data imported',
                time: '15 minutes ago',
                color: AppColors.primaryBlue,
              ),
              const Divider(height: 32),
              _ActivityItem(
                icon: Icons.psychology_rounded,
                title: 'AI Query Processed',
                subtitle: 'Pre-qualification requirements for Subaru EyeSight',
                time: '1 hour ago',
                color: AppColors.cardAI,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final String change;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.change,
    required this.color,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: _isHovered
            ? NeumorphicDecoration.glowingBorder(
                glowColor: widget.color,
                radius: 16,
                glowIntensity: 0.4,
              )
            : NeumorphicDecoration.flat(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 20,
                  ),
                ),
                Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.change,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _AnimatedDashboardBackground extends StatefulWidget {
  const _AnimatedDashboardBackground();

  @override
  State<_AnimatedDashboardBackground> createState() => _AnimatedDashboardBackgroundState();
}

class _AnimatedDashboardBackgroundState extends State<_AnimatedDashboardBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _DashboardBackgroundPainter(_controller.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _DashboardBackgroundPainter extends CustomPainter {
  final double animation;

  _DashboardBackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Subtle gradient orbs
    final orbs = [
      {'x': 0.8, 'y': 0.2, 'r': 200.0, 'color': AppColors.primaryBlue, 'speed': 0.5},
      {'x': 0.2, 'y': 0.7, 'r': 150.0, 'color': AppColors.cardAI, 'speed': 0.7},
      {'x': 0.9, 'y': 0.9, 'r': 180.0, 'color': AppColors.primaryBlueDark, 'speed': 0.3},
    ];

    for (var orb in orbs) {
      final x = size.width * (orb['x'] as double) +
          50 * _sin(animation * (orb['speed'] as double));
      final y = size.height * (orb['y'] as double) +
          30 * _cos(animation * (orb['speed'] as double));

      paint.shader = RadialGradient(
        colors: [
          (orb['color'] as Color).withOpacity(0.08),
          (orb['color'] as Color).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: orb['r'] as double));

      canvas.drawCircle(Offset(x, y), orb['r'] as double, paint);
    }
  }

  double _sin(double value) => 
      (value * 3.14159 * 2).remainder(6.28318) < 3.14159 
          ? (value * 3.14159 * 2).remainder(6.28318) / 3.14159 * 2 - 1 
          : 1 - ((value * 3.14159 * 2).remainder(6.28318) - 3.14159) / 3.14159 * 2;
  
  double _cos(double value) => _sin(value + 0.25);

  @override
  bool shouldRepaint(_DashboardBackgroundPainter oldDelegate) =>
      animation != oldDelegate.animation;
}

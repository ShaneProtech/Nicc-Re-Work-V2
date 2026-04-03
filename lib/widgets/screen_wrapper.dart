import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'animated_background.dart';

class ScreenWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackground;
  final Widget? floatingActionButton;
  final Color? accentColor;

  const ScreenWrapper({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.showBackground = true,
    this.floatingActionButton,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showBackground)
          const AnimatedBackground(showParticles: false, showGrid: true),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(child: child),
            ],
          ),
        ),
        if (floatingActionButton != null)
          Positioned(
            right: 24,
            bottom: 24,
            child: floatingActionButton!,
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (accentColor != null)
                      Container(
                        width: 4,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor!.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                ],
              ],
            ),
          ),
          if (actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                        padding: EdgeInsets.only(
                          left: entry.key > 0 ? 12 : 0,
                        ),
                        child: entry.value,
                      ))
                  .toList(),
            ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class NeumorphicIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;
  final double size;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.tooltip,
    this.size = 44,
  });

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: _isPressed
              ? NeumorphicDecoration.pressed(radius: widget.size / 3)
              : _isHovered && widget.color != null
                  ? NeumorphicDecoration.glowingBorder(
                      glowColor: widget.color!,
                      radius: widget.size / 3,
                      glowIntensity: 0.4,
                    )
                  : NeumorphicDecoration.flat(radius: widget.size / 3),
          child: Icon(
            widget.icon,
            color: _isHovered
                ? widget.color ?? AppColors.textPrimary
                : AppColors.textSecondary,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class NeumorphicSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Color? accentColor;

  const NeumorphicSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.controller,
    this.accentColor,
  });

  @override
  State<NeumorphicSearchBar> createState() => _NeumorphicSearchBarState();
}

class _NeumorphicSearchBarState extends State<NeumorphicSearchBar> {
  bool _isFocused = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: _isFocused && widget.accentColor != null
          ? NeumorphicDecoration.glowingBorder(
              glowColor: widget.accentColor!,
              radius: 14,
              glowIntensity: 0.3,
            )
          : NeumorphicDecoration.concave(radius: 14),
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _isFocused
                  ? widget.accentColor ?? AppColors.primaryBlue
                  : AppColors.textMuted,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    color: AppColors.textMuted,
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicListTile extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accentColor;

  const NeumorphicListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accentColor,
  });

  @override
  State<NeumorphicListTile> createState() => _NeumorphicListTileState();
}

class _NeumorphicListTileState extends State<NeumorphicListTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _isPressed
              ? NeumorphicDecoration.pressed(radius: 14)
              : _isHovered && widget.accentColor != null
                  ? NeumorphicDecoration.glowingBorder(
                      glowColor: widget.accentColor!,
                      radius: 14,
                      glowIntensity: 0.3,
                    )
                  : NeumorphicDecoration.flat(radius: 14, intensity: 0.5),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isHovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
              if (widget.onTap != null && widget.trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: _isHovered
                      ? widget.accentColor ?? AppColors.textSecondary
                      : AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeumorphicDropZone extends StatefulWidget {
  final Widget child;
  final List<String> allowedExtensions;
  final ValueChanged<List<String>> onFilesDropped;
  final Color? accentColor;

  const NeumorphicDropZone({
    super.key,
    required this.child,
    required this.allowedExtensions,
    required this.onFilesDropped,
    this.accentColor,
  });

  @override
  State<NeumorphicDropZone> createState() => _NeumorphicDropZoneState();
}

class _NeumorphicDropZoneState extends State<NeumorphicDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAccept: (data) {
        setState(() => _isDragging = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragging = false),
      onAccept: (_) => setState(() => _isDragging = false),
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: _isDragging
              ? NeumorphicDecoration.glowingBorder(
                  glowColor: widget.accentColor ?? AppColors.primaryBlue,
                  radius: 20,
                  glowIntensity: 0.6,
                )
              : NeumorphicDecoration.concave(radius: 20),
          child: widget.child,
        );
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: NeumorphicDecoration.flat(radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ).animate()
            .fadeIn(duration: 200.ms)
            .scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: NeumorphicDecoration.concave(radius: 24),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? AppColors.textMuted,
              ),
            ).animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!.animate().fadeIn(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

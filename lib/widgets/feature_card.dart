import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.97 : _isHovered ? 1.02 : 1.0),
          decoration: _isPressed
              ? NeumorphicDecoration.pressed(radius: 18)
              : _isHovered
                  ? NeumorphicDecoration.glowingBorder(
                      glowColor: widget.color,
                      radius: 18,
                      glowIntensity: 0.6,
                    )
                  : NeumorphicDecoration.flat(radius: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                if (_isHovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.color.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? widget.color.withOpacity(0.2)
                              : widget.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: _isHovered
                              ? Border.all(
                                  color: widget.color.withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 24,
                          color: widget.color,
                        ),
                      ).animate(target: _isHovered ? 1 : 0)
                          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isHovered
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: _isHovered
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_isHovered)
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: widget.color.withOpacity(0.7),
                        ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? accentColor;
  final EdgeInsets padding;
  final double borderRadius;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = 14,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
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
          padding: widget.padding,
          decoration: _isPressed
              ? NeumorphicDecoration.pressed(radius: widget.borderRadius)
              : _isHovered && widget.accentColor != null
                  ? NeumorphicDecoration.glowingBorder(
                      glowColor: widget.accentColor!,
                      radius: widget.borderRadius,
                      glowIntensity: 0.4,
                    )
                  : NeumorphicDecoration.flat(radius: widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? glowColor;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: glowColor != null
          ? NeumorphicDecoration.glowingBorder(
              glowColor: glowColor!,
              radius: borderRadius,
              glowIntensity: 0.3,
            )
          : NeumorphicDecoration.flat(radius: borderRadius),
      child: child,
    );
  }
}


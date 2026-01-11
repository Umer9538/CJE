import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated vote button widget for initiatives
class InitiativeVoteButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isLoading;
  final bool isDisabled;

  const InitiativeVoteButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSelected = false,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<InitiativeVoteButton> createState() => _InitiativeVoteButtonState();
}

class _InitiativeVoteButtonState extends State<InitiativeVoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InitiativeVoteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when selection changes
    if (widget.isSelected && !oldWidget.isSelected) {
      _playSelectionAnimation();
    }
  }

  void _playSelectionAnimation() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  void _handleTap() {
    if (widget.isDisabled || widget.isLoading) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Play tap animation
    _controller.forward().then((_) {
      _controller.reverse();
    });

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isDisabled ? Colors.grey : widget.color;
    final backgroundColor = widget.isSelected
        ? effectiveColor.withValues(alpha: 0.25)
        : effectiveColor.withValues(alpha: 0.1);
    final borderColor = widget.isSelected
        ? effectiveColor
        : Colors.transparent;

    return GestureDetector(
      onTap: _handleTap,
      onTapDown: (_) {
        if (!widget.isDisabled && !widget.isLoading) {
          _controller.forward();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected
                ? _bounceAnimation.value
                : _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(effectiveColor),
                      ),
                    )
                  else
                    AnimatedScale(
                      scale: widget.isSelected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.isSelected ? _getFilledIcon() : widget.icon,
                        color: effectiveColor,
                        size: 24,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: effectiveColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.isSelected) ...[
                    const SizedBox(height: 2),
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: effectiveColor,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getFilledIcon() {
    // Return filled version of icon when selected
    if (widget.icon == Icons.thumb_up_rounded ||
        widget.icon == Icons.thumb_up_outlined) {
      return Icons.thumb_up;
    } else if (widget.icon == Icons.thumb_down_rounded ||
        widget.icon == Icons.thumb_down_outlined) {
      return Icons.thumb_down;
    } else if (widget.icon == Icons.remove_circle_outline_rounded ||
        widget.icon == Icons.remove_circle_outline) {
      return Icons.remove_circle;
    }
    return widget.icon;
  }
}

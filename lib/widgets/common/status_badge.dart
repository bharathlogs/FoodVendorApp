import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum StatusType { open, closed, preparing, ready, newOrder }

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final bool showIcon;
  final bool large;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            _AnimatedStatusDot(color: _color),
            SizedBox(width: large ? 8 : 6),
          ],
          Text(
            _text,
            style: TextStyle(
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (status) {
      case StatusType.open:
        return AppColors.success;
      case StatusType.closed:
        return AppColors.error;
      case StatusType.preparing:
        return AppColors.primary;
      case StatusType.ready:
        return AppColors.success;
      case StatusType.newOrder:
        return AppColors.info;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case StatusType.open:
        return AppColors.success.withValues(alpha: 0.12);
      case StatusType.closed:
        return AppColors.error.withValues(alpha: 0.12);
      case StatusType.preparing:
        return AppColors.primary.withValues(alpha: 0.12);
      case StatusType.ready:
        return AppColors.success.withValues(alpha: 0.12);
      case StatusType.newOrder:
        return AppColors.info.withValues(alpha: 0.12);
    }
  }

  String get _text {
    switch (status) {
      case StatusType.open:
        return 'Open Now';
      case StatusType.closed:
        return 'Closed';
      case StatusType.preparing:
        return 'Preparing';
      case StatusType.ready:
        return 'Ready';
      case StatusType.newOrder:
        return 'New';
    }
  }
}

class _AnimatedStatusDot extends StatefulWidget {
  final Color color;

  const _AnimatedStatusDot({required this.color});

  @override
  State<_AnimatedStatusDot> createState() => _AnimatedStatusDotState();
}

class _AnimatedStatusDotState extends State<_AnimatedStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.6),
                blurRadius: 6,
                spreadRadius: _animation.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

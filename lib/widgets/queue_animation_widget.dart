import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated queue visualization showing people in line
class QueueAnimationWidget extends StatefulWidget {
  final int peopleCount;
  final int currentPosition;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const QueueAnimationWidget({
    super.key,
    required this.peopleCount,
    required this.currentPosition,
    this.size = 200,
    this.activeColor = const Color(0xFF3B82F6),
    this.inactiveColor = const Color(0xFFE2E8F0),
  });

  @override
  State<QueueAnimationWidget> createState() => _QueueAnimationWidgetState();
}

class _QueueAnimationWidgetState extends State<QueueAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            painter: QueuePainter(
              peopleCount: widget.peopleCount,
              currentPosition: widget.currentPosition,
              animation: _controller.value,
              pulse: _pulseController.value,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
            ),
          );
        },
      ),
    );
  }
}

class QueuePainter extends CustomPainter {
  final int peopleCount;
  final int currentPosition;
  final double animation;
  final double pulse;
  final Color activeColor;
  final Color inactiveColor;

  QueuePainter({
    required this.peopleCount,
    required this.currentPosition,
    required this.animation,
    required this.pulse,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Draw queue line path
    _drawQueuePath(canvas, size, center, radius);

    // Draw people in queue
    _drawPeopleInQueue(canvas, center, radius);

    // Draw current user indicator
    _drawCurrentUserIndicator(canvas, center, radius);
  }

  void _drawQueuePath(Canvas canvas, Size size, Offset center, double radius) {
    final paint = Paint()
      ..color = inactiveColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Create a winding queue path
    final startX = center.dx - radius * 0.8;
    final startY = center.dy + radius * 0.5;

    path.moveTo(startX, startY);

    // Zigzag queue line
    for (int i = 0; i < 3; i++) {
      final y = startY - (i * radius * 0.35);
      path.lineTo(startX + (i.isEven ? 0 : radius * 1.6), y);
      if (i < 2) {
        path.lineTo(startX + (i.isEven ? radius * 1.6 : 0), y - radius * 0.15);
      }
    }

    // Draw dashed line
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashWidth = 8.0;
    final dashSpace = 6.0;
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance)?.position;
        distance += dashWidth;
        final end = metric.getTangentForOffset(distance)?.position;
        if (start != null && end != null) {
          canvas.drawLine(start, end, paint);
        }
        distance += dashSpace;
      }
    }
  }

  void _drawPeopleInQueue(Canvas canvas, Offset center, double radius) {
    final maxPeople = math.min(peopleCount, 8);

    for (int i = 0; i < maxPeople; i++) {
      final progress = i / maxPeople;
      final angle = -math.pi / 2 + (progress * math.pi * 1.5);

      // Calculate position along spiral
      final spiralRadius = radius * (0.4 + progress * 0.4);
      final x = center.dx + spiralRadius * math.cos(angle);
      final y = center.dy + spiralRadius * math.sin(angle);

      final isCurrentUser = i == (maxPeople - currentPosition);
      final isAhead = i < (maxPeople - currentPosition);

      _drawPerson(
        canvas,
        Offset(x, y),
        isCurrentUser,
        isAhead,
        i,
      );
    }
  }

  void _drawPerson(
    Canvas canvas,
    Offset position,
    bool isCurrent,
    bool isAhead,
    int index,
  ) {
    // Animate position slightly
    final animatedY = position.dy + math.sin(animation * math.pi * 2 + index) * 2;
    final animatedPos = Offset(position.dx, animatedY);

    if (isCurrent) {
      // Draw glow for current user
      final glowPaint = Paint()
        ..color = activeColor.withOpacity(0.3 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(animatedPos, 15 + (pulse * 5), glowPaint);
    }

    // Draw person body
    final bodyPaint = Paint()
      ..color = isCurrent ? activeColor : (isAhead ? inactiveColor : activeColor.withOpacity(0.5))
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(animatedPos - const Offset(0, 8), 5, bodyPaint);

    // Body
    final bodyPath = Path();
    bodyPath.moveTo(animatedPos.dx, animatedPos.dy - 3);
    bodyPath.lineTo(animatedPos.dx, animatedPos.dy + 5);
    bodyPath.lineTo(animatedPos.dx - 3, animatedPos.dy + 10);
    bodyPath.moveTo(animatedPos.dx, animatedPos.dy + 5);
    bodyPath.lineTo(animatedPos.dx + 3, animatedPos.dy + 10);

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = bodyPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Arms
    canvas.drawLine(
      animatedPos - const Offset(0, 1),
      animatedPos - const Offset(5, 1),
      Paint()
        ..color = bodyPaint.color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    if (isCurrent) {
      // Draw pulsing ring for current user
      final ringPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(animatedPos, 12 + (pulse * 3), ringPaint);
    }
  }

  void _drawCurrentUserIndicator(Canvas canvas, Offset center, double radius) {
    // Draw "YOU" indicator
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'YOU',
        style: TextStyle(
          color: activeColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position near current user
    final maxPeople = math.min(peopleCount, 8);
    final currentIndex = maxPeople - currentPosition;
    final progress = currentIndex / maxPeople;
    final angle = -math.pi / 2 + (progress * math.pi * 1.5);
    final spiralRadius = radius * (0.4 + progress * 0.4);

    final indicatorX = center.dx + spiralRadius * math.cos(angle) + 15;
    final indicatorY = center.dy + spiralRadius * math.sin(angle) - 20;

    // Draw arrow
    final arrowPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final arrowPath = Path();
    arrowPath.moveTo(indicatorX, indicatorY + 15);
    arrowPath.lineTo(indicatorX, indicatorY + 25);
    arrowPath.moveTo(indicatorX, indicatorY + 25);
    arrowPath.lineTo(indicatorX - 3, indicatorY + 22);
    arrowPath.moveTo(indicatorX, indicatorY + 25);
    arrowPath.lineTo(indicatorX + 3, indicatorY + 22);

    canvas.drawPath(arrowPath, arrowPaint);

    textPainter.paint(
      canvas,
      Offset(indicatorX - textPainter.width / 2, indicatorY - textPainter.height),
    );
  }

  @override
  bool shouldRepaint(QueuePainter oldDelegate) => true;
}

/// Simple animated queue progress indicator
class QueueProgressIndicator extends StatefulWidget {
  final int current;
  final int total;
  final Color color;

  const QueueProgressIndicator({
    super.key,
    required this.current,
    required this.total,
    this.color = const Color(0xFF3B82F6),
  });

  @override
  State<QueueProgressIndicator> createState() => _QueueProgressIndicatorState();
}

class _QueueProgressIndicatorState extends State<QueueProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(QueueProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      _controller.forward(from: 0);
    }
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
          size: const Size(double.infinity, 60),
          painter: QueueProgressPainter(
            current: widget.current,
            total: widget.total,
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class QueueProgressPainter extends CustomPainter {
  final int current;
  final int total;
  final double progress;
  final Color color;

  QueueProgressPainter({
    required this.current,
    required this.total,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final completed = total - current;
    final personWidth = size.width / total;

    for (int i = 0; i < total; i++) {
      final x = i * personWidth + personWidth / 2;
      final isCompleted = i < completed;
      final isCurrent = i == completed;

      final personColor = isCompleted
          ? color
          : isCurrent
              ? color
              : color.withOpacity(0.2);

      final scale = isCurrent ? (1.0 + progress * 0.2) : 1.0;

      _drawSimplePerson(
        canvas,
        Offset(x, size.height / 2),
        personColor,
        scale,
        isCurrent,
      );
    }
  }

  void _drawSimplePerson(
    Canvas canvas,
    Offset position,
    Color color,
    double scale,
    bool isCurrent,
  ) {
    final paint = Paint()..color = color;

    // Draw circle for head
    canvas.drawCircle(
      position - Offset(0, 10 * scale),
      4 * scale,
      paint,
    );

    // Draw line for body
    canvas.drawLine(
      position - Offset(0, 6 * scale),
      position + Offset(0, 6 * scale),
      Paint()
        ..color = color
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round,
    );

    if (isCurrent) {
      // Draw checkmark
      final checkPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final checkPath = Path();
      checkPath.moveTo(position.dx - 5, position.dy - 18);
      checkPath.lineTo(position.dx - 2, position.dy - 15);
      checkPath.lineTo(position.dx + 5, position.dy - 22);

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(QueueProgressPainter oldDelegate) => true;
}

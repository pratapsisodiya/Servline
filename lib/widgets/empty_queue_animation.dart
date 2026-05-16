import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated illustration for empty queue state
class EmptyQueueAnimation extends StatefulWidget {
  final double size;
  final String message;

  const EmptyQueueAnimation({
    super.key,
    this.size = 200,
    this.message = 'No queue yet',
  });

  @override
  State<EmptyQueueAnimation> createState() => _EmptyQueueAnimationState();
}

class _EmptyQueueAnimationState extends State<EmptyQueueAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _floatController]),
            builder: (context, child) {
              return CustomPaint(
                painter: EmptyQueuePainter(
                  animation: _controller.value,
                  float: _floatController.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class EmptyQueuePainter extends CustomPainter {
  final double animation;
  final double float;

  EmptyQueuePainter({required this.animation, required this.float});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw empty queue posts
    _drawQueuePosts(canvas, size, center);

    // Draw floating person waiting
    _drawFloatingPerson(canvas, center);

    // Draw particles
    _drawParticles(canvas, size, center);
  }

  void _drawQueuePosts(Canvas canvas, Size size, Offset center) {
    final postPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final ropePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Left post
    final leftPostX = center.dx - size.width * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftPostX - 5, center.dy, 10, size.height * 0.3),
        const Radius.circular(5),
      ),
      postPaint,
    );

    // Right post
    final rightPostX = center.dx + size.width * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightPostX - 5, center.dy, 10, size.height * 0.3),
        const Radius.circular(5),
      ),
      postPaint,
    );

    // Rope between posts (wavy)
    final ropePath = Path();
    ropePath.moveTo(leftPostX, center.dy + 20);

    for (double i = 0; i <= 1; i += 0.1) {
      final x = leftPostX + (rightPostX - leftPostX) * i;
      final y = center.dy + 20 + math.sin(i * math.pi * 2 + animation * math.pi * 2) * 5;
      ropePath.lineTo(x, y);
    }

    canvas.drawPath(ropePath, ropePaint);
  }

  void _drawFloatingPerson(Canvas canvas, Offset center) {
    final floatOffset = float * 10 - 5;
    final personCenter = Offset(center.dx, center.dy - 20 + floatOffset);

    final personPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(personCenter - const Offset(0, 15), 8, personPaint);

    // Body
    final bodyPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      personCenter - const Offset(0, 7),
      personCenter + const Offset(0, 10),
      bodyPaint,
    );

    // Arms (waving)
    final armAngle = math.sin(animation * math.pi * 2) * 0.3;
    canvas.drawLine(
      personCenter - const Offset(0, 3),
      personCenter - Offset(10 * math.cos(armAngle), 3 + 10 * math.sin(armAngle)),
      bodyPaint,
    );

    canvas.drawLine(
      personCenter - const Offset(0, 3),
      personCenter + const Offset(10, -3),
      bodyPaint,
    );

    // Legs
    canvas.drawLine(
      personCenter + const Offset(0, 10),
      personCenter + const Offset(-5, 20),
      bodyPaint,
    );

    canvas.drawLine(
      personCenter + const Offset(0, 10),
      personCenter + const Offset(5, 20),
      bodyPaint,
    );

    // Thought bubble
    _drawThoughtBubble(canvas, personCenter - const Offset(20, 30));
  }

  void _drawThoughtBubble(Canvas canvas, Offset position) {
    final bubblePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Main bubble
    canvas.drawCircle(position, 20, bubblePaint);
    canvas.drawCircle(position, 20, borderPaint);

    // Small bubbles
    canvas.drawCircle(position + const Offset(15, 15), 5, bubblePaint);
    canvas.drawCircle(position + const Offset(15, 15), 5, borderPaint);

    canvas.drawCircle(position + const Offset(20, 20), 3, bubblePaint);
    canvas.drawCircle(position + const Offset(20, 20), 3, borderPaint);

    // Question mark in bubble
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawParticles(Canvas canvas, Size size, Offset center) {
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (animation + i / 5) * math.pi * 2;
      final radius = 80 + math.sin(animation * math.pi * 2 + i) * 10;

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final opacity = (math.sin(animation * math.pi * 2 + i) + 1) / 2;

      particlePaint.color = const Color(0xFF3B82F6).withOpacity(opacity * 0.3);

      canvas.drawCircle(Offset(x, y), 3, particlePaint);
    }
  }

  @override
  bool shouldRepaint(EmptyQueuePainter oldDelegate) => true;
}

/// Animated checkmark for completed queue
class QueueCompletedAnimation extends StatefulWidget {
  final double size;

  const QueueCompletedAnimation({super.key, this.size = 120});

  @override
  State<QueueCompletedAnimation> createState() =>
      _QueueCompletedAnimationState();
}

class _QueueCompletedAnimationState extends State<QueueCompletedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;
  late Animation<double> _circleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: CompletedCheckPainter(
              circleProgress: _circleAnimation.value,
              checkProgress: _checkAnimation.value,
            ),
          );
        },
      ),
    );
  }
}

class CompletedCheckPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;

  CompletedCheckPainter({
    required this.circleProgress,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle
    final circlePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      math.pi * 2 * circleProgress,
      false,
      circlePaint,
    );

    // Draw checkmark
    final checkPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final checkPath = Path();
    checkPath.moveTo(center.dx - radius * 0.4, center.dy);

    if (checkProgress > 0) {
      final firstPartProgress = math.min(checkProgress * 2, 1.0);
      checkPath.lineTo(
        center.dx - radius * 0.4 + (radius * 0.25 * firstPartProgress),
        center.dy + (radius * 0.25 * firstPartProgress),
      );

      if (checkProgress > 0.5) {
        final secondPartProgress = (checkProgress - 0.5) * 2;
        checkPath.lineTo(
          center.dx - radius * 0.15 + (radius * 0.55 * secondPartProgress),
          center.dy + radius * 0.25 - (radius * 0.6 * secondPartProgress),
        );
      }
    }

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(CompletedCheckPainter oldDelegate) => true;
}

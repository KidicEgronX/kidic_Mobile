import 'package:flutter/material.dart';
import 'dart:math' as math;

class RunningAnimation extends StatefulWidget {
  const RunningAnimation({super.key});

  @override
  State<RunningAnimation> createState() => _RunningAnimationState();
}

class _RunningAnimationState extends State<RunningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _runningController;
  late Animation<Offset> _childAnimation;
  late Animation<Offset> _parentAnimation;
  late Animation<double> _legAnimation;

  @override
  void initState() {
    super.initState();

    // Create main animation controller with 10 seconds duration for full screen traversal
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Create running animation controller for leg movement
    _runningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Child runs faster and ahead
    _childAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0), // Start from right edge of screen
      end: const Offset(-1.5, 0), // End at left edge of screen
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Parent follows behind, chasing the child
    _parentAnimation = Tween<Offset>(
      begin: const Offset(2.2, 0), // Start further right but visible
      end: const Offset(-1.0, 0), // End at left but doesn't catch up
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Leg animation for running effect
    _legAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_runningController);

    // Start the animation
    _playAnimationWithInterval();
  }

  void _playAnimationWithInterval() {
    // Start the running leg animation
    _runningController.repeat();

    // Play the main animation
    _controller.forward().then((_) {
      // Stop the running animation
      _runningController.stop();

      // Reset the animation
      _controller.reset();

      // Wait for the remaining time to complete 35 seconds
      Future.delayed(const Duration(seconds: 25), () {
        // If widget is still mounted, play again
        if (mounted) {
          _playAnimationWithInterval();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _runningController.dispose();
    super.dispose();
  }

  Widget _buildRunningChild() {
    return AnimatedBuilder(
      animation: _legAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Head with 3D effect
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDBB5), // Skin color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Text('�', style: TextStyle(fontSize: 10)),
              ),
            ),
            const SizedBox(height: 1),
            // Arms with running motion
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: math.sin(_legAnimation.value + math.pi) * 0.4,
                  child: Container(
                    width: 2,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDBB5),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Transform.rotate(
                  angle: -math.sin(_legAnimation.value + math.pi) * 0.4,
                  child: Container(
                    width: 2,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDBB5),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Body with 3D effect
            Container(
              width: 14,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.shade300, Colors.red.shade500],
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Legs with running animation and 3D effect
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left leg
                Transform.rotate(
                  angle: math.sin(_legAnimation.value) * 0.5,
                  child: Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Right leg
                Transform.rotate(
                  angle: -math.sin(_legAnimation.value) * 0.5,
                  child: Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRunningParent() {
    return AnimatedBuilder(
      animation: _legAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Head with 3D effect
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDBB5), // Skin color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Text('👩', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 1),
            // Arms with running motion and 3D effect
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: math.sin(_legAnimation.value + math.pi) * 0.4,
                  child: Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDBB5),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Transform.rotate(
                  angle: -math.sin(_legAnimation.value + math.pi) * 0.4,
                  child: Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDBB5),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Body with 3D effect and gradient
            Container(
              width: 18,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.teal.shade300, Colors.teal.shade500],
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Legs with running animation and 3D effect
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left leg
                Transform.rotate(
                  angle: math.sin(_legAnimation.value) * 0.6,
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade400,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.brown.shade300, Colors.brown.shade500],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                // Right leg
                Transform.rotate(
                  angle: -math.sin(_legAnimation.value) * 0.6,
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade400,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 1,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.brown.shade300, Colors.brown.shade500],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Increased height for larger 3D characters
      clipBehavior: Clip.none, // Allow characters to go beyond bounds
      child: Stack(
        clipBehavior: Clip.none, // Allow overflow for smooth animation
        children: [
          // Child character
          SlideTransition(
            position: _childAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildRunningChild(),
            ),
          ),

          // Parent character chasing
          SlideTransition(
            position: _parentAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _buildRunningParent(),
            ),
          ),
        ],
      ),
    );
  }
}

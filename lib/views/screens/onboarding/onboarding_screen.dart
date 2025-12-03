import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../routes/route_names.dart';

/// Onboarding/Welcome Screen
/// Shows CJE branding with Continue button
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          // Decorative curved line
          Positioned(
            top: size.height * 0.15,
            left: -50,
            right: -50,
            child: CustomPaint(
              size: Size(size.width + 100, 200),
              painter: _CurvedLinePainter(),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingXL),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gold,
                          AppColors.gold.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'CJE',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing32),

                  // Title
                  const Text(
                    'CJE Platform',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing12),

                  // Subtitle
                  Text(
                    'Empowering Student Councils',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go(RouteNames.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the decorative curved line
class _CurvedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    // Create a smooth S-curve
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

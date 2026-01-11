import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../routes/route_names.dart';
import '../main/main_shell.dart';
import 'widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundDecorations(size),
          _buildMainContent(user),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.15),
                  AppColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.3,
          left: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.navy.withValues(alpha: 0.08),
                  AppColors.navy.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(dynamic user) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              HomeHeader(user: user),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: HomeWelcomeCard(user: user)),
                    const SliverToBoxAdapter(child: HomeQuickStats()),
                    SliverToBoxAdapter(
                      child: HomeSectionTitle(
                        title: AppLocalizations.of(context).translate('upcoming_events'),
                        icon: Icons.calendar_month_rounded,
                        onSeeAll: () {
                          ref.read(navigationIndexProvider.notifier).state = 3; // Meetings tab
                          context.go(RouteNames.meetings);
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: HomeUpcomingEvents()),
                    SliverToBoxAdapter(
                      child: HomeSectionTitle(
                        title: AppLocalizations.of(context).translate('recent_activity'),
                        icon: Icons.bolt_rounded,
                        onSeeAll: () {
                          ref.read(navigationIndexProvider.notifier).state = 1; // Announcements tab
                          context.go(RouteNames.announcements);
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: HomeActivityFeed()),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

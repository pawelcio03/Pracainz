import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/app/app_dependencies.dart';
import '../../dashboard/dashboard_screen.dart';
import '../application/auth_session_controller.dart';
import 'auth_loading_screen.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.dependencies,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final AppDependencies dependencies;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late AuthSessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = AuthSessionController(
      authRepository: widget.dependencies.authRepository,
    );
  }

  @override
  void didUpdateWidget(covariant AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependencies.authRepository ==
        widget.dependencies.authRepository) {
      return;
    }

    _sessionController.dispose();
    _sessionController = AuthSessionController(
      authRepository: widget.dependencies.authRepository,
    );
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sessionController,
      builder: (context, _) {
        if (_sessionController.isLoading) {
          return const AuthLoadingScreen(
            title: 'Przywracanie sesji',
            description:
                'Sprawdzanie aktywnego logowania i przygotowanie panelu uzytkownika.',
          );
        }

        final user = _sessionController.user;
        if (user == null) {
          return AuthScreen(authRepository: widget.dependencies.authRepository);
        }

        return DashboardScreen(
          userId: user.uid,
          authRepository: widget.dependencies.authRepository,
          userName: _userName(user),
          userEmail: user.email,
          userPhotoUrl: user.photoURL,
          onSignOut: _sessionController.signOut,
          budgetRepository: widget.dependencies.budgetRepository,
          categoryRepository: widget.dependencies.categoryRepository,
          exportShareGateway: widget.dependencies.exportShareGateway,
          goalContributionPlanRepository:
              widget.dependencies.goalContributionPlanRepository,
          goalRepository: widget.dependencies.goalRepository,
          investmentRepository: widget.dependencies.investmentRepository,
          investmentQuoteService: widget.dependencies.investmentQuoteService,
          monthlyReportRepository: widget.dependencies.monthlyReportRepository,
          dailyPortfolioSnapshotRepository:
              widget.dependencies.portfolioSnapshotRepository,
          reportArchiveRepository: widget.dependencies.reportArchiveRepository,
          recurringIncomeRepository:
              widget.dependencies.recurringIncomeRepository,
          subscriptionRepository: widget.dependencies.subscriptionRepository,
          importCategoryRuleRepository:
              widget.dependencies.importCategoryRuleRepository,
          transactionImportHistoryRepository:
              widget.dependencies.transactionImportHistoryRepository,
          themePreferencesRepository:
              widget.dependencies.themePreferencesRepository,
          transactionRepository: widget.dependencies.transactionRepository,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          userProfileRepository: widget.dependencies.userProfileRepository,
        );
      },
    );
  }

  String _userName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Uzytkownik';
  }
}

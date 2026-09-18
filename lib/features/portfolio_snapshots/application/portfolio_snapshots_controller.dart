import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/finance_models.dart';
import '../domain/portfolio_snapshot_repository.dart';

class PortfolioSnapshotsController extends ChangeNotifier {
  PortfolioSnapshotsController({
    required this.repository,
    required this.userId,
  }) {
    _subscription = repository
        .watchSnapshots(userId)
        .listen(
          (snapshots) {
            _snapshots = snapshots;
            _error = null;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  final PortfolioSnapshotRepository repository;
  final String userId;
  late final StreamSubscription<List<PortfolioDailySnapshot>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<PortfolioDailySnapshot> _snapshots = const [];

  bool get isLoading => _isLoading;

  Object? get error => _error;

  List<PortfolioDailySnapshot> get snapshots => _snapshots;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

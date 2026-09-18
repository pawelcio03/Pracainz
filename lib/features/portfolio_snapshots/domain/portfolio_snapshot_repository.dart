import '../../../models/finance_models.dart';

abstract class PortfolioSnapshotRepository {
  const PortfolioSnapshotRepository();

  Stream<List<PortfolioDailySnapshot>> watchSnapshots(String userId);
}

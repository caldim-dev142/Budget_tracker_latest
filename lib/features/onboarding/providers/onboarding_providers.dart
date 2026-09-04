import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/database.dart';
import '../../auth/providers/auth_providers.dart';

final onboardingStateProvider = StateProvider<int>((ref) => 0); // tracks current step 0-3

class OnboardingData {
  double salary = 0.0;
  int salaryDay = 1;
  List<String> mandatoryCategoryIds = [];
  double emergencyFundTarget = 0.0;
  double savingsGoalTarget = 0.0;
  String savingsGoalName = '';
}

final onboardingDataProvider = StateProvider<OnboardingData>((ref) => OnboardingData());

final completeOnboardingProvider = FutureProvider.autoDispose<void>((ref) async {
  final db = ref.read(appDatabaseProvider);
  final authState = ref.read(authStateProvider).valueOrNull;
  if (authState == null || authState.householdId == null) return;
  final householdId = authState.householdId!;

  final data = ref.read(onboardingDataProvider);
  
  // Save protection goal (emergency fund)
  if (data.emergencyFundTarget > 0) {
    await db.into(db.sinkingFundsTable).insert(SinkingFundsTableCompanion.insert(
      id: 'fund-ef-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Emergency Fund',
      householdId: householdId,
      openingReservePaise: Value((data.emergencyFundTarget * 100).toInt()),
    ));
  }

  // Save savings goal
  if (data.savingsGoalTarget > 0 && data.savingsGoalName.isNotEmpty) {
    await db.into(db.savingGoalsTable).insert(SavingGoalsTableCompanion.insert(
      id: 'goal-sav-${DateTime.now().millisecondsSinceEpoch}',
      name: data.savingsGoalName,
      householdId: householdId,
      bucket: 'other_goals',
      targetPaise: Value((data.savingsGoalTarget * 100).toInt()),
    ));
  }
  
  // Finish
  await ref.read(authStateNotifierProvider.notifier).completeOnboarding();
});

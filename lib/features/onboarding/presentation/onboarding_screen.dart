import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_providers.dart';
import '../../auth/providers/auth_providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(onboardingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Budget Tracker'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (step + 1) / 4),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(step, context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step, BuildContext context, WidgetRef ref) {
    switch (step) {
      case 0:
        return _buildStep1Salary(ref);
      case 1:
        return _buildStep2Mandatory(ref);
      case 2:
        return _buildStep3Protection(ref);
      case 3:
        return _buildStep4Savings(ref);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Salary(WidgetRef ref) {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Step 1: Your Income', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('What is your expected monthly salary?', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Salary',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              final data = ref.read(onboardingDataProvider.notifier).state;
              data.salary = double.tryParse(val) ?? 0;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => ref.read(onboardingStateProvider.notifier).state++,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Mandatory(WidgetRef ref) {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Step 2: Mandatory Expenses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Think about your fixed costs (Rent, Groceries, Utilities).', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          // Simplified for MVP - usually would list categories to select
          const Text('We will pre-populate categories for you based on typical household expenses.', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => ref.read(onboardingStateProvider.notifier).state++,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Protection(WidgetRef ref) {
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Step 3: Protection Goal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Let\'s set an Emergency Fund Target (Recommended: 3x monthly expenses).', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Emergency Fund Target',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              final data = ref.read(onboardingDataProvider.notifier).state;
              data.emergencyFundTarget = double.tryParse(val) ?? 0;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => ref.read(onboardingStateProvider.notifier).state++,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Savings(WidgetRef ref) {
    return Padding(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Step 4: Savings Goal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('What is one major savings goal you are working towards?', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Goal Name (e.g. Vacation, Laptop)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              final data = ref.read(onboardingDataProvider.notifier).state;
              data.savingsGoalName = val;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              final data = ref.read(onboardingDataProvider.notifier).state;
              data.savingsGoalTarget = double.tryParse(val) ?? 0;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              // Complete Onboarding
              await ref.read(completeOnboardingProvider.future);
            },
            child: const Text('Finish Setup'),
          ),
        ],
      ),
    );
  }
}

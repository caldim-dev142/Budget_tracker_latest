import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/input_formatters.dart';
import '../providers/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
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
                child: _buildStep(step, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step, BuildContext context) {
    switch (step) {
      case 0:
        return _buildStep1Salary(context);
      case 1:
        return _buildStep2Mandatory(context);
      case 2:
        return _buildStep3Protection(context);
      case 3:
        return _buildStep4Savings(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Salary(BuildContext context) {
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AppInputFormatters.positiveDecimal()],
            decoration: const InputDecoration(
              labelText: 'Monthly Salary *',
              hintText: 'e.g. 50000',
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
            onPressed: () {
              final data = ref.read(onboardingDataProvider);
              if (data.salary <= 0) {
                AppFeedback.showWarning(context, 'Please enter a monthly salary greater than ₹0.');
                return;
              }
              ref.read(onboardingStateProvider.notifier).state++;
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Mandatory(BuildContext context) {
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

  Widget _buildStep3Protection(BuildContext context) {
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AppInputFormatters.positiveDecimal()],
            decoration: const InputDecoration(
              labelText: 'Emergency Fund Target *',
              hintText: 'e.g. 100000',
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
            onPressed: () {
              final data = ref.read(onboardingDataProvider);
              if (data.emergencyFundTarget <= 0) {
                AppFeedback.showWarning(context, 'Please enter an emergency fund target greater than ₹0.');
                return;
              }
              ref.read(onboardingStateProvider.notifier).state++;
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Savings(BuildContext context) {
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
              labelText: 'Goal Name (e.g. Vacation, Laptop) *',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              final data = ref.read(onboardingDataProvider.notifier).state;
              data.savingsGoalName = val.trim();
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AppInputFormatters.positiveDecimal()],
            decoration: const InputDecoration(
              labelText: 'Target Amount *',
              hintText: 'e.g. 50000',
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
            onPressed: _isSubmitting
                ? null
                : () async {
                    final data = ref.read(onboardingDataProvider);
                    if (data.savingsGoalName.trim().isEmpty) {
                      AppFeedback.showWarning(context, 'Please enter a name for your savings goal.');
                      return;
                    }
                    if (data.savingsGoalTarget <= 0) {
                      AppFeedback.showWarning(context, 'Please enter a target amount greater than ₹0.');
                      return;
                    }

                    setState(() => _isSubmitting = true);
                    try {
                      await ref.read(completeOnboardingProvider.future);
                      if (context.mounted) {
                        AppFeedback.showSuccess(context, 'Setup complete! Welcome to your budget.');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppFeedback.showError(context, 'Failed to complete setup', error: e);
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Finish Setup'),
          ),
        ],
      ),
    );
  }
}

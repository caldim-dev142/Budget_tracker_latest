import 'package:flutter/material.dart';

/// Legal and Compliance URLs for Google Play Store compliance (Phase 5).
/// 
/// IMPORTANT: Replace the placeholder URLs below with your live, public URLs
/// prior to submitting the application to the Google Play Console.
class LegalConstants {
  LegalConstants._();

  /// URL to the publicly hosted Privacy Policy.
  /// Example: https://yourdomain.com/privacy-policy
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://calbudget.app/privacy-policy',
  );

  /// URL to the publicly hosted Terms of Service.
  /// Example: https://yourdomain.com/terms-of-service
  static const String termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
    defaultValue: 'https://calbudget.app/terms-of-service',
  );

  /// URL for external web-based account deletion request (Google Play requirement).
  /// Example: https://yourdomain.com/delete-account
  static const String accountDeletionUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
    defaultValue: 'https://calbudget.app/delete-account',
  );

  /// Support email for user contact & compliance inquiries.
  static const String supportEmail = 'support@calbudget.app';

  /// Shows the Privacy Policy summary dialog in-app.
  static void showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Color(0xFF0E7C7B)),
            SizedBox(width: 10),
            Text('Privacy Policy'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CalBudget Privacy & Data Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 10),
              Text(
                '• Your financial data is stored locally on your device with offline-first encryption.\n\n'
                '• When online synchronization is active, data is transferred securely over encrypted HTTPS connections to our cloud database.\n\n'
                '• We do not sell, rent, or share your personal financial transactions or personal identity with third-party advertisers.\n\n'
                '• You can permanently delete your account and all associated cloud data at any time from Settings → Delete Account.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 14),
              Text(
                'Full Policy & Web Deletion:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SelectableText(
                privacyPolicyUrl,
                style: TextStyle(color: Color(0xFF0E7C7B), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows the Terms of Service dialog in-app.
  static void showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: Color(0xFF0E7C7B)),
            SizedBox(width: 10),
            Text('Terms of Service'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CalBudget Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 10),
              Text(
                '• CalBudget is a personal budgeting and financial planning tool provided for informational purposes.\n\n'
                '• CalBudget does not provide certified financial, tax, or investment advice.\n\n'
                '• You are responsible for maintaining the security of your device credentials, PIN, and biometric access.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 14),
              Text(
                'Full Terms Document:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SelectableText(
                termsOfServiceUrl,
                style: TextStyle(color: Color(0xFF0E7C7B), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

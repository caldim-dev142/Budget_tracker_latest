# Privacy Policy — BudgetIQ

**Last updated:** [DATE OF PUBLICATION]

This Privacy Policy explains how BudgetIQ ("the App", "we", "us") collects, uses, and protects your information. BudgetIQ is a personal/family budgeting app developed by Caldim Engineering.

## 1. Information We Collect

**Account information.** When you sign in, we collect your name and email address via Firebase Authentication (Google/email sign-in). We do not receive or store your password — authentication is handled entirely by Firebase.

**Financial data you enter.** BudgetIQ stores the financial information you choose to enter: income, expenses, budgets, savings goals, protection/insurance entries, account and card labels, and any notes you add to a transaction. This data is used solely to power the budgeting features of the app.

**Device and diagnostic data.** We use Firebase Crashlytics to automatically collect crash reports and basic diagnostic information (device model, OS version, app version) when the app crashes or encounters an error. This helps us find and fix bugs. Crash reports do not include your financial data.

**Local storage.** A copy of your data is stored locally on your device in an encrypted database (SQLCipher) so the app works offline. This local copy syncs with our servers when you're connected to the internet.

## 2. How We Use Your Information

We use the information above only to:
- Provide and operate the budgeting features of the App
- Sync your data across your devices
- Diagnose and fix technical problems
- Respond to support requests you send us

We do not use your financial data for advertising, and we do not sell your data to anyone.

## 3. How We Store and Protect Your Information

- Your account and financial data are stored in a managed PostgreSQL database (hosted via Supabase).
- Data in transit between the app and our servers is encrypted (HTTPS/TLS).
- Your local on-device copy of the data is encrypted at rest.
- Access to production data is restricted to the developer for the purpose of maintaining the service.

## 4. Third-Party Services

BudgetIQ uses the following third-party services to operate:

| Service | Purpose | Data involved |
|---|---|---|
| Firebase Authentication (Google) | Sign-in | Name, email |
| Firebase Crashlytics (Google) | Crash reporting | Device/app diagnostic info |
| Supabase (PostgreSQL hosting) | Database storage | Your account and financial data |

We do not share your data with advertisers, data brokers, or any other third party beyond what is needed to operate the services above.

## 5. Data Retention and Deletion

Your data is retained for as long as your account is active. You can request deletion of your account and all associated data at any time by contacting us at **[SUPPORT EMAIL]**. We will delete your data within a reasonable timeframe after verifying your request.

## 6. Your Rights

Depending on your location, you may have rights to access, correct, export, or delete your personal data. To exercise any of these rights, contact us at **[SUPPORT EMAIL]**.

## 7. Children's Privacy

BudgetIQ is not directed at children under 13 (or the relevant minimum age in your jurisdiction), and we do not knowingly collect data from children.

## 8. Changes to This Policy

We may update this Privacy Policy from time to time. If we make material changes, we will update the "Last updated" date above. Continued use of the App after changes constitutes acceptance of the updated policy.

## 9. Contact Us

If you have questions about this Privacy Policy or your data, contact us at:

**[SUPPORT EMAIL]**

---
*This policy is a starting draft based on BudgetIQ's current architecture (Firebase Auth, Firebase Crashlytics, Supabase/PostgreSQL) and does not constitute legal advice. Review it (or have it reviewed) before publishing, especially if you plan to operate in jurisdictions with specific requirements (e.g. GDPR in the EU, India's DPDP Act).*

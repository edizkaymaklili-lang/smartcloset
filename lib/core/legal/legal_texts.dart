/// All legal document texts for Smart Closet.
/// Effective date: February 2026
class LegalTexts {
  LegalTexts._();

  static const String appName = 'Smart Closet';
  static const String companyEmail = 'legal@stilasist.app';
  static const String effectiveDate = 'February 14, 2026';

  // ─────────────────────────────────────────────
  // PRIVACY POLICY
  // ─────────────────────────────────────────────
  static const String privacyPolicyTitle = 'Privacy Policy';

  static const String privacyPolicy = '''
Effective Date: $effectiveDate

$appName ("we", "our", or "the app") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your personal data when you use our services.

1. DATA CONTROLLER
$appName is the data controller responsible for your personal data. For any inquiries, contact us at $companyEmail.

2. DATA WE COLLECT
We collect the following personal data when you use the app:

• Account Data: Email address, display name, and password (stored securely via Firebase Authentication).
• Profile Data: City of residence, style preferences, body type, and personalization attributes you provide.
• Wardrobe Data: Photos and descriptions of clothing items you upload.
• Location Data: GPS coordinates or city name, collected only when you grant permission, used for weather-based recommendations and the Style Feed map.
• Usage Data: App interactions, feature usage, and error logs collected via Firebase Analytics and Crashlytics.
• Content Data: Photos, captions, and tags you share on the Style Feed.

3. HOW WE USE YOUR DATA
We use your personal data to:
• Provide personalized outfit and style recommendations.
• Display weather-appropriate clothing suggestions based on your location.
• Enable the Style Feed social features.
• Maintain and improve the app's functionality and performance.
• Send optional push notifications about daily recommendations (if enabled).
• Detect and resolve technical errors.

4. LEGAL BASIS FOR PROCESSING
We process your data on the following legal bases:
• Performance of a contract: To provide the core app services you signed up for.
• Legitimate interests: To improve the app and ensure its security.
• Consent: For optional features such as location access, push notifications, and background removal.

5. DATA SHARING
We do not sell your personal data. We share data only with:
• Firebase / Google LLC: For authentication, cloud storage, analytics, and crash reporting. Data may be transferred to Google's servers in the United States and other countries. Google is certified under the EU-U.S. Data Privacy Framework.
• Remove.bg (if API key provided): Your wardrobe photos may be sent to remove.bg for background removal processing. This is optional and requires your explicit action.

6. DATA RETENTION
• Account and profile data: Retained as long as your account is active.
• Wardrobe photos: Stored until you delete them or your account.
• Analytics data: Retained for up to 14 months per Google's standard policy.
• You may request deletion of your data at any time (see Section 8).

7. DATA SECURITY
We implement industry-standard security measures including encrypted transmission (HTTPS/TLS), Firebase's built-in security rules, and secure authentication. No system is 100% secure; use a strong password and keep it confidential.

8. YOUR RIGHTS
Depending on your location, you may have the right to:
• Access the personal data we hold about you.
• Correct inaccurate or incomplete data.
• Request deletion of your personal data ("right to be forgotten").
• Restrict or object to certain processing activities.
• Data portability — receive your data in a machine-readable format.
• Withdraw consent at any time (without affecting prior processing).

To exercise these rights, contact us at $companyEmail.

9. CHILDREN'S PRIVACY
$appName is not intended for users under the age of 13. We do not knowingly collect personal data from children. If you believe a child has provided us with personal data, please contact us immediately.

10. COOKIES AND LOCAL STORAGE
The web version of $appName uses browser localStorage to store your preferences (dark mode, settings). This is strictly necessary for the app to function and does not require consent. We do not use tracking cookies for advertising purposes.

11. INTERNATIONAL TRANSFERS
Your data may be transferred to and stored in countries outside your own, including the United States, where Google's infrastructure is located. These transfers are protected by appropriate safeguards.

12. CHANGES TO THIS POLICY
We may update this Privacy Policy from time to time. We will notify you of significant changes within the app. Continued use of the app after changes constitutes acceptance of the updated policy.

13. CONTACT
For privacy-related inquiries or to exercise your rights:
Email: $companyEmail
''';

  // ─────────────────────────────────────────────
  // TERMS OF SERVICE
  // ─────────────────────────────────────────────
  static const String termsOfServiceTitle = 'Terms of Service';

  static const String termsOfService = '''
Effective Date: $effectiveDate

Please read these Terms of Service ("Terms") carefully before using $appName. By creating an account or using the app, you agree to be bound by these Terms.

1. ACCEPTANCE OF TERMS
By accessing or using $appName, you confirm that you are at least 13 years of age and agree to these Terms. If you do not agree, you must not use the app.

2. YOUR ACCOUNT
• You are responsible for maintaining the confidentiality of your account credentials.
• You must provide accurate and current information during registration.
• You are responsible for all activity that occurs under your account.
• Notify us immediately at $companyEmail if you suspect unauthorized access to your account.

3. ACCEPTABLE USE
You agree not to:
• Use the app for any unlawful purpose or in violation of any local, national, or international regulations.
• Upload content that is defamatory, obscene, hateful, or infringes the intellectual property rights of others.
• Attempt to gain unauthorized access to the app's systems or other users' accounts.
• Scrape, copy, or redistribute content from the Style Feed without permission.
• Use automated tools or bots to interact with the app.
• Impersonate another person or entity.

4. USER-GENERATED CONTENT (STYLE FEED)
• You retain ownership of the photos and content you post on the Style Feed.
• By posting content, you grant $appName a non-exclusive, royalty-free, worldwide license to display and distribute your content within the app.
• You are solely responsible for the content you post. Do not post images of other people without their consent.
• We reserve the right to remove any content that violates these Terms.

5. INTELLECTUAL PROPERTY
All app content, design, logos, and software (excluding user-generated content) are the intellectual property of $appName. You may not copy, modify, distribute, or create derivative works without our prior written consent.

6. DISCLAIMER OF WARRANTIES
$appName is provided "as is" and "as available" without any warranties of any kind, express or implied. We do not guarantee that the app will be uninterrupted, error-free, or that recommendations will suit your specific needs. Style recommendations are for informational purposes only.

7. LIMITATION OF LIABILITY
To the fullest extent permitted by applicable law, $appName shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the app, including but not limited to loss of data or profits.

8. THIRD-PARTY SERVICES
The app integrates with third-party services (Firebase, Google, OpenStreetMap, remove.bg). Use of these services is subject to their respective terms and privacy policies. We are not responsible for the practices of third-party services.

9. TERMINATION
We reserve the right to suspend or terminate your account at any time, without notice, if you violate these Terms. You may delete your account at any time through the app settings.

10. CHANGES TO TERMS
We may modify these Terms at any time. Material changes will be communicated within the app. Your continued use after changes constitutes acceptance of the new Terms.

11. GOVERNING LAW
These Terms are governed by and construed in accordance with the laws of the Republic of Turkey, without regard to conflict of law principles.

12. CONTACT
For questions regarding these Terms:
Email: $companyEmail
''';

  // ─────────────────────────────────────────────
  // DATA PROCESSING NOTICE (KVKK / GDPR)
  // ─────────────────────────────────────────────
  static const String dataProcessingTitle = 'Data Processing Notice';

  static const String dataProcessingNotice = '''
Effective Date: $effectiveDate

This Data Processing Notice is provided in accordance with the Turkish Personal Data Protection Law No. 6698 (KVKK) and the EU General Data Protection Regulation (GDPR).

DATA CONTROLLER
$appName
Contact: $companyEmail

CATEGORIES OF PERSONAL DATA PROCESSED
• Identity Data: Name, email address.
• Location Data: City, GPS coordinates (with permission).
• Preference Data: Style preferences, body attributes, hobbies, work type.
• Visual Data: Clothing photos you upload and Style Feed posts.
• Technical Data: Device info, IP address, app usage logs.

PURPOSES AND LEGAL BASIS OF PROCESSING

Purpose | Legal Basis
─────────────────────────────────────────────
User authentication and account management | Contract performance
Personalized style and outfit recommendations | Contract performance
Weather-based clothing suggestions | Legitimate interest / Consent (location)
Style Feed social features | Contract performance
App security, error monitoring (Crashlytics) | Legitimate interest
Analytics and performance improvement | Legitimate interest
Push notifications (if enabled) | Consent
Background removal via remove.bg API | Consent (explicit user action)

DATA RECIPIENTS
Your personal data may be shared with the following categories of recipients:
• Google LLC / Firebase — authentication, database, storage, analytics, crash reporting.
• remove.bg — image processing (only when you choose to use this feature).
All recipients are contractually bound to process your data only for specified purposes and to apply appropriate security measures.

INTERNATIONAL DATA TRANSFERS
Your data may be transferred outside Turkey and/or the European Economic Area. Such transfers are made to countries or organisations that provide adequate data protection safeguards.

DATA RETENTION PERIODS
• Account data: Until account deletion + 30 days.
• Wardrobe and Style Feed content: Until deleted by you or account closure.
• Analytics data: Up to 14 months.
• Log data: Up to 90 days.

YOUR RIGHTS UNDER KVKK AND GDPR
You have the right to:
✓ Learn whether your personal data is being processed.
✓ Request information about the processing.
✓ Learn the purpose of processing and whether data is used for intended purposes.
✓ Know the third parties to whom data is transferred.
✓ Request correction of incomplete or incorrect data.
✓ Request deletion or destruction of data (subject to legal obligations).
✓ Object to processing carried out by automated means.
✓ Request compensation if you suffer damage due to unlawful processing.

To exercise your rights, send a written request to:
$companyEmail

We will respond within 30 days. Identity verification may be required.

CONSENT WITHDRAWAL
Where processing is based on your consent (location, notifications, remove.bg), you may withdraw consent at any time through the app's Settings screen. Withdrawal does not affect the lawfulness of processing before withdrawal.
''';

  // ─────────────────────────────────────────────
  // COOKIE / STORAGE NOTICE (Web)
  // ─────────────────────────────────────────────
  static const String storageNoticeTitle = 'Storage Notice';

  static const String storageNotice = '''
Effective Date: $effectiveDate

$appName (web version) uses browser localStorage and session storage solely to provide core functionality. We do not use cookies for advertising or tracking purposes.

WHAT WE STORE LOCALLY
• Authentication tokens (Firebase session)
• App settings: dark mode, notification preferences, background removal settings
• Cached wardrobe data for offline-like performance

These storage items are strictly necessary for the app to function correctly and do not require separate consent under applicable regulations. They are not shared with third parties and are cleared when you log out or clear your browser data.

For questions: $companyEmail
''';
}

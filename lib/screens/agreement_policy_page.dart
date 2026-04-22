import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// User agreement aligned with the Ancora / MediTrack backend spec (Firestore, roles, displayId, Storage).
class AgreementPolicyPage extends StatelessWidget {
  const AgreementPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Agreement & policy'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.onPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ancora user agreement',
              style: textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: April 2026. Ancora is a medication adherence assistant built for the Ancora / MediTrack project. By using the app, you accept the practices below.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'The service',
              body:
                  'Ancora helps you track medications, log doses, share progress with optional caregivers, and (where enabled) use reminders and photo verification. The app uses Firebase (Authentication, Firestore, Cloud Storage, and Cloud Messaging) as described in the project technical specification.',
            ),
            _Section(
              title: 'Account & roles',
              body:
                  'You sign up with an email and password. Your account is either a patient or a caregiver, set at registration and not changed afterwards. You are responsible for keeping your password secure.',
            ),
            _Section(
              title: 'Display code',
              body:
                  'Patients receive a unique four-digit code. Caregivers may only link to you if you give them this code. Do not post your code publicly; treat it like a PIN to authorise a caregiver relationship.',
            ),
            _Section(
              title: 'Data we store',
              body:
                  'We store profile fields (e.g. name, phone, age, optional profile photo), medication schedules, dose logs, caregiver links, and (for devices you allow) push notification tokens. Medication and adherence data is stored in Cloud Firestore under your user document as defined in the backend spec.',
            ),
            _Section(
              title: 'Profile & dose photos',
              body:
                  'You may upload a profile picture, stored in Firebase Storage at a path reserved for your account. When you use photo verification for a dose, that image is stored separately as proof and is only readable to you and caregivers who are already linked. Images must respect Storage security rules (type and size limits).',
            ),
            _Section(
              title: 'Caregivers',
              body:
                  'If you add a caregiver, they can see the adherence and schedule information required for the caregiver features (e.g. status, history), per Firestore security rules. You can manage linked caregivers from the flows provided in the app, subject to the same rules.',
            ),
            _Section(
              title: 'Notifications',
              body:
                  'The app may register for push and local notifications for reminders and optional caregiver alerts, where implemented and where your device and plan allow. You can control notification permissions in system settings.',
            ),
            _Section(
              title: 'Disclaimer',
              body:
                  'Ancora does not replace professional medical advice, diagnosis, or treatment. Always follow your health provider’s instructions. The software is provided as part of a university-style project; availability and features may change.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.onPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

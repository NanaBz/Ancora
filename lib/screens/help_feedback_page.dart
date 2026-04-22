import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// In-app help and a mailto for feedback. Replace [kSupportEmail] with your course or team inbox.
const String kSupportEmail = 'ancora.support@example.com';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({Key? key}) : super(key: key);

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:$kSupportEmail?subject=${Uri.encodeComponent('Ancora feedback')}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email. Contact your course team.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app available. Contact your course team.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help & feedback'),
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
              'Help',
              style: textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _HelpItem(
              icon: Icons.medication_outlined,
              title: 'Medications & reminders',
              body:
                  'Add a medication from the + tab. Set name, strength, how often you take it, and times. Reminders are scheduled on your device when supported. You can mark doses taken from the home screen.',
            ),
            _HelpItem(
              icon: Icons.pin_outlined,
              title: 'Your display code',
              body:
                  'In More, you’ll see a four-digit code. Share it only with caregivers you trust so they can add you. Don’t post it in public or chat groups you don’t control.',
            ),
            _HelpItem(
              icon: Icons.verified_user_outlined,
              title: 'Caregivers',
              body:
                  'If someone adds you with your code, they can see your adherence and schedule as allowed by the app. Use Agreement & policy for an overview of data use.',
            ),
            _HelpItem(
              icon: Icons.calendar_today_outlined,
              title: 'History & progress',
              body:
                  'Use the calendar tab to review past days, streaks, and adherence. Colours on the calendar reflect whether doses were taken or missed.',
            ),
            const SizedBox(height: 32),
            Text(
              'Feedback',
              style: textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Questions, bugs, or product ideas? Contact the project team. Replace the support address in the app with your real course or organisation email if you distribute a custom build.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SelectableText(
              kSupportEmail,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _emailSupport(context),
              icon: const Icon(Icons.email_outlined, size: 20),
              label: const Text('Open email to send feedback'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppTheme.pageBackground],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.favorite_border, size: 56, color: AppTheme.primaryColor.withValues(alpha: 0.9)),
                  const SizedBox(height: 20),
                  Text(
                    'ANCORA',
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 36,
                      letterSpacing: 3,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your Anchor in Medication Adherence',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  _FeatureCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Smart Reminders',
                    subtitle: 'Never miss a dose with intelligent, personalized notifications',
                  ),
                  const SizedBox(height: 14),
                  _FeatureCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Live Photo Verification',
                    subtitle: 'Prove you took your medication with real-time photo capture',
                  ),
                  const SizedBox(height: 14),
                  _FeatureCard(
                    icon: Icons.groups_outlined,
                    title: 'Caregiver Connection',
                    subtitle: 'Share your progress with loved ones and healthcare providers',
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/signup');
                    },
                    child: const Text('Get Started'),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Are you a caregiver? ',
                        style: textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/caregiver-auth');
                        },
                        child: Text(
                          'Click here',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.featureCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

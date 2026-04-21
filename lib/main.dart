import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/landing_page.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/history_page.dart';
import 'screens/add_medication_page.dart';
import 'screens/more_page.dart';
import 'screens/caregiver_auth_page.dart';
import 'screens/caregiver_home_page.dart';
import 'screens/caregiver_clients_page.dart';
import 'screens/caregiver_add_user_page.dart';
import 'screens/caregiver_more_page.dart';
import 'screens/caregiver_login_page.dart';
import 'screens/caregiver_signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const AncoraApp());
}

class AncoraApp extends StatelessWidget {
  const AncoraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ancora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/history': (context) => const HistoryPage(),
        '/add': (context) => const AddMedicationPage(),
        '/more': (context) => const MorePage(),
        '/caregiver-auth': (context) => const CaregiverAuthPage(),
        '/caregiver-home': (context) => const CaregiverHomePage(),
        '/caregiver-clients': (context) => CaregiverClientsPage(),
        '/caregiver-add-user': (context) => CaregiverAddUserPage(),
        '/caregiver-more': (context) => CaregiverMorePage(),
        '/caregiver-login': (context) => CaregiverLoginPage(),
        '/caregiver-signup': (context) => CaregiverSignUpPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final user = authSnap.data;
        if (user == null) return const LandingPage();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              );
            }
            final data = userSnap.data?.data() as Map<String, dynamic>?;
            final role = data?['role'] as String?;

            if (role == 'caregiver') return const CaregiverHomePage();
            return const HomePage();
          },
        );
      },
    );
  }
}

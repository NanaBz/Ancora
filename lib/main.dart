import 'package:flutter/material.dart';
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

void main() {
  runApp(const AncoraApp());
}

class AncoraApp extends StatelessWidget {
  const AncoraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ancora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF2CB9B0),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(firstName: 'John'),
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

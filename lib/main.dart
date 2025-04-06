import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sahayak/screens/auth%20screen/login_screen.dart';
import 'package:sahayak/screens/home_screen.dart'; // Example for HomeScreen (after login)
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox<String>('notesBox');  // Open Hive box for storing data

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sahayak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthWrapper(),  // Using the AuthWrapper for auth state handling
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),  // Add HomeScreen route if needed
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return const HomeScreen();  // Redirect to HomeScreen if logged in
          } else {
            return const LoginScreen();  // Show LoginScreen if user is not logged in
          }
        } else {
          return const Center(child: CircularProgressIndicator());  // Loading screen while checking auth status
        }
      },
    );
  }
}

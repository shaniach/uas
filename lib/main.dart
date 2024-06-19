import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:taxify_apps/components/common/dashboard.dart';
import 'package:taxify_apps/components/login_page.dart';
import 'package:taxify_apps/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxify App',
      theme: ThemeData(
        primaryColor: Color(0xFFFFA726),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFFA726),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFFFFA726), // Yellow-orange color for buttons
          textTheme: ButtonTextTheme.primary,
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange)
            .copyWith(secondary: Color(0xFFFFA726)),
      ),
      home: SplashScreen(), // Initial page of your app
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Method to check if user is authenticated
    Future<void> checkAuthStatus(BuildContext context) async {
      FirebaseAuth auth = FirebaseAuth.instance;
      await Future.delayed(Duration(seconds: 2)); // Simulating a 2 second delay

      if (auth.currentUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }

    // Call checkAuthStatus when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png', width: 500),
            SizedBox(height: 24),
            Text(
              'Taxify App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';

//App Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_screen.dart';

//Models
import 'models/building.dart';

//Providers
import 'providers/buildings_provider.dart';
import 'providers/user_provider.dart';

import 'services/building_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e, stack) {
    // Log the error and continue with user-visible message
    print('Firebase initialization failed: $e');
    print(stack);
  }

  if (firebaseInitialized) {
    await FirebaseAppCheck.instance.activate(
      // Use debug provider for development
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    final buildingService = BuildingService();
    await buildingService.initializeDefaultBuildings();
  }

  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized) {
      return MaterialApp(
        title: 'Tultul App',
        home: Scaffold(
          appBar: AppBar(title: const Text('Initialization Error')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Firebase failed to initialize.\nPlease add your GoogleService-Info.plist to ios/Runner and rebuild.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BuildingsProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Tultul App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7B1113), // Maroon
            primary: const Color(0xFF7B1113), // Maroon
            secondary: const Color(0xFF014421), // Forest Green
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const MainScreen(),
          '/map': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            final building =
                args != null ? args['building'] as Building? : null;
            return MainScreen(initialIndex: 0, selectedBuilding: building);
          },
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isSettingUp = false;
  String? _currentUserId;
  String? _errorMessage;

  void _setupUser(User user) {
    if (_currentUserId == user.uid && _isSettingUp) return;

    _currentUserId = user.uid;
    _isSettingUp = true;
    _errorMessage = null;

    Provider.of<UserProvider>(context, listen: false)
        .setUser(user)
        .then((_) {
          if (!mounted) return;
          setState(() {
            _isSettingUp = false;
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() {
            _isSettingUp = false;
            _errorMessage = e.toString();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Auth error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;
        if (!_isSettingUp && _currentUserId != user.uid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _setupUser(user);
          });
        }

        if (_isSettingUp) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up your profile...'),
                ],
              ),
            ),
          );
        }

        if (_errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return const MainScreen();
      },
    );
  }
}

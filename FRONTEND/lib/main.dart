import 'package:flutter/material.dart';
import 'package:dentcare/getstart.dart';
import 'package:dentcare/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'utils/role_provider.dart';
import 'services/user_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Hive for Offline Storage
  await Hive.initFlutter();
  await DatabaseService.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notifications
  await NotificationService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DentCare Premium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.accent),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            // Ensure the Firestore user document exists upon login
            UserService.ensureUserDocument(snapshot.data!);

            // Wrap the main app view with the RoleProvider
            return const RoleProviderWrapper(child: Home());
          }
          return const Getstart();
        },
      ),
    );
  }
}

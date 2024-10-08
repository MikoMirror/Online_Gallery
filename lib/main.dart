import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'blocs/auth_bloc.dart';
import 'screens/login_screen.dart';
import '../theme/app_theme.dart';
import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      BlocProvider(
        create: (context) => AuthBloc(),
        child: MaterialApp(
          title: 'Flutter Auth Demo',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: LoginScreen(),
        ),
      ),
    );
  }, (error, stack) {
    print('Caught error: $error');
    print('Stack trace: $stack');
  });
}
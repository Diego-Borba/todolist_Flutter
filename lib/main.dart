import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:flutter/services.dart';
//import 'screens/home.dart';
//import 'task_list_screen.dart';
import 'login_screen.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://hrharveoxypxlatqntkb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyaGFydmVveHlweGxhdHFudGtiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTcwOTY3NzgsImV4cCI6MjAzMjY3Mjc3OH0.vno_s4AnSI0g64SYBHCjr5E8mV71HYq7frGoyiK5FAo',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

Future<AuthResponse> _googleSignIn() async {
  const webClientId =
      '565837037834-vf7vlf3oi96g04k7qjd0u47jh20s31al.apps.googleusercontent.com';

  final GoogleSignIn googleSignIn = GoogleSignIn(
    serverClientId: webClientId,
  );
  final googleUser = await googleSignIn.signIn();
  final googleAuth = await googleUser!.authentication;
  final accessToken = googleAuth.accessToken;
  final idToken = googleAuth.idToken;

  if (accessToken == null) {
    throw 'No Access Token found.';
  }
  if (idToken == null) {
    throw 'No ID Token found.';
  }

  return supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: accessToken,
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Login'),
    ),
    body: const Center(
      child: ElevatedButton(
        onPressed: _googleSignIn,
        child: Text('Login com Google'),
      ),
    ),
  );
}

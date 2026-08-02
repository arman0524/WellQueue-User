import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsign;
import 'package:local_auth/local_auth.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final gsign.GoogleSignIn _googleSignIn = gsign.GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Biometric Auth
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access WellQueue',
        biometricOnly: true,
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('Error with Biometric Auth: $e');
      return false;
    }
  }

  // Google Sign-In
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (!_isGoogleSignInInitialized) {
        await _googleSignIn.initialize(
          serverClientId: 'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com',
        );
        _isGoogleSignInInitialized = true;
      }

      final gsign.GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final gsign.GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      // Ignore or log error
      debugPrint('Error with Google Sign-In: $e');
      return null;
    }
  }

  // Check if session exists
  bool get hasSession => _supabase.auth.currentSession != null;

  // Sign Out
  Future<void> signOut() async {
    if (_isGoogleSignInInitialized) {
      await _googleSignIn.signOut();
    }
    await _supabase.auth.signOut();
  }
}

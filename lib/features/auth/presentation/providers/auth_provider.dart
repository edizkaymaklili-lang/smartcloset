import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../main.dart' show firebaseAvailableProvider;
import '../../domain/entities/auth_state.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final firebaseReady = ref.watch(firebaseAvailableProvider);
    if (!firebaseReady) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthState(
        userId: user.uid,
        email: user.email,
        displayName: user.displayName,
        status: AuthStatus.authenticated,
      );
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthState(
        userId: credential.user?.uid,
        email: credential.user?.email,
        displayName: credential.user?.displayName,
        status: AuthStatus.authenticated,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e.code),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Sign in failed: ${e.toString()}',
      );
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
      state = AuthState(
        userId: credential.user?.uid,
        email: credential.user?.email,
        displayName: displayName,
        status: AuthStatus.authenticated,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapAuthError(e.code),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Sign up failed: ${e.toString()}',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      if (kIsWeb) {
        // Web platform: Use Firebase Auth popup directly
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // Add scopes if needed
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Sign in with popup
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);

        state = AuthState(
          userId: userCredential.user?.uid,
          email: userCredential.user?.email,
          displayName: userCredential.user?.displayName,
          status: AuthStatus.authenticated,
        );
      } else {
        // Mobile/Desktop platform: Use google_sign_in package
        final googleSignIn = GoogleSignIn.instance;

        // google_sign_in v7: event-based authentication
        final completer = Completer<GoogleSignInAccount?>();
        StreamSubscription<GoogleSignInAuthenticationEvent>? sub;

        sub = googleSignIn.authenticationEvents.listen(
          (event) {
            switch (event) {
              case GoogleSignInAuthenticationEventSignIn(:final user):
                if (!completer.isCompleted) completer.complete(user);
              case GoogleSignInAuthenticationEventSignOut():
                if (!completer.isCompleted) completer.complete(null);
            }
            sub?.cancel();
          },
          onError: (error) {
            if (!completer.isCompleted) completer.completeError(error);
            sub?.cancel();
          },
        );

        // Trigger Google authentication
        await googleSignIn.authenticate();

        final googleUser = await completer.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () => null,
        );

        if (googleUser == null) {
          state = state.copyWith(status: AuthStatus.unauthenticated);
          return;
        }

        // v7: authentication is a sync getter with idToken only
        final idToken = googleUser.authentication.idToken;
        final credential = GoogleAuthProvider.credential(idToken: idToken);

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        state = AuthState(
          userId: userCredential.user?.uid,
          email: userCredential.user?.email,
          displayName: userCredential.user?.displayName,
          status: AuthStatus.authenticated,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google sign in failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // Google sign out may fail if not signed in with Google
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Quick login for demo/testing purposes - bypasses Firebase Auth
  void quickLogin() {
    state = const AuthState(
      userId: 'demo_user',
      email: 'demo@stilasist.com',
      displayName: 'Demo User',
      status: AuthStatus.authenticated,
    );
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'No user found with this email.',
      'wrong-password' => 'Incorrect password.',
      'email-already-in-use' => 'This email is already in use.',
      'weak-password' => 'Password is too weak. At least 6 characters required.',
      'invalid-email' => 'Invalid email address.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'user-disabled' => 'This account has been disabled.',
      _ => 'An error occurred: $code',
    };
  }
}

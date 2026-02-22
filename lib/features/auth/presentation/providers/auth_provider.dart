import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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

    // Listen to Firebase Auth state changes (handles redirect, session restore, etc.)
    final sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _createUserProfile(user);
        state = AuthState(
          userId: user.uid,
          email: user.email,
          displayName: user.displayName,
          emailVerified: user.emailVerified,
          status: AuthStatus.authenticated,
        );
      } else if (state.status != AuthStatus.loading) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
    ref.onDispose(sub.cancel);

    // Check current user synchronously
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthState(
        userId: user.uid,
        email: user.email,
        displayName: user.displayName,
        emailVerified: user.emailVerified,
        status: AuthStatus.authenticated,
      );
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Creates or updates user profile in Firestore
  Future<void> _createUserProfile(User user) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create new user profile
        await userDoc.set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'User',
          'photoUrl': user.photoURL,
          'city': '',
          'bio': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing profile with latest info
        await userDoc.update({
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'User',
          'photoUrl': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log error but don't fail authentication
      debugPrint('Failed to create/update user profile: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create/update user profile in Firestore
      if (credential.user != null) {
        await _createUserProfile(credential.user!);
      }

      state = AuthState(
        userId: credential.user?.uid,
        email: credential.user?.email,
        displayName: credential.user?.displayName,
        emailVerified: credential.user?.emailVerified ?? false,
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

      // Create user profile in Firestore
      if (credential.user != null) {
        await _createUserProfile(credential.user!);
      }

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
        // Web platform: Try popup first (works on Chrome), fallback to redirect
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        try {
          final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
          if (userCredential.user != null) {
            await _createUserProfile(userCredential.user!);
          }
          state = AuthState(
            userId: userCredential.user?.uid,
            email: userCredential.user?.email,
            displayName: userCredential.user?.displayName,
            status: AuthStatus.authenticated,
          );
        } catch (popupError) {
          debugPrint('Popup sign-in failed, trying redirect: $popupError');
          // Fallback to redirect if popup is blocked
          await FirebaseAuth.instance.signInWithRedirect(googleProvider);
        }
        return;
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

        // Create/update user profile in Firestore
        if (userCredential.user != null) {
          await _createUserProfile(userCredential.user!);
        }

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

  /// Sends a password reset email. Returns null on success, error message on failure.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  /// Changes the password for the currently signed-in user.
  /// Returns null on success, error message on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        return 'You must be signed in to change your password.';
      }
      // Re-authenticate before sensitive operation
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  /// Permanently deletes the current user account and all associated data.
  /// Returns null on success, error message on failure.
  Future<String?> deleteAccount(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        return 'You must be signed in to delete your account.';
      }
      // Re-authenticate before deletion
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      // Delete Firestore user doc
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      } catch (_) {}
      await user.delete();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  /// Sends email verification to the current user.
  /// Returns null on success, error message on failure.
  Future<String?> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'You must be signed in to verify your email.';
      }
      if (user.emailVerified) {
        return 'Email is already verified.';
      }
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  /// Reloads the current user to get the latest email verification status.
  /// Returns true if email is now verified, false otherwise.
  Future<bool> checkEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser != null) {
        state = state.copyWith(emailVerified: updatedUser.emailVerified);
        return updatedUser.emailVerified;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to reload user: $e');
      return false;
    }
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

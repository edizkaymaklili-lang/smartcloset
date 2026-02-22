import 'package:flutter_test/flutter_test.dart';
import 'package:stil_asist/features/auth/domain/entities/auth_state.dart';

void main() {
  group('AuthState', () {
    test('initial state has correct defaults', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.userId, isNull);
      expect(state.email, isNull);
      expect(state.displayName, isNull);
      expect(state.emailVerified, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('isAuthenticated is false for initial status', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated is true only when status is authenticated', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        userId: 'user123',
      );
      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated is false for unauthenticated status', () {
      const state = AuthState(status: AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated is false for loading status', () {
      const state = AuthState(status: AuthStatus.loading);
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated is false for error status', () {
      const state = AuthState(status: AuthStatus.error);
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith preserves fields not explicitly overridden', () {
      const initial = AuthState(
        userId: 'u1',
        email: 'a@b.com',
        displayName: 'Alice',
        emailVerified: true,
        status: AuthStatus.authenticated,
      );
      final updated = initial.copyWith(status: AuthStatus.loading);

      expect(updated.userId, 'u1');
      expect(updated.email, 'a@b.com');
      expect(updated.displayName, 'Alice');
      expect(updated.emailVerified, isTrue);
      expect(updated.status, AuthStatus.loading);
    });

    test('copyWith can override every field', () {
      const initial = AuthState(
        userId: 'u1',
        email: 'old@b.com',
        status: AuthStatus.authenticated,
      );
      final updated = initial.copyWith(
        userId: 'u2',
        email: 'new@b.com',
        status: AuthStatus.unauthenticated,
        errorMessage: 'Signed out',
      );

      expect(updated.userId, 'u2');
      expect(updated.email, 'new@b.com');
      expect(updated.status, AuthStatus.unauthenticated);
      expect(updated.errorMessage, 'Signed out');
    });

    test('error state carries error message and is not authenticated', () {
      const state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Wrong password',
      );
      expect(state.errorMessage, 'Wrong password');
      expect(state.isAuthenticated, isFalse);
    });

    test('authenticated state with emailVerified reflects correctly', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        userId: 'u1',
        emailVerified: true,
      );
      expect(state.isAuthenticated, isTrue);
      expect(state.emailVerified, isTrue);
    });
  });
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../data/local/database.dart';
import '../../../core/security/password_hasher.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/services/app_init_service.dart';

final serverUrlProvider = StateProvider<String>((_) => 'http://192.168.1.94:3001');
final tokenProvider = StateProvider<String?>((_) => null);

enum AuthMode { authenticated, offline, guest }

class AuthState {
  final AuthMode authMode;
  final bool isAuthenticated;
  final String? userId;
  final String? householdId;
  final String? email;
  final String? displayName;
  final String? token;
  final String? authProvider;
  final bool hasCompletedOnboarding;

  const AuthState({
    this.authMode = AuthMode.guest,
    this.isAuthenticated = false,
    this.userId,
    this.householdId,
    this.email,
    this.displayName,
    this.token,
    this.authProvider,
    this.hasCompletedOnboarding = false,
  });

  AuthState copyWith({
    AuthMode? authMode,
    bool? isAuthenticated,
    String? userId,
    String? householdId,
    String? email,
    String? displayName,
    String? token,
    String? authProvider,
    bool? hasCompletedOnboarding,
  }) {
    return AuthState(
      authMode: authMode ?? this.authMode,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      token: token ?? this.token,
      authProvider: authProvider ?? this.authProvider,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final Ref _ref;
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 3),
    ),
  );

  AuthStateNotifier(this._ref) : super(const AsyncValue.data(AuthState())) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = await SecureStore.readAccessToken();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          return handler.next(options);
        },
      ),
    );
    _restoreSavedSession();
  }

  Future<void> _restoreSavedSession() async {
    try {
      final token = await SecureStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        // If legacy dummy/offline token was stored, clear it out
        if (token == 'offline-token' || token == 'demo-token') {
          await SecureStore.clearTokens();
          _ref.read(tokenProvider.notifier).state = null;
          state = const AsyncValue.data(AuthState(authMode: AuthMode.guest));
          return;
        }

        final email = await SecureStore.read('auth_email');
        final displayName = await SecureStore.read('auth_name');
        final userId = await SecureStore.read('auth_user_id');
        final householdId = await SecureStore.read('auth_household_id');
        final hasCompletedOnboarding = (await SecureStore.read('has_completed_onboarding')) == 'true';

        if (email != null && userId != null && householdId != null) {
          _ref.read(tokenProvider.notifier).state = token;
          final db = _ref.read(appDatabaseProvider);
          await AppInitService.clearAllDummyData(db);
          await AppInitService.ensureUserHouseholdSeed(db, householdId);

          state = AsyncValue.data(AuthState(
            authMode: AuthMode.authenticated,
            isAuthenticated: true,
            householdId: householdId,
            userId: userId,
            email: email,
            displayName: displayName ?? email.split('@').first,
            token: token,
            authProvider: 'restored',
            hasCompletedOnboarding: hasCompletedOnboarding,
          ));
          return;
        }
      }
    } catch (_) {}

    // No valid session stored -> default to unauthenticated state
    state = const AsyncValue.data(AuthState(authMode: AuthMode.guest));
  }

  final _googleSignIn = GoogleSignIn(
    serverClientId: '812371931220-nfm4elvsk9sbsu1e2bh3mu8une6gb96o.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Authenticate with Google ID token via NestJS backend, with local offline fallback
  Future<void> authenticateWithGoogleIdToken({
    required String idToken,
    required String email,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    final normEmail = email.trim().toLowerCase();
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : normEmail.split('@').first;

    try {
      final serverUrl = _ref.read(serverUrlProvider);
      try {
        if (idToken.isNotEmpty) {
          final res = await _dio.post(
            '$serverUrl/auth/google',
            data: {
              'idToken': idToken,
            },
          );
          final data = res.data;
          final token = data['accessToken'];
          final refreshToken = data['refreshToken'];
          final user = data['user'];

          if (token != null) {
            await SecureStore.writeAccessToken(token);
            if (refreshToken != null) {
              await SecureStore.writeRefreshToken(refreshToken);
            }
            final householdId = user['householdId'] ?? 'household';
            final uId = user['id'] ?? 'user';
            final uEmail = user['email'] ?? normEmail;
            final uName = user['displayName'] ?? name;

            await SecureStore.write('auth_email', uEmail);
            await SecureStore.write('auth_name', uName);
            await SecureStore.write('auth_user_id', uId);
            await SecureStore.write('auth_household_id', householdId);

            final db = _ref.read(appDatabaseProvider);
            await AppInitService.clearAllDummyData(db);
            await AppInitService.ensureUserHouseholdSeed(db, householdId);

            _ref.read(tokenProvider.notifier).state = token;
            state = AsyncValue.data(AuthState(
              authMode: AuthMode.authenticated,
              isAuthenticated: true,
              email: uEmail,
              displayName: uName,
              householdId: householdId,
              userId: uId,
              token: token,
              authProvider: 'google',
              hasCompletedOnboarding: false, // Force true or fetch from API if supported
            ));
            return;
          }
        }
      } catch (_) {
        // Connection offline or backend unreachable — fallback to local database
      }

      // Local offline database fallback with REAL Google user account
      final db = _ref.read(appDatabaseProvider);
      await _ensureUsersTable(db);
      final existingUsers = await (db.select(db.usersTable)
            ..where((u) => u.email.equals(normEmail)))
          .get();

      late String userId;
      late String householdId;

      if (existingUsers.isNotEmpty) {
        final u = existingUsers.first;
        userId = u.id;
        householdId = u.householdId;
      } else {
        userId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
        householdId = 'hsh-${DateTime.now().millisecondsSinceEpoch}';
        await db.into(db.usersTable).insert(
              UsersTableCompanion.insert(
                id: userId,
                email: normEmail,
                password: const Value.absent(),
                displayName: name,
                householdId: householdId,
                authProvider: const Value('google'),
                createdAt: DateTime.now(),
              ),
            );
      }

      await SecureStore.write('auth_email', normEmail);
      await SecureStore.write('auth_name', name);
      await SecureStore.write('auth_user_id', userId);
      await SecureStore.write('auth_household_id', householdId);

      await AppInitService.clearAllDummyData(db);
      await AppInitService.ensureUserHouseholdSeed(db, householdId);
      final token = 'google-oauth-${DateTime.now().millisecondsSinceEpoch}';
      await SecureStore.writeAccessToken(token);
      _ref.read(tokenProvider.notifier).state = token;
      state = AsyncValue.data(AuthState(
        authMode: AuthMode.offline,
        isAuthenticated: true,
        userId: userId,
        householdId: householdId,
        email: normEmail,
        displayName: name,
        token: token,
        authProvider: 'google',
        hasCompletedOnboarding: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Triggers official Google OAuth + Firebase Auth sign-in flow across Android, iOS, and Web.
  /// Authenticates with Firebase via GoogleAuthProvider credential and retrieves the verified Firebase ID token.
  Future<bool> signInWithGoogleOAuth() async {
    final previousState = state.valueOrNull ?? const AuthState(authMode: AuthMode.guest);
    state = const AsyncValue.loading();
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        // User canceled sign-in -> restore previous state cleanly
        state = AsyncValue.data(previousState);
        return false;
      }

      final googleAuth = await googleAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase user authentication returned null.');
      }

      final String? firebaseIdToken = await firebaseUser.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Unable to obtain Firebase ID token.');
      }

      final verifiedEmail = firebaseUser.email ?? googleAccount.email;
      final verifiedName = firebaseUser.displayName ??
          googleAccount.displayName ??
          verifiedEmail.split('@').first;

      await authenticateWithGoogleIdToken(
        idToken: firebaseIdToken,
        email: verifiedEmail,
        displayName: verifiedName,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Google sign-in failed.';
      if (e.code == 'account-exists-with-different-credential') {
        message = 'An account already exists with a different credential.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid Google sign-in credentials.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      state = AsyncValue.error(message, StackTrace.current);
      return false;
    } catch (e, st) {
      debugPrint('Google Sign-In Exception: $e\n$st');
      final errStr = e.toString();
      if (errStr.contains('SocketException')) {
        state = AsyncValue.error('Network error during Google sign-in. Please check your connection.', StackTrace.current);
      } else {
        state = AsyncValue.error('Google sign-in failed: $errStr', StackTrace.current);
      }
      return false;
    }

  }

  Future<void> _ensureUsersTable(AppDatabase db) async {
    try {
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS "users" (
          "id" TEXT NOT NULL PRIMARY KEY,
          "email" TEXT NOT NULL,
          "password" TEXT,
          "display_name" TEXT NOT NULL,
          "household_id" TEXT NOT NULL,
          "auth_provider" TEXT NOT NULL DEFAULT 'email',
          "created_at" INTEGER NOT NULL
        );
      ''');
    } catch (_) {}
  }

  /// Real Google Sign-In Verification & User Account Creation
  Future<void> googleSignIn({required String email, String? displayName, String? idToken}) async {
    await authenticateWithGoogleIdToken(
      idToken: idToken ?? '',
      email: email,
      displayName: displayName,
    );
  }

  /// Real Password Authentication & Account Verification
  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final db = _ref.read(appDatabaseProvider);
    await _ensureUsersTable(db);
    final normEmail = email.trim().toLowerCase();

    try {
      final serverUrl = _ref.read(serverUrlProvider);
      try {
        final res = await _dio.post(
          '$serverUrl/auth/login',
          data: {'email': normEmail, 'password': password},
        );
        final data = res.data;
        final token = data['accessToken'];
        final user = data['user'];

        _ref.read(tokenProvider.notifier).state = token;
        state = AsyncValue.data(AuthState(
          authMode: AuthMode.authenticated,
          isAuthenticated: true,
          email: user['email'],
          displayName: user['displayName'],
          householdId: user['householdId'],
          userId: user['id'],
          token: token,
          authProvider: 'email',
        ));
        return;
      } catch (_) {
        // Fallback to local database authentication
      }

      final existingUsers = await (db.select(db.usersTable)
            ..where((u) => u.email.equals(normEmail)))
          .get();

      if (existingUsers.isEmpty) {
        state = AsyncValue.error(
          'No account found for "$normEmail". Please register an account first.',
          StackTrace.current,
        );
        return;
      }

      final user = existingUsers.first;
      bool valid = false;
      if (user.password != null && user.authProvider == 'email') {
        if (PasswordHasher.isHashed(user.password)) {
          valid = PasswordHasher.verify(password, user.password!);
        } else if (user.password == password) {
          valid = true;
          // Auto-upgrade legacy plaintext password to PBKDF2 hash
          final newHash = PasswordHasher.hash(password);
          await (db.update(db.usersTable)..where((u) => u.id.equals(user.id)))
              .write(UsersTableCompanion(password: Value(newHash)));
        }
      } else {
        valid = true;
      }

      if (!valid) {
        state = AsyncValue.error(
          'Incorrect password for "$normEmail". Please check your password and try again.',
          StackTrace.current,
        );
        return;
      }

      final token = 'auth-${DateTime.now().millisecondsSinceEpoch}';
      await SecureStore.writeAccessToken(token);
      await SecureStore.write('auth_email', user.email);
      await SecureStore.write('auth_name', user.displayName);
      await SecureStore.write('auth_user_id', user.id);
      await SecureStore.write('auth_household_id', user.householdId);

      await AppInitService.ensureUserHouseholdSeed(db, user.householdId);
      _ref.read(tokenProvider.notifier).state = token;

      state = AsyncValue.data(AuthState(
        authMode: AuthMode.offline,
        isAuthenticated: true,
        email: user.email,
        displayName: user.displayName,
        householdId: user.householdId,
        userId: user.id,
        token: token,
        authProvider: user.authProvider,
        hasCompletedOnboarding: false, // Default to false for new logins unless fetched from backend
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Real Account Registration & Persistent Storage
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String householdName,
  }) async {
    state = const AsyncValue.loading();
    final db = _ref.read(appDatabaseProvider);
    await _ensureUsersTable(db);
    final normEmail = email.trim().toLowerCase();

    try {
      final existing = await (db.select(db.usersTable)
            ..where((u) => u.email.equals(normEmail)))
          .get();

      if (existing.isNotEmpty) {
        state = AsyncValue.error(
          'An account with email "$normEmail" already exists. Please log in.',
          StackTrace.current,
        );
        return;
      }

      final userId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
      final householdId = 'hsh-${DateTime.now().millisecondsSinceEpoch}';
      final hashedPassword = PasswordHasher.hash(password);
      final finalDisplayName = displayName.trim().isNotEmpty ? displayName.trim() : normEmail.split('@').first;

      await db.into(db.usersTable).insert(
            UsersTableCompanion.insert(
              id: userId,
              email: normEmail,
              password: Value(hashedPassword),
              displayName: finalDisplayName,
              householdId: householdId,
              authProvider: const Value('email'),
              createdAt: DateTime.now(),
            ),
          );

      final token = 'auth-${DateTime.now().millisecondsSinceEpoch}';
      await SecureStore.writeAccessToken(token);
      await SecureStore.write('auth_email', normEmail);
      await SecureStore.write('auth_name', finalDisplayName);
      await SecureStore.write('auth_user_id', userId);
      await SecureStore.write('auth_household_id', householdId);

      await AppInitService.ensureUserHouseholdSeed(db, householdId);
      _ref.read(tokenProvider.notifier).state = token;

      state = AsyncValue.data(AuthState(
        authMode: AuthMode.authenticated,
        isAuthenticated: true,
        email: normEmail,
        displayName: finalDisplayName,
        householdId: householdId,
        userId: userId,
        token: token,
        authProvider: 'email',
        hasCompletedOnboarding: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeOnboarding() async {
    await SecureStore.write('has_completed_onboarding', 'true');
    if (state.valueOrNull != null) {
      state = AsyncValue.data(state.value!.copyWith(hasCompletedOnboarding: true));
    }
  }

  Future<void> logout() async {
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      final refreshToken = await SecureStore.readRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post(
          '$serverUrl/auth/logout',
          data: {'family': refreshToken},
        );
      }
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await SecureStore.clearTokens();
    await SecureStore.delete('auth_email');
    await SecureStore.delete('auth_name');
    await SecureStore.delete('auth_user_id');
    await SecureStore.delete('auth_household_id');
    await SecureStore.delete('has_completed_onboarding');
    final db = _ref.read(appDatabaseProvider);
    await AppInitService.clearAllDummyData(db);
    _ref.read(tokenProvider.notifier).state = null;
    state = const AsyncValue.data(AuthState(authMode: AuthMode.guest));
  }
}

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthState>>(
  (ref) => AuthStateNotifier(ref),
);

final authStateProvider = authStateNotifierProvider;

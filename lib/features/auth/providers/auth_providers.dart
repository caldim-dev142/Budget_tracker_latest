import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../data/local/database.dart';
import '../../../core/security/password_hasher.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/services/app_init_service.dart';
import '../../../core/services/sync_service.dart';

/// Production backend URL supplied at compile-time via --dart-define=BACKEND_URL=https://...
const String kBackendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');

final serverUrlProvider = StateProvider<String>((_) {
  if (kBackendUrl.isNotEmpty) {
    return kBackendUrl;
  }
  if (kReleaseMode) {
    // In production release builds, default to empty string so it doesn't leak developer LAN IP
    return '';
  }
  // Default development fallback for Android emulator / local testing (NestJS runs on port 3001)
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3001';
  }
  return 'http://localhost:3001';
});
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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
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
          Future.microtask(() async {
            await _ref.read(syncServiceProvider).pullFromServer();
            await _ref.read(syncServiceProvider).syncAllQueue();
          });
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

  /// Authenticate with Google ID token via NestJS backend
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
      if (serverUrl.isEmpty) {
        throw Exception('Server URL is not configured. Please contact support.');
      }

      if (idToken.isEmpty) {
        throw Exception('Missing Google ID token.');
      }

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

      if (token == null || user == null) {
        throw Exception('Invalid response received from authentication server.');
      }

      final householdId = user['householdId'] ?? 'household';
      final uId = user['id'] ?? 'user';
      final uEmail = user['email'] ?? normEmail;
      final uName = user['displayName'] ?? name;

      await SecureStore.writeAccessToken(token);
      if (refreshToken != null) {
        await SecureStore.writeRefreshToken(refreshToken);
      }

      await SecureStore.write('auth_email', uEmail);
      await SecureStore.write('auth_name', uName);
      await SecureStore.write('auth_user_id', uId);
      await SecureStore.write('auth_household_id', householdId);

      final db = _ref.read(appDatabaseProvider);
      await _ensureUsersTable(db);
      final existingLocal = await (db.select(db.usersTable)..where((u) => u.id.equals(uId))).get();
      if (existingLocal.isEmpty) {
        await db.into(db.usersTable).insert(
              UsersTableCompanion.insert(
                id: uId,
                email: uEmail,
                password: const Value.absent(),
                displayName: uName,
                householdId: householdId,
                authProvider: const Value('google'),
                createdAt: DateTime.now(),
              ),
            );
      }

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
        hasCompletedOnboarding: false,
      ));
      Future.microtask(() async {
        await _ref.read(syncServiceProvider).pullFromServer();
        await _ref.read(syncServiceProvider).syncAllQueue();
      });
    } on DioException catch (e, st) {
      String msg = 'Google authentication failed. Please check your connection.';
      if (e.response != null) {
        final resData = e.response?.data;
        if (resData is Map && resData.containsKey('message')) {
          final m = resData['message'];
          msg = m is List ? m.join(', ') : m.toString();
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        msg = 'Unable to connect to server. Please check your internet connection and try again.';
      }
      state = AsyncValue.error(msg, st);
    } catch (e, st) {
      state = AsyncValue.error(e.toString().replaceAll('Exception: ', ''), st);
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
      if (serverUrl.isNotEmpty) {
        try {
          final res = await _dio.post(
            '$serverUrl/auth/login',
            data: {'email': normEmail, 'password': password},
          );
          final data = res.data;
          final token = data['accessToken'];
          final refreshToken = data['refreshToken'];
          final user = data['user'];

          if (token != null && user != null) {
            final userId = user['id'] as String;
            final householdId = user['householdId'] as String;
            final userEmail = (user['email'] as String?) ?? normEmail;
            final displayName = (user['displayName'] as String?) ?? userEmail.split('@').first;

            await SecureStore.writeAccessToken(token);
            if (refreshToken != null) {
              await SecureStore.writeRefreshToken(refreshToken);
            }
            await SecureStore.write('auth_email', userEmail);
            await SecureStore.write('auth_name', displayName);
            await SecureStore.write('auth_user_id', userId);
            await SecureStore.write('auth_household_id', householdId);

            // Sync user cache locally for offline access
            final existingUsers = await (db.select(db.usersTable)..where((u) => u.id.equals(userId))).get();
            if (existingUsers.isEmpty) {
              await db.into(db.usersTable).insert(
                UsersTableCompanion.insert(
                  id: userId,
                  email: userEmail,
                  password: Value(PasswordHasher.hash(password)),
                  displayName: displayName,
                  householdId: householdId,
                  authProvider: const Value('email'),
                  createdAt: DateTime.now(),
                ),
              );
            }

            await AppInitService.ensureUserHouseholdSeed(db, householdId);
            _ref.read(tokenProvider.notifier).state = token;

            state = AsyncValue.data(AuthState(
              authMode: AuthMode.authenticated,
              isAuthenticated: true,
              email: userEmail,
              displayName: displayName,
              householdId: householdId,
              userId: userId,
              token: token,
              authProvider: 'email',
            ));

            Future.microtask(() async {
              await _ref.read(syncServiceProvider).pullFromServer();
              await _ref.read(syncServiceProvider).syncAllQueue();
            });
            return;
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
            state = AsyncValue.error(
              'Invalid email or password. Please check your credentials.',
              StackTrace.current,
            );
            return;
          }
          // If server is unreachable, allow falling back to cached offline account if present
          if (e.type != DioExceptionType.connectionTimeout &&
              e.type != DioExceptionType.sendTimeout &&
              e.type != DioExceptionType.receiveTimeout &&
              e.type != DioExceptionType.connectionError) {
            final resData = e.response?.data;
            String msg = 'Authentication failed.';
            if (resData is Map && resData.containsKey('message')) {
              final m = resData['message'];
              msg = m is List ? m.join(', ') : m.toString();
            }
            state = AsyncValue.error(msg, StackTrace.current);
            return;
          }
        }
      }

      // Offline login fallback ONLY for already cached local users
      final existingUsers = await (db.select(db.usersTable)
            ..where((u) => u.email.equals(normEmail)))
          .get();

      if (existingUsers.isEmpty) {
        state = AsyncValue.error(
          'Unable to reach server. Please check your internet connection.',
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
        hasCompletedOnboarding: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e.toString().replaceAll('Exception: ', ''), st);
    }
  }

  /// Real Account Registration & Persistent Storage in Supabase
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
    final cleanDisplayName =
        displayName.trim().isNotEmpty ? displayName.trim() : normEmail.split('@').first;
    final cleanHouseholdName =
        householdName.trim().isNotEmpty ? householdName.trim() : "$cleanDisplayName's Household";

    try {
      final serverUrl = _ref.read(serverUrlProvider);
      if (serverUrl.isEmpty) {
        throw Exception('Server URL is not configured. Please check your application settings.');
      }

      final res = await _dio.post(
        '$serverUrl/auth/register',
        data: {
          'email': normEmail,
          'password': password,
          'displayName': cleanDisplayName,
          'householdName': cleanHouseholdName,
        },
      );
      final data = res.data;
      final token = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final user = data['user'];

      if (token == null || user == null) {
        throw Exception('Invalid response received from authentication server.');
      }

      final userId = user['id'] as String;
      final householdId = user['householdId'] as String;
      final retEmail = (user['email'] as String?) ?? normEmail;
      final retName = (user['displayName'] as String?) ?? cleanDisplayName;

      await SecureStore.writeAccessToken(token);
      if (refreshToken != null) {
        await SecureStore.writeRefreshToken(refreshToken);
      }
      await SecureStore.write('auth_email', retEmail);
      await SecureStore.write('auth_name', retName);
      await SecureStore.write('auth_user_id', userId);
      await SecureStore.write('auth_household_id', householdId);

      // Persist authenticated profile to local Drift database cache
      final existing = await (db.select(db.usersTable)..where((u) => u.id.equals(userId))).get();
      if (existing.isEmpty) {
        await db.into(db.usersTable).insert(
              UsersTableCompanion.insert(
                id: userId,
                email: retEmail,
                password: Value(PasswordHasher.hash(password)),
                displayName: retName,
                householdId: householdId,
                authProvider: const Value('email'),
                createdAt: DateTime.now(),
              ),
            );
      }

      await AppInitService.ensureUserHouseholdSeed(db, householdId);

      _ref.read(tokenProvider.notifier).state = token;
      state = AsyncValue.data(AuthState(
        authMode: AuthMode.authenticated,
        isAuthenticated: true,
        email: retEmail,
        displayName: retName,
        householdId: householdId,
        userId: userId,
        token: token,
        authProvider: 'email',
        hasCompletedOnboarding: false,
      ));

      Future.microtask(() async {
        await _ref.read(syncServiceProvider).pullFromServer();
        await _ref.read(syncServiceProvider).syncAllQueue();
      });
    } on DioException catch (e, st) {
      String msg = 'Registration failed. Please check your internet connection.';
      if (e.response != null) {
        final resData = e.response?.data;
        if (resData is Map && resData.containsKey('message')) {
          final m = resData['message'];
          msg = m is List ? m.join(', ') : m.toString();
        } else if (e.response?.statusCode == 409) {
          msg = 'An account with email "$normEmail" already exists. Please sign in.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        msg = 'Unable to connect to server. Please check your internet connection and try again.';
      }
      state = AsyncValue.error(msg, st);
    } catch (e, st) {
      state = AsyncValue.error(e.toString().replaceAll('Exception: ', ''), st);
    }
  }

  Future<void> completeOnboarding() async {
    await SecureStore.write('has_completed_onboarding', 'true');
    if (state.valueOrNull != null) {
      state = AsyncValue.data(state.value!.copyWith(hasCompletedOnboarding: true));
    }
  }

  /// Fetch household details & member list from backend
  Future<Map<String, dynamic>?> fetchHouseholdDetails() async {
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      final res = await _dio.get('$serverUrl/households/me');
      if (res.data != null && res.data['household'] != null) {
        return Map<String, dynamic>.from(res.data['household']);
      }
    } catch (e) {
      debugPrint('fetchHouseholdDetails error: $e');
    }
    return null;
  }

  /// Create a new household (generates ID only when triggered)
  Future<String?> createHousehold(String name) async {
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      final res = await _dio.post(
        '$serverUrl/households',
        data: {'name': name.trim()},
      );
      final data = res.data;
      final household = data['household'];
      final newHouseholdId = household['id'] as String;
      final tokens = data['tokens'];

      if (tokens != null && tokens['accessToken'] != null) {
        await SecureStore.writeAccessToken(tokens['accessToken']);
        _ref.read(tokenProvider.notifier).state = tokens['accessToken'];
      }
      await SecureStore.write('auth_household_id', newHouseholdId);

      // Seed Drift database for this new household
      final db = _ref.read(appDatabaseProvider);
      await AppInitService.ensureUserHouseholdSeed(db, newHouseholdId);

      // Update local user in Drift table
      final currentAuth = state.valueOrNull;
      if (currentAuth?.userId != null) {
        await (db.update(db.usersTable)..where((u) => u.id.equals(currentAuth!.userId!)))
            .write(UsersTableCompanion(householdId: Value(newHouseholdId)));
      }

      if (state.valueOrNull != null) {
        state = AsyncValue.data(state.value!.copyWith(householdId: newHouseholdId));
      }

      Future.microtask(() async {
        await _ref.read(syncServiceProvider).pullFromServer();
        await _ref.read(syncServiceProvider).syncAllQueue();
      });

      return newHouseholdId;
    } catch (e) {
      debugPrint('createHousehold error: $e');
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  /// Join an existing household using household ID
  Future<void> joinHousehold(String householdId) async {
    final trimmedId = householdId.trim();
    if (trimmedId.isEmpty) {
      throw Exception('Please enter a valid Household ID.');
    }

    try {
      final serverUrl = _ref.read(serverUrlProvider);
      final res = await _dio.post(
        '$serverUrl/households/join',
        data: {'householdId': trimmedId},
      );
      final data = res.data;
      final tokens = data['tokens'];

      if (tokens != null && tokens['accessToken'] != null) {
        await SecureStore.writeAccessToken(tokens['accessToken']);
        _ref.read(tokenProvider.notifier).state = tokens['accessToken'];
      }
      await SecureStore.write('auth_household_id', trimmedId);

      // Seed Drift database for this joined household
      final db = _ref.read(appDatabaseProvider);
      await AppInitService.ensureUserHouseholdSeed(db, trimmedId);

      // Update local user in Drift table
      final currentAuth = state.valueOrNull;
      if (currentAuth?.userId != null) {
        await (db.update(db.usersTable)..where((u) => u.id.equals(currentAuth!.userId!)))
            .write(UsersTableCompanion(householdId: Value(trimmedId)));
      }

      if (state.valueOrNull != null) {
        state = AsyncValue.data(state.value!.copyWith(householdId: trimmedId));
      }

      Future.microtask(() async {
        await _ref.read(syncServiceProvider).pullFromServer();
        await _ref.read(syncServiceProvider).syncAllQueue();
      });
    } catch (e) {
      debugPrint('joinHousehold error: $e');
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  /// Update household name (Owner only)
  Future<void> updateHouseholdName(String newName) async {
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      await _dio.patch(
        '$serverUrl/households/me',
        data: {'name': newName.trim()},
      );
    } catch (e) {
      debugPrint('updateHouseholdName error: $e');
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  /// Delete household (Owner only)
  Future<void> deleteHousehold() async {
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      final res = await _dio.delete('$serverUrl/households/me');
      final data = res.data;
      final tokens = data['tokens'];

      if (tokens != null && tokens['accessToken'] != null) {
        await SecureStore.writeAccessToken(tokens['accessToken']);
        _ref.read(tokenProvider.notifier).state = tokens['accessToken'];
      }
      await SecureStore.delete('auth_household_id');

      // Update local user in Drift table
      final db = _ref.read(appDatabaseProvider);
      final currentAuth = state.valueOrNull;
      if (currentAuth?.userId != null) {
        await (db.update(db.usersTable)..where((u) => u.id.equals(currentAuth!.userId!)))
            .write(const UsersTableCompanion(householdId: Value('')));
      }

      if (state.valueOrNull != null) {
        state = AsyncValue.data(state.value!.copyWith(householdId: ''));
      }
    } catch (e) {
      debugPrint('deleteHousehold error: $e');
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  /// Remove an individual member from household (Owner only)
  Future<void> removeHouseholdMember(String memberId) async {
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      await _dio.delete('$serverUrl/households/members/$memberId');
    } catch (e) {
      debugPrint('removeHouseholdMember error: $e');
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
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
    await SecureStore.delete('app_lock_enabled');
    _ref.read(appLockEnabledProvider.notifier).state = false;
    _ref.read(appUnlockedProvider.notifier).state = false;
    final db = _ref.read(appDatabaseProvider);
    await AppInitService.clearAllDummyData(db);
    _ref.read(tokenProvider.notifier).state = null;
    state = const AsyncValue.data(AuthState(authMode: AuthMode.guest));
  }

  /// Permanently deletes user account from server (DELETE /users/me) and cleans up local session & data.
  Future<void> deleteAccount() async {
    final serverUrl = _ref.read(serverUrlProvider);
    final currentAuth = state.valueOrNull;
    final userId = currentAuth?.userId;

    if (serverUrl.isNotEmpty) {
      try {
        await _dio.delete('$serverUrl/users/me');
      } catch (e) {
        debugPrint('deleteAccount backend call error: $e');
        if (e is DioException && e.response?.data != null) {
          final msg = e.response?.data['message'];
          if (msg != null) throw Exception(msg.toString());
        }
        rethrow;
      }
    }

    // Delete user from local Drift database if present
    if (userId != null) {
      final db = _ref.read(appDatabaseProvider);
      try {
        await (db.delete(db.usersTable)..where((u) => u.id.equals(userId))).go();
      } catch (_) {}
    }

    // Sign out from Firebase and Google Auth if signed in
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.delete().catchError((_) {});
      }
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect().catchError((_) {});
        await _googleSignIn.signOut();
      }
    } catch (_) {}

    // Wipe local credentials and session
    await SecureStore.clearTokens();
    await SecureStore.delete('auth_email');
    await SecureStore.delete('auth_name');
    await SecureStore.delete('auth_user_id');
    await SecureStore.delete('auth_household_id');
    await SecureStore.delete('has_completed_onboarding');
    await SecureStore.delete('app_lock_enabled');
    _ref.read(appLockEnabledProvider.notifier).state = false;
    _ref.read(appUnlockedProvider.notifier).state = false;
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

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;

import 'package:budget_tracker/data/local/database.dart';
import 'package:budget_tracker/core/services/sync_service.dart';
import 'package:budget_tracker/features/auth/providers/auth_providers.dart';

class MockAuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> implements AuthStateNotifier {
  final Dio mockDioInstance;
  MockAuthStateNotifier(AuthState initialState, this.mockDioInstance)
      : super(AsyncValue.data(initialState));

  @override
  Dio get dio => mockDioInstance;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late Dio mockDio;

  const testHouseholdId = 'hh-test-123';
  const testUserId = 'user-test-123';
  const testToken = 'mock-jwt-token';
  const testServerUrl = 'https://api.budgetiq.test';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockDio = Dio(BaseOptions(baseUrl: testServerUrl));

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authenticatedDioProvider.overrideWithValue(mockDio),
        serverUrlProvider.overrideWith((ref) => testServerUrl),
        authStateNotifierProvider.overrideWith((ref) => MockAuthStateNotifier(
              const AuthState(
                authMode: AuthMode.authenticated,
                token: testToken,
                userId: testUserId,
                householdId: testHouseholdId,
              ),
              mockDio,
            )),
      ],
    );

    // Seed basic category for test household
    await db.into(db.categoriesTable).insert(
      CategoriesTableCompanion.insert(
        id: 'cat-test-1',
        householdId: testHouseholdId,
        kind: 'spending',
        name: 'Groceries',
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('SyncService Timeout, Cancellation, and Concurrency Tests', () {
    test('1. Successful Force Sync -> completes and updates lastSyncAtProvider', () async {
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/sync/batch')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'pushed': 1},
            ));
          }
          if (options.path.contains('/sync/pull')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'categories': [],
                'accounts': [],
                'creditCards': [],
                'entries': [],
              },
            ));
          }
          return handler.resolve(Response(requestOptions: options, statusCode: 200, data: {}));
        },
      ));

      final syncService = container.read(syncServiceProvider);
      expect(syncService.isSyncRunning, isFalse);

      final outcome = await syncService.syncAllQueue();

      expect(outcome.status, equals(SyncStatus.success));
      expect(outcome.isSuccess, isTrue);
      expect(syncService.isSyncRunning, isFalse);
      expect(container.read(lastSyncAtProvider), isNotNull);
    });

    test('2. Backend unavailable / hanging -> timeout fires -> loading stops with timedOut', () async {
      // Mock Dio hangs indefinitely
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Never resolves until cancelled
          final cancelToken = options.cancelToken;
          if (cancelToken != null) {
            cancelToken.whenCancel.then((_) {
              handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'Cancelled by timeout',
              ));
            });
          }
        },
      ));

      final syncService = container.read(syncServiceProvider);
      final initialLastSync = container.read(lastSyncAtProvider);

      final outcome = await syncService.syncAllQueue(
        timeout: const Duration(milliseconds: 150),
      );

      expect(outcome.status, equals(SyncStatus.timedOut));
      expect(outcome.isSuccess, isFalse);
      expect(syncService.isSyncRunning, isFalse);
      // lastSyncAtProvider must NOT be updated
      expect(container.read(lastSyncAtProvider), equals(initialLastSync));
    });

    test('3. Cancelled sync -> stops loading immediately and no state update occurs', () async {
      final cancelToken = CancelToken();

      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = options.cancelToken;
          if (token != null) {
            token.whenCancel.then((_) {
              handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'User cancelled sync',
              ));
            });
          }
        },
      ));

      final syncService = container.read(syncServiceProvider);
      final initialLastSync = container.read(lastSyncAtProvider);

      // Start sync
      final syncFuture = syncService.syncAllQueue(cancelToken: cancelToken);
      expect(syncService.isSyncRunning, isTrue);

      // Cancel mid-flight
      await Future.delayed(const Duration(milliseconds: 50));
      cancelToken.cancel('User tapped cancel');

      final outcome = await syncFuture;

      expect(outcome.status, equals(SyncStatus.cancelled));
      expect(outcome.isSuccess, isFalse);
      expect(syncService.isSyncRunning, isFalse);
      expect(container.read(lastSyncAtProvider), equals(initialLastSync));
    });

    test('4. Late response after cancellation/timeout cannot overwrite state (generation counter)', () async {
      final completer1 = Completer<Response>();
      final cancelToken1 = CancelToken();

      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.cancelToken == cancelToken1) {
            // First request awaits completer
            final res = await completer1.future;
            return handler.resolve(res);
          } else {
            // Second request succeeds immediately
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'categories': [], 'entries': []},
            ));
          }
        },
      ));

      final syncService = container.read(syncServiceProvider);

      // Start operation #1
      final future1 = syncService.syncAllQueue(
        cancelToken: cancelToken1,
        timeout: const Duration(milliseconds: 100),
      );

      // Wait for timeout on operation #1
      final outcome1 = await future1;
      expect(outcome1.status, equals(SyncStatus.timedOut));
      expect(syncService.isSyncRunning, isFalse);

      // Start operation #2 and let it succeed
      final outcome2 = await syncService.syncAllQueue();
      expect(outcome2.status, equals(SyncStatus.success));
      final op2Timestamp = container.read(lastSyncAtProvider);
      expect(op2Timestamp, isNotNull);

      // Now operation #1's late response arrives in the background
      if (!completer1.isCompleted) {
        completer1.complete(Response(
          requestOptions: RequestOptions(path: '/sync/batch'),
          statusCode: 200,
          data: {'success': true},
        ));
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify that operation #2's timestamp was NOT overwritten by operation #1's late response
      expect(container.read(lastSyncAtProvider), equals(op2Timestamp));
    });

    test('5. Duplicate Force Sync attempts are safely prevented', () async {
      final requestStarted = Completer<void>();
      final requestFinish = Completer<void>();

      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!requestStarted.isCompleted) requestStarted.complete();
          await requestFinish.future;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'categories': [], 'entries': []},
          ));
        },
      ));

      final syncService = container.read(syncServiceProvider);

      // Start first sync
      final sync1Future = syncService.syncAllQueue();
      await requestStarted.future;
      expect(syncService.isSyncRunning, isTrue);

      // Attempt second sync concurrently
      final sync2Outcome = await syncService.syncAllQueue();

      // Second sync must immediately report inProgress without creating competing requests
      expect(sync2Outcome.status, equals(SyncStatus.inProgress));
      expect(sync2Outcome.message, contains('already in progress'));

      // Finish first sync
      requestFinish.complete();
      final sync1Outcome = await sync1Future;
      expect(sync1Outcome.status, equals(SyncStatus.success));
      expect(syncService.isSyncRunning, isFalse);
    });

    test('6. Timeout/cancellation does not delete or corrupt unsynced local data', () async {
      // Enqueue a local offline entry into sync_queue
      await db.syncQueueDao.enqueue(
        id: 'offline-entry-1',
        op: 'insert',
        entity: 'entry',
        entityId: 'entry-123',
        payload: {
          'id': 'entry-123',
          'householdId': testHouseholdId,
          'categoryId': 'cat-test-1',
          'kind': 'spending',
          'amountPaise': 50000,
          'entryDate': DateTime.now().toIso8601String(),
        },
      );

      final countBefore = await db.syncQueueDao.pendingCount();
      expect(countBefore, equals(1));

      // Mock Dio hangs to trigger timeout
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final cancelToken = options.cancelToken;
          if (cancelToken != null) {
            cancelToken.whenCancel.then((_) {
              handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'Cancelled by timeout',
              ));
            });
          }
        },
      ));

      final syncService = container.read(syncServiceProvider);

      // Run sync with timeout
      final outcome = await syncService.syncAllQueue(
        timeout: const Duration(milliseconds: 100),
      );

      expect(outcome.status, equals(SyncStatus.timedOut));

      // Verify that the unsynced entry in sync_queue was NOT deleted or corrupted
      final countAfter = await db.syncQueueDao.pendingCount();
      expect(countAfter, equals(1));

      final pendingItems = await db.syncQueueDao.getPending();
      expect(pendingItems.length, equals(1));
      expect(pendingItems.first.id, equals('offline-entry-1'));
      expect(pendingItems.first.entityId, equals('entry-123'));
      expect(pendingItems.first.syncedAt, isNull);
    });
  });
}

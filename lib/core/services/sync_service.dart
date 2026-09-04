import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/entry.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../data/local/database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

class SyncService {
  final Ref _ref;
  final _dio = Dio();
  final Connectivity _connectivity = Connectivity();

  SyncService(this._ref) {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        syncAllQueue();
      }
    });
  }

  Future<void> syncEntry(Entry entry) async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    if (authState == null || authState.authMode != AuthMode.authenticated) {
      print('Offline mode: sync skipped.');
      return;
    }

    final token = authState.token;
    if (token == null) return;

    try {
      final payload = {
        'id': entry.id,
        'categoryId': entry.categoryId,
        'kind': entry.kind.name,
        'accountId': entry.accountId,
        'cardId': entry.cardId,
        'entryDate': entry.entryDate.toIso8601String(),
        'amountPaise': entry.amount.paise,
        'note': entry.note,
        'parentId': entry.parentId,
        'version': entry.version,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
      };

      await _dio.post(
        '$serverUrl/entries/batch',
        data: [payload],
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('Sync successful for entry ${entry.id}');
    } catch (e) {
      print('Sync failed: $e. Leaving in offline queue.');
    }
  }

  Future<int> syncAllQueue() async {
    final db = _ref.read(appDatabaseProvider);
    final pending = await db.syncQueueDao.getPending();
    if (pending.isEmpty) return 0;

    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    if (authState == null || authState.authMode != AuthMode.authenticated) {
      print('Offline mode: sync all skipped.');
      return 0;
    }

    final token = authState.token;
    if (token == null) return 0;

    int successCount = 0;
    for (final op in pending) {
      if (op.entity == 'entry') {
        try {
          final payload = jsonDecode(op.payload);
          if (op.op == 'insert') {
            await _dio.post(
              '$serverUrl/entries/batch',
              data: [payload],
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                },
              ),
            );
          }
          await db.syncQueueDao.markSynced(op.id);
          successCount++;
        } catch (e) {
          print('Failed to sync op ${op.id}: $e');
        }
      }
    }
    return successCount;
  }
}

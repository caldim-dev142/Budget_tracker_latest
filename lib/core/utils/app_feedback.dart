import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Centralized UI feedback service for consistent SnackBars, error messages,
/// and confirmation dialogs across the mobile app.
class AppFeedback {
  AppFeedback._();

  /// Converts any technical error, exception, or API response into a
  /// human-friendly, actionable user message.
  static String formatError(Object? error) {
    if (error == null) return 'An unexpected issue occurred. Please try again.';

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet connection.';
        case DioExceptionType.connectionError:
          return 'Unable to reach the server. Please verify your connection or server status.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final resData = error.response?.data;
          String? serverMsg;
          if (resData is Map && resData.containsKey('message')) {
            final m = resData['message'];
            serverMsg = m is List ? m.join(', ') : m.toString();
          } else if (resData is String && resData.isNotEmpty) {
            serverMsg = resData;
          }

          if (statusCode == 401) {
            return serverMsg ?? 'Session expired or invalid credentials. Please sign in again.';
          } else if (statusCode == 403) {
            return serverMsg ?? 'Access denied. You do not have permission for this action.';
          } else if (statusCode == 404) {
            return serverMsg ?? 'Requested information or resource was not found.';
          } else if (statusCode == 409) {
            return serverMsg ?? 'A conflict occurred. This record or item may already exist.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'The server encountered an error ($statusCode). Please try again in a few moments.';
          }
          return serverMsg ?? 'Server error ($statusCode). Please try again.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return error.message ?? 'Network connection error. Please try again.';
      }
    }

    if (error is SocketException) {
      return 'Network unreachable. Please check your Wi-Fi or mobile data.';
    }

    if (error is TimeoutException) {
      return 'The operation timed out. Please try again.';
    }

    final raw = error.toString().trim();

    // Clean up common technical prefixes
    var cleaned = raw
        .replaceAll(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^Error:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^PlatformException\([^)]*\):\s*', caseSensitive: false), '');

    final lower = cleaned.toLowerCase();

    // Specific database & business constraint patterns
    if (lower.contains('foreign key') || lower.contains('fk constraint')) {
      return 'Unable to save this entry because a related item (such as category or account) is no longer available.';
    }

    if (lower.contains('unique constraint') || lower.contains('already exists')) {
      return 'An entry with these details already exists. Please review and try again.';
    }

    if (lower.contains('database is locked') || lower.contains('busy')) {
      return 'Database is busy. Please try your action again in a moment.';
    }

    if (lower.contains('database') ||
        lower.contains('sqlite') ||
        lower.contains('drift')) {
      return 'Database operation failed. Your changes were safely kept and will retry.';
    }

    if (lower.contains('connection refused') || lower.contains('failed host lookup')) {
      return 'Unable to reach the server. Please check your network connection and server settings.';
    }

    if (cleaned.isEmpty) {
      return 'An unexpected issue occurred. Please try again.';
    }

    // Capitalize first letter
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  /// Shows a modern floating success SnackBar.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20), // Deep Forest Green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: duration,
          action: action,
        ),
      );
  }

  /// Shows a modern floating error SnackBar with user-friendly formatting.
  static void showError(
    BuildContext context,
    String message, {
    Object? error,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    final detailedError = error != null ? formatError(error) : null;
    final text = detailedError != null ? '$message: $detailedError' : message;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFC62828), // Dark Red
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: duration,
          action: action,
        ),
      );
  }

  /// Shows a modern floating warning SnackBar.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.black87, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFFB74D), // Amber
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: duration,
        ),
      );
  }

  /// Shows a modern floating informational SnackBar.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1976D2), // Blue
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: duration,
        ),
      );
  }

  /// Shows a standardized confirmation dialog for destructive or significant actions.
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isDestructive ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }
}

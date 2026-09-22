import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';

/// Emits `true` if network connectivity (wifi/mobile/ethernet) is active, `false` otherwise.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  });
});

/// Subtle offline status banner shown when the device loses internet connectivity.
class OfflineBanner extends ConsumerWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the persisted last-sync timestamp once so health is accurate on
    // a cold start rather than defaulting to "never synced".
    ref.watch(lastSyncBootstrapProvider);

    final isOffline = ref.watch(isOnlineProvider).valueOrNull == false;
    final health = ref.watch(syncHealthProvider);

    // IMPORTANT: this banner used to read radio connectivity ONLY, and said
    // "Local data will sync automatically" — reassuring wording that stayed on
    // screen even when every sync had been failing for weeks. Connectivity is
    // not the same thing as "your data reached the server", so sync health now
    // takes priority over the offline state.
    _BannerSpec? spec;
    if (health == SyncHealth.stale) {
      // Highest priority: un-backed-up data outranks a mere connectivity blip.
      spec = _BannerSpec(
        color: Colors.red.shade700,
        icon: Icons.warning_amber_rounded,
        text: 'Not backed up • Your data is only on this phone',
      );
    } else if (isOffline) {
      spec = _BannerSpec(
        color: Colors.amber.shade800,
        icon: Icons.cloud_off_rounded,
        text: 'Working Offline • Changes will sync when you reconnect',
      );
    } else if (health == SyncHealth.pending) {
      spec = _BannerSpec(
        color: Colors.blueGrey.shade600,
        icon: Icons.cloud_upload_outlined,
        text: 'Backing up your changes…',
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                spec != null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              color: spec?.color ?? Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(spec?.icon ?? Icons.cloud_off_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        spec?.text ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Visual description of whichever status banner is currently warranted.
class _BannerSpec {
  final Color color;
  final IconData icon;
  final String text;

  const _BannerSpec({
    required this.color,
    required this.icon,
    required this.text,
  });
}

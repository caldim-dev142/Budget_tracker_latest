import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

/// UTC offset in minutes for displaying dates/times across the app.
/// Default: 330 = IST (UTC+5:30). User can change in Settings.
final timezoneOffsetProvider = StateProvider<int>((_) => 330);

/// Timezone ID string for display in the Settings picker.
/// Default: 'Asia/Kolkata'
final selectedTimezoneIdProvider = StateProvider<String>((_) => 'Asia/Kolkata');

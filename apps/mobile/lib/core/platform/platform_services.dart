import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Thin wrappers over plugins, so widget tests can swap them for fakes.

/// Keeps the screen from sleeping.
class ScreenAwake {
  const ScreenAwake();
  Future<void> enable() => WakelockPlus.enable();
  Future<void> disable() => WakelockPlus.disable();
}

/// The phone's share sheet.
class Sharing {
  const Sharing();
  Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

/// Opens links in other apps (WhatsApp, email, the browser).
class Launcher {
  const Launcher();
  Future<bool> canOpen(Uri uri) => canLaunchUrl(uri);
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

final screenAwakeProvider = Provider<ScreenAwake>((ref) => const ScreenAwake());
final sharingProvider = Provider<Sharing>((ref) => const Sharing());
final launcherProvider = Provider<Launcher>((ref) => const Launcher());

/// "1.2.0 (14)".
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// Whether to draw glass as solid surfaces: Android phones that report low memory or
/// have 3 GB of RAM or less (spec section 2).
final solidSurfacesProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isAndroid) return false;
  final info = await DeviceInfoPlugin().androidInfo;
  return info.isLowRamDevice || info.physicalRamSize <= 3072;
});

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceFingerprint {
  final String osVersion;
  final String model;
  final String manufacturer;
  final String isPhysicalDevice;

  DeviceFingerprint({
    required this.osVersion,
    required this.model,
    required this.manufacturer,
    required this.isPhysicalDevice,
  });
}

final deviceFingerprintProvider = FutureProvider<DeviceFingerprint>((ref) async {
  final deviceInfo = DeviceInfoPlugin();
  
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return DeviceFingerprint(
      osVersion: 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
      model: androidInfo.model,
      manufacturer: androidInfo.manufacturer,
      isPhysicalDevice: androidInfo.isPhysicalDevice ? 'Yes' : 'No (EMULATOR NOT ALLOWED)',
    );
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return DeviceFingerprint(
      osVersion: '${iosInfo.systemName} ${iosInfo.systemVersion}',
      model: iosInfo.utsname.machine,
      manufacturer: 'Apple',
      isPhysicalDevice: iosInfo.isPhysicalDevice ? 'Yes' : 'No (EMULATOR NOT ALLOWED)',
    );
  }
  
  return DeviceFingerprint(
    osVersion: Platform.operatingSystemVersion,
    model: 'Unknown Desktop/Web',
    manufacturer: 'Unknown',
    isPhysicalDevice: 'Unknown',
  );
});

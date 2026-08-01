import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> hasInternetConnection() async {
    try {
      final dynamic result = await Connectivity().checkConnectivity();

      if (result is List<ConnectivityResult>) {
        final hasUsableNetwork = result.any((r) => r != ConnectivityResult.none);
        if (!hasUsableNetwork) return false;
      } else if (result == ConnectivityResult.none) {
        return false;
      }

      final lookup = await InternetAddress.lookup('jssolutions-eg.com')
          .timeout(const Duration(seconds: 5));

      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

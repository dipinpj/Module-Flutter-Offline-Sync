import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Network utility functions for checking connectivity and internet availability
class NetworkUtils {
  /// Check if internet is available
  static Future<bool> isInternetAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Additional check by trying to reach a reliable endpoint
      try {
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(Duration(seconds: 5));
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check internet connectivity and show alert dialog if not available
  static Future<bool> checkInternetAndAlert(BuildContext context) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // Show alert dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Internet'),
            content: const Text(
                'Please check your internet connection and try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    return true; // Internet is available
  }

  /// Get connectivity status
  static Future<ConnectivityResult> getConnectivityStatus() async {
    return await Connectivity().checkConnectivity();
  }

  static Stream<ConnectivityResult> get connectivityStream {
    
    return Connectivity().onConnectivityChanged;
  }
}

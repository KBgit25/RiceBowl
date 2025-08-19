
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:rice_bowl_deluxe/screen/web_view_screen.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Request tracking permission on iOS
    if (Platform.isIOS) {
      await _requestTrackingPermission();
    }

    // Navigate to webview
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
      );
    }
  }

  Future<void> _requestTrackingPermission() async {
    try {
      // Get current tracking authorization status
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;

      // If status is not determined, request permission
      if (status == TrackingStatus.notDetermined) {
        final requestStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        print('Tracking authorization status: $requestStatus');

        // Handle the response
        switch (requestStatus) {
          case TrackingStatus.authorized:
            print('User authorized tracking');
            break;
          case TrackingStatus.denied:
            print('User denied tracking');
            break;
          case TrackingStatus.restricted:
            print('Tracking is restricted');
            break;
          case TrackingStatus.notDetermined:
            print('Tracking status not determined');
            break;
          case TrackingStatus.notSupported:
              print('Tracking status not determined');
              break;
        }
      } else {
        print('Tracking authorization status already determined: $status');
      }
    } catch (e) {
      print('Error requesting tracking permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/splashimage.png",
              width: 380,
              height: 400,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
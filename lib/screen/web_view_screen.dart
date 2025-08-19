import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool trackingAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
    _initializeWebView();
  }

  Future<void> _checkTrackingStatus() async {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      setState(() {
        trackingAllowed = status == TrackingStatus.authorized;
      });
    } else {
      // On Android, we assume tracking is allowed unless user opts out
      setState(() {
        trackingAllowed = true;
      });
    }
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar if needed
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });

            // Inject JavaScript to handle cookies based on tracking permission
            _handleCookieConsent();
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://app.ricebowldeluxe.com/'));
  }

  Future<void> _handleCookieConsent() async {
    // If tracking is not allowed, inject JavaScript to disable tracking cookies
    if (!trackingAllowed) {
      const jsCode = '''
        // Disable tracking cookies
        document.cookie.split(";").forEach(function(c) { 
          document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); 
        });
        
        // Block Google Analytics if present
        if (typeof gtag !== 'undefined') {
          gtag('config', 'GA_MEASUREMENT_ID', {
            'anonymize_ip': true,
            'allow_ad_personalization_signals': false
          });
        }
        
        // Disable other common tracking
        if (typeof _gaq !== 'undefined') {
          _gaq = [];
        }
      ''';

      try {
        await controller.runJavaScript(jsCode);
        print('Cookie blocking JavaScript injected');
      } catch (e) {
        print('Error injecting JavaScript: $e');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) {
      controller.goBack();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Rice Bowl Deluxe'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await controller.canGoBack()) {
                controller.goBack();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (Platform.isIOS)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'privacy') {
                    _showPrivacyDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip),
                        SizedBox(width: 8),
                        Text('Privacy Settings'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tracking Status: ${trackingAllowed ? "Allowed" : "Blocked"}'),
              const SizedBox(height: 10),
              const Text(
                'To change tracking permissions, please go to Settings > Privacy & Security > Tracking on your device.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
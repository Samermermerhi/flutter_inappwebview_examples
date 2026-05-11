import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: PayhipApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class PayhipApp extends StatefulWidget {
  const PayhipApp({super.key});

  @override
  State<PayhipApp> createState() => _PayhipAppState();
}

class _PayhipAppState extends State<PayhipApp> {
  InAppWebViewController? webViewController;

  // --- CONFIGURATION: REPLACE THIS URL ---
  final String myStoreUrl = "https://yourcustomdomain.com"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(myStoreUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
            supportMultipleWindows: true, // Crucial for PayPal/Stripe popups
            javaScriptCanOpenWindowsAutomatically: true,
            // Forces Google/Facebook to allow the login by mimicking a real browser
            userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
            allowsInlineMediaPlayback: true, // For YouTube videos
          ),
          
          // Handles YouTube and other external app links
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url!;
            
            // Check if it is a YouTube link
            if (uri.host.contains("youtube.com") || uri.host.contains("youtu.be")) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              }
            }

            // Allow standard web navigation
            if (["http", "https"].contains(uri.scheme)) {
              return NavigationActionPolicy.ALLOW;
            }

            // Try to open other apps (Mail, Phone, etc)
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
              return NavigationActionPolicy.CANCEL;
            }
            
            return NavigationActionPolicy.ALLOW;
          },

          // Handles the actual popup windows for payments
          onCreateWindow: (controller, createWindowAction) async {
            showDialog(
              context: context,
              builder: (context) {
                return WindowPopup(createWindowAction: createWindowAction);
              },
            );
            return true;
          },
        ),
      ),
    );
  }
}

// Widget to display the payment popup (PayPal/Stripe)
class WindowPopup extends StatelessWidget {
  final CreateWindowAction createWindowAction;
  const WindowPopup({super.key, required this.createWindowAction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Payment"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InAppWebView(
        windowId: createWindowAction.windowId,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
        ),
      ),
    );
  }
}

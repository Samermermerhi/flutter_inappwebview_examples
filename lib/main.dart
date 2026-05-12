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
  
  // 1. CHANGE THIS to your custom domain
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
            // 2. PayPal/Stripe support: allows payment windows to open
            supportMultipleWindows: true, 
            javaScriptCanOpenWindowsAutomatically: true,
            // 3. Google/FB Login fix: mimics a real mobile browser
            userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
            allowsInlineMediaPlayback: true, 
          ),
          
          // 4. Handles YouTube App redirects
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url!;
            if (uri.host.contains("youtube.com") || uri.host.contains("youtu.be")) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              }
            }
            return NavigationActionPolicy.ALLOW;
          },

          // 5. Handles actual payment popup windows (PayPal/Stripe)
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

// Widget to handle Secure Payment Popups
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

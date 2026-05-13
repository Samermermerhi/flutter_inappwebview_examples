import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // --- KEEP YOUR EXISITING HARDCODED KEYS HERE ---
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBxgD6VGgZjma-NplKABakpP6bWAbspBo4",                
        appId: "1:25389115383:android:b1cda09502be3caed2b0f2",   
        messagingSenderId: "25389115383",      
        projectId: "payhip-store-app",   
      ),
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await FirebaseMessaging.instance.subscribeToTopic("marketing");
    }
  } catch (e) {
    debugPrint("Firebase connection failed: $e");
  }

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
  
  // Update this to your real custom domain (.com)
  final String myStoreUrl = "https://samermerhi.com"; 

  @override
  void initState() {
    super.initState();
    _setupNotificationInteractions();
  }

  // Listens for notification taps and forces the WebView to redirect
  void _setupNotificationInteractions() async {
    // 1. Handles tap when the app was COMPLETELY CLOSED
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageRedirect(initialMessage);
    }

    // 2. Handles tap when the app was in the BACKGROUND / MINIMIZED
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageRedirect(message);
    });

    // 3. NEW ADDITION: Listens for notifications while the app is OPEN on the screen
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Displays a native, clean pop-up dialog box right over your website view
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(message.notification!.title ?? "Notification"),
            content: Text(message.notification!.body ?? ""),
            actions: [
              TextButton(
                child: const Text("Dismiss"),
                onPressed: () => Navigator.pop(context),
              ),
              if (message.data.containsKey('url'))
                TextButton(
                  child: const Text("View"),
                  onPressed: () {
                    Navigator.pop(context);
                    _handleMessageRedirect(message);
                  },
                ),
            ],
          ),
        );
      }
    });
  }


  void _handleMessageRedirect(RemoteMessage message) {
    // Looks for a custom web link attached to the notification data payload
    if (message.data.containsKey('url')) {
      String? targetUrl = message.data['url'];
      if (targetUrl != null && webViewController != null) {
        webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(targetUrl)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(myStoreUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
            supportMultipleWindows: true,
            javaScriptCanOpenWindowsAutomatically: true,
            userAgent: "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
            allowsInlineMediaPlayback: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
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
          onCreateWindow: (controller, createWindowAction) async {
            showDialog(
              context: context,
              builder: (context) => WindowPopup(createWindowAction: createWindowAction),
            );
            return true;
          },
        ),
      ),
    );
  }
}

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

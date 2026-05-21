import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'payment_receipt_page.dart';
import 'payment_types.dart';

// Only import webview for non-web platforms
import 'package:webview_flutter/webview_flutter.dart' 
    show WebViewController, JavaScriptMode, NavigationDelegate, WebResourceError, WebViewWidget;

class PaymobPaymentPage extends StatefulWidget {
  final bool isYearly;
  final double amount;
  final PaymentMethodType method;
  final String methodTitle;

  const PaymobPaymentPage({
    super.key,
    required this.isYearly,
    required this.amount,
    required this.method,
    required this.methodTitle,
  });

  @override
  State<PaymobPaymentPage> createState() => _PaymobPaymentPageState();
}

class _PaymobPaymentPageState extends State<PaymobPaymentPage> {
  late WebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  // Paymob payment links
  static const String _monthlyLink = 'https://paymob.link/xbSLf';
  static const String _yearlyLink = 'https://paymob.link/0Ew5Q';

  String get _paymentLink => widget.isYearly ? _yearlyLink : _monthlyLink;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _launchPaymentWeb();
    } else {
      _initializeWebView();
    }
  }

  /// Launch payment link in browser on web platform
  Future<void> _launchPaymentWeb() async {
    try {
      final Uri url = Uri.parse(_paymentLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Simulate payment completion after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _completePayment();
        }
      } else {
        setState(() {
          _errorMessage = 'Could not launch payment link';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Initialize WebView for mobile platforms
  void _initializeWebView() {
    if (kIsWeb) return;
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkForPaymentSuccess(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_paymentLink));
  }

  void _checkForPaymentSuccess(String url) {
    // Check if payment was successful based on URL patterns
    if (url.contains('success') || 
        url.contains('complete') || 
        url.contains('finish') ||
        url.contains('invoice')) {
      _completePayment();
    }
  }

  Future<void> _completePayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        final planType = widget.isYearly ? 'yearly' : 'monthly';
        await ApiService.subscribeUser(userId, planType);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => PaymentReceiptPage(
            method: widget.method,
            amount: widget.amount,
            methodTitle: widget.methodTitle,
            isYearly: widget.isYearly,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      print('Error completing payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version - payment opened in external browser
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          elevation: 0,
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.payment_rounded,
                  size: 64,
                  color: Color(0xFFFF6B00),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment opened in browser',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Complete your payment and you\'ll be automatically redirected back',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _errorMessage = null);
                      _launchPaymentWeb();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile version - WebView
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          elevation: 0,
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              if (_webViewController != null) {
                final canGoBack = await _webViewController!.canGoBack();
                if (canGoBack) {
                  await _webViewController!.goBack();
                } else {
                  if (mounted) Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            if (_webViewController != null)
              WebViewWidget(controller: _webViewController!),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFFF6B00),
                  ),
                ),
              ),
            if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, 
                      color: Colors.red, 
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeWebView,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}


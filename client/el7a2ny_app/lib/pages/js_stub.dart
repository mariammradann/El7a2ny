// lib/pages/js_stub.dart
// Stub implementation of dart:js for non-web platforms (VM tests, mobile, desktop).
// On Web, the real `dart:js` is used via the conditional import in security_camera_page.dart.

/// A no-op stand-in for `js.JsObject` so that `js.context.callMethod(...)` compiles on VM.
class _JsContextStub {
  void callMethod(String method, [List<dynamic>? args]) {
    // No-op on non-web platforms
  }
}

// Expose as `context` to match the `dart:js` API surface used in the page.
final context = _JsContextStub();

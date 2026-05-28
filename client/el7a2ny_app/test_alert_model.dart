import 'lib/models/alert_model.dart';
import 'dart:convert';
import 'dart:ui' as ui;

void main() {
  String jsonStr = '''
  {"incident_id":"3d21064c-9617-495f-ab01-836eafbba81d","user":"fef5bed0-1c2e-4a04-bb5c-e5c590c3dcf1","reporter_name":"yousef ahmed","category":"accident","description":"helppppp","media_files":["/media/reports/fef5bed0-1c2e-4a04-bb5c-e5c590c3dcf1/upload_0_24SpgVC.jpg"],"status":"reported","created_at":"2026-05-28T10:59:50+0300","admin_id":null,"daleel_id":null,"lat":29.9651231,"lng":31.2592793,"address":null,"current_volunteers":1,"total_volunteers":8,"ai_analysis":{"analysis_id":"91808c78-6866-4"}}
  ''';
  var json = jsonDecode(jsonStr);
  try {
    var model = AlertModel.fromJson(json);
    print('Success: ${model.id}');
  } catch (e, stack) {
    print('Exception: $e');
    print('Stacktrace: $stack');
  }
}

import 'dart:convert';

void main() {
  String jsonStr = '[{"id":"b459786e-dc60-4378-8128-6f9392880deb","user_id":"2bb56e10-b0c8-4d46-bbcc-15eb981bbf1e","name":"ali hany","phone":"01022333333","lat":29.965168977509204,"lng":31.25931111488887,"response_time":"0:00:03","badges":[]}]';
  
  try {
    List data = jsonDecode(jsonStr);
    List<Map<String, dynamic>> typedData = data.cast<Map<String, dynamic>>();
    // Force lazily evaluated cast to happen
    print('Cast success: ${typedData.length}');
    print('First element: ${typedData[0]['name']}');
  } catch (e) {
    print('Exception: $e');
  }
}

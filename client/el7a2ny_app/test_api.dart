import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  String baseUrl = 'http://127.0.0.1:8000';
  String incidentId = 'f09e4864-2e78-404a-adcd-1fae000772bd';
  
  try {
    print('Fetching incident details...');
    var res1 = await http.get(Uri.parse('$baseUrl/api/incidents/$incidentId/?_t=1'));
    print('Details Status: ${res1.statusCode}');
    if (res1.statusCode == 200) {
      print('Details JSON keys: ${jsonDecode(res1.body).keys}');
    }
    
    print('Fetching responders...');
    var res2 = await http.get(Uri.parse('$baseUrl/alerts/$incidentId/responders/?_t=1'));
    print('Responders Status: ${res2.statusCode}');
    if (res2.statusCode == 200) {
      var list = jsonDecode(res2.body) as List;
      print('Responders Count: ${list.length}');
      if (list.isNotEmpty) {
         print('First Responder Name: ${list[0]['name']}');
      }
    }
  } catch (e) {
    print('Exception: $e');
  }
}

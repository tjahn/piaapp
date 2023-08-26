import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsRequest {
  static Future<void> send(String phoneNumber) async {
    final url = Uri.parse(
        'https://xyycvixsvh.execute-api.eu-central-1.amazonaws.com/Prod/sms');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({"phoneNumber": phoneNumber});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print('Response: ${response.body}');
    } else {
      print('Status code: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  }
}

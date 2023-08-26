import 'dart:convert';

import 'package:http/http.dart' as http;

class SmsRequest {
  SmsRequest() {}

  Future<String> send(String phoneNumber) async {
    final Uri url = Uri.parse(
        'https://xyycvixsvh.execute-api.eu-central-1.amazonaws.com/Prod/sms');
    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({"phoneNumber": phoneNumber});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("http invalid status code ${response.statusCode}");
    }
  }
}

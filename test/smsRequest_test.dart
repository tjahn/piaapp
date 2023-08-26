import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../lib/utils/smsRequest.dart';

void main() {
  group('ApiHelper', () {
    final client = SmsRequest();

    test('sendPostRequest returns successfully', () async {
      final phoneNumber = '+41792703030';
      final expectedUrl = Uri.parse('https://xyycvixsvh.execute-api.eu-central-1.amazonaws.com/Prod/sms');
      final expectedHeaders = {'Content-Type': 'application/json'};
      final expectedBody = '{"phonenumber":"$phoneNumber"}';

      final response = await SmsRequest.send(phoneNumber);
    });
  });
}

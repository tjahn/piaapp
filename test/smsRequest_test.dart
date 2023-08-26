import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../lib/utils/smsRequest.dart';

void main() {
  group('ApiHelper', () {
    final client = SmsRequest();

    test('sendPostRequest returns successfully', () async {
      final phoneNumber = '+41792703030';
      final response = await SmsRequest().send(phoneNumber);
    });
  });
}

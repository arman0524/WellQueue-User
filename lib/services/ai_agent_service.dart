import 'dart:convert';
import 'package:http/http.dart' as http;

class AIAgentService {
  static Future<bool> triggerAIAgentCall({
    required String clinicName,
    required String language,
  }) async {
    try {
      // TODO: Replace with your actual Make.com / Zapier / custom webhook URL
      const String webhookUrl = 'https://hook.us1.make.com/your-webhook-id';

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clinic_name': clinicName,
          'action': 'book_appointment',
          'language': language,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

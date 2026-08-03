import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AIAgentService {
  static Future<bool> triggerAIAgentCall({
    required String clinicName,
    required String clinicId,
    required String language,
  }) async {
    try {
      // Fetch real user details from Supabase
      final user = Supabase.instance.client.auth.currentUser;
      String userName = 'Patient';
      String userPhone = '';
      String userEmail = user?.email ?? '';

      if (user != null) {
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();
          
          userName = profileData['full_name'] ?? 'Patient';
          userPhone = profileData['phone_number'] ?? '';
          
          if (userPhone.isNotEmpty) {
            // Clean up the number (remove spaces, dashes)
            userPhone = userPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
            
            // Format to E.164 if missing country code
            if (!userPhone.startsWith('+')) {
              if (userPhone.length == 10) {
                userPhone = '+91$userPhone'; // Assume India +91 for 10-digit numbers
              } else {
                userPhone = '+$userPhone'; // Otherwise just prepend +
              }
            }
          }
        } catch (e) {
          print('Error fetching profile: $e');
        }
      }

      // Make.com webhook URL
      const String webhookUrl = 'https://hook.eu1.make.com/egtkqbewvypifulq5v20ult51uz7mfi0';

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clinic_name': clinicName,
          'clinic_id': clinicId,
          'action': 'book_appointment',
          'language': language,
          'timestamp': DateTime.now().toIso8601String(),
          'user_name': userName,
          'user_id': user?.id ?? '',
          'user_phone': userPhone,
          'user_email': userEmail,
          'from_number': '+18313195803',
        }),
      );

      print('Webhook Response Status: ${response.statusCode}');
      print('Webhook Response Body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202;
    } catch (e) {
      print('Webhook Exception: $e');
      return false;
    }
  }
}

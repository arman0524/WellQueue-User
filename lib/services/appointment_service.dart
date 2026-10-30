import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Book a new appointment manually
  static Future<Map<String, dynamic>> bookAppointment({
    required String clinicId,
    required String appointmentDate,
    required String appointmentTime,
    required String consultationType,
    String? patientName,
    String? patientPhone,
    String? patientEmail,
    String? relationship,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in. Please sign in to book an appointment.');
    }

    String resolvedPatientName = patientName?.trim() ?? '';
    String resolvedPatientPhone = patientPhone?.trim() ?? '';
    String resolvedPatientEmail = patientEmail?.trim() ?? (user.email ?? '');

    if (resolvedPatientName.isEmpty || resolvedPatientPhone.isEmpty) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('full_name, phone_number')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          if (resolvedPatientName.isEmpty) {
            resolvedPatientName = profile['full_name'] ?? '';
          }
          if (resolvedPatientPhone.isEmpty) {
            resolvedPatientPhone = profile['phone_number'] ?? '';
          }
        }
      } catch (e) {
        debugPrint('Could not fetch user profile details: $e');
      }
    }

    if (resolvedPatientName.isEmpty) {
      resolvedPatientName = user.userMetadata?['full_name'] ??
          (user.email != null && user.email!.contains('@')
              ? user.email!.split('@').first
              : 'Patient');
    }

    final appointmentData = {
      'user_id': user.id,
      'clinic_id': clinicId,
      'patient_name': resolvedPatientName,
      'patient_phone': resolvedPatientPhone,
      'patient_email': resolvedPatientEmail,
      'relationship': relationship ?? 'self',
      'consultation_type': consultationType,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'status': 'upcoming',
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await _supabase
        .from('appointments')
        .insert(appointmentData)
        .select('*, clinics(name, image_url, address, category)')
        .single();

    return response;
  }

  /// Fetch all appointments for the current user, ordered by date descending.
  static Future<List<Map<String, dynamic>>> fetchAppointments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('appointments')
          .select('*, clinics(name, image_url, address, category)')
          .eq('user_id', user.id)
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  /// Fetch only upcoming appointments.
  static Future<List<Map<String, dynamic>>> fetchUpcomingAppointments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = await _supabase
          .from('appointments')
          .select('*, clinics(name, image_url, address, category)')
          .eq('user_id', user.id)
          .eq('status', 'upcoming')
          .gte('appointment_date', today)
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching upcoming appointments: $e');
      return [];
    }
  }

  /// Fetch past and cancelled appointments.
  static Future<List<Map<String, dynamic>>> fetchPastAppointments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = await _supabase
          .from('appointments')
          .select('*, clinics(name, image_url, address, category)')
          .eq('user_id', user.id)
          .or('status.eq.completed,status.eq.cancelled,appointment_date.lt.$today')
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching past appointments: $e');
      return [];
    }
  }

  /// Cancel an appointment.
  static Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);

      // TODO: If Cal.com booking UID is available, cancel on Cal.com too
      // via an HTTP call to Cal.com API.

      return true;
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      return false;
    }
  }

  /// Reschedule an appointment to a new date and time.
  static Future<bool> rescheduleAppointment(
    String appointmentId,
    String newDate,
    String newTime,
  ) async {
    try {
      await _supabase.from('appointments').update({
        'appointment_date': newDate,
        'appointment_time': newTime,
        'status': 'upcoming',
      }).eq('id', appointmentId);

      // TODO: If Cal.com booking UID is available, reschedule on Cal.com too
      // via an HTTP call to Cal.com API.

      return true;
    } catch (e) {
      debugPrint('Error rescheduling appointment: $e');
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QueueService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream active queue entries for the authenticated user in real-time
  static Stream<List<Map<String, dynamic>>> streamActiveQueues() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('queue_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .asyncMap((entries) async {
          // Filter active statuses (waiting, calling, serving)
          final active = entries.where((e) {
            final s = e['status']?.toString().toLowerCase();
            return s == 'waiting' || s == 'calling' || s == 'serving' || s == null;
          }).toList();

          if (active.isEmpty) return <Map<String, dynamic>>[];

          final enriched = <Map<String, dynamic>>[];
          for (final entry in active) {
            final clinicId = entry['clinic_id'];
            Map<String, dynamic>? clinicData;

            if (clinicId != null) {
              try {
                clinicData = await _supabase
                    .from('clinics')
                    .select('id, name, category, address, wait_time, image_url')
                    .eq('id', clinicId)
                    .maybeSingle();
              } catch (e) {
                debugPrint('Error fetching clinic details: $e');
              }
            }

            // Calculate live position in the queue
            int position = 1;
            try {
              final createdAt = entry['created_at'];
              if (clinicId != null && createdAt != null) {
                final ahead = await _supabase
                    .from('queue_entries')
                    .select('id')
                    .eq('clinic_id', clinicId)
                    .inFilter('status', ['waiting', 'calling', 'serving'])
                    .lte('created_at', createdAt);
                position = (ahead as List).length;
                if (position < 1) position = 1;
              }
            } catch (e) {
              debugPrint('Error calculating queue position: $e');
            }

            enriched.add({
              ...entry,
              'clinic': clinicData,
              'calculated_position': position,
            });
          }

          return enriched;
        });
  }

  /// Fetch past queue history for the current user
  static Future<List<Map<String, dynamic>>> fetchQueueHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('queue_entries')
          .select('*, clinics(id, name, category, address, image_url)')
          .eq('user_id', user.id)
          .inFilter('status', ['completed', 'cancelled'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching queue history: $e');
      return [];
    }
  }

  /// Join virtual queue for a clinic
  static Future<Map<String, dynamic>> joinQueue({
    required String clinicId,
    String? patientName,
    String? patientPhone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Please log in to join a virtual queue.');
    }

    // Check if user already has an active entry for this clinic
    final existing = await _supabase
        .from('queue_entries')
        .select('id, token_number, status, clinics(id, name, category, address, wait_time)')
        .eq('user_id', user.id)
        .eq('clinic_id', clinicId)
        .inFilter('status', ['waiting', 'calling', 'serving'])
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    // Resolve patient details
    String resolvedName = patientName?.trim() ?? '';
    String resolvedPhone = patientPhone?.trim() ?? '';

    if (resolvedName.isEmpty || resolvedPhone.isEmpty) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('full_name, phone_number')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          if (resolvedName.isEmpty) resolvedName = profile['full_name'] ?? '';
          if (resolvedPhone.isEmpty) resolvedPhone = profile['phone_number'] ?? '';
        }
      } catch (e) {
        debugPrint('Error reading profile for queue: $e');
      }
    }

    if (resolvedName.isEmpty) {
      resolvedName = user.userMetadata?['full_name'] ??
          (user.email != null && user.email!.contains('@')
              ? user.email!.split('@').first
              : 'Patient');
    }

    // Generate next token number
    int nextTokenNumber = 1;
    try {
      final latest = await _supabase
          .from('queue_entries')
          .select('token_number')
          .eq('clinic_id', clinicId)
          .order('token_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latest != null && latest['token_number'] != null) {
        nextTokenNumber = (latest['token_number'] as int) + 1;
      }
    } catch (e) {
      debugPrint('Error finding next token number: $e');
    }

    final insertData = {
      'user_id': user.id,
      'clinic_id': clinicId,
      'patient_name': resolvedName,
      'patient_phone': resolvedPhone,
      'status': 'waiting',
      'token_number': nextTokenNumber,
    };

    final response = await _supabase
        .from('queue_entries')
        .insert(insertData)
        .select('*, clinics(id, name, category, address, wait_time)')
        .single();

    return response;
  }

  /// Leave active queue (sets status to cancelled)
  static Future<bool> leaveQueue(String entryId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('queue_entries').update({
        'status': 'cancelled',
        'updated_at': now,
      }).eq('id', entryId);
      return true;
    } catch (e) {
      debugPrint('Error leaving queue: $e');
      return false;
    }
  }

  /// Mark queue entry as checked in
  static Future<bool> checkIn(String entryId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('queue_entries').update({
        'updated_at': now,
      }).eq('id', entryId);
      return true;
    } catch (e) {
      debugPrint('Error checking in: $e');
      return false;
    }
  }
}

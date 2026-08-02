import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clinic_model.dart';
import 'dart:convert';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Box _cacheBox = Hive.box('offline_cache');

  // Fetch clinics with offline fallback
  Future<List<ClinicModel>> getClinics() async {
    try {
      final response = await _supabase.from('clinics').select();
      
      // Cache the response
      await _cacheBox.put('clinics', jsonEncode(response));
      
      return (response as List).map((c) => ClinicModel.fromJson(c)).toList();
    } catch (e) {
      // Fallback to offline cache
      final cached = _cacheBox.get('clinics');
      if (cached != null) {
        final List decoded = jsonDecode(cached);
        return decoded.map((c) => ClinicModel.fromJson(c)).toList();
      }
      return [];
    }
  }

  // Subscribe to real-time clinic updates
  SupabaseStreamBuilder streamClinics() {
    return _supabase.from('clinics').stream(primaryKey: ['id']);
  }
}

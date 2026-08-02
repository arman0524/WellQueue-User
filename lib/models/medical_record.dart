class MedicalRecord {
  final String id;
  final String userId;
  final String conditionName;
  final String? notes;
  final DateTime? dateRecorded;

  MedicalRecord({
    required this.id,
    required this.userId,
    required this.conditionName,
    this.notes,
    this.dateRecorded,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      userId: json['user_id'],
      conditionName: json['condition_name'],
      notes: json['notes'],
      dateRecorded: json['date_recorded'] != null
          ? DateTime.tryParse(json['date_recorded'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'condition_name': conditionName,
      if (notes != null) 'notes': notes,
      if (dateRecorded != null)
        'date_recorded': dateRecorded!.toIso8601String().split('T')[0],
    };
  }
}

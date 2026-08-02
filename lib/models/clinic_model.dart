import 'package:latlong2/latlong.dart';

class ClinicModel {
  final String id;
  final String name;
  final String category;
  final String address;
  final String? imageUrl;
  final bool isOpen;
  final double rating;
  final int reviews;
  final String waitTime;
  final String hours;
  final double latitude;
  final double longitude;

  ClinicModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.imageUrl,
    this.isOpen = true,
    this.rating = 4.5,
    this.reviews = 0,
    this.waitTime = '15 min wait',
    this.hours = '08:00 AM - 05:00 PM',
    this.latitude = 40.730610,
    this.longitude = -73.935242,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Clinic',
      category: json['category'] ?? 'General Care',
      address: json['address'] ?? 'Unknown Address',
      imageUrl: json['image_url'],
      isOpen: json['is_open'] ?? true,
      rating: (json['rating'] != null) ? (json['rating'] as num).toDouble() : 4.5,
      reviews: json['reviews'] ?? 0,
      waitTime: json['wait_time'] ?? '15 min wait',
      hours: json['hours'] ?? '08:00 AM - 05:00 PM',
      latitude: (json['latitude'] != null) ? (json['latitude'] as num).toDouble() : 40.730610,
      longitude: (json['longitude'] != null) ? (json['longitude'] as num).toDouble() : -73.935242,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'address': address,
      'image_url': imageUrl,
      'is_open': isOpen,
      'rating': rating,
      'reviews': reviews,
      'wait_time': waitTime,
      'hours': hours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
  
  LatLng get location => LatLng(latitude, longitude);
}

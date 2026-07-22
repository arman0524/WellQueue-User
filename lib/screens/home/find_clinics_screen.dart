import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../clinic/clinic_details_screen.dart';
import '../queue/my_queues_screen.dart';

class FindClinicsScreen extends StatefulWidget {
  const FindClinicsScreen({super.key});

  @override
  State<FindClinicsScreen> createState() => _FindClinicsScreenState();
}

class _FindClinicsScreenState extends State<FindClinicsScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  bool _isMapView = false;
  Map<String, dynamic>? _selectedClinicForMap;

  final MapController _mapController = MapController();

  final LatLng _userLocation = const LatLng(40.730610, -73.935242);

  final List<Map<String, dynamic>> _clinics = [
    {
      'id': '1',
      'name': 'City Health Urgent Care',
      'category': 'Urgent Care',
      'address': '124 Clinical Row, Medical District, NY 10012',
      'isOpen': true,
      'rating': 4.8,
      'reviews': 120,
      'distance': '0.8 km',
      'waitTime': '15 min wait',
      'hours': '08:00 AM - 09:00 PM',
      'location': const LatLng(40.7350, -73.9400),
      'image': 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': '2',
      'name': 'Beacon Wellness Center',
      'category': 'Pediatrics',
      'address': '88 Health Blvd, NY 10015',
      'isOpen': true,
      'rating': 4.6,
      'reviews': 95,
      'distance': '1.4 km',
      'waitTime': '5 min wait',
      'hours': '08:30 AM - 07:00 PM',
      'location': const LatLng(40.7250, -73.9280),
      'image': 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': '3',
      'name': 'Family First Medical',
      'category': 'General Care',
      'address': '45 Avenue B, NY 10009',
      'isOpen': false,
      'rating': 4.9,
      'reviews': 210,
      'distance': '2.1 km',
      'waitTime': 'Opens 8:00 AM',
      'hours': '08:00 AM - 05:00 PM',
      'location': const LatLng(40.7180, -73.9520),
      'image': 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(context),
          const MyQueuesScreen(),
          _buildProfileTab(context),
        ],
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Find Clinics'),
            _buildNavItem(1, Icons.event_rounded, 'My Queues'),
            _buildNavItem(2, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.outline,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen(BuildContext context) {
    final filteredClinics = _selectedCategory == 'All'
        ? _clinics
        : _clinics.where((c) => c['category'] == _selectedCategory).toList();

    return SafeArea(
      child: Stack(
        children: [
          // Main Body: List View or Full OpenStreetMap View
          _isMapView
              ? _buildOpenStreetMap(filteredClinics)
              : _buildListView(context, filteredClinics),

          // Floating Top App Bar & Search Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'WellQueue',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Toggle Map/List View Button
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isMapView = !_isMapView;
                              });
                            },
                            icon: Icon(
                              _isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded,
                              size: 18,
                            ),
                            label: Text(_isMapView ? 'List' : 'OSM Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search clinics, doctors, symptoms...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.outline),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                      ),
                      fillColor: AppColors.surfaceContainerLow,
                      filled: true,
                    ),
                  ),

                  // Category Chips
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: ['All', 'Urgent Care', 'Pediatrics', 'General Care', 'Dental'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLowest,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map View Selected Clinic Info Card Overlay
          if (_isMapView && _selectedClinicForMap != null)
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: _buildMapClinicCard(context, _selectedClinicForMap!),
            ),
        ],
      ),
    );
  }

  // OpenStreetMap Widget using flutter_map
  Widget _buildOpenStreetMap(List<Map<String, dynamic>> clinics) {
    return Padding(
      padding: const EdgeInsets.only(top: 170),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation,
          initialZoom: 13.5,
          onTap: (_, _) {
            setState(() => _selectedClinicForMap = null);
          },
        ),
        children: [
          // OpenStreetMap Tile Layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.wellqueueuser',
          ),

          // OpenStreetMap Markers
          MarkerLayer(
            markers: [
              // User Location Pulse Marker
              Marker(
                point: _userLocation,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Clinic Interactive Markers
              ...clinics.map((clinic) {
                final isSelected = _selectedClinicForMap?['id'] == clinic['id'];
                final LatLng pos = clinic['location'];

                return Marker(
                  point: pos,
                  width: 60,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedClinicForMap = clinic;
                      });
                      _mapController.move(pos, 14.5);
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryContainer : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected ? AppColors.primaryContainer : AppColors.primary)
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            clinic['distance'],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // Clinic List View
  Widget _buildListView(BuildContext context, List<Map<String, dynamic>> clinics) {
    return Padding(
      padding: const EdgeInsets.only(top: 170),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: clinics.length,
        itemBuilder: (context, index) {
          final clinic = clinics[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClinicDetailsScreen(clinic: clinic),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  clinic['name'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: clinic['isOpen']
                                      ? AppColors.successContainer
                                      : AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  clinic['isOpen'] ? 'OPEN' : 'CLOSED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: clinic['isOpen']
                                        ? AppColors.success
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                '${clinic['rating']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                ' (${clinic['reviews']}) • ${clinic['distance']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                clinic['waitTime'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Floating Map Card Preview
  Widget _buildMapClinicCard(BuildContext context, Map<String, dynamic> clinic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  clinic['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _selectedClinicForMap = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            clinic['address'],
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    clinic['waitTime'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClinicDetailsScreen(clinic: clinic),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Details', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                'AR',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Alex Rivera',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Health ID: #WQ-9920-X',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: AppColors.primary),
              title: const Text('Medical History'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border_rounded, color: AppColors.primary),
              title: const Text('Saved Clinics'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Logout', style: TextStyle(color: AppColors.error)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

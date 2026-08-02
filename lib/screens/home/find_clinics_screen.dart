import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';
import '../clinic/clinic_details_screen.dart';
import '../queue/my_queues_screen.dart';
import '../profile/profile_screen.dart';

class FindClinicsScreen extends StatefulWidget {
  const FindClinicsScreen({super.key});

  @override
  State<FindClinicsScreen> createState() => _FindClinicsScreenState();
}

class _FindClinicsScreenState extends State<FindClinicsScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  Map<String, dynamic>? _selectedClinicForMap;
  bool _isLocating = true;
  String _locationStatusText = 'Locating...';

  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _clinics = [];

  final MapController _mapController = MapController();

  // Default initial location (used while fetching or fallback)
  LatLng _userLocation = const LatLng(40.730610, -73.935242);

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndFetch();
    _fetchClinics();
  }

  Future<void> _fetchClinics() async {
    final clinicsModels = await _dbService.getClinics();
    final mappedClinics = clinicsModels.map((c) => {
      'id': c.id,
      'name': c.name,
      'category': c.category,
      'address': c.address,
      'isOpen': c.isOpen,
      'rating': c.rating,
      'reviews': c.reviews,
      'distance': '1.2 km', // Mock distance
      'waitTime': c.waitTime,
      'hours': c.hours,
      'location': LatLng(c.latitude, c.longitude),
      'image': c.imageUrl,
    }).toList();

    if (mounted) {
      setState(() {
        _clinics = mappedClinics;
      });
    }

    // Optional: listen to stream for real-time updates
    _dbService.streamClinics().listen((event) {
      if (!mounted) return;
      _fetchClinics(); // re-fetch or map event
    });
  }

  Future<void> _requestLocationPermissionAndFetch() async {
    setState(() {
      _isLocating = true;
      _locationStatusText = 'Requesting location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationStatusText = 'Location service disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocating = false;
            _locationStatusText = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _locationStatusText = 'Location permission permanently denied';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final realLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = realLocation;
        _isLocating = false;
        _locationStatusText = 'Live Location';
      });

      _mapController.move(realLocation, 14.0);
    } catch (e) {
      setState(() {
        _isLocating = false;
        _locationStatusText = 'Using default location';
      });
    }
  }

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
          const ProfileScreen(),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 26),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, size: 13, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          _locationStatusText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Notifications Icon Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.onSurface,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar Field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search clinics, specialists, symptoms...',
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
            const SizedBox(height: 14),

            // Category Chips
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
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
            const SizedBox(height: 18),

            // OpenStreetMap Card (Positioned directly below searchbar & categories)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Map Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: const [
                              Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Live Nearby Map',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _requestLocationPermissionAndFetch,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                if (_isLocating)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else
                                  const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                const Text(
                                  'My Location',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // OpenStreetMap Embedded View (Height 230)
                  SizedBox(
                    height: 230,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
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
                              // Real Location User Marker
                              Marker(
                                point: _userLocation,
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.25),
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

                              // Interactive Clinic Markers
                              ...filteredClinics.map((clinic) {
                                final isSelected = _selectedClinicForMap?['id'] == clinic['id'];
                                final LatLng pos = clinic['location'];

                                return Marker(
                                  point: pos,
                                  width: 54,
                                  height: 54,
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
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryContainer
                                                : AppColors.primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isSelected
                                                        ? AppColors.primaryContainer
                                                        : AppColors.primary)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.local_hospital_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.outlineVariant),
                                          ),
                                          child: Text(
                                            clinic['distance'],
                                            style: const TextStyle(
                                              fontSize: 9,
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
                    ),
                  ),
                ],
              ),
            ),

            // Map Selected Clinic Floating Preview (if a pin is tapped on OSM)
            if (_selectedClinicForMap != null) ...[
              const SizedBox(height: 12),
              _buildMapClinicCard(context, _selectedClinicForMap!),
            ],

            const SizedBox(height: 24),

            // Nearby Clinics Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Clinics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredClinics.length} Available',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Nearby Clinics Cards List
            ...filteredClinics.asMap().entries.map((entry) => FadeInUp(
              delay: Duration(milliseconds: 100 * entry.key),
              duration: const Duration(milliseconds: 500),
              child: _buildClinicCard(context, entry.value),
            )),
          ],
        ),
      ),
    );
  }

  // Clinic List Item Card Widget
  Widget _buildClinicCard(BuildContext context, Map<String, dynamic> clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
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
              Hero(
                tag: 'clinic-image-${clinic['id']}',
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    image: clinic['image'] != null
                        ? DecorationImage(
                            image: NetworkImage(clinic['image']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: clinic['image'] == null
                      ? const Icon(
                          Icons.local_hospital_rounded,
                          color: AppColors.primary,
                          size: 38,
                        )
                      : null,
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
                    Text(
                      clinic['address'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        const Text(
                          'Join Queue >',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
  }

  // Floating Map Card Selected Preview
  Widget _buildMapClinicCard(BuildContext context, Map<String, dynamic> clinic) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinic['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  clinic['address'],
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Details', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';

class SavedClinicsScreen extends StatefulWidget {
  const SavedClinicsScreen({super.key});

  @override
  State<SavedClinicsScreen> createState() => _SavedClinicsScreenState();
}

class _SavedClinicsScreenState extends State<SavedClinicsScreen> {
  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClinics();
  }

  Future<void> _fetchClinics() async {
    try {
      final data = await Supabase.instance.client
          .from('clinics')
          .select()
          .order('name');
          
      if (mounted) {
        setState(() {
          _clinics = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clinics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Clinics Directory',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _clinics.isEmpty
              ? const Center(
                  child: Text(
                    'No clinics available.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: _clinics.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final clinic = _clinics[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 400 + (index * 150)),
                      child: _buildSavedClinicCard(clinic),
                    );
                  },
                ),
    );
  }

  Widget _buildSavedClinicCard(Map<String, dynamic> clinic) {
    bool isOpen = clinic['isOpen'] == true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: clinic['image_url'] != null
                        ? Image.network(
                            clinic['image_url'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: AppColors.primaryContainer,
                            child: const Icon(Icons.local_hospital, color: AppColors.primary),
                          ),
                  ),
                  const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              clinic['name'] ?? 'Unknown Clinic',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.bookmark_border_rounded, color: AppColors.outline, size: 22),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clinic['address'] ?? 'No address provided',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '4.8 (120)', // Placeholder rating
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOpen 
                                  ? Colors.green.withValues(alpha: 0.1) 
                                  : AppColors.outlineVariant.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpen ? 'OPEN' : 'CLOSED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOpen ? Colors.green[700] : AppColors.outline,
                              ),
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
      ),
    );
  }
}

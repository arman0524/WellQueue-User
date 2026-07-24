import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';

class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Medical History',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () {
              // TODO: Add new record
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _buildVitalsSection(),
            ),
            const SizedBox(height: 24),
            
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: _buildSectionTitle('Known Allergies'),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: _buildRecordCard(
                title: 'Penicillin',
                subtitle: 'Severe allergic reaction (Hives, Swelling)',
                date: 'Diagnosed: 2015',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),

            FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: _buildSectionTitle('Current Medications'),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: _buildRecordCard(
                title: 'Lisinopril 10mg',
                subtitle: 'Take 1 tablet daily for blood pressure',
                date: 'Prescribed: Oct 2023',
                icon: Icons.medication_rounded,
                iconColor: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),

            FadeInUp(
              duration: const Duration(milliseconds: 900),
              child: _buildSectionTitle('Past Conditions & Surgeries'),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: _buildRecordCard(
                title: 'Appendectomy',
                subtitle: 'Surgical removal of appendix',
                date: 'Procedure Date: Mar 2018',
                icon: Icons.local_hospital_rounded,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildVitalsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVitalItem('Blood Type', 'O+', Icons.bloodtype_rounded),
          Container(height: 40, width: 1, color: AppColors.outlineVariant),
          _buildVitalItem('Height', '175 cm', Icons.height_rounded),
          Container(height: 40, width: 1, color: AppColors.outlineVariant),
          _buildVitalItem('Weight', '70 kg', Icons.monitor_weight_rounded),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard({
    required String title,
    required String subtitle,
    required String date,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.outline),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

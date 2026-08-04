import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ai_agent_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> clinic;

  const BookAppointmentScreen({super.key, required this.clinic});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  int _selectedDateIndex = 1;
  String _selectedTimeSlot = '08:30';
  String _selectedConsultationType = 'General Checkup';

  List<Map<String, String>> _dates = [];

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  void _generateDates() {
    final now = DateTime.now();
    _dates = List.generate(14, (index) {
      final date = now.add(Duration(days: index));
      return {
        'day': DateFormat('EEE').format(date),
        'date': DateFormat('dd').format(date),
        'month': DateFormat('MMMM yyyy').format(date),
        'fullDate': DateFormat('yyyy-MM-dd').format(date),
      };
    });
  }

  final List<String> _morningSlots = ['08:00', '08:15', '08:30', '08:45', '09:00', '09:15', '09:30', 'Booked'];
  final List<String> _afternoonSlots = ['02:00', '02:15', '02:30', '02:45', '03:00', '03:15', '03:30', '03:45'];

  void _showLanguageSelectionDialog() {
    final List<String> languages = ['English', 'Hindi'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select AI Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(languages[index]),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                  onTap: () {
                    Navigator.of(context).pop();
                    _triggerAIAgentCall(languages[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerAIAgentCall(String language) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling for the appointment in $language...'),
        duration: const Duration(seconds: 2),
      ),
    );

    final success = await AIAgentService.triggerAIAgentCall(
      clinicName: widget.clinic['name'] ?? 'Unknown Clinic',
      clinicId: widget.clinic['id'] ?? '',
      language: language,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Agent is calling you to complete booking!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to trigger AI agent.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.business, color: AppColors.primary, size: 20),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                Text(_dates[_selectedDateIndex]['month']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = _selectedDateIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppColors.onPrimaryContainer, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            date['day']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date['date']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text('Available Slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.outline),
                const SizedBox(width: 8),
                Text('MORNING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _morningSlots.map((slot) => _buildTimeSlot(slot)).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 18, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('1:00 PM - 2:00 PM: Staff Lunch Break', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.wb_twilight, size: 18, color: AppColors.outline),
                const SizedBox(width: 8),
                Text('AFTERNOON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _afternoonSlots.map((slot) => _buildTimeSlot(slot)).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Appointment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            const SizedBox(height: 16),
            const Text('Consultation Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.outline)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildConsultationChip('General Checkup'),
                _buildConsultationChip('Follow-up'),
                _buildConsultationChip('Emergency'),
              ],
            ),
            const SizedBox(height: 20), // small padding at the end of the list
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selected Slot', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                      const SizedBox(height: 2),
                      Text('${_dates[_selectedDateIndex]['day']}, ${_dates[_selectedDateIndex]['month']} ${_dates[_selectedDateIndex]['date']} • $_selectedTimeSlot', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Consultation Fee', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                      const SizedBox(height: 2),
                      const Text('\$45.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Confirm Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showLanguageSelectionDialog,
                  icon: const Icon(Icons.call, color: AppColors.primary),
                  label: const Text('Book via Call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String slot) {
    final isBooked = slot == 'Booked';
    final isSelected = slot == _selectedTimeSlot;

    return GestureDetector(
      onTap: isBooked ? null : () => setState(() => _selectedTimeSlot = slot),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isBooked ? AppColors.surfaceContainerLowest : (isSelected ? AppColors.primary : AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          slot,
          style: TextStyle(
            color: isBooked ? AppColors.outlineVariant : (isSelected ? Colors.white : AppColors.onSurface),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontStyle: isBooked ? FontStyle.italic : FontStyle.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationChip(String type) {
    final isSelected = type == _selectedConsultationType;
    return GestureDetector(
      onTap: () => setState(() => _selectedConsultationType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

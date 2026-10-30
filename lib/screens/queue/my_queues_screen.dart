import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../services/queue_service.dart';

class MyQueuesScreen extends StatefulWidget {
  const MyQueuesScreen({super.key});

  @override
  State<MyQueuesScreen> createState() => _MyQueuesScreenState();
}

class _MyQueuesScreenState extends State<MyQueuesScreen> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _pastHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndHistory();
  }

  Future<void> _loadProfileAndHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
        }
      } catch (e) {
        debugPrint('Error loading user profile: $e');
      }
    }

    try {
      final history = await QueueService.fetchQueueHistory();
      if (mounted) {
        setState(() {
          _pastHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading queue history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatOrdinal(int number) {
    if (number <= 0) return '1st';
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  String _formatRelativeTime(dynamic dateValue) {
    if (dateValue == null) return 'Recently';
    try {
      final dt = DateTime.parse(dateValue.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return 'Recently';
    }
  }

  Future<void> _leaveQueue(Map<String, dynamic> queueEntry) async {
    final clinicName = queueEntry['clinic']?['name'] ?? 'the clinic';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Queue?'),
        content: Text('Are you sure you want to leave the virtual queue for $clinicName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay in Queue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await QueueService.leaveQueue(queueEntry['id']);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Left queue for $clinicName')),
          );
          _loadProfileAndHistory();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to leave queue. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCheckInModal(Map<String, dynamic> queueEntry) {
    final clinicName = queueEntry['clinic']?['name'] ?? 'Clinic';
    final token = queueEntry['token_number'] != null
        ? '#WQ-${queueEntry['token_number'].toString().padLeft(2, '0')}'
        : '#WQ-${queueEntry['id'].toString().substring(0, 4).toUpperCase()}';
    final patientName = queueEntry['patient_name'] ?? _userProfile?['full_name'] ?? 'Patient';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Digital Check-In Pass',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Present this ticket at the front desk or scan at the clinic kiosk',
                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 140, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      token,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clinicName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patient: $patientName',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    QueueService.checkIn(queueEntry['id']);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checked in successfully! You will be notified when called.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm Check-In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = _userProfile?['full_name'] ?? user?.userMetadata?['full_name'] ?? (user?.email != null && user!.email!.contains('@') ? user.email!.split('@').first : 'User');
    final healthId = _userProfile?['health_id'] ?? (user != null ? '#WQ-${user.id.substring(0, 6).toUpperCase()}' : '#WQ-USER');
    final avatarUrl = _userProfile?['avatar_url'];
    final initials = _getInitials(fullName);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProfileAndHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Profile Section
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          image: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {},
                                )
                              : null,
                        ),
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Health ID: $healthId',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Real-Time Active Queues Stream
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: QueueService.streamActiveQueues(),
                builder: (context, snapshot) {
                  final activeQueues = snapshot.data ?? [];
                  final countText = '${activeQueues.length} Active';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Active Queues',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (activeQueues.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                countText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (activeQueues.isEmpty)
                        _buildEmptyActiveQueueCard()
                      else
                        ...activeQueues.map((entry) => _buildActiveQueueCard(entry)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Queue History Section
              const Text(
                'Past Queue History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoadingHistory)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_pastHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'No past queue history yet',
                      style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ..._pastHistory.map((history) => _buildHistoryItem(history)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActiveQueueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Queues',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are not currently in any virtual queue.\nExplore clinics nearby to join a virtual queue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQueueCard(Map<String, dynamic> entry) {
    final clinic = entry['clinic'] as Map<String, dynamic>?;
    final clinicName = clinic?['name'] ?? 'Clinic';
    final category = clinic?['category'] ?? 'General Care';
    final token = entry['token_number'] != null
        ? '#WQ-${entry['token_number'].toString().padLeft(2, '0')}'
        : '#WQ-${entry['id'].toString().substring(0, 4).toUpperCase()}';

    final int position = entry['calculated_position'] ?? 1;
    final positionText = _formatOrdinal(position);

    // Dynamic wait estimate: ~10 minutes per person ahead
    final waitMinutes = (position <= 1) ? 5 : position * 10;
    final waitText = position == 1 ? 'Next!' : '$waitMinutes mins';

    final relativeTime = _formatRelativeTime(entry['updated_at'] ?? entry['joined_at'] ?? entry['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.onSecondaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinicName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$category • Ticket $token',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _leaveQueue(entry),
                child: const Text(
                  'Leave',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Position & Wait Time Display
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR POSITION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        positionText,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ESTIMATED WAIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        waitText,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Updated $relativeTime',
                    style: const TextStyle(fontSize: 11, color: AppColors.outline),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCheckInModal(entry),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Check In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> history) {
    final clinic = history['clinics'] as Map<String, dynamic>?;
    final clinicName = clinic?['name'] ?? 'Clinic';
    final category = clinic?['category'] ?? 'General Consultation';
    final status = (history['status'] ?? 'Completed').toString().toUpperCase();
    final isCancelled = status == 'CANCELLED';

    String dateStr = '';
    try {
      final dt = DateTime.parse(history['created_at']).toLocal();
      dateStr = DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      dateStr = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category,
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCancelled ? 'Cancelled' : 'Completed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? AppColors.error : AppColors.success,
                ),
              ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

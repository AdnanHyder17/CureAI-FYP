// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:p1/theme.dart';

class DoctorDetailPage extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const DoctorDetailPage({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.account_circle,
                        size: 120,
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Doctor Information
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Name and Qualification
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorData['nickname'] ?? 'Doctor',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctorData['qualification'] ?? 'Medical Doctor',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(doctorData['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} (${(doctorData['totalReviews'] as num?)?.toInt() ?? 0})',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Specialization and Experience
                  Row(
                    children: [
                      _buildInfoCard(
                        context,
                        Icons.medical_services_outlined,
                        'Specialization',
                        doctorData['specialization'] ?? 'General',
                        AppColors.secondary,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoCard(
                        context,
                        Icons.history,
                        'Experience',
                        '${(doctorData['experience'] as num?)?.toInt() ?? 0} Years',
                        AppColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Consultation Fee
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: AppColors.success,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Fee',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${(doctorData['consultationFee'] as num?)?.toInt() ?? 0}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctorData['bio'] ?? 'No information provided.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 24),

                  // Availability Section
                  Text(
                    'Availability',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildAvailabilitySection(context, doctorData),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Booking functionality would go here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking functionality will be implemented here')),
            );
          },
          child: const Text('Book Appointment'),

        ),
      ),
    );

  }

  Widget _buildInfoCard(
      BuildContext context,
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection(BuildContext context, Map<String, dynamic> doctorData) {
    final weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: weekdays.map((day) {
          final availability = doctorData['availability']?[day];
          final hasSlots = availability != null && (availability as List).isNotEmpty;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: weekdays.last == day
                      ? Colors.transparent
                      : AppColors.gray.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    _capitalizeFirstLetter(day),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: hasSlots
                      ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (availability).map<Widget>((slot) {

                      final startTime = (slot['startTime'] as Timestamp?)?.toDate();
                      final endTime = (slot['endTime'] as Timestamp?)?.toDate();


                      if (startTime == null || endTime == null) {
                        return const SizedBox.shrink();
                      }

                      final formatter = DateFormat('h:mm a');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${formatter.format(startTime)} - ${formatter.format(endTime)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
                  )
                      : Text(
                    'Not Available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
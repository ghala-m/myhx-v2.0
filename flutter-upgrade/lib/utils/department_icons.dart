import 'package:flutter/material.dart';

/// Resolves the icon keys used in [Departments] and the specialty templates
/// into real Material icons.
class DepartmentIcons {
  DepartmentIcons._();

  static const Map<String, IconData> _map = {
    'medical_services': Icons.medical_services_rounded,
    'favorite': Icons.favorite_rounded,
    'air': Icons.air_rounded,
    'lunch_dining': Icons.lunch_dining_rounded,
    'water_drop': Icons.water_drop_rounded,
    'science': Icons.science_rounded,
    'psychology': Icons.psychology_rounded,
    'psychology_alt': Icons.psychology_alt_rounded,
    'accessibility_new': Icons.accessibility_new_rounded,
    'bloodtype': Icons.bloodtype_rounded,
    'coronavirus': Icons.coronavirus_rounded,
    'sanitizer': Icons.sanitizer_rounded,
    'spa': Icons.spa_rounded,
    'grass': Icons.grass_rounded,
    'elderly': Icons.elderly_rounded,
    'child_care': Icons.child_care_rounded,
    'crib': Icons.crib_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'family_restroom': Icons.family_restroom_rounded,
    'healing': Icons.healing_rounded,
    'accessible_forward': Icons.accessible_forward_rounded,
    'monitor_heart': Icons.monitor_heart_rounded,
    'timeline': Icons.timeline_rounded,
    'wc': Icons.wc_rounded,
    'pregnant_woman': Icons.pregnant_woman_rounded,
    'visibility': Icons.visibility_rounded,
    'hearing': Icons.hearing_rounded,
    'face': Icons.face_rounded,
    'emergency': Icons.emergency_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'bed': Icons.bed_rounded,
    'airline_seat_flat': Icons.airline_seat_flat_rounded,
    'radiology': Icons.radar_rounded,
    'biotech': Icons.biotech_rounded,
    'medication': Icons.medication_rounded,
    'restaurant': Icons.restaurant_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'record_voice_over': Icons.record_voice_over_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'vaccines': Icons.vaccines_rounded,
    'masks': Icons.masks_rounded,
  };

  static IconData resolve(String? key) =>
      _map[key] ?? Icons.local_hospital_rounded;
}

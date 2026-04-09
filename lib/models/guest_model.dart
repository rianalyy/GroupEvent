import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum RsvpStatus {
  pending('En attente'),
  oui('Oui'),
  peutEtre('Peut-être'),
  non('Non');

  final String label;
  const RsvpStatus(this.label);

  Color get color {
    switch (this) {
      case RsvpStatus.oui:      return AppColors.success;
      case RsvpStatus.peutEtre: return AppColors.warning;
      case RsvpStatus.non:      return AppColors.error;
      case RsvpStatus.pending:  return Colors.white54;
    }
  }

  IconData get icon {
    switch (this) {
      case RsvpStatus.oui:      return Icons.check_circle_rounded;
      case RsvpStatus.peutEtre: return Icons.help_rounded;
      case RsvpStatus.non:      return Icons.cancel_rounded;
      case RsvpStatus.pending:  return Icons.hourglass_empty_rounded;
    }
  }
}

class GuestModel {
  final int? id;
  final int eventId;
  final String name;
  final String? email;
  final RsvpStatus rsvpStatus;
  final int? userId;

  GuestModel({
    this.id,
    required this.eventId,
    required this.name,
    this.email,
    this.rsvpStatus = RsvpStatus.pending,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'name': name.trim(),
      'email': email?.trim(),
      'rsvp_status': rsvpStatus.name,
      'user_id': userId,
    };
  }

  factory GuestModel.fromMap(Map<String, dynamic> map) {
    return GuestModel(
      id: map['id'],
      eventId: map['event_id'],
      name: map['name'],
      email: map['email'],
      rsvpStatus: RsvpStatus.values.firstWhere(
        (e) => e.name == map['rsvp_status'],
        orElse: () => RsvpStatus.pending,
      ),
      userId: map['user_id'],
    );
  }

  GuestModel copyWith({RsvpStatus? rsvpStatus}) {
    return GuestModel(
      id: id, eventId: eventId, name: name,
      email: email, rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      userId: userId,
    );
  }
}

// ─── Modelo: Plan disponible (catálogo) ──────────────────────────────────────
class Plan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int? weeklyClasses;

  const Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    this.weeklyClasses,
  });

  factory Plan.fromMap(Map<String, dynamic> m) => Plan(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        currency: m['currency'] as String? ?? 'ARS',
        weeklyClasses: m['max_reservations_per_week'] as int?,
      );

  List<String> get features {
    if (description.trim().isEmpty) return [];
    return description
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  String get formattedPrice {
    final n = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
      buf.write(n[i]);
    }
    return buf.toString();
  }
}

// ─── Modelo: Plan / Suscripción ───────────────────────────────────────────────
class UserPlan {
  final String id;
  final String planId;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int? maxReservations;
  final int? weeklyClasses;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  const UserPlan({
    required this.id,
    required this.planId,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.maxReservations,
    this.weeklyClasses,
  });

  bool get isActive => status == 'active';

  int get daysRemaining {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

// ─── Modelo: Clase de pilates ─────────────────────────────────────────────────

/// Acción principal que la tarjeta de una clase ofrece al usuario.
///
/// La promoción desde la lista de espera es automática (trigger en la BD):
/// al liberarse un cupo se inscribe al primero en orden de llegada que tenga
/// plan activo y no supere su límite semanal. Por eso el cliente solo ofrece
/// anotarse / salir de la lista; nunca "reservar desde la espera".
enum ClassCardAction { book, joinWaitlist, leaveWaitlist, booked }

class PilatesClass {
  final String id;
  final String name;
  final String instructor;
  final String time; // e.g. "07:30"
  final String period; // "AM" / "PM"
  final String room;
  final String level;
  final int durationMin;
  final int totalSpots;
  final int takenSpots;
  final String equipment;
  final String description;
  final bool isBooked;
  final String? reservationId;
  final DateTime? sessionDate;
  final bool isInWaitlist;
  final String? waitlistId;

  const PilatesClass({
    required this.id,
    required this.name,
    required this.instructor,
    required this.time,
    required this.period,
    required this.room,
    required this.level,
    required this.durationMin,
    required this.totalSpots,
    required this.takenSpots,
    required this.equipment,
    required this.description,
    this.isBooked = false,
    this.reservationId,
    this.sessionDate,
    this.isInWaitlist = false,
    this.waitlistId,
  });

  int get availableSpots {
    final free = totalSpots - takenSpots;
    return free < 0 ? 0 : free;
  }

  bool get isFull => totalSpots - takenSpots <= 0;

  /// Decide qué acción mostrar en la tarjeta de la clase.
  ///
  /// [forceFull] permite a la UI marcar la clase como llena cuando el
  /// servidor rechazó una reserva por capacidad aunque el conteo local
  /// todavía no se haya refrescado.
  ClassCardAction cardAction({bool forceFull = false}) {
    if (isBooked) return ClassCardAction.booked;
    if (isInWaitlist) return ClassCardAction.leaveWaitlist;
    if (isFull || forceFull) return ClassCardAction.joinWaitlist;
    return ClassCardAction.book;
  }
}

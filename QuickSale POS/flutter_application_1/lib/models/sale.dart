
class Sale {
  int? id;
  final double totalAmount;
  final DateTime date;
  final int userId;
  final int? clienteId; // Puede ser nulo si la venta no está asociada a un cliente
  final String? clientName; // New field
  final String? clientPhone; // New field
  final String? paymentMethod; // Nuevo campo para el método de pago

  Sale({
    this.id,
    required this.totalAmount,
    required this.date,
    required this.userId,
    this.clienteId,
    this.clientName, // New field
    this.clientPhone, // New field
    this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'userId': userId,
      'clienteId': clienteId,
      'clientName': clientName, // New field
      'clientPhone': clientPhone, // New field
      'paymentMethod': paymentMethod,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      totalAmount: map['totalAmount'],
      date: DateTime.parse(map['date']),
      userId: map['userId'],
      clienteId: map['clienteId'],
      clientName: map['clientName'], // New field
      clientPhone: map['clientPhone'], // New field
      paymentMethod: map['paymentMethod'],
    );
  }
}

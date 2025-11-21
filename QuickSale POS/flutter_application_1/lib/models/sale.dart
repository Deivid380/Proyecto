
class Sale {
  int? id;
  final double totalAmount;
  final DateTime date;
  final int userId;
  final int? clienteId; // Puede ser nulo si la venta no está asociada a un cliente
  final String? paymentMethod; // Nuevo campo para el método de pago

  Sale({
    this.id,
    required this.totalAmount,
    required this.date,
    required this.userId,
    this.clienteId,
    this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'userId': userId,
      'clienteId': clienteId,
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
      paymentMethod: map['paymentMethod'],
    );
  }
}

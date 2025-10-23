
class Sale {
  int? id;
  final double totalAmount;
  final DateTime date;

  Sale({this.id, required this.totalAmount, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'date': date.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      totalAmount: map['total_amount'],
      date: DateTime.parse(map['date']),
    );
  }
}

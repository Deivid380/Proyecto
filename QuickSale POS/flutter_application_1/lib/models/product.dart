
class Product {
  int? id;
  String name;
  double price;
  int stock;
  String? barcode;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
  });

  // Convert a Product into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'barcode': barcode,
    };
  }

  // Implement a factory constructor for creating a new Product instance from a map.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      barcode: map['barcode'],
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, price: $price, stock: $stock, barcode: $barcode}';
  }
}

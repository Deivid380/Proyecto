
class Cliente {
  int? id;
  String nombre;
  String? telefono;
  double deudaActual;

  Cliente({
    this.id,
    required this.nombre,
    this.telefono,
    this.deudaActual = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'deudaActual': deudaActual,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      deudaActual: map['deudaActual'],
    );
  }

  @override
  String toString() {
    return 'Cliente{id: $id, nombre: $nombre, telefono: $telefono, deudaActual: $deudaActual}';
  }
}

class Habito {
  int? id; // El ID será autoincrementado por la base de datos
  String nombre;
  String frecuencia;
  String dias;

  Habito({
    this.id,
    required this.nombre,
    required this.frecuencia,
    required this.dias,
  });

  // Convierte un objeto Habito a un Mapa para la base de datos.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'frecuencia': frecuencia,
      'dias': dias,
    };
  }
}
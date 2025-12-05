class Habito {
  int? id; 
  String nombre;
  String frecuencia;
  String dias;

  Habito({
    this.id,
    required this.nombre,
    required this.frecuencia,
    required this.dias,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'frecuencia': frecuencia,
      'dias': dias,
    };
  }
}
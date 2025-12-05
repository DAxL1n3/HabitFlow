import 'package:flutter_test/flutter_test.dart';
import 'package:dal_flutter/utils/validators.dart';

void main() {
  group('Pruebas de Validators', () {
    test('validateRequired devuelve error si el texto está vacío', () {
      final result = Validators.validateRequired('');
      expect(result, 'Este campo es obligatorio.');
    });

    test('validateRequired devuelve null si hay texto válido', () {
      final result = Validators.validateRequired('Beber agua');
      expect(result, null);
    });

    test('validateEmail detecta correos inválidos', () {
      final result = Validators.validateEmail('esto-no-es-un-correo');
      expect(result, 'Ingresa un correo válido.');
    });

    test('validateEmail acepta correos correctos', () {
      final result = Validators.validateEmail('prueba@ejemplo.com');
      expect(result, null);
    });

    test('validatePassword exige mínimo 6 caracteres', () {
      final result = Validators.validatePassword('12345');
      expect(result, 'La contraseña debe tener al menos 6 caracteres.');
    });

    test('validatePassword acepta contraseñas seguras', () {
      final result = Validators.validatePassword('123456');
      expect(result, null);
    });
  });
}
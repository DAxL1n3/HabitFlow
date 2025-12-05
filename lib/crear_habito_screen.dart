import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/validators.dart';

class CrearHabitoScreen extends StatefulWidget {
  final QueryDocumentSnapshot? habitoSnapshot;
  const CrearHabitoScreen({super.key, this.habitoSnapshot});
  @override
  State<CrearHabitoScreen> createState() => _CrearHabitoScreenState();
}

class _CrearHabitoScreenState extends State<CrearHabitoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _habitoController;
  late TextEditingController _frecuenciaController;
  late TextEditingController _diasController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final habitoData = widget.habitoSnapshot?.data() as Map<String, dynamic>?;
    _habitoController = TextEditingController(
      text: habitoData?['nombre'] ?? '',
    );
    _frecuenciaController = TextEditingController(
      text: habitoData?['frecuencia'] ?? '',
    );
    _diasController = TextEditingController(text: habitoData?['dias'] ?? '');
  }

  Future<void> _guardarOActualizarHabito() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Usuario no autenticado."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic> habitoMap = {
      'nombre': _habitoController.text,
      'frecuencia': _frecuenciaController.text,
      'dias': _diasController.text,
      'userId': user.uid,
    };

    try {
      if (widget.habitoSnapshot == null) {
        habitoMap['fechaCreacion'] = Timestamp.now();
        await FirebaseFirestore.instance.collection('habitos').add(habitoMap);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Hábito creado con éxito!"),
              backgroundColor: Colors.green,
            ),
          );
          _habitoController.clear();
          _frecuenciaController.clear();
          _diasController.clear();
          FocusScope.of(context).unfocus(); // Ocultar teclado
        }
      } else {
        await FirebaseFirestore.instance
            .collection('habitos')
            .doc(widget.habitoSnapshot!.id)
            .update(habitoMap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Hábito actualizado"),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.habitoSnapshot != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fondo gris muy suave
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? "Editar Objetivo" : "Nuevo Objetivo"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. CABECERA CURVA
            _buildHeader(),

            // 2. FORMULARIO FLOTANTE
            Transform.translate(
              offset: const Offset(
                0,
                -40,
              ), // Subimos el formulario para que monte el header
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Detalles del Hábito",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 25),

                        _buildLabel("Nombre de la actividad"),
                        _buildTextField(
                          controller: _habitoController,
                          hint: "Ej. Leer, Correr, Meditar",
                          icon: Icons.edit_outlined,
                          validator: Validators.validateRequired,
                        ),

                        const SizedBox(height: 20),

                        _buildLabel("Frecuencia diaria"),
                        _buildTextField(
                          controller: _frecuenciaController,
                          hint: "Ej. 3 veces",
                          icon: Icons.repeat,
                          validator: Validators.validateRequired,
                        ),

                        const SizedBox(height: 20),

                        _buildLabel("Duración del reto (Días)"),
                        _buildTextField(
                          controller: _diasController,
                          hint: "Ej. 30",
                          icon: Icons.calendar_today_outlined,
                          isNumber: true,
                          validator: Validators.validateRequired,
                        ),

                        const SizedBox(height: 35),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _guardarOActualizarHabito,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  backgroundColor: Colors.blue[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.blue.withOpacity(0.4),
                                ),
                                child: Text(
                                  isEditing
                                      ? "Guardar Cambios"
                                      : "Comenzar Hábito",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE DISEÑO ---

  Widget _buildHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Icon(
            Icons.auto_awesome,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blueGrey[700],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: Colors.blue[800], size: 22),
        filled: true,
        fillColor: const Color(0xFFF5F7FA), // Gris muy claro para el input
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade200, width: 1.5),
        ),
      ),
    );
  }
}

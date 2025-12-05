import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'crear_habito_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
 
  final List<Map<String, String>> _habitos = [];

  void _navegarACrearHabito() async {
    final nuevoHabito = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearHabitoScreen()),
    );

    if (nuevoHabito != null) {
      setState(() {
        _habitos.add(nuevoHabito);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'${nuevoHabito['nombre']}' fue agregado."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _eliminarHabito(int index) {
    setState(() {
      final habitoEliminado = _habitos.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'${habitoEliminado['nombre']}' eliminado."),
          backgroundColor: Colors.orange,
        ),
      );
    });
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Hábitos"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _cerrarSesion),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarACrearHabito,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _habitos.isEmpty
            ? const Center(child: Text("Aún no tienes hábitos. ¡Agrega uno!"))
            : ListView.builder(
                itemCount: _habitos.length,
                itemBuilder: (context, index) {
                  final habito = _habitos[index];
                  return Card(
                    child: ListTile(
                      title: Text(habito['nombre']!),
                      subtitle: Text(
                        "Frecuencia: ${habito['frecuencia']}, Días: ${habito['dias']}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _eliminarHabito(index),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

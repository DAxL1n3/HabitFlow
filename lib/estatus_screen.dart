import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crear_habito_screen.dart';

class EstatusScreen extends StatelessWidget {
  const EstatusScreen({super.key});

  String _getFechaHoy() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  int _parsearFrecuencia(String textoFrecuencia) {
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(textoFrecuencia);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 1;
  }

  Future<void> _incrementarProgreso(
    String docId,
    Map<String, dynamic> historial,
    int metaDiaria,
  ) async {
    final hoy = _getFechaHoy();
    int conteoActual = int.tryParse(historial[hoy]?.toString() ?? '0') ?? 0;

    if (conteoActual < metaDiaria) {
      conteoActual++;
      await FirebaseFirestore.instance.collection('habitos').doc(docId).set({
        'historialProgreso': {hoy: conteoActual},
        if (conteoActual >= metaDiaria)
          'diasCompletados': FieldValue.arrayUnion([hoy]),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _resetearProgresoHoy(String docId) async {
    final hoy = _getFechaHoy();
    await FirebaseFirestore.instance.collection('habitos').doc(docId).set({
      'historialProgreso': {hoy: 0},
      'diasCompletados': FieldValue.arrayRemove([hoy]),
    }, SetOptions(merge: true));
  }

  void _eliminarHabito(
    BuildContext context,
    String docId,
    String nombre,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('habitos')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'$nombre' eliminado."),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar '$nombre'."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final hoy = _getFechaHoy();

    if (userId == null) {
      return const Center(child: Text("Error: Usuario no encontrado."));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Mi Progreso Diario",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false, 
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900], 
        elevation: 0, 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('habitos')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allDocs = snapshot.data!.docs;
          final pendientes = <QueryDocumentSnapshot>[];
          final completados = <QueryDocumentSnapshot>[];

          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final meta = _parsearFrecuencia(
              data['frecuencia']?.toString() ?? "1",
            );
            final historial =
                data['historialProgreso'] as Map<String, dynamic>? ?? {};
            final realizadosHoy =
                int.tryParse(historial[hoy]?.toString() ?? '0') ?? 0;

            if (realizadosHoy >= meta) {
              completados.add(doc);
            } else {
              pendientes.add(doc);
            }
          }

          final totalHabitos = allDocs.length;
          final totalCompletados = completados.length;
          final porcentajeGlobal = totalHabitos == 0
              ? 0.0
              : (totalCompletados / totalHabitos);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGlobalSummary(
                  totalCompletados,
                  totalHabitos,
                  porcentajeGlobal,
                ),

                const SizedBox(height: 25),

                if (pendientes.isNotEmpty) ...[
                  _buildSectionTitle("POR HACER (${pendientes.length})"),
                  const SizedBox(height: 10),
                  ...pendientes
                      .map((doc) => _buildActiveHabitCard(context, doc, hoy))
                      ,
                ],

                if (completados.isNotEmpty) ...[
                  const SizedBox(height: 25),
                  _buildSectionTitle("TERMINADOS HOY (${completados.length})"),
                  const SizedBox(height: 10),
                  ...completados
                      .map((doc) => _buildCompletedHabitCard(context, doc))
                      ,
                ],

                if (pendientes.isEmpty && completados.isNotEmpty)
                  _buildAllDoneMessage(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlobalSummary(int hechos, int total, double porcentaje) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[800], 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tu desempeño hoy",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                "${(porcentaje * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 10,
              backgroundColor: Colors.blue[900], 
              color: Colors.greenAccent, 
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Has completado $hechos de $total hábitos",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHabitCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String hoy,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final frecuenciaTexto = data['frecuencia']?.toString() ?? "1";
    final meta = _parsearFrecuencia(frecuenciaTexto);
    final historial = data['historialProgreso'] as Map<String, dynamic>? ?? {};
    final realizados = int.tryParse(historial[hoy]?.toString() ?? '0') ?? 0;
    final porcentaje = (realizados / meta).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: Colors.blue[700],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nombre'] ?? 'Hábito',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Meta: $frecuenciaTexto",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildEditMenu(context, doc, data['nombre']),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Progreso",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$realizados/$meta",
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: porcentaje,
                          minHeight: 6,
                          backgroundColor: Colors.grey[100],
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                InkWell(
                  onTap: () => _incrementarProgreso(doc.id, historial, meta),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedHabitCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.1),
        ), 
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.green, size: 20),
        ),
        title: Text(
          data['nombre'],
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.undo, color: Colors.grey[400], size: 20),
          onPressed: () => _resetearProgresoHoy(doc.id),
        ),
      ),
    );
  }

  Widget _buildAllDoneMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.green[300]),
          const SizedBox(height: 15),
          Text(
            "¡Todo listo por hoy!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Has cumplido todas tus metas.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMenu(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String nombre,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Colors.grey[400],
      ), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => CrearHabitoScreen(habitoSnapshot: doc),
            ),
          );
        } else if (value == 'delete') {
          _eliminarHabito(context, doc.id, nombre);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 18),
              SizedBox(width: 10),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 10),
              Text('Eliminar'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.blueGrey[700],
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_list_bulleted, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "Sin hábitos aún",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Comienza agregando uno nuevo",
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

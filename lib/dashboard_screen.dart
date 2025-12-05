import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _parsearInt(String texto) {
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(texto);
    return match != null ? int.parse(match.group(0)!) : 1;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String nombreUsuario = user?.displayName ?? 'Usuario';

    final String fechaHoy = DateFormat(
      'EEEE, d'
          ','
          ' MMMM',
      'es_MX',
    ).format(DateTime.now());

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80, 
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fechaHoy.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                text: 'Hola, ',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
                children: [
                  TextSpan(
                    text: nombreUsuario.split(' ')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ), 
                ],
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('habitos')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                    child: Column(
                      children: [
                        TableCalendar(
                          locale: 'es_MX',
                          firstDay: DateTime.utc(2023, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },

                          headerStyle: const HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: Colors.blue,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: Colors.blue,
                            ),
                          ),
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            defaultTextStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            weekendTextStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),

                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) =>
                                _buildColoredDay(day, docs),
                            todayBuilder: (context, day, focusedDay) =>
                                _buildColoredDay(day, docs, isToday: true),
                            selectedBuilder: (context, day, focusedDay) =>
                                _buildColoredDay(day, docs, isSelected: true),
                          ),
                        ),

                        const SizedBox(height: 15),
                        const Divider(indent: 20, endIndent: 20),
                        const SizedBox(height: 10),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _LeyendaChip(
                              color: Color(0xFF66BB6A),
                              text: "Logrado",
                            ),
                            _LeyendaChip(
                              color: Color(0xFFFFA726),
                              text: "Parcial",
                            ), 
                            _LeyendaChip(
                              color: Color(0xFFEF5350),
                              text: "Faltó",
                            ), 
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    "DETALLES DEL DÍA",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _selectedDay == null
                      ? _buildEmptyState(
                          "Selecciona un día en el calendario\npara ver tu rendimiento.",
                        )
                      : _buildDayDetails(docs, _selectedDay!),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColoredDay(
    DateTime day,
    List<QueryDocumentSnapshot> docs, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final dateString = _formatDate(day);
    final dayNormalized = _normalizeDate(day);
    int habitosActivos = 0;
    int habitosCompletados = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp? ts = data['fechaCreacion'];
      if (ts == null) continue;
      DateTime inicio = _normalizeDate(ts.toDate());
      int dias = _parsearInt(data['dias']?.toString() ?? "1");
      DateTime fin = inicio.add(Duration(days: dias - 1));

      if ((dayNormalized.isAfter(inicio) ||
              dayNormalized.isAtSameMomentAs(inicio)) &&
          (dayNormalized.isBefore(fin) ||
              dayNormalized.isAtSameMomentAs(fin))) {
        habitosActivos++;
        if (List<String>.from(
          data['diasCompletados'] ?? [],
        ).contains(dateString)) {
          habitosCompletados++;
        }
      }
    }

    Color bgColor = Colors.transparent;
    Color textColor = Colors.black87;
    BoxBorder? border;

    if (habitosActivos > 0) {
      if (habitosCompletados == habitosActivos) {
        bgColor = const Color(0xFF66BB6A);
        textColor = Colors.white; 
      } else if (habitosCompletados > 0) {
        bgColor = const Color(0xFFFFA726);
        textColor = Colors.white; 
      } else if (dayNormalized.isBefore(_normalizeDate(DateTime.now()))) {
        bgColor = const Color(0xFFEF5350);
        textColor = Colors.white; 
      }
    }

    if (isSelected) {
      border = Border.all(color: Colors.blue[800]!, width: 2.5);
      if (bgColor == Colors.transparent) textColor = Colors.blue[800]!;
    } else if (isToday && bgColor == Colors.transparent) {
      bgColor = Colors.blue[50]!;
      textColor = Colors.blue[800]!;
    }

    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDayDetails(
    List<QueryDocumentSnapshot> docs,
    DateTime selectedDate,
  ) {
    final dateString = _formatDate(selectedDate);
    final dayNormalized = _normalizeDate(selectedDate);

    final habitosDelDia = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp? ts = data['fechaCreacion'];
      if (ts == null) return false;
      DateTime inicio = _normalizeDate(ts.toDate());
      int dias = _parsearInt(data['dias']?.toString() ?? "1");
      DateTime fin = inicio.add(Duration(days: dias - 1));
      return (dayNormalized.isAfter(inicio) ||
              dayNormalized.isAtSameMomentAs(inicio)) &&
          (dayNormalized.isBefore(fin) || dayNormalized.isAtSameMomentAs(fin));
    }).toList();

    if (habitosDelDia.isEmpty) {
      return _buildEmptyState("No tenías hábitos programados\npara este día.");
    }

    return ListView.separated(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habitosDelDia.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final data = habitosDelDia[index].data() as Map<String, dynamic>;
        final fueCompletado = List<String>.from(
          data['diasCompletados'] ?? [],
        ).contains(dateString);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: fueCompletado
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fueCompletado ? Colors.green[50] : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                fueCompletado ? Icons.check : Icons.close,
                color: fueCompletado ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              data['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            trailing: Text(
              fueCompletado ? "Completado" : "Pendiente",
              style: TextStyle(
                color: fueCompletado ? Colors.green[700] : Colors.red[400],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 15),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _LeyendaChip extends StatelessWidget {
  final Color color;
  final String text;
  const _LeyendaChip({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

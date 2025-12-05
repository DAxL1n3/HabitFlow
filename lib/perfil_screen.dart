import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  File? _pickedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          if (userDoc.data()!.containsKey('profileImageUrl')) {
            _profileImageUrl = userDoc.data()!['profileImageUrl'];
          }
        });
      }
    } catch (e) {
      print("Error cargando perfil: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80, 
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _isLoading = true; 
        });

        if (_currentUser == null) return;

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profiles') 
            .child(
              '${_currentUser!.uid}.jpg',
            );

        await storageRef.putFile(_pickedImage!);

        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .set(
              {'profileImageUrl': downloadUrl},
              SetOptions(merge: true),
            ); 

        setState(() {
          _profileImageUrl = downloadUrl;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Foto actualizada y guardada en la nube."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al subir foto: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generarRespaldo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('habitos')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();
      if (snapshot.docs.isEmpty)
        throw Exception("No tienes hábitos para respaldar.");

      List<Map<String, dynamic>> listaDatos = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['fechaCreacion'] is Timestamp) {
          data['fechaCreacion'] = (data['fechaCreacion'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        listaDatos.add(data);
      }

      final String jsonString = jsonEncode(listaDatos);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/respaldo_habitflow.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Mi Respaldo HabitFlow');
      _mostrarMensaje("Copia de seguridad lista.", Colors.green);
    } catch (e) {
      _mostrarMensaje(
        "Error: ${e.toString().replaceAll('Exception: ', '')}",
        Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restaurarRespaldo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      File file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();
      final List<dynamic> listaDatos = jsonDecode(jsonString);
      final batch = FirebaseFirestore.instance.batch();

      for (var item in listaDatos) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(item);
        data['userId'] = _currentUser!.uid;
        if (data['fechaCreacion'] is String) {
          data['fechaCreacion'] = Timestamp.fromDate(
            DateTime.parse(data['fechaCreacion']),
          );
        }
        final ref = FirebaseFirestore.instance.collection('habitos').doc();
        batch.set(ref, data);
      }
      await batch.commit();
      _mostrarMensaje("¡Datos restaurados correctamente!", Colors.green);
    } catch (e) {
      _mostrarMensaje("Error al restaurar: Archivo inválido.", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editarNombre() async {
    String nuevoNombre = _currentUser?.displayName ?? "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Nombre"),
        content: TextField(
          autofocus: true,
          decoration: _inputDecoration("Nombre Completo"),
          controller: TextEditingController(text: nuevoNombre),
          onChanged: (val) => nuevoNombre = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nuevoNombre.trim().isEmpty) return;
              try {
                await _currentUser?.updateDisplayName(nuevoNombre);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .set({'displayName': nuevoNombre}, SetOptions(merge: true));
                await _currentUser?.reload();
                setState(() {});
                Navigator.pop(context);
                _mostrarMensaje("Nombre actualizado.", Colors.blue);
              } catch (e) {
                _mostrarMensaje("Error al actualizar.", Colors.red);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _editarCorreo() async {
    String nuevoCorreo = "";
    String passwordActual = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar Correo"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Confirma tu contraseña actual.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Nuevo Correo"),
                onChanged: (val) => nuevoCorreo = val,
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: _inputDecoration("Contraseña Actual"),
                onChanged: (val) => passwordActual = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nuevoCorreo.trim().isEmpty || passwordActual.isEmpty) {
                _mostrarMensaje("Campos obligatorios.", Colors.orange);
                return;
              }
              if (!nuevoCorreo.contains('@')) {
                _mostrarMensaje("Correo inválido.", Colors.orange);
                return;
              }
              try {
                AuthCredential credential = EmailAuthProvider.credential(
                  email: _currentUser!.email!,
                  password: passwordActual,
                );
                await _currentUser!.reauthenticateWithCredential(credential);
                await _currentUser!.verifyBeforeUpdateEmail(nuevoCorreo);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .set({'email': nuevoCorreo}, SetOptions(merge: true));
                Navigator.pop(context);
                _mostrarMensaje(
                  "Verificación enviada al nuevo correo.",
                  Colors.green,
                );
              } on FirebaseAuthException catch (e) {
                _mostrarMensaje(
                  e.code == 'wrong-password'
                      ? "Contraseña incorrecta."
                      : "Error: ${e.message}",
                  Colors.red,
                );
              }
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarPassword() async {
    String currentPass = "";
    String newPass = "";
    String confirmPass = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar Contraseña"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ingresa tu contraseña actual.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              TextField(
                obscureText: true,
                decoration: _inputDecoration("Contraseña Actual"),
                onChanged: (val) => currentPass = val,
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: _inputDecoration("Nueva Contraseña"),
                onChanged: (val) => newPass = val,
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: _inputDecoration("Repetir Nueva"),
                onChanged: (val) => confirmPass = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (currentPass.isEmpty ||
                  newPass.isEmpty ||
                  confirmPass.isEmpty) {
                _mostrarMensaje("Campos obligatorios.", Colors.orange);
                return;
              }
              if (newPass != confirmPass) {
                _mostrarMensaje("No coinciden.", Colors.red);
                return;
              }
              if (newPass.length < 6) {
                _mostrarMensaje("Mínimo 6 caracteres.", Colors.red);
                return;
              }
              try {
                AuthCredential credential = EmailAuthProvider.credential(
                  email: _currentUser!.email!,
                  password: currentPass,
                );
                await _currentUser!.reauthenticateWithCredential(credential);
                await _currentUser!.updatePassword(newPass);
                Navigator.pop(context);
                _mostrarMensaje("Contraseña actualizada.", Colors.green);
              } on FirebaseAuthException catch (e) {
                _mostrarMensaje(
                  e.code == 'wrong-password'
                      ? "Contraseña incorrecta."
                      : "Error: ${e.message}",
                  Colors.red,
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("INFORMACIÓN PERSONAL"),
                        const SizedBox(height: 15),
                        _buildSettingsCard([
                          _buildEditableTile(
                            Icons.person_outline,
                            "Nombre",
                            _currentUser?.displayName ?? "Sin nombre",
                            _editarNombre,
                          ),
                          _buildDivider(),
                          _buildEditableTile(
                            Icons.email_outlined,
                            "Correo",
                            _currentUser?.email ?? "Sin correo",
                            _editarCorreo,
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: Icons.lock_outline,
                            color: Colors.grey,
                            title: "Cambiar Contraseña",
                            onTap: _cambiarPassword,
                            isLink: true,
                          ),
                        ]),

                        const SizedBox(height: 30),

                        _buildSectionTitle("COPIA DE SEGURIDAD"),
                        const SizedBox(height: 15),
                        _buildSettingsCard([
                          _buildSettingsTile(
                            icon: Icons.save_alt,
                            color: Colors.blue,
                            title: "Guardar Copia Local (JSON)",
                            subtitle: "Exportar mis hábitos",
                            onTap: _generarRespaldo,
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: Icons.restore,
                            color: Colors.orange,
                            title: "Restaurar Datos",
                            subtitle: "Importar desde archivo",
                            onTap: _restaurarRespaldo,
                          ),
                        ]),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              "Cerrar Sesión",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(15),
                              side: BorderSide(
                                color: Colors.red.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("¿Cerrar sesión?"),
                                  content: const Text(
                                    "Tendrás que ingresar tus datos nuevamente.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _cerrarSesion();
                                      },
                                      child: const Text(
                                        "Salir",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[800]!, Colors.blue[600]!],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (bc) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo),
                        title: const Text('Galería'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Cámara'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null)
                              as ImageProvider?,
                    child: (_pickedImage == null && _profileImageUrl == null)
                        ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditableTile(
    IconData icon,
    String title,
    String value,
    VoidCallback onEdit,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[800], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue),
        onPressed: onEdit,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLink = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: Icon(
        isLink ? Icons.arrow_forward_ios : Icons.chevron_right,
        size: 16,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 60, endIndent: 20);
}

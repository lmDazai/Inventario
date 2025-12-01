import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. CARGAR VARIABLES DE ENTORNO
  await dotenv.load(fileName: ".env");

  // 2. INICIALIZAR SUPABASE
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventario App',
      themeMode: ThemeMode.system, // Detectar tema del sistema
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[800], // Color oscuro para inputs
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const InventoryHomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA PRINCIPAL: LISTA DE INVENTARIO (CON SUPABASE)
// ---------------------------------------------------------------------------
class InventoryHomeScreen extends StatelessWidget {
  const InventoryHomeScreen({super.key});

  void _navigateToForm(BuildContext context, {Map<String, dynamic>? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryFormScreen(item: item),
      ),
    );
  }

  Future<void> _showSearchOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('Escanear QR / Código de Barras'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SimpleScanner()),
                  );
                  if (result != null && result is String) {
                    _searchAndNavigate(context, result);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Ingresar Código Manualmente'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showManualSearchDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManualSearchDialog(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Buscar por Código"),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: "Ingrese ID o Código"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_searchController.text.isNotEmpty) {
                _searchAndNavigate(context, _searchController.text);
              }
            },
            child: const Text("Buscar"),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAndNavigate(BuildContext context, String code) async {
    try {
      final data = await Supabase.instance.client
          .from('inventario')
          .select()
          .eq('codigo', code)
          .maybeSingle();

      if (data != null) {
        _navigateToForm(context, item: data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item no encontrado")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al buscar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('inventario')
        .stream(primaryKey: ['id']).order('fecha', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Inventario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchOptions(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No hay items en el inventario"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: item['foto_url'] != null &&
                          item['foto_url'].toString().isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(item['foto_url']))
                      : const Icon(Icons.image_not_supported),
                  title: Text("${item['tipo']} ${item['subtipo'] ?? ''}"),
                  subtitle: Text(
                      "ID: ${item['codigo'] ?? item['id']} - ${item['ubicacion']}"),
                  trailing: Text(item['estado'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _navigateToForm(context, item: item),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        label: const Text("Nuevo Ingreso"),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA DE FORMULARIO
// ---------------------------------------------------------------------------
class InventoryFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;

  const InventoryFormScreen({super.key, this.item});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedType;
  String? _selectedPcSubtype;
  String? _selectedState;
  File? _imageFile;
  String? _networkImageUrl;
  bool _isLoading = false;

  final List<String> _types = [
    "PC",
    "Pantalla",
    "Notebook",
    "Data",
    "Impresora",
    "Tablet",
    "Televisor",
    "Parlante",
    "Fotocopiadora"
  ];
  final List<String> _states = ["Operativo", "Inactivo"];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      // Mapear campos de Supabase
      _idController.text = widget.item!['codigo'] ?? '';
      _locationController.text = widget.item!['ubicacion'] ?? '';
      _selectedType = widget.item!['tipo'];
      _selectedPcSubtype = widget.item!['subtipo'];
      _selectedState = widget.item!['estado'];
      _networkImageUrl = widget.item!['foto_url'];
    }
  }

  // 1. Escanear
  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScanner()),
    );

    if (result != null && result is String) {
      setState(() {
        _idController.text = result;
      });
    }
  }

  // 2. GPS
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Permiso de ubicación denegado")));
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = "${place.street}, ${place.locality}";
          setState(() {
            _locationController.text = address;
          });
        } else {
          setState(() {
            _locationController.text =
                "${position.latitude}, ${position.longitude}";
          });
        }
      } catch (e) {
        // Fallback si falla geocoding
        setState(() {
          _locationController.text =
              "${position.latitude}, ${position.longitude}";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error GPS: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. Foto
  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  // 4. Guardar
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Faltan datos (Tipo o Estado)")));
      return;
    }

    if (_selectedType == 'PC' && _selectedPcSubtype == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona Torre o AIO")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _networkImageUrl;

      // Subir imagen a Supabase Storage
      if (_imageFile != null) {
        final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'uploads/$fileName';

        // Subir archivo
        await Supabase.instance.client.storage
            .from('inventario_fotos')
            .upload(path, _imageFile!);

        // Obtener URL pública
        finalImageUrl = Supabase.instance.client.storage
            .from('inventario_fotos')
            .getPublicUrl(path);
      }

      final dataToSave = {
        'codigo': _idController.text,
        'tipo': _selectedType,
        'subtipo': _selectedType == 'PC' ? _selectedPcSubtype : null,
        'ubicacion': _locationController.text,
        'estado': _selectedState,
        'foto_url': finalImageUrl,
        'fecha': DateTime.now().toIso8601String(),
      };

      if (widget.item != null) {
        // Actualizar
        await Supabase.instance.client
            .from('inventario')
            .update(dataToSave)
            .eq('id', widget.item!['id']); // Usamos el ID interno de Supabase
      } else {
        // Crear nuevo
        // 1. Verificar si ya existe
        final existing = await Supabase.instance.client
            .from('inventario')
            .select()
            .eq('codigo', _idController.text);

        if (existing.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("El equipo ya existe en la base de datos"),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // Detener guardado
        }

        await Supabase.instance.client.from('inventario').insert(dataToSave);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 5. Eliminar
  Future<void> _deleteItem() async {
    if (widget.item == null) return;

    bool confirm = await showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text("Eliminar"),
              content: const Text("¿Seguro que deseas eliminar este ítem?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text("Cancelar")),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text("Eliminar",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('inventario')
            .delete()
            .eq('id', widget.item!['id']);

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Item" : "Nuevo Ingreso"),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteItem,
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // CAMPO 1: ID
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _idController,
                            decoration: const InputDecoration(
                                labelText: "ID / Código de Barras"),
                            validator: (v) => v!.isEmpty ? "Requerido" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: _scanBarcode,
                          icon: const Icon(Icons.qr_code),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // CAMPO 2: TIPO
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: "Tipo"),
                      items: _types
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedType = val;
                          if (val != 'PC') _selectedPcSubtype = null;
                        });
                      },
                    ),

                    if (_selectedType == 'PC') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200)),
                        child: Row(
                          children: [
                            const Text("Modelo PC:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text("Torre"),
                              selected: _selectedPcSubtype == 'Torre',
                              onSelected: (sel) => setState(() =>
                                  _selectedPcSubtype = sel ? 'Torre' : null),
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text("AIO"),
                              selected: _selectedPcSubtype == 'AIO',
                              onSelected: (sel) => setState(() =>
                                  _selectedPcSubtype = sel ? 'AIO' : null),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),

                    // CAMPO 3: UBICACIÓN
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                          labelText: "Ubicación",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.location_on),
                            onPressed: _getCurrentLocation,
                          )),
                    ),
                    const SizedBox(height: 15),

                    // CAMPO 4: ESTADO
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(labelText: "Estado"),
                      items: _states
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedState = val),
                    ),
                    const SizedBox(height: 15),

                    // CAMPO 5: FOTO
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover)
                                : (_networkImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_networkImageUrl!),
                                        fit: BoxFit.cover)
                                    : null)),
                        child: _imageFile == null && _networkImageUrl == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text("Tocar para tomar foto"),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 25),

                    FilledButton(
                      onPressed: _saveData,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text("GUARDAR DATOS"),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET ESCÁNER SIMPLE (CORREGIDO)
// ---------------------------------------------------------------------------
class SimpleScanner extends StatefulWidget {
  const SimpleScanner({super.key});

  @override
  State<SimpleScanner> createState() => _SimpleScannerState();
}

class _SimpleScannerState extends State<SimpleScanner> {
  bool _hasScanned = false; // Flag para evitar múltiples lecturas

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Código")),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasScanned) return; // Si ya escaneó, ignorar

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              setState(() {
                _hasScanned = true; // Marcar como escaneado
              });

              // Devolvemos el primer código encontrado
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

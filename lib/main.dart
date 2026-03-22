import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'content_page.dart';

void main() {
  initializeDateFormatting('es_ES', null).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => AuthProvider(),
        child: const WacoApp(),
      ),
    );
  });
}

// --- MODELS ---
class UserModel {
  final int id;
  final String name;
  final String avatarUrl;
  // Added to support role-based logic
  final List<String> roles;

  UserModel({required this.id, required this.name, required this.avatarUrl, required this.roles});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_urls']['96'],
      // Ensure roles is always a list of strings
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  // Helper to check for a role
  bool hasRole(String role) => roles.contains(role);
}

// --- PROVIDERS ---
class AuthProvider extends ChangeNotifier {
  String? _token;
  UserModel? _user;

  String? get token => _token;
  UserModel? get user => _user;

  bool get isAuthenticated => _token != null && _user != null;

  final AuthService _authService = AuthService('https://yosoyve.eterica.website');

  Future<bool> loginAndSetUser(String username, String password) async {
    final result = await _authService.login(username, password);
    if (result.token != null && !result.hasError) {
      _token = result.token;
      try {
        final user = await _authService.getProfile(_token!);
        if (user != null) {
          _user = user;
          notifyListeners();
          return true;
        } else {
          logout();
          return false;
        }
      } catch (e) {
        logout();
        return false;
      }
    }
    return false;
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}

// --- SERVICES ---
class AuthService {
  final String wordpressUrl;

  AuthService(this.wordpressUrl);

  Future<AuthResult> login(String username, String password) async {
    final url = Uri.parse('$wordpressUrl/wp-json/jwt-auth/v1/token');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return AuthResult(token: body['token']);
      } else {
        return AuthResult(error: 'Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return AuthResult(error: 'Error de Red: $e');
    }
  }

  Future<UserModel?> getProfile(String token) async {
    // The 'context=edit' is crucial to get all user data including roles
    final url = Uri.parse('$wordpressUrl/wp-json/wp/v2/users/me?context=edit');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        // You may want to log the error here
        return null;
      }
    } catch (e) {
      // You may want to log the error here
      return null;
    }
  }
}

class AuthResult {
  final String? token;
  final String? error;
  AuthResult({this.token, this.error});
  bool get hasError => error != null;
}

// --- MAIN APP WIDGETS ---
class WacoApp extends StatelessWidget {
  const WacoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waco 0.4',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const MyHomePage(title: 'Waco 0.4'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late Stream<DateTime> _dateTimeStream;

  @override
  void initState() {
    super.initState();
    _dateTimeStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final List<Widget> widgetOptions = <Widget>[
      const InfoCard(text: 'Miranda'),
      const InfoCard(text: 'Página de Literatura'),
      authProvider.isAuthenticated ? const ProfilePage() : const LoginPage(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: authProvider.isAuthenticated
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _showAboutDialog(context),
              child: Image.asset('assets/images/Logo.png', height: 48),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StreamBuilder<DateTime>(
              stream: _dateTimeStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(width: 80);
                final dt = snapshot.data!;
                return SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat.Hms().format(dt), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(DateFormat.yMMMMd('es').format(dt), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
      ),
      drawer: authProvider.isAuthenticated ? const MainDrawer() : null,
      body: Container(
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/background/roraima_van_gogh.jpg'), fit: BoxFit.cover)),
        child: Center(child: widgetOptions.elementAt(_selectedIndex)),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Literatura'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Usuario'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber[200],
            unselectedItemColor: Colors.white70,
            onTap: _onItemTapped,
            backgroundColor: Colors.black.withOpacity(0.2),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.black.withAlpha(128),
            title: const Text('Acerca de Waco 0.4', style: TextStyle(color: Colors.white)),
            content: const Text('Esta es una aplicación de demostración de Flutter.', style: TextStyle(color: Colors.white)),
            actions: <Widget>[
              TextButton(
                child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- CUSTOM WIDGETS ---
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Helper function to create a ListTile and handle navigation
    Widget _buildMenuTile({required String title, required IconData icon, required VoidCallback onTap}) {
      return ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onTap: () {
          Navigator.pop(context); // Close the drawer
          onTap(); // Execute the specific action
        },
      );
    }

    return Drawer(
      backgroundColor: Colors.black.withOpacity(0.85),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1)),
            child: Center(child: Image.asset('assets/images/Logo.png', height: 80)),
          ),

          // --- MENU ITEMS ---

          // Example: Item visible to everyone
          _buildMenuTile(
            title: 'Formulario Base Electoral 2026',
            icon: Icons.how_to_vote,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContentPage(
                    url: 'https://yosoyve.eterica.website/demo-formulario-base-electoral-2026/',
                    title: 'Formulario Electoral',
                  ),
                ),
              );
            },
          ),

          // Example: Item for Transcriptores, Editors, and Administrators
          if (user != null && (user.hasRole('transcriptor') || user.hasRole('editor') || user.hasRole('administrator')))
            _buildMenuTile(
              title: 'Panel de Transcripción',
              icon: Icons.edit_document,
              onTap: () {
                // TODO: Navigate to the Transcription Panel page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Acceso a Panel de Transcripción (Próximamente)')),
                );
              },
            ),

          // Example: Item ONLY for Editors and Administrators
          if (user != null && (user.hasRole('editor') || user.hasRole('administrator')))
            _buildMenuTile(
              title: 'Validar Contenido',
              icon: Icons.check_circle_outline,
              onTap: () {
                // TODO: Navigate to the Validation page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Acceso a Validación de Contenido (Próximamente)')),
                );
              },
            ),
            
          // Example: Item ONLY for Administrators
          if (user != null && user.hasRole('administrator'))
            _buildMenuTile(
              title: 'Administración General',
              icon: Icons.admin_panel_settings,
              onTap: () {
                // TODO: Navigate to the Admin page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Acceso a Administración (Próximamente)')),
                );
              },
            ),

        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  const InfoCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginAndSetUser(_usernameController.text, _passwordController.text);

    if (!mounted) return;

    if (success) {
      // Login was successful, ProfilePage will be shown
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Usuario o contraseña incorrectos.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(178),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(128),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Acceso de Usuario', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Usuario o Email', labelStyle: TextStyle(color: Colors.white), prefixIcon: Icon(Icons.person, color: Colors.white), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => (v == null || v.isEmpty) ? 'Por favor, introduce tu usuario' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => (v == null || v.isEmpty) ? 'Por favor, introduce tu contraseña' : null,
                  ),
                  const SizedBox(height: 30),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 14), textAlign: TextAlign.center),
                    ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.amber[200],
                      disabledBackgroundColor: Colors.amber[200]?.withOpacity(0.5),
                      disabledForegroundColor: Colors.black.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Acceder'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 5.0))),
          ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(178),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(128), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Perfil de Usuario', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(user.avatarUrl), backgroundColor: Colors.grey[800]),
            const SizedBox(height: 20),
            Text(user.name, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Display the user roles
            Text(user.roles.join(', ').toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            const Divider(color: Colors.white54),
            const SizedBox(height: 10),
            _buildMenu(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.edit, color: Colors.white),
          title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función aún no implementada.'))),
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.white),
          title: const Text('Configuración', style: TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función aún no implementada.'))),
        ),
        const Divider(color: Colors.white54),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
          onTap: () => authProvider.logout(),
        ),
      ],
    );
  }
}

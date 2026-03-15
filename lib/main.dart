
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

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

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  void login(String token) {
    _token = token;
    notifyListeners();
  }

  void logout() {
    _token = null;
    notifyListeners();
  }
}


class WacoApp extends StatelessWidget {
  const WacoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waco 0.4',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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

  Widget _getUserPage(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return authProvider.isAuthenticated ? const ProfilePage() : const LoginPage();
  }

  @override
  void initState() {
    super.initState();
    _dateTimeStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.5),
            title: const Text('Acerca de Waco 0.4', style: TextStyle(color: Colors.white)),
            content: const Text('Esta es una aplicación de demostración de Flutter.', style: TextStyle(color: Colors.white)),
            actions: <Widget>[
              TextButton(
                child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      const InfoCard(text: 'Página de Inicio'),
      const InfoCard(text: 'Página de Literatura'),
      _getUserPage(context),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: _showAboutDialog,
              child: Image.asset('assets/images/Logo.png', height: 48),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StreamBuilder<DateTime>(
              stream: _dateTimeStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final dateTime = snapshot.data!;
                  final timeString = DateFormat.Hms().format(dateTime);
                  final dateString = DateFormat.yMMMMd('es').format(dateTime);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(timeString, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(dateString, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Literatura',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Usuario',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[200],
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  const InfoCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AuthService {
  final String wordpressUrl;

  AuthService(this.wordpressUrl);

  Future<String?> login(String username, String password) async {
    final url = Uri.parse('$wordpressUrl/wp-json/jwt-auth/v1/token');
    try {
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['token'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
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
  final _authService = AuthService('https://yosoyve.eterica.website');

  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (token != null) {
        Provider.of<AuthProvider>(context, listen: false).login(token);
      } else {
        setState(() {
          _errorMessage = 'Usuario o contraseña incorrectos.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Acceso de Usuario',
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuario o Email',
                labelStyle: TextStyle(color: Colors.white),
                prefixIcon: Icon(Icons.person, color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce tu usuario';
                }
                return null;
              },
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
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce tu contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Colors.amber[200],
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Acceder'),
                  ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Perfil de Usuario',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.account_circle, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            '¡Bienvenido!',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

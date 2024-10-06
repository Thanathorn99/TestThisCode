import 'package:flutter/material.dart';
// ignore: unused_import
import '../database/auth.dart';
// ignore: unused_import
import '../database/database_helper.dart';
// ignore: unused_import
import '../pages/product.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _passwd = '';

  Future _showAlert(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent.shade100, Colors.orange.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            width: 350, // Width of the box
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // เพิ่มความโปร่งใส
              borderRadius: BorderRadius.circular(24), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.2), // Shadow with light opacity
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 4), // Changes position of shadow
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 100.0,
                  child: Text(
                    'Clean-Up App',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 12,
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(
                  Icons.person, // Cleaning related icon
                  size: 200,
                  color: Colors.orange,
                ),
                const SizedBox(height: 25.0),
                TextFormField(
                  key: UniqueKey(),
                  obscureText: false,
                  initialValue: _email,
                  autofocus: true,
                  onChanged: (value) => _email = value,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.email, color: Colors.orange.shade700),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 15.0,
                    ),
                    hintText: "Email",
                    hintStyle: TextStyle(color: Colors.orange.shade300),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                    filled: true,
                    fillColor: Colors.orange[50], // Light orange color
                  ),
                ),
                const SizedBox(height: 25.0),
                TextFormField(
                  key: UniqueKey(),
                  obscureText: true,
                  initialValue: _passwd,
                  onChanged: (value) => _passwd = value,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.orange.shade700),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 15.0,
                    ),
                    hintText: "Password",
                    hintStyle: TextStyle(color: Colors.orange.shade300),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                    filled: true,
                    fillColor: Colors.orange[50], // Light orange color
                  ),
                ),
                const SizedBox(height: 35.0),
                Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(30.0),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orangeAccent, Colors.orange.shade500],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await UserAuthentication()
                            .signInWithEmailAndPassword(_email, _passwd)
                            .then((res) {
                          if (res == true) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                      dbHelper: DatabaseHelper(),
                                    )));
                            setState(() {
                              _email = '';
                              _passwd = '';
                            });
                          } else {
                            _showAlert(context,
                                'Invalid email or password for logging in');
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        width: MediaQuery.of(context).size.width,
                        child: const Text(
                          "Login",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

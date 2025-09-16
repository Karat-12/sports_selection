import 'package:flutter/material.dart';
import 'upload_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      Future.delayed(Duration(seconds: 1), () {
        setState(() => loading = false);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UploadScreen()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email',
                    onChanged: (val) => email = val,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (val) => val != null && val.length >= 6 ? null : 'Password must be 6+ chars',
                    onChanged: (val) => password = val,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Login', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'video_upload.dart';

//REGISTER PAGE
class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  RegisterPageState createState() => RegisterPageState();
}

//create new accout with user details

class RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController aadharController = TextEditingController();

  String? selectedCountry;
  String? selectedState;
  String? selectedCity;
  DateTime? selectedDob;

  //create new account with user details
  Future<void> _registerUser() async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Store extra details in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid) // Use UID as document ID
          .set({
            "uid": userCredential.user!.uid,
            "full_name": nameController.text.trim(),
            "email": emailController.text.trim(),
            "mobile": mobileController.text.trim(),
            "country": selectedCountry,
            "state": selectedState,
            "city": selectedCity,
            "dob": selectedDob?.toIso8601String(),
            "school_college": schoolController.text.trim(),
            "aadhar_no": aadharController.text.trim(),
          });

      // Success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registered Successfully!")));
      // we need t o navigate to login page after registration
      // Navigate after success
      /*Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>  VideoUploadPage()),// removed const fior this widjet
    );*/
    } on FirebaseAuthException catch (e) {
      // Handle errors like weak password / email already in use
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: "Mobile Number"),
              ),
              const SizedBox(height: 10),

              /// Dropdowns
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Country"),
                items: ["India", "USA", "UK", "Other"]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCountry = val),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "State"),
                items: ["Karnataka", "Maharashtra", "Delhi", "Other"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => selectedState = val),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "City"),
                items: ["Bangalore", "Mumbai", "Delhi", "Other"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCity = val),
              ),
              const SizedBox(height: 10),

              /// DOB Picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDob == null
                          ? "Date of Birth: Not Selected"
                          : "Date of Birth: ${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}",
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        initialDate: DateTime(2005),
                      );
                      if (picked != null) {
                        setState(() => selectedDob = picked);
                      }
                    },
                    child: const Text("Select"),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: schoolController,
                decoration: const InputDecoration(
                  labelText: "School/College Name",
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: aadharController,
                decoration: const InputDecoration(labelText: "Aadhar Number"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              /// Terms & Conditions
              Row(
                children: [
                  Checkbox(value: true, onChanged: (val) {}),
                  const Expanded(
                    child: Text(
                      "By registering, you agree to our Terms & Conditions",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _registerUser(); // Call the function

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Registered Successfully!")),
                    );
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VideoUploadPage()),
                  );
                },
                child: const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//LOGIN PAGE
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Firebase sign in
                  UserCredential userCredential = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                  // Login success
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Login Successful")),
                  );

                  // Navigate to VideoUploadPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VideoUploadPage()),
                  );
                } on FirebaseAuthException catch (e) {
                  // Handle login errors
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Login failed: ${e.message}")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Unexpected error: $e")),
                  );
                }
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticket_system/screens/loginscreen.dart';

import '../core/services/api_register.dart';


class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}


class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _positionController = TextEditingController();


  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;


  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;


  // ================= PASSWORD RULES =================
  bool get _hasMinLength       => _passwordController.text.length >= 8;
  bool get _hasUppercase       => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase       => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber          => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar     => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]'));

  String? _validatePassword(String password) {
    if (password.isEmpty) return "Password is required";
    if (!_hasMinLength)   return "Must be at least 8 characters";
    if (!_hasUppercase)   return "Must contain an uppercase letter";
    if (!_hasLowercase)   return "Must contain a lowercase letter";
    if (!_hasNumber)      return "Must contain a number";
    if (!_hasSpecialChar) return "Must contain a special character";
    return null;
  }


  // ================= FORM =================
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _field("Username", _usernameController, null)),
            const SizedBox(width: 15),
            Expanded(child: _field("Email", _emailController, emailError)),
          ],
        ),


        const SizedBox(height: 15),


        Row(
          children: [
            Expanded(child: _field("Full Name", _nameController, nameError)),
            const SizedBox(width: 15),
            Expanded(child: _positionField()),
          ],
        ),


        const SizedBox(height: 15),


        _passwordField(),
        const SizedBox(height: 15),
        _confirmPasswordField(),


        const SizedBox(height: 25),


        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF268A15),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Register"),
          ),
        ),
      ],
    );
  }


  // ================= FIELD BUILDER =================
  Widget _field(String label, TextEditingController controller, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF111827)),
          decoration: _inputDecoration(label, error),
        ),
      ],
    );
  }


  // ================= POSITION =================
  Widget _positionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Position",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),


        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          value: _positionController.text.isEmpty
              ? null
              : _positionController.text,
          items: ["Analytics Engineer - OIC, Application Analyst 2, Application Developer, Application Developer 1 - OIC, Business Intelligence Analyst - OIC, Business Intelligence Lead OIC, Business Relationship Manager - OIC, Chief Data Officer - OIC, Chief Data Scientist - OIC, Chief Operating Officer - OIC, Cloud Engineer - OIC, Cloud Operations Administrator - OIC, Cloud Operations Support, Compliance, Compliance Officer, Data Scientist OIC, DDFA- OIC, Developer, Developer 1, Developer 1 - OIC, Developer 2 - OIC, Finance Assistant, Information Security Officer - OIC, Junior Analytics Developer, Junior Analytics Engineer, Junior Data Engineer, Machine Learning Engineer OIC, Product Specialist, Product Specialist 1, Product Specialist 1 - OIC, Product Specialist Head OIC, Project Manager - OIC, Quality Assurance Analyst, Quality Assurance Analyst 1, Quality Assurance Manager, Report Specialist I, Report Specialist II, Report Specialist II - OIC, Report Specialist III, Report Specialist III - OIC, Risk Management Officer - OIC, Senior Finance Officer OIC"]
              .map(
                (pos) => DropdownMenuItem(
              value: pos,
              child: Text(
                pos,
                style: const TextStyle(color: Color(0xFF111827)),
              ),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() {
              _positionController.text = value!;
            });
          },
          decoration: _inputDecoration("Select position", null),
        ),
      ],
    );
  }

  // ================= PASSWORD =================
  Widget _passwordField() {
    final password = _passwordController.text;
    final showRules = password.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 5),

        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enableSuggestions: false,
          autocorrect: false,
          style: const TextStyle(color: Color(0xFF111827)),
          onChanged: (_) => setState(() {}), // rebuild to update rule indicators
          decoration: _inputDecoration(
            "Password",
            passwordError,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF268A15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Live password rule indicators ──────────────────
        _passwordRule("At least 8 characters",   _hasMinLength,   showRules),
        _passwordRule("Uppercase letter (A–Z)",   _hasUppercase,   showRules),
        _passwordRule("Lowercase letter (a–z)",   _hasLowercase,   showRules),
        _passwordRule("Number (0–9)",              _hasNumber,      showRules),
        _passwordRule("Special character (!@#…)", _hasSpecialChar, showRules),
      ],
    );
  }

  // ================= PASSWORD RULE ROW =================
  Widget _passwordRule(String label, bool met, bool showRules) {
    final color = !showRules
        ? const Color(0xFF9CA3AF)
        : met
        ? const Color(0xFF268A15)
        : Colors.red;

    final icon = !showRules
        ? Icons.radio_button_unchecked
        : met
        ? Icons.check_circle
        : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, height: 1.4),
          ),
        ],
      ),
    );
  }


  Widget _confirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Confirm Password",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),


        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: const TextStyle(color: Color(0xFF111827)),
          decoration: _inputDecoration(
            "Confirm Password",
            confirmPasswordError,
            suffix: GestureDetector(
              onTap: () => setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }),
              child: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: const Color(0xFF268A15),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ================= DECORATION =================
  InputDecoration _inputDecoration(
      String hint,
      String? error, {
        Widget? suffix,
      }) {
    final isError = error != null;


    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF4F6F9),


      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isError ? Colors.red : const Color(0xFFE5E7EB),
        ),
      ),


      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isError ? Colors.red : const Color(0xFF268A15),
          width: 2,
        ),
      ),


      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),


      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),


      errorText: error,
    );
  }


  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }


  void _handleRegister() async {
    setState(() {
      nameError = _nameController.text.isEmpty ? "Name is required" : null;

      if (_emailController.text.isEmpty) {
        emailError = "Email is required";
      } else if (!_isValidEmail(_emailController.text)) {
        emailError = "Enter a valid email";
      } else {
        emailError = null;
      }

      // ✅ Full password validation
      passwordError = _validatePassword(_passwordController.text);

      // ✅ Confirm password check
      if (_confirmPasswordController.text.isEmpty) {
        confirmPasswordError = "Please confirm your password";
      } else if (_confirmPasswordController.text != _passwordController.text) {
        confirmPasswordError = "Passwords do not match";
      } else {
        confirmPasswordError = null;
      }
    });


    if (nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null) {
      try {
        await ApiRegistration.registerUser(
          username: _usernameController.text,
          email: _emailController.text,
          fullName: _nameController.text,
          position: _positionController.text,
          password: _passwordController.text,
        );


        if (!mounted) return;


        _showSuccessDialog();
      } catch (e) {
        if (!mounted) return;


        String message = e.toString();


        if (message.toLowerCase().contains("exist")) {
          _showErrorDialog("User already exists");
        } else {
          _showErrorDialog("Registration failed. Please try again.");
        }
      }
    }
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF268A15),
                    size: 60,
                  ),


                  const SizedBox(height: 15),


                  const Text(
                    "Registration Successful",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),


                  const SizedBox(height: 10),


                  const Text(
                    "Your account has been created successfully. Wait for the Admin to approve your registration",
                    textAlign: TextAlign.center,
                  ),


                  const SizedBox(height: 20),


                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Go to Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),


                  const SizedBox(height: 15),


                  const Text(
                    "Registration Failed",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),


                  const SizedBox(height: 10),


                  Text(message, textAlign: TextAlign.center),


                  const SizedBox(height: 20),


                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("OK"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;


          return Row(
            children: [
              // ================= LEFT PANEL (LOGO) =================
              if (!isMobile)
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xFFFFFFFF),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/favicon1.png',
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),


                          const Text(
                            'IDIYANALE',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),


                          const SizedBox(height: 10),


                          const Text(
                            'Bakawan Ticketing System',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


              // ================= RIGHT PANEL (FORM) =================
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Color(0xFF111827),
                                    ),
                                  ),


                                  const SizedBox(width: 5),


                                  const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),


                              const SizedBox(height: 20),


                              _buildForm(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
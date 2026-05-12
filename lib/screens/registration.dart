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
  final _nameController        = TextEditingController();
  final _lastNameController    = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController    = TextEditingController();
  final _positionController    = TextEditingController();
  final _institutionController = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;

  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? positionError;
  String? institutionError;

  // ================= POSITION LIST =================
  static const List<String> _positions = [
    'Analytics Engineer - OIC',
    'Application Analyst 2',
    'Application Developer',
    'Application Developer 1 - OIC',
    'Business Intelligence Analyst - OIC',
    'Business Intelligence Lead OIC',
    'Business Relationship Manager - OIC',
    'Chief Data Officer - OIC',
    'Chief Data Scientist - OIC',
    'Chief Operating Officer - OIC',
    'Cloud Engineer - OIC',
    'Cloud Operations Administrator - OIC',
    'Cloud Operations Support',
    'Compliance',
    'Compliance Officer',
    'Data Scientist OIC',
    'DDFA- OIC',
    'Developer',
    'Developer 1',
    'Developer 1 - OIC',
    'Developer 2 - OIC',
    'Finance Assistant',
    'Information Security Officer - OIC',
    'Junior Analytics Developer',
    'Junior Analytics Engineer',
    'Junior Data Engineer',
    'Machine Learning Engineer OIC',
    'Product Specialist',
    'Product Specialist 1',
    'Product Specialist 1 - OIC',
    'Product Specialist Head OIC',
    'Project Manager - OIC',
    'Quality Assurance Analyst',
    'Quality Assurance Analyst 1',
    'Quality Assurance Manager',
    'Report Specialist I',
    'Report Specialist II',
    'Report Specialist II - OIC',
    'Report Specialist III',
    'Report Specialist III - OIC',
    'Risk Management Officer - OIC',
    'Senior Finance Officer OIC',
  ];

  // ================= INSTITUTION LIST =================
  static const List<String> _institutions = [
    'MHI Healthcare Inc.',
    'CMIT',
    'FDSAP',
    'Bakawan Data Analytics',
    'EMPC',
    'CARD Bank',
    'CARD SME Bank',
    'CARD RBI',
    'CARD Inc.',
    'Padayon Microfinance',
    'Astro',
    'Laguna Fresh',
    'CARD MRI International Partnership Project Institution',
    'CARD MRI Holdings Company',
    'CARD MBA',
    'Bente Production',
    'Hijos Tours',
    'CARD Publishing House',
    'CARD Indogrosir Inc.',
    'LIKHA NI INAY',
    'OTTO KONEK',
    'CARD Pioneer Microinsurance Inc.',
    'CARD Mutually Reinforcing Institutions',
    'CARD Engagement Services Inc.',
    'CARD MRI Development Institute Inc.',
    'CARD-PCPD',
    'BotiCARD Pharmacy',
    'CaMIA (CARD MRI Insurance Agency)',
    'CARD MBA Pioneer',
  ];

  // ================= PASSWORD RULES =================
  bool get _hasMinLength   => _passwordController.text.length >= 8;
  bool get _hasUppercase   => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase   => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber      => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]'));

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
        // Row 1: First Name | Last Name
        Row(
          children: [
            Expanded(child: _firstNameField()),
            const SizedBox(width: 15),
            Expanded(child: _lastNameField()),
          ],
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(child: _usernameField()),
            const SizedBox(width: 15),
            Expanded(child: _emailField()),
          ],
        ),

        const SizedBox(height: 15),

        // Row 3: Position | Institution
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _positionField()),
            const SizedBox(width: 15),
            Expanded(child: _institutionField()),
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

  // ================= USERNAME FIELD =================
  Widget _usernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Username",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _usernameController,
          style: const TextStyle(color: Color(0xFF111827)),
          onChanged: (_) {
            setState(() {});
          },
          decoration: _inputDecoration("Enter username", null),
        ),
      ],
    );
  }

  // ================= FIRST NAME FIELD =================
  Widget _firstNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "First Name",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Color(0xFF111827)),
          onChanged: (_) {
            if (firstNameError != null) {
              setState(() => firstNameError = null);
            }
          },
          decoration: _inputDecoration(
            "First Name",
            firstNameError,
          ),
        ),
      ],
    );
  }

// ================= LAST NAME FIELD =================
  Widget _lastNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Last Name",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _lastNameController,
          style: const TextStyle(color: Color(0xFF111827)),
          onChanged: (_) {
            if (lastNameError != null) {
              setState(() => lastNameError = null);
            }
          },
          decoration: _inputDecoration(
            "Last Name",
            lastNameError,
          ),
        ),
      ],
    );
  }

  // ================= EMAIL FIELD =================
  Widget _emailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Email",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Color(0xFF111827)),
          onChanged: (_) {
            if (emailError != null) setState(() => emailError = null);
          },
          decoration: _inputDecoration("Email", emailError),
        ),
      ],
    );
  }

  // ================= POSITION (AUTOCOMPLETE) =================
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

        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return _positions;
            return _positions.where((pos) =>
                pos.toLowerCase().contains(
                    textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _positionController.text = selection;
              positionError = null;
            });
          },
          fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
            if (_positionController.text.isNotEmpty &&
                fieldController.text.isEmpty) {
              fieldController.text = _positionController.text;
            }
            return TextField(
              controller: fieldController,
              focusNode: focusNode,
              style: const TextStyle(color: Color(0xFF111827)),
              onChanged: (val) {
                _positionController.text = val;
                if (positionError != null) setState(() => positionError = null);
              },
              decoration: _inputDecoration(
                "Search position…",
                positionError,
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) =>
              _optionsView(options, onSelected),
        ),

        if (positionError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              positionError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ================= INSTITUTION (AUTOCOMPLETE) =================
  Widget _institutionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Institution",
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),

        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return _institutions;
            return _institutions.where((inst) =>
                inst.toLowerCase().contains(
                    textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            setState(() {
              _institutionController.text = selection;
              institutionError = null;
            });
          },
          fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
            if (_institutionController.text.isNotEmpty &&
                fieldController.text.isEmpty) {
              fieldController.text = _institutionController.text;
            }
            return TextField(
              controller: fieldController,
              focusNode: focusNode,
              style: const TextStyle(color: Color(0xFF111827)),
              onChanged: (val) {
                _institutionController.text = val;
                if (institutionError != null) setState(() => institutionError = null);
              },
              decoration: _inputDecoration(
                "Search institution…",
                institutionError,
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) =>
              _optionsView(options, onSelected),
        ),

        if (institutionError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              institutionError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ================= SHARED OPTIONS VIEW =================
  Widget _optionsView(
      Iterable<String> options,
      void Function(String) onSelected,
      ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return InkWell(
                onTap: () => onSelected(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= PASSWORD =================
  Widget _passwordField() {
    final showRules = _passwordController.text.isNotEmpty;

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
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration(
            "Password",
            passwordError,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF268A15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

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
        : met ? const Color(0xFF268A15) : Colors.red;

    final icon = !showRules
        ? Icons.radio_button_unchecked
        : met ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 12, color: color, height: 1.4)),
        ],
      ),
    );
  }

  // ================= CONFIRM PASSWORD =================
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
              onTap: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
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
  InputDecoration _inputDecoration(String hint, String? error,
      {Widget? suffix}) {
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

  // ================= REGISTER HANDLER =================
  void _handleRegister() async {
    setState(() {
      firstNameError =
      _nameController.text.isEmpty ? "First name is required" : null;
      lastNameError =
      _lastNameController.text.isEmpty ? "Last name is required" : null;

      if (_emailController.text.isEmpty) {
        emailError = "Email is required";
      } else if (!_isValidEmail(_emailController.text)) {
        emailError = "Enter a valid email";
      } else {
        emailError = null;
      }

      positionError = _positionController.text.isEmpty
          ? "Please select a position"
          : null;

      institutionError = _institutionController.text.isEmpty
          ? "Please select an institution"
          : null;

      passwordError = _validatePassword(_passwordController.text);

      if (_confirmPasswordController.text.isEmpty) {
        confirmPasswordError = "Please confirm your password";
      } else if (_confirmPasswordController.text != _passwordController.text) {
        confirmPasswordError = "Passwords do not match";
      } else {
        confirmPasswordError = null;
      }
    });

    if (firstNameError == null &&
        lastNameError == null &&
        emailError == null &&
        positionError == null &&
        institutionError == null &&
        passwordError == null &&
        confirmPasswordError == null) {
      try {
        await ApiRegistration.registerUser(
          username:    _usernameController.text,
          email:       _emailController.text,
          firstName:   _nameController.text,
          lastName:    _lastNameController.text,
          position:    _positionController.text,
          institution: _institutionController.text,
          password:    _passwordController.text,
        );

        if (!mounted) return;
        _showSuccessDialog();
      } catch (e) {
        if (!mounted) return;
        final message = e.toString();
        if (message.toLowerCase().contains("exist")) {
          _showErrorDialog("User already exists");
        } else {
          _showErrorDialog("Registration failed. Please try again.");
        }
      }
    }
  }

  // ================= SUCCESS DIALOG =================
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF268A15), size: 60),
                  const SizedBox(height: 15),
                  const Text(
                    "Registration Successful",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              builder: (context) => LoginScreen()),
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

  // ================= ERROR DIALOG =================
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;

          return Row(
            children: [
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
                            border:
                            Border.all(color: const Color(0xFFE5E7EB)),
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
                                    onPressed: () =>
                                        Navigator.pop(context),
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
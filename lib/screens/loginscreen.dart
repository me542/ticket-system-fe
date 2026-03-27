import 'package:flutter/material.dart';
import 'package:ticket_system/core/services/api_register.dart';
import 'package:ticket_system/core/services/api_login.dart';
import 'package:ticket_system/main.dart';
import 'package:ticket_system/screens/dashboard_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginTab = true;
  bool _obscurePassword = true;
  bool _obscurePasswordReg = true;
  bool _showSecondRegisterStep = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Register form controllers
  final _usernameController = TextEditingController();
  final _passwordRegController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailRegController = TextEditingController();

  //String? _selectedRole;
  String? _selectedPosition;
  String? _emailError;

  //final List<String> _roles = ['Approver', 'Endorser', 'Resolver'];
  final List<String> _positions = ['Product Specialist', 'Quality Assurance', 'Cloud Operation Support'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _passwordRegController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailRegController.dispose();
    super.dispose();
  }

  void _resetRegisterForm() {
    _usernameController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailRegController.clear();
    _passwordRegController.clear();
    //_selectedRole = null;
    _selectedPosition = null;
    _showSecondRegisterStep = false;
    _emailError = null;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isFirstStepValid() {
    return _usernameController.text.isNotEmpty &&
        _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty;
  }

  bool _isSecondStepValid() {
    return _emailRegController.text.isNotEmpty &&
        _passwordRegController.text.isNotEmpty &&
        _selectedPosition != null &&
        //_selectedRole != null &&
        _emailError == null;
  }

  void _validateEmail(String email) {
    setState(() {
      if (email.isEmpty) {
        _emailError = null;
      } else if (!_isValidEmail(email)) {
        _emailError = 'Invalid email format';
      } else {
        _emailError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with letter icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF268A15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'TS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Title
              const Text(
                'Ticket System',
                style: TextStyle(
                  color: Color(0xFF268A15),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),

              // Subtitle
              const Text(
                'Test',
                style: TextStyle(
                  color: Color(0xFF8A92A3),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),

              // Login Form Container - Smaller Width
              Center(
                child: Container(
                  width: 500,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2A3142),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Login/Register Tabs
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLoginTab = true;
                                  _resetRegisterForm();
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      color: _isLoginTab
                                          ? const Color(0xFF268A15)
                                          : const Color(0xFF8A92A3),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: _isLoginTab
                                          ? const Color(0xFF268A15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLoginTab = false;
                                  _resetRegisterForm();
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    'Register',
                                    style: TextStyle(
                                      color: !_isLoginTab
                                          ? const Color(0xFF268A15)
                                          : const Color(0xFF8A92A3),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: !_isLoginTab
                                          ? const Color(0xFF268A15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // LOGIN TAB
                      if (_isLoginTab) ...[
                        // Email Field
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: Color(0xFF8A92A3),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'admin@example.com',
                            hintStyle: const TextStyle(
                              color: Color(0xFF4A5268),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF268A15),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F1419),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF2A3142),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF2A3142),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF268A15),
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: Color(0xFF8A92A3),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF4A5268),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: Color(0xFF268A15),
                              size: 20,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF268A15),
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F1419),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF2A3142),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF2A3142),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF268A15),
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter username and password'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final response = await ApiLogin.login(
                                username: _usernameController.text.trim(),
                                password: _passwordController.text.trim(),
                              );

                              if (response['success'] == true) {
                                // ✅ LOGIN SUCCESS
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Login successful'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MainShell(),
                                  ),
                                );

                              } else {
                                // ❌ LOGIN FAILED
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response['error'] ?? 'Login failed'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },


                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF268A15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ]

                      // REGISTER TAB
                      else ...[
                        // STEP 1: Username, First Name, Last Name
                        if (!_showSecondRegisterStep) ...[
                          // Username Field
                          const Text(
                            'Username',
                            style: TextStyle(
                              color: Color(0xFF8A92A3),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Username',
                              hintStyle: const TextStyle(
                                color: Color(0xFF4A5268),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF268A15),
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F1419),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF268A15),
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // First Name Field
                          const Text(
                            'First Name',
                            style: TextStyle(
                              color: Color(0xFF8A92A3),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _firstNameController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Name',
                              hintStyle: const TextStyle(
                                color: Color(0xFF4A5268),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF268A15),
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F1419),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF268A15),
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Last Name Field
                          const Text(
                            'Last Name',
                            style: TextStyle(
                              color: Color(0xFF8A92A3),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _lastNameController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Lastname',
                              hintStyle: const TextStyle(
                                color: Color(0xFF4A5268),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF268A15),
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F1419),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF268A15),
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Next Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isFirstStepValid()
                                  ? () {
                                setState(() {
                                  _showSecondRegisterStep = true;
                                });
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFirstStepValid()
                                    ? const Color(0xFF268A15)
                                    : Colors.grey[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ]

                        // STEP 2: Email, Password, Position, Role
                        else ...[
                          // Email Field
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: Color(0xFF8A92A3),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _emailRegController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: _validateEmail,
                            decoration: InputDecoration(
                              hintText: '@example.com',
                              hintStyle: const TextStyle(
                                color: Color(0xFF4A5268),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF268A15),
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F1419),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _emailError != null
                                      ? Colors.red
                                      : const Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _emailError != null
                                      ? Colors.red
                                      : const Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _emailError != null
                                      ? Colors.red
                                      : const Color(0xFF268A15),
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _emailError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),

                          // Password Field
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFF8A92A3),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _passwordRegController,
                            obscureText: _obscurePasswordReg,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(
                                color: Color(0xFF4A5268),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outlined,
                                color: Color(0xFF268A15),
                                size: 20,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obscurePasswordReg = !_obscurePasswordReg;
                                  });
                                },
                                child: Icon(
                                  _obscurePasswordReg
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF268A15),
                                  size: 20,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F1419),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A3142),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF268A15),
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Position Dropdown
                          const Text(
                            'Position',
                            style: TextStyle(
                              color: Color(0xFF8A92A3),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2A3142),
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPosition,
                              hint: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Select a position',
                                  style: const TextStyle(
                                    color: Color(0xFF4A5268),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: const Color(0xFF1A1F2E),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPosition = newValue;
                                });
                              },
                              items: _positions.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Role Dropdown
                          /*const Text(
                            'Role',
                            style: TextStyle(
                              color: Color(0xFF8A92A3),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2A3142),
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              hint: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Select a role',
                                  style: const TextStyle(
                                    color: Color(0xFF4A5268),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: const Color(0xFF1A1F2E),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue;
                                });
                              },
                              items: _roles.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          ),*/
                          const SizedBox(height: 20),

                          // Back and Register Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showSecondRegisterStep = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: Color(0xFF268A15),
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(
                                      color: Color(0xFF268A15),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(onPressed: _isSecondStepValid()
                                    ? () async {
                                  try {
                                    final response = await ApiRegister.register(
                                      username: _usernameController.text,
                                      password: _passwordRegController.text,
                                      firstName: _firstNameController.text,
                                      lastName: _lastNameController.text,
                                      email: _emailRegController.text,
                                      position: _selectedPosition!,
                                    );

                                    // ✅ SUCCESS
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Registration successful!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // OPTIONAL: go to login tab
                                    setState(() {
                                      _isLoginTab = true;
                                      _resetRegisterForm();
                                    });

                                    // OR navigate directly
                                    // Navigator.pushReplacementNamed(context, AppRoutes.dashboard);

                                  } catch (e) {
                                    // ❌ ERROR
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                                    : null,

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSecondStepValid()
                                        ? const Color(0xFF268A15)
                                        : Colors.grey[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:ui';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticket_system/core/services/api_login.dart';
import 'package:ticket_system/core/services/api_forgot_password.dart';
import 'package:ticket_system/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => emailError = 'Please enter your email');
    }
    if (password.isEmpty) {
      setState(() => passwordError = 'Please enter your password');
    }
    if (email.isEmpty || password.isEmpty) return;

    final response = await ApiLogin.login(
      username: email,
      password: password,
    );

    if (response['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainShell(),
        ),
      );
    } else {
      setState(() {
        emailError = ' ';
        passwordError =
            response['error'] ?? 'Invalid email or password';
      });
    }
  }

  // =========================
  // FORGOT PASSWORD DIALOG (ENTER EMAIL)
  // =========================

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    String? errorText; // Holds error message

    bool isValidEmail(String email) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Forgot Password',
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Opacity(
            opacity: anim1.value,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2A3142),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Forgot Password',
                          style: TextStyle(
                            color: Color(0xFF268A15),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter your email to receive a verification code.',
                          style: TextStyle(
                            color: Color(0xFF8A92A3),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'admin@example.com',
                            hintStyle: const TextStyle(
                              color: Color(0xFF4A5268),
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF268A15),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F1419),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: errorText != null
                                    ? Colors.red
                                    : const Color(0xFF2A3142),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: errorText != null
                                    ? Colors.red
                                    : const Color(0xFF2A3142),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: errorText != null
                                    ? Colors.red
                                    : const Color(0xFF268A15),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorText!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final email = emailController.text.trim();

                              // Email format validation
                              if (email.isEmpty || !isValidEmail(email)) {
                                setState(() {
                                  errorText = 'Please enter a valid email';
                                });
                                return;
                              }

                              final res =
                                  await ApiForgotPassword.forgotPassword(email);

                              if (res['success'] && res['token'] != null) {
                                Navigator.pop(context); // Close only on success
                                _showVerifyCodeDialog(email, res['token']);
                              } else {
                                setState(() {
                                  errorText =
                                      res['error'] ?? 'Email does not exist';
                                });
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
                              'Send Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  // =========================
  // VERIFY CODE DIALOG
  // =========================
  void _showVerifyCodeDialog(String email, String token) {
    final List<TextEditingController> otpControllers = List.generate(
      6,
      (_) => TextEditingController(),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3142), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Code Has Been Sent',
                  style: TextStyle(
                    color: Color(0xFF268A15),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter the code:',
                  style: TextStyle(color: Color(0xFF8A92A3), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50, // Wider box for digit
                      child: TextField(
                        controller: otpControllers[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly, // Only numbers
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF0F1419),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null
                                  ? Colors.red
                                  : const Color(0xFF2A3142),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null
                                  ? Colors.red
                                  : const Color(0xFF2A3142),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorText != null
                                  ? Colors.red
                                  : const Color(0xFF268A15),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          // Move focus automatically
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }

                          // Reset error when user types again
                          setStateDialog(() {
                            errorText = null;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final enteredCode = otpControllers
                          .map((e) => e.text.trim())
                          .join();

                      if (enteredCode.length < 6) {
                        setStateDialog(() {
                          errorText = 'Please enter the complete 6-digit code';
                        });
                        return;
                      }

                      if (enteredCode != token) {
                        setStateDialog(() {
                          errorText = 'Code does not match';
                        });
                        return;
                      }

                      Navigator.pop(context);
                      _showNewPasswordDialog(token);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF268A15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Verify Code',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // NEW PASSWORD DIALOG
  // =========================
  void _showNewPasswordDialog(String token) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    String? passwordError;
    String? confirmError;

    void showNotification(String message, {Color color = Colors.green}) {
      Flushbar(
        message: message,
        duration: const Duration(seconds: 3),
        backgroundColor: color,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3142), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set New Password',
                  style: TextStyle(
                    color: Color(0xFF268A15),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter your new password.',
                  style: TextStyle(color: Color(0xFF8A92A3), fontSize: 14),
                ),
                const SizedBox(height: 16),

                // New Password Field
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'New password',
                    hintStyle: const TextStyle(color: Color(0xFF4A5268)),
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: Color(0xFF268A15),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setStateDialog(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      child: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF268A15),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: passwordError != null
                            ? Colors.red
                            : const Color(0xFF2A3142),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: passwordError != null
                            ? Colors.red
                            : const Color(0xFF2A3142),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: passwordError != null
                            ? Colors.red
                            : const Color(0xFF268A15),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setStateDialog(() {
                      passwordError = null;
                    });
                  },
                ),
                if (passwordError != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      passwordError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Confirm Password Field
                TextField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: const TextStyle(color: Color(0xFF4A5268)),
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: Color(0xFF268A15),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setStateDialog(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                      child: Icon(
                        obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF268A15),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F1419),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: confirmError != null
                            ? Colors.red
                            : const Color(0xFF2A3142),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: confirmError != null
                            ? Colors.red
                            : const Color(0xFF2A3142),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: confirmError != null
                            ? Colors.red
                            : const Color(0xFF268A15),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setStateDialog(() {
                      confirmError = null;
                    });
                  },
                ),
                if (confirmError != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      confirmError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newPassword = passwordController.text.trim();
                      final confirmPassword = confirmController.text.trim();

                      // Validate passwords
                      if (newPassword.isEmpty) {
                        setStateDialog(() {
                          passwordError = 'Please enter a new password';
                        });
                        return;
                      }
                      if (confirmPassword.isEmpty) {
                        setStateDialog(() {
                          confirmError = 'Please confirm your password';
                        });
                        return;
                      }
                      if (newPassword != confirmPassword) {
                        setStateDialog(() {
                          confirmError = 'Passwords do not match';
                        });
                        return;
                      }

                      final res = await ApiForgotPassword.resetPassword(
                        token: token,
                        newPassword: newPassword,
                      );

                      if (res['success']) {
                        Navigator.pop(context);
                        showNotification('Password reset successful');
                      } else {
                        showNotification(
                          res['error'] ?? 'Failed to reset password',
                          color: Colors.red,
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
                      'Set Password',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // MAIN LOGIN UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
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
              const Text(
                'Ticket System',
                style: TextStyle(
                  color: Color(0xFF268A15),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Test',
                style: TextStyle(
                  color: Color(0xFF8A92A3),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),

              // Login Form
              Center(
                child: Container(
                  width: 400,
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
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: Color(0xFF8A92A3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // ✅ Email Field
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.next, // 👈 Next button
                        onSubmitted: (_) {
                          FocusScope.of(context).nextFocus(); // 👈 go to password
                        },
                        decoration: InputDecoration(
                          hintText: 'admin@example.com',
                          hintStyle: const TextStyle(color: Color(0xFF4A5268)),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF268A15),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F1419),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: emailError != null
                                  ? Colors.red
                                  : const Color(0xFF2A3142),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: emailError != null
                                  ? Colors.red
                                  : const Color(0xFF2A3142),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: emailError != null
                                  ? Colors.red
                                  : const Color(0xFF268A15),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (emailError != null) {
                            setState(() => emailError = null);
                          }
                        },
                      ),

                      if (emailError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          emailError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],

                      const SizedBox(height: 15),

                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF8A92A3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // ✅ Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.done, // 👈 Done button
                        onSubmitted: (_) => _handleLogin(), // 👈 ENTER triggers login
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Color(0xFF4A5268)),
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: Color(0xFF268A15),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF268A15),
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F1419),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: passwordError != null
                                  ? Colors.red
                                  : const Color(0xFF2A3142),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: passwordError != null
                                  ? Colors.red
                                  : const Color(0xFF2A3142),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: passwordError != null
                                  ? Colors.red
                                  : const Color(0xFF268A15),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (passwordError != null) {
                            setState(() => passwordError = null);
                          }
                        },
                      ),

                      if (passwordError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          passwordError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Color(0xFF268A15)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleLogin, // 👈 reuse same logic
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF268A15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


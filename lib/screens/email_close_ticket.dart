import 'package:flutter/material.dart';
import 'loginscreen.dart';

class TicketClosedPage extends StatelessWidget {
  const TicketClosedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 90,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Ticket Closed Successfully',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Thank you for confirming that your issue has been resolved. '
                        'This ticket has now been closed.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text('Back to Idiyanale'),
                    ),
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
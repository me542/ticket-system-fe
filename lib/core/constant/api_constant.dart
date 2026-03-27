class ApiConstants {
  static const String baseUrl = 'https://your-api-url.com/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';

  // Ticket endpoints
  static const String tickets = '$baseUrl/tickets';
  static const String ticketById = '$baseUrl/tickets'; // append /{id}

  // User endpoints
  static const String users = '$baseUrl/users';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
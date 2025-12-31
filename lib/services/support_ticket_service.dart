import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/support_ticket.dart';

class SupportTicketService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all tickets with filters and pagination
  static Future<TicketsResponse> getAllTickets({
    String? status,
    String? priority,
    String? orderId,
    String? customerId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final url = ApiConfig.getAllTicketsUrl(
        status: status,
        priority: priority,
        orderId: orderId,
        customerId: customerId,
        page: page,
        size: size,
      );

      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TicketsResponse.fromJson(json);
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tickets: $e');
      rethrow;
    }
  }

  /// Get ticket by ID
  static Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      final url = ApiConfig.getTicketByIdUrl(ticketId);
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SupportTicket.fromJson(json);
      } else {
        print('Failed to get ticket: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting ticket: $e');
      return null;
    }
  }

  /// Get ticket statistics
  static Future<TicketStatistics> getTicketStatistics() async {
    try {
      final url = ApiConfig.ticketStatisticsUrl;
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TicketStatistics.fromJson(json);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      rethrow;
    }
  }

  /// Update ticket status
  static Future<Map<String, dynamic>> updateTicketStatus(
    String ticketId,
    String status,
    String updatedBy,
  ) async {
    try {
      final url = ApiConfig.updateTicketStatusUrl(ticketId);
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'updatedBy': updatedBy,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'ticket': SupportTicket.fromJson(json),
        };
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? errorBody?['error'] ?? 'Failed to update status';
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error updating status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Update ticket priority
  static Future<Map<String, dynamic>> updateTicketPriority(
    String ticketId,
    String priority,
  ) async {
    try {
      final url = ApiConfig.updateTicketPriorityUrl(ticketId);
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'priority': priority,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'ticket': SupportTicket.fromJson(json),
        };
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? errorBody?['error'] ?? 'Failed to update priority';
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error updating priority: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Assign ticket to agent
  static Future<Map<String, dynamic>> assignTicket(
    String ticketId,
    String agentId,
  ) async {
    try {
      final url = ApiConfig.assignTicketUrl(ticketId);
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agentId': agentId,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'ticket': SupportTicket.fromJson(json),
        };
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? errorBody?['error'] ?? 'Failed to assign ticket';
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error assigning ticket: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Add agent response to ticket
  /// Note: This automatically sets the ticket status to RESOLVED
  static Future<Map<String, dynamic>> addAgentResponse(
    String ticketId,
    String message,
  ) async {
    try {
      final url = ApiConfig.addAgentResponseUrl(ticketId);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'ticket': SupportTicket.fromJson(json),
        };
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody?['message'] ?? errorBody?['error'] ?? 'Failed to add response';
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('Error adding response: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}


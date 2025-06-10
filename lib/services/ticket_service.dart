import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import 'seat_service.dart';

class TicketService {
  static const String _ticketsKey = 'user_tickets';

  // Save a new ticket
  static Future<bool> saveTicket(Ticket ticket) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing tickets
      List<Ticket> tickets = await getTickets();

      // Add new ticket
      tickets.add(ticket);

      // Convert to JSON and save
      List<String> ticketsJson =
          tickets.map((ticket) => jsonEncode(ticket.toJson())).toList();

      return await prefs.setStringList(_ticketsKey, ticketsJson);
    } catch (e) {
      print('Error saving ticket: $e');
      return false;
    }
  }

  // Get all tickets
  static Future<List<Ticket>> getTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get stored tickets
      List<String>? ticketsJson = prefs.getStringList(_ticketsKey);

      if (ticketsJson == null || ticketsJson.isEmpty) {
        return [];
      }

      // Convert JSON to Ticket objects
      return ticketsJson
          .map((ticketJson) => Ticket.fromJson(jsonDecode(ticketJson)))
          .toList();
    } catch (e) {
      print('Error getting tickets: $e');
      return [];
    }
  }

  // Cancel a ticket by ID
  static Future<bool> cancelTicket(String ticketId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing tickets
      List<Ticket> tickets = await getTickets();

      // Find the ticket to cancel
      int ticketIndex = tickets.indexWhere((ticket) => ticket.id == ticketId);

      if (ticketIndex == -1) {
        // Ticket not found
        return false;
      }

      Ticket ticketToCancel = tickets[ticketIndex];

      // Check if the ticket is still within cancellation window
      if (!ticketToCancel.isCancelable) {
        return false;
      }

      // Remove the ticket
      tickets.removeAt(ticketIndex);

      // Save updated ticket list
      List<String> ticketsJson =
          tickets.map((ticket) => jsonEncode(ticket.toJson())).toList();

      bool savedTickets = await prefs.setStringList(_ticketsKey, ticketsJson);

      if (savedTickets) {
        // Remove the booked seats
        await SeatService.removeBookedSeats(
            ticketToCancel.movieTitle,
            ticketToCancel.theaterName,
            ticketToCancel.showtime,
            ticketToCancel.seats);
      }

      return savedTickets;
    } catch (e) {
      print('Error cancelling ticket: $e');
      return false;
    }
  }

  // Clear all tickets (for testing)
  static Future<bool> clearTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_ticketsKey);
    } catch (e) {
      print('Error clearing tickets: $e');
      return false;
    }
  }
}

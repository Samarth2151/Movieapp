import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import 'ticket_service.dart';

class SeatService {
  static const String _bookedSeatsKey = 'booked_seats_data';

  // Get all booked seats from all tickets
  static Future<Map<String, List<String>>> getAllBookedSeats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First check if we have a cached version
      String? bookedSeatsJson = prefs.getString(_bookedSeatsKey);

      if (bookedSeatsJson != null) {
        Map<String, dynamic> bookedSeatsMap = json.decode(bookedSeatsJson);
        Map<String, List<String>> result = {};

        bookedSeatsMap.forEach((key, value) {
          result[key] = List<String>.from(value);
        });

        return result;
      }

      // If no cached version, build it from tickets
      return await _buildBookedSeatsFromTickets();
    } catch (e) {
      print('Error getting booked seats: $e');
      return {};
    }
  }

  // Check if specific seats are booked for a movie, theater and showtime
  static Future<bool> areSeatsBooked(String movieTitle, String theaterName,
      String showtime, List<String> seatsToCheck) async {
    try {
      Map<String, List<String>> allBookedSeats = await getAllBookedSeats();

      // Create a key to look up the specific movie/theater/showtime combination
      String bookingKey = _createBookingKey(movieTitle, theaterName, showtime);

      // If this movie/theater/showtime doesn't exist in our map, seats aren't booked
      if (!allBookedSeats.containsKey(bookingKey)) {
        return false;
      }

      // Check if any of the seats are in the booked list
      List<String> bookedSeatsForShow = allBookedSeats[bookingKey]!;

      for (String seat in seatsToCheck) {
        if (bookedSeatsForShow.contains(seat)) {
          return true; // At least one seat is already booked
        }
      }

      return false; // None of the seats are booked
    } catch (e) {
      print('Error checking if seats are booked: $e');
      return false;
    }
  }

  // Get booked seats for a specific movie, theater and showtime
  static Future<List<String>> getBookedSeatsForShow(
      String movieTitle, String theaterName, String showtime) async {
    try {
      Map<String, List<String>> allBookedSeats = await getAllBookedSeats();

      String bookingKey = _createBookingKey(movieTitle, theaterName, showtime);

      if (allBookedSeats.containsKey(bookingKey)) {
        return allBookedSeats[bookingKey]!;
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting booked seats for show: $e');
      return [];
    }
  }

  // Add booked seats when a new ticket is created
  static Future<bool> addBookedSeats(String movieTitle, String theaterName,
      String showtime, List<String> seats) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current booked seats
      Map<String, List<String>> allBookedSeats = await getAllBookedSeats();

      // Create a key for this specific movie/theater/showtime
      String bookingKey = _createBookingKey(movieTitle, theaterName, showtime);

      // Add these seats to the existing list or create a new entry
      if (allBookedSeats.containsKey(bookingKey)) {
        // Add seats that aren't already in the list
        for (String seat in seats) {
          if (!allBookedSeats[bookingKey]!.contains(seat)) {
            allBookedSeats[bookingKey]!.add(seat);
          }
        }
      } else {
        // New entry
        allBookedSeats[bookingKey] = seats;
      }

      // Convert back to JSON and save
      Map<String, dynamic> saveMap = {};
      allBookedSeats.forEach((key, value) {
        saveMap[key] = value;
      });

      String saveJson = json.encode(saveMap);
      return await prefs.setString(_bookedSeatsKey, saveJson);
    } catch (e) {
      print('Error adding booked seats: $e');
      return false;
    }
  }

  // Remove booked seats when a ticket is cancelled
  static Future<bool> removeBookedSeats(String movieTitle, String theaterName,
      String showtime, List<String> seats) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current booked seats
      Map<String, List<String>> allBookedSeats = await getAllBookedSeats();

      // Create a key for this specific movie/theater/showtime
      String bookingKey = _createBookingKey(movieTitle, theaterName, showtime);

      // Check if this movie/theater/showtime exists
      if (!allBookedSeats.containsKey(bookingKey)) {
        return false; // Nothing to remove
      }

      // Remove the specified seats
      for (String seat in seats) {
        allBookedSeats[bookingKey]!.remove(seat);
      }

      // If all seats for this show are removed, remove the entire entry
      if (allBookedSeats[bookingKey]!.isEmpty) {
        allBookedSeats.remove(bookingKey);
      }

      // Convert back to JSON and save
      Map<String, dynamic> saveMap = {};
      allBookedSeats.forEach((key, value) {
        saveMap[key] = value;
      });

      String saveJson = json.encode(saveMap);
      return await prefs.setString(_bookedSeatsKey, saveJson);
    } catch (e) {
      print('Error removing booked seats: $e');
      return false;
    }
  }

  // Rebuild the booked seats cache from all tickets
  static Future<Map<String, List<String>>>
      _buildBookedSeatsFromTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all tickets
      List<Ticket> tickets = await TicketService.getTickets();

      // Build the map
      Map<String, List<String>> bookedSeatsMap = {};

      for (Ticket ticket in tickets) {
        String bookingKey = _createBookingKey(
            ticket.movieTitle, ticket.theaterName, ticket.showtime);

        if (bookedSeatsMap.containsKey(bookingKey)) {
          // Add seats from this ticket
          bookedSeatsMap[bookingKey]!.addAll(ticket.seats);
        } else {
          // Create a new entry
          bookedSeatsMap[bookingKey] = List<String>.from(ticket.seats);
        }
      }

      // Save for future use
      Map<String, dynamic> saveMap = {};
      bookedSeatsMap.forEach((key, value) {
        saveMap[key] = value;
      });

      String saveJson = json.encode(saveMap);
      await prefs.setString(_bookedSeatsKey, saveJson);

      return bookedSeatsMap;
    } catch (e) {
      print('Error building booked seats from tickets: $e');
      return {};
    }
  }

  // Helper to create a consistent key format
  static String _createBookingKey(
      String movieTitle, String theaterName, String showtime) {
    return '${movieTitle.trim()}_${theaterName.trim()}_${showtime.trim()}';
  }
}

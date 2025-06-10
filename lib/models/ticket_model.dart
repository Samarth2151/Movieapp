class Ticket {
  final String id;
  final String movieTitle;
  final String theaterName;
  final String showtime;
  final String price;
  final List<String> seats;
  final String transactionId;
  final DateTime bookingDate;
  final DateTime
      cancellationDeadline; // When the ticket can no longer be cancelled

  Ticket({
    required this.id,
    required this.movieTitle,
    required this.theaterName,
    required this.showtime,
    required this.price,
    required this.seats,
    required this.transactionId,
    required this.bookingDate,
    DateTime? cancellationDeadline,
  }) : this.cancellationDeadline = cancellationDeadline ??
            bookingDate.add(Duration(
                minutes: 5)); // 5 minute cancellation window by default

  // Convert Ticket to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieTitle': movieTitle,
      'theaterName': theaterName,
      'showtime': showtime,
      'price': price,
      'seats': seats,
      'transactionId': transactionId,
      'bookingDate': bookingDate.toIso8601String(),
      'cancellationDeadline': cancellationDeadline.toIso8601String(),
    };
  }

  // Create Ticket from JSON
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      movieTitle: json['movieTitle'],
      theaterName: json['theaterName'],
      showtime: json['showtime'],
      price: json['price'],
      seats: List<String>.from(json['seats']),
      transactionId: json['transactionId'],
      bookingDate: DateTime.parse(json['bookingDate']),
      cancellationDeadline: json.containsKey('cancellationDeadline')
          ? DateTime.parse(json['cancellationDeadline'])
          : null, // Handle older tickets without this field
    );
  }

  // Check if the ticket is still cancelable
  bool get isCancelable => DateTime.now().isBefore(cancellationDeadline);

  // Get the remaining time for cancellation in seconds
  int get remainingCancellationTime {
    if (!isCancelable) return 0;
    return cancellationDeadline.difference(DateTime.now()).inSeconds;
  }
}

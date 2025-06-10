import 'package:flutter/material.dart';
import 'payment_screen.dart';
import 'services/seat_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String movieTitle;
  final String theaterName;
  final String showtime;
  final String price;
  final int numberOfSeats;

  const SeatSelectionScreen({
    required this.movieTitle,
    required this.theaterName,
    required this.showtime,
    required this.price,
    required this.numberOfSeats,
  });

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<String> selectedSeats = [];
  final int rows = 8;
  final int seatsPerRow = 10;
  final List<String> rowLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  List<String> bookedSeats = [];
  bool isLoading = true;

  // Pre-booked seats demo data (will be replaced by actual booked seats)
  final List<String> _fixedBookedSeats = [
    'A3',
    'A4',
    'A5',
    'B7',
    'B8',
    'C1',
    'C2',
    'C6',
    'C7',
    'D4',
    'D5',
    'E2',
    'E3',
    'E8',
    'E9',
    'F5',
    'F6',
    'G1',
    'G2',
    'G9',
    'G10',
    'H4',
    'H5',
    'H6',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookedSeats();
  }

  // Load previously booked seats for this show
  Future<void> _loadBookedSeats() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get booked seats from seat service
      List<String> alreadyBookedSeats = await SeatService.getBookedSeatsForShow(
          widget.movieTitle, widget.theaterName, widget.showtime);

      setState(() {
        // Combine fixed demo seats with actual booked seats from previous bookings
        bookedSeats = [..._fixedBookedSeats, ...alreadyBookedSeats];
        // Remove duplicates
        bookedSeats = bookedSeats.toSet().toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading booked seats: $e');
      setState(() {
        // Fallback to fixed demo seats only
        bookedSeats = _fixedBookedSeats;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Seats'),
        backgroundColor: Color(0xFFE51937),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Movie Info Bar
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movieTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${widget.theaterName} • ${widget.showtime}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFE51937),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.numberOfSeats} Seats',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Seat Legend
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('Available', Colors.grey[300]!),
                      _buildLegendItem('Booked', Colors.grey[700]!),
                      _buildLegendItem('Selected', Color(0xFFE51937)),
                    ],
                  ),
                ),

                // Screen
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SCREEN',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Seats Layout
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(rows, (rowIndex) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              // Row Label
                              SizedBox(
                                width: 30,
                                child: Center(
                                  child: Text(
                                    rowLabels[rowIndex],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Seats
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      List.generate(seatsPerRow, (seatIndex) {
                                    final seatNumber = seatIndex + 1;
                                    final seatId =
                                        '${rowLabels[rowIndex]}$seatNumber';
                                    final isBooked =
                                        bookedSeats.contains(seatId);
                                    final isSelected =
                                        selectedSeats.contains(seatId);

                                    return GestureDetector(
                                      onTap: isBooked
                                          ? null
                                          : () {
                                              setState(() {
                                                if (isSelected) {
                                                  selectedSeats.remove(seatId);
                                                } else {
                                                  if (selectedSeats.length <
                                                      widget.numberOfSeats) {
                                                    selectedSeats.add(seatId);
                                                  } else {
                                                    // Remove the first seat and add the new one
                                                    // (rotating selection if user changes their mind)
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Maximum ${widget.numberOfSeats} seats can be selected.'),
                                                        duration: Duration(
                                                            seconds: 1),
                                                      ),
                                                    );
                                                    selectedSeats.removeAt(0);
                                                    selectedSeats.add(seatId);
                                                  }
                                                }
                                              });
                                            },
                                      child: Container(
                                        margin:
                                            EdgeInsets.symmetric(horizontal: 3),
                                        width: 25,
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: isBooked
                                              ? Colors.grey[700]
                                              : isSelected
                                                  ? Color(0xFFE51937)
                                                  : Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Text(
                                            seatNumber.toString(),
                                            style: TextStyle(
                                              color: (isBooked || isSelected)
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              SizedBox(width: 30), // Balance with row label
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // Selected Seats Info
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Seats',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selectedSeats.isEmpty
                                ? 'None'
                                : selectedSeats.join(', '),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE51937),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.price} × ${selectedSeats.length} = ₹${int.parse(widget.price.substring(1)) * selectedSeats.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedSeats.length == widget.numberOfSeats
                  ? Color(0xFFE51937)
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: selectedSeats.length == widget.numberOfSeats
                ? () {
                    // Navigate to payment screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          movieTitle: widget.movieTitle,
                          theaterName: widget.theaterName,
                          showtime: widget.showtime,
                          price: widget.price,
                          totalAmount: int.parse(widget.price.substring(1)) *
                              selectedSeats.length,
                          selectedSeats: selectedSeats,
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(
              selectedSeats.length == widget.numberOfSeats
                  ? 'Proceed to Payment'
                  : 'Select ${widget.numberOfSeats} Seats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

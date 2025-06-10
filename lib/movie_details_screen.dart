import 'package:flutter/material.dart';
import 'seat_selection_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String rating;

  const MovieDetailsScreen({
    required this.title,
    required this.imageUrl,
    required this.rating,
  });

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  int _selectedDate = 0;
  int _selectedSeats = 2; // Default number of seats
  final List<String> _dates = [
    'Today',
    'Tomorrow',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final Map<String, List<Map<String, dynamic>>> _theaters = {
    'PVR Cinemas': [
      {'time': '10:30 AM', 'price': '₹150'},
      {'time': '1:45 PM', 'price': '₹180'},
      {'time': '5:15 PM', 'price': '₹200'},
      {'time': '9:30 PM', 'price': '₹220'},
    ],
    'INOX Multiplex': [
      {'time': '11:00 AM', 'price': '₹160'},
      {'time': '2:30 PM', 'price': '₹190'},
      {'time': '6:00 PM', 'price': '₹210'},
      {'time': '10:00 PM', 'price': '₹230'},
    ],
    'Cinepolis': [
      {'time': '10:00 AM', 'price': '₹140'},
      {'time': '1:15 PM', 'price': '₹170'},
      {'time': '4:45 PM', 'price': '₹200'},
      {'time': '8:30 PM', 'price': '₹220'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Movie Banner with Title overlay
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[500],
                        child: Center(
                          child:
                              Icon(Icons.movie, size: 50, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Color(0xFFE51937),
            actions: [
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.favorite_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to favorites')),
                  );
                },
              ),
            ],
          ),

          // Movie Info
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              widget.rating,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        '2h 15m • UA • Drama, Action',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Date Selector
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = index;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _selectedDate == index
                            ? Color(0xFFE51937)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _dates[index],
                          style: TextStyle(
                            color: _selectedDate == index
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Cinemas List
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 24, right: 16, bottom: 8),
              child: Text(
                'Select Theater & Showtime',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final theaterName = _theaters.keys.elementAt(index);
                final showtimes = _theaters[theaterName]!;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.theater_comedy,
                                color: Color(0xFFE51937)),
                            SizedBox(width: 8),
                            Text(
                              theaterName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.info_outline,
                                size: 18, color: Colors.grey),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dolby Atmos, Food & Beverages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: showtimes.map((showtime) {
                            return GestureDetector(
                              onTap: () {
                                _showSeatSelectionDialog(theaterName, showtime);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      showtime['time'],
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      showtime['price'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _theaters.length,
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE51937),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Proceed to seat selection')),
              );
            },
            child: Text(
              'Book Tickets',
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

  // Show seat selection dialog
  void _showSeatSelectionDialog(
      String theaterName, Map<String, dynamic> showtime) {
    int seats = _selectedSeats;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Seats'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.title} at $theaterName',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Time: ${showtime['time']}',
                      style: TextStyle(color: Colors.grey[700])),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle),
                        color: Color(0xFFE51937),
                        onPressed: seats > 1
                            ? () {
                                setState(() {
                                  seats--;
                                });
                              }
                            : null,
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$seats ${seats == 1 ? 'Seat' : 'Seats'}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle),
                        color: Color(0xFFE51937),
                        onPressed: seats < 10
                            ? () {
                                setState(() {
                                  seats++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Price: ${showtime['price']} × $seats = ₹${int.parse(showtime['price'].substring(1)) * seats}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE51937),
                  ),
                  child: Text('Continue'),
                  onPressed: () {
                    _selectedSeats = seats; // Save selected seats count
                    Navigator.of(context).pop();

                    // Navigate to seat selection screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeatSelectionScreen(
                          movieTitle: widget.title,
                          theaterName: theaterName,
                          showtime: showtime['time'],
                          price: showtime['price'],
                          numberOfSeats: seats,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

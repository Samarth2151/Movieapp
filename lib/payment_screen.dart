import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/ticket_model.dart';
import 'services/ticket_service.dart';
import 'services/seat_service.dart';
import 'tickets_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String movieTitle;
  final String theaterName;
  final String showtime;
  final String price;
  final int totalAmount;
  final List<String> selectedSeats;

  const PaymentScreen({
    required this.movieTitle,
    required this.theaterName,
    required this.showtime,
    required this.price,
    required this.totalAmount,
    required this.selectedSeats,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPaymentMethod = 0;
  bool _isProcessing = false;
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Color(0xFFE51937),
      ),
      body: _isProcessing
          ? _buildProcessingPayment()
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    _buildOrderSummary(),

                    SizedBox(height: 24),

                    // Payment Method Selection
                    Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Payment Options
                    _buildPaymentOptions(),

                    SizedBox(height: 24),

                    // Payment Details Form
                    _selectedPaymentMethod == 0
                        ? _buildCreditCardForm()
                        : _buildUpiForm(),

                    SizedBox(height: 16),

                    // Terms & Conditions
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By proceeding, you agree to our terms and conditions for booking tickets and payment.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isProcessing
          ? null
          : BottomAppBar(
              child: Container(
                height: 80,
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE51937),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _processPayment,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PAY ₹${widget.totalAmount}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProcessingPayment() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFE51937),
          ),
          SizedBox(height: 24),
          Text(
            'Processing Your Payment...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Please do not press back or refresh',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            _buildOrderRow('Movie', widget.movieTitle),
            _buildOrderRow('Theater', widget.theaterName),
            _buildOrderRow('Time', widget.showtime),
            _buildOrderRow('Seats', widget.selectedSeats.join(', ')),
            _buildOrderRow('Ticket Price',
                '${widget.price} × ${widget.selectedSeats.length}'),
            Divider(),
            _buildOrderRow(
              'Total Amount',
              '₹${widget.totalAmount}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Color(0xFFE51937) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _buildPaymentMethodTile(
          0,
          'Credit/Debit Card',
          Icons.credit_card,
          'Visa, Mastercard, RuPay',
        ),
        SizedBox(height: 12),
        _buildPaymentMethodTile(
          1,
          'UPI Payment',
          Icons.account_balance,
          'GooglePay, PhonePe, Paytm',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
      int index, String title, IconData icon, String subtitle) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == index
                ? Color(0xFFE51937)
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Radio(
              value: index,
              groupValue: _selectedPaymentMethod,
              activeColor: Color(0xFFE51937),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = index;
                });
              },
            ),
            Icon(icon, color: Colors.grey[700]),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
              hintText: 'XXXX XXXX XXXX XXXX',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _cardNameController,
            decoration: InputDecoration(
              labelText: 'Name on Card',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter name on card';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    hintText: 'MM/YY',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _CardExpiryFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter expiry date';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                    hintText: 'XXX',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpiForm() {
    final TextEditingController _upiController = TextEditingController();
    bool _isUpiValid = false;

    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UPI ID Input Section
          Text(
            'UPI ID',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _upiController,
            decoration: InputDecoration(
              labelText: 'Enter UPI ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance),
              hintText: 'yourname@upi',
              helperText: 'Example: 9876543210@upi, username@oksbi',
              suffixIcon: TextButton(
                onPressed: () {
                  // Simulate UPI ID verification
                  if (_upiController.text.contains('@') &&
                      _upiController.text.length > 5) {
                    setState(() {
                      _isUpiValid = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('UPI ID verified successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    setState(() {
                      _isUpiValid = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Invalid UPI ID. Please check and try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  'VERIFY',
                  style: TextStyle(
                    color: Color(0xFFE51937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          if (_isUpiValid)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'UPI ID verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 24),

          // UPI QR Code Section
          Text(
            'Scan QR to Pay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Simulated QR code with text
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Stack(
                      children: [
                        // QR code grid pattern (simplified)
                        GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: 25,
                          itemBuilder: (context, index) {
                            // Create a random-like QR pattern
                            final isBlack =
                                index % 3 == 0 || index % 7 == 0 || index == 12;
                            return Container(
                              color: isBlack ? Colors.black : Colors.white,
                            );
                          },
                        ),
                        // Overlay text
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(4),
                            color: Colors.white,
                            child: Text(
                              'UPI QR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Amount: ₹${widget.totalAmount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          Divider(),

          SizedBox(height: 16),

          // UPI Apps Section
          Text(
            'Pay using UPI Apps',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: [
              _buildUpiAppOption('Google Pay', Icons.g_mobiledata),
              _buildUpiAppOption('PhonePe', Icons.phone_android),
              _buildUpiAppOption('Paytm', Icons.payment),
              _buildUpiAppOption('BHIM', Icons.currency_rupee),
              _buildUpiAppOption('Amazon Pay', Icons.shopping_cart),
              _buildUpiAppOption('WhatsApp', Icons.chat),
              _buildUpiAppOption('iMobile Pay', Icons.account_balance),
              _buildUpiAppOption('More', Icons.more_horiz),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildUpiAppOption(String name, IconData icon) {
    return InkWell(
      onTap: () {
        // Simulate opening the UPI app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launching $name for payment...'),
            duration: Duration(seconds: 1),
          ),
        );

        // Show processing payment after a short delay
        Future.delayed(Duration(milliseconds: 1500), () {
          setState(() {
            _isProcessing = true;
          });

          // Simulate payment processing
          Future.delayed(Duration(seconds: 3), () {
            // Generate transaction ID
            final transactionId = _generateTransactionId();

            // Save ticket to storage
            _saveTicket(transactionId);
          });
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 30,
                color: name == 'Google Pay'
                    ? Colors.blue
                    : name == 'PhonePe'
                        ? Colors.purple
                        : name == 'Paytm'
                            ? Colors.blue
                            : name == 'BHIM'
                                ? Colors.green
                                : name == 'Amazon Pay'
                                    ? Colors.orange
                                    : name == 'WhatsApp'
                                        ? Colors.green
                                        : Color(0xFFE51937),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    // For credit/debit card, validate the form
    if (_selectedPaymentMethod == 0 && !_formKey.currentState!.validate()) {
      return;
    }

    // Show loading indicator
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    Future.delayed(Duration(seconds: 3), () {
      // Generate transaction ID
      final transactionId = _generateTransactionId();

      // Save ticket to storage
      _saveTicket(transactionId);
    });
  }

  // Save ticket to storage
  Future<void> _saveTicket(String transactionId) async {
    // Create ticket object
    final ticket = Ticket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      movieTitle: widget.movieTitle,
      theaterName: widget.theaterName,
      showtime: widget.showtime,
      price: widget.price,
      seats: widget.selectedSeats,
      transactionId: transactionId,
      bookingDate: DateTime.now(),
    );

    // Save to ticket storage
    await TicketService.saveTicket(ticket);

    // Also save the seats as booked
    await SeatService.addBookedSeats(widget.movieTitle, widget.theaterName,
        widget.showtime, widget.selectedSeats);

    // Show success dialog
    _showPaymentSuccessDialog(transactionId);
  }

  void _showPaymentSuccessDialog([String? transactionId]) {
    final tId = transactionId ?? _generateTransactionId();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 16),
            Text('Payment Successful!'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your booking has been confirmed.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.movieTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('${widget.theaterName} • ${widget.showtime}'),
                    SizedBox(height: 8),
                    Text('Seats: ${widget.selectedSeats.join(', ')}'),
                    SizedBox(height: 8),
                    Text(
                      'Transaction ID: $tId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Pop all screens and return to movie list
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('BACK TO HOME'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE51937),
            ),
            onPressed: () {
              // Navigate to tickets screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => TicketsScreen()),
                (route) => route.isFirst,
              );
            },
            child: Text('VIEW TICKETS'),
          ),
        ],
      ),
    );
  }

  String _generateTransactionId() {
    // Generate a random transaction ID for demo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'BMSTKTODR${timestamp.toString().substring(5)}';
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i != text.length - 1) {
        buffer.write('/');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

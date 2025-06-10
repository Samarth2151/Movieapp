import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'models/ticket_model.dart';
import 'services/ticket_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

class TicketsScreen extends StatefulWidget {
  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  Map<String, Timer> _cancelationTimers = {};
  Map<String, int> _remainingSeconds = {};

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    // Cancel all timers when screen is disposed
    _cancelationTimers.values.forEach((timer) => timer.cancel());
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tickets = await TicketService.getTickets();

      // Cancel existing timers
      _cancelationTimers.values.forEach((timer) => timer.cancel());
      _cancelationTimers.clear();
      _remainingSeconds.clear();

      setState(() {
        _tickets = tickets;
        _tickets.sort((a, b) =>
            b.bookingDate.compareTo(a.bookingDate)); // Most recent first

        // Setup timers for cancelable tickets
        for (var ticket in _tickets) {
          if (ticket.isCancelable) {
            _remainingSeconds[ticket.id] = ticket.remainingCancellationTime;
            _startCancellationTimer(ticket.id);
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tickets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCancellationTimer(String ticketId) {
    _cancelationTimers[ticketId] =
        Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds[ticketId]! > 0) {
          _remainingSeconds[ticketId] = _remainingSeconds[ticketId]! - 1;
        } else {
          timer.cancel();
          _cancelationTimers.remove(ticketId);
          _remainingSeconds.remove(ticketId);
          // Refresh the list to update UI
          _loadTickets();
        }
      });
    });
  }

  Future<void> _cancelTicket(Ticket ticket) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cancel Ticket'),
            content: Text(
                'Are you sure you want to cancel this ticket for ${ticket.movieTitle}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('NO'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE51937),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('YES, CANCEL'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      bool success = await TicketService.cancelTicket(ticket.id);

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket cancelled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh ticket list
        _loadTickets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel ticket. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Share ticket details with others
  Future<void> _shareTicket(Ticket ticket) async {
    final text = '''
🎬 Movie Ticket: ${ticket.movieTitle}
🏢 Theater: ${ticket.theaterName}
🕒 Showtime: ${ticket.showtime}
💺 Seats: ${ticket.seats.join(', ')}
🎫 Transaction ID: ${ticket.transactionId}
📅 Booked on: ${_formatDate(ticket.bookingDate)}
    ''';

    await Share.share(text,
        subject: 'My Movie Ticket for ${ticket.movieTitle}');
  }

  // Download ticket as PDF
  Future<void> _downloadTicket(Ticket ticket, String qrData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate PDF document
      final pdf = pw.Document();

      // Create QR code image
      final qrImage = await _generateQrImage(qrData);

      // Add content to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header with movie title
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.all(12),
                  color: PdfColor.fromInt(0xFFE51937),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'E-TICKET',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        ticket.movieTitle,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // QR code section
                pw.Padding(
                  padding: pw.EdgeInsets.all(16),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Show this QR code at the entrance',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: 1,
                          ),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        padding: pw.EdgeInsets.all(16),
                        child: qrImage != null
                            ? pw.Image(
                                pw.MemoryImage(qrImage),
                                width: 150,
                                height: 150,
                              )
                            : pw.Container(
                                width: 150,
                                height: 150,
                                child: pw.Center(
                                  child: pw.Text('QR Code Unavailable'),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Ticket Details Section
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  margin: pw.EdgeInsets.symmetric(horizontal: 16),
                  padding: pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TICKET DETAILS',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Divider(),
                      pw.SizedBox(height: 8),
                      _buildPdfInfoRow('Theater:', ticket.theaterName),
                      pw.SizedBox(height: 4),
                      _buildPdfInfoRow('Showtime:', ticket.showtime),
                      pw.SizedBox(height: 4),
                      _buildPdfInfoRow('Seats:', ticket.seats.join(', ')),
                      pw.SizedBox(height: 4),
                      _buildPdfInfoRow(
                          'Price:', '${ticket.price} × ${ticket.seats.length}'),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // Transaction details
                pw.Container(
                  margin: pw.EdgeInsets.symmetric(horizontal: 16),
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfInfoRow('Transaction ID:', ticket.transactionId,
                          isSmall: true),
                      pw.SizedBox(height: 4),
                      _buildPdfInfoRow(
                          'Booking Date:', _formatDate(ticket.bookingDate),
                          isSmall: true),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.all(8),
                  color: PdfColors.grey200,
                  child: pw.Text(
                    'Thank you for booking with BookMyShow',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Determine the appropriate directory for saving files
      Directory? directory;

      if (Platform.isAndroid) {
        // On Android, use the downloads directory
        directory = await getExternalStorageDirectory();
      } else {
        // On iOS, use the documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create a file with timestamp to avoid overwriting
      // Using .docx extension to open with Word
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'ticket_${ticket.id}_$timestamp.docx';
      final filePath = '${directory.path}/$filename';

      // Save PDF to file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      print('File saved to: $filePath');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket saved as Word document to ${directory.path}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 10),
            action: SnackBarAction(
              label: 'OPEN WITH WORD',
              onPressed: () async {
                // Open the PDF file
                final result = await _openWithWordApp(filePath);
                if (!result && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Could not open the file with Word. Location: $filePath'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 8),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving ticket: $e');

      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving ticket: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function to build PDF info rows
  pw.Widget _buildPdfInfoRow(String label, String value,
      {bool isSmall = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.grey700,
            fontSize: isSmall ? 8 : 10,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: !isSmall ? pw.FontWeight.bold : null,
              fontSize: isSmall ? 8 : 10,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Generate QR code image bytes for PDF
  Future<Uint8List?> _generateQrImage(String qrData) async {
    try {
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      final imageSize = 200.0;
      final image = await qrPainter.toImageData(imageSize,
          format: ui.ImageByteFormat.png);
      return image?.buffer.asUint8List();
    } catch (e) {
      print('Error generating QR image: $e');
      return null;
    }
  }

  // Try to open the file with Microsoft Word or other word processing app
  Future<bool> _openWithWordApp(String filePath) async {
    try {
      // Create file URI
      final Uri uri = Uri.file(filePath);

      // Log the file path for debugging
      print('Attempting to open file with Word: $filePath');
      print('URI: $uri');

      bool opened = false;

      // Android specific handling to try to open with Word
      if (Platform.isAndroid) {
        try {
          // Try to use an Android intent to specifically target Microsoft Word apps
          final fileUri = uri.toString();
          final contentUri = 'content://$filePath';

          // Microsoft Word package names to try
          final wordPackages = [
            'com.microsoft.office.word', // Microsoft Word
            'com.google.android.apps.docs.editors.docs', // Google Docs
            'cn.wps.moffice_eng' // WPS Office
          ];

          for (final package in wordPackages) {
            try {
              // Create an intent URI to open the file with a specific app
              final intentUri = Uri.parse(
                  'intent:#Intent;action=android.intent.action.VIEW;'
                  'type=application/vnd.openxmlformats-officedocument.wordprocessingml.document;'
                  'package=$package;'
                  'S.android.intent.extra.STREAM=${Uri.encodeComponent(contentUri)};'
                  'end');

              print('Trying to open with package $package: $intentUri');
              if (await canLaunchUrl(intentUri)) {
                opened = await launchUrl(intentUri);
                if (opened) break;
              }
            } catch (e) {
              print('Failed to open with $package: $e');
            }
          }
        } catch (e) {
          print('Word-specific launch failed: $e');
          // Continue to generic approach
        }
      }

      // If the specific Word approach failed or we're on iOS,
      // try the generic file opening approach
      if (!opened && await canLaunchUrl(uri)) {
        opened = await launchUrl(uri);
      }

      return opened;
    } catch (e) {
      print('Error opening file with Word: $e');
      return false;
    }
  }

  // Contact customer support
  Future<void> _contactSupport(Ticket? ticket) async {
    // Show support options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Customer Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you like to contact support?'),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFFE51937)),
              title: Text('Email Support'),
              subtitle: Text('support@bookmyshow.com'),
              onTap: () {
                Navigator.pop(context);
                if (ticket != null) {
                  _launchEmail(ticket);
                } else {
                  _launchGeneralEmail();
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFFE51937)),
              title: Text('Call Support'),
              subtitle: Text('+1 800-MOVIES'),
              onTap: () {
                Navigator.pop(context);
                _launchPhone();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.chat, color: Color(0xFFE51937)),
              title: Text('Live Chat'),
              subtitle: Text('Chat with a representative'),
              onTap: () {
                Navigator.pop(context);
                _showChatInterface();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  // Launch general support email without ticket info
  Future<void> _launchGeneralEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@bookmyshow.com',
      queryParameters: {
        'subject': 'Customer Support Request',
        'body': '''
Hello Support Team,

I need assistance with my account.

Thank you,
[Your Name]
        ''',
      },
    );

    try {
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Launch email app with pre-filled support email
  Future<void> _launchEmail(Ticket ticket) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@bookmyshow.com',
      queryParameters: {
        'subject': 'Support Request for Ticket: ${ticket.id}',
        'body': '''
Hello Support Team,

I need assistance with my movie ticket:

Transaction ID: ${ticket.transactionId}
Movie: ${ticket.movieTitle}
Theater: ${ticket.theaterName}
Showtime: ${ticket.showtime}
Seats: ${ticket.seats.join(', ')}
Booking Date: ${_formatDate(ticket.bookingDate)}

Issue description:

Thank you,
[Your Name]
        ''',
      },
    );

    try {
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Launch phone app with support number
  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '18006684377');

    try {
      final canLaunch = await canLaunchUrl(phoneUri);
      if (canLaunch) {
        await launchUrl(phoneUri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show a simple chat interface
  void _showChatInterface() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE51937),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.support_agent, color: Color(0xFFE51937)),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Online Now',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.all(16),
                children: [
                  _buildChatMessage(
                    'Hello! How can I help you with your ticket today?',
                    isSupport: true,
                  ),
                  SizedBox(height: 12),
                  _buildChatMessage(
                    'Our support team is online between 9 AM and 9 PM. You can type your message below.',
                    isSupport: true,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Color(0xFFE51937),
                    child: Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a chat message bubble
  Widget _buildChatMessage(String message, {bool isSupport = false}) {
    return Row(
      mainAxisAlignment:
          isSupport ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (isSupport)
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE51937),
            child: Icon(Icons.support_agent, color: Colors.white, size: 16),
          ),
        SizedBox(width: isSupport ? 8 : 0),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSupport ? Colors.grey[200] : Color(0xFFE51937),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: isSupport ? Colors.black87 : Colors.white,
            ),
          ),
        ),
        SizedBox(width: isSupport ? 0 : 8),
        if (!isSupport)
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              'Me',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tickets'),
        backgroundColor: Color(0xFFE51937),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _tickets.isEmpty
                ? _buildEmptyState()
                : _buildTicketsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_num_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Tickets Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your booked tickets will appear here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE51937),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to book tickets
            },
            child: Text('Browse Movies'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    // Generate QR code data from ticket info
    final qrData = json.encode({
      'id': ticket.id,
      'movieTitle': ticket.movieTitle,
      'theaterName': ticket.theaterName,
      'showtime': ticket.showtime,
      'seats': ticket.seats.join(', '),
      'transactionId': ticket.transactionId,
    });

    final bool isCancelable = ticket.isCancelable;
    final int? remainingTime =
        isCancelable ? _remainingSeconds[ticket.id] : null;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Movie and Date Header with Cancel Button
          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFFE51937),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.movieTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(ticket.bookingDate),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                isCancelable
                    ? Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              _formatTime(remainingTime!),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.confirmation_num,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'CONFIRMED',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),

          // Ticket Details
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Code
                GestureDetector(
                  onTap: () => _showQRDialog(ticket, qrData),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 100,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.all(4),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to enlarge',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Ticket Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTicketInfoRow(
                        'Theater',
                        ticket.theaterName,
                        Icons.theater_comedy,
                      ),
                      _buildTicketInfoRow(
                        'Showtime',
                        ticket.showtime,
                        Icons.access_time,
                      ),
                      _buildTicketInfoRow(
                        'Seats',
                        ticket.seats.join(', '),
                        Icons.event_seat,
                      ),
                      _buildTicketInfoRow(
                        'Price',
                        '${ticket.price} × ${ticket.seats.length}',
                        Icons.payment,
                      ),
                      SizedBox(height: 8),
                      Divider(),
                      SizedBox(height: 8),
                      _buildTicketInfoRow(
                        'Transaction ID',
                        ticket.transactionId,
                        Icons.confirmation_number,
                        isImportant: false,
                        textSize: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ticket Actions
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button for cancelable tickets
                if (isCancelable)
                  _buildTicketAction(
                    'Cancel',
                    Icons.cancel_outlined,
                    isDestructive: true,
                    onTap: () => _cancelTicket(ticket),
                  )
                else
                  _buildTicketAction(
                    'Share',
                    Icons.share,
                    onTap: () => _shareTicket(ticket),
                  ),
                _buildTicketAction(
                  'Download',
                  Icons.download,
                  onTap: () => _downloadTicket(ticket, qrData),
                ),
                if (!isCancelable)
                  _buildTicketAction(
                    'Support',
                    Icons.help_outline,
                    onTap: () => _contactSupport(ticket),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog(Ticket ticket, String qrData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Color(0xFFE51937),
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    'E-Ticket',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    ticket.movieTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Show this QR code at the entrance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    padding: EdgeInsets.all(8),
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${ticket.theaterName} • ${ticket.showtime}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Seats: ${ticket.seats.join(', ')}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE51937),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isImportant = true,
    double textSize = 14,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: textSize,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                fontSize: textSize,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketAction(
    String label,
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isDestructive ? Colors.red : Color(0xFFE51937),
            size: 20,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDestructive ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Build Profile Button with custom UI
  Widget _buildProfileButton(BuildContext context) {
    return GestureDetector(

      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE51937),
              Color(0xFFAA1428),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(
                Icons.person,
                color: Color(0xFFE51937),
                size: 20,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show profile bottom sheet with user information and options
  void _showProfileBottomSheet(BuildContext context) {
    // Mock user data - In a real app, this would come from a user service
    final userData = {
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'phone': '+1 123-456-7890',
      'memberSince': 'January 2023',
      'ticketCount': _tickets.length.toString(),
      'premiumMember': true,
      'profileImage': null, // Would store image path in real app
      'notificationsEnabled': true,
      'darkModeEnabled': false,
      'language': 'English',
      'location': 'New York, USA',
    };

    final String userName = userData['name'] as String;
    final String userInitials = userName.split(' ').map((e) => e[0]).join();
    final String memberSince = userData['memberSince'] as String;
    final String ticketCount = userData['ticketCount'] as String;
    final bool isPremium = userData['premiumMember'] as bool;
    final bool notificationsEnabled = userData['notificationsEnabled'] as bool;
    final bool darkModeEnabled = userData['darkModeEnabled'] as bool;
    final String language = userData['language'] as String;
    final String location = userData['location'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Profile header
            Container(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE51937),
                    Color(0xFFAA1428),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile picture and name
                  Row(
                    children: [
                      Hero(
                        tag: 'profileAvatar',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              userInitials,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE51937),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                if (isPremium)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PREMIUM',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(width: 8),
                                Text(
                                  'Member since $memberSince',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // User stats
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Tickets', ticketCount),
                        _buildDivider(),
                        _buildStatItem('Points', '2,450'),
                        _buildDivider(),
                        _buildStatItem('Level', isPremium ? 'Premium' : 'Standard'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Options list
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildProfileListTile(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    subtitle: 'View and edit your profile',
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile editing coming soon'),
                          backgroundColor: Colors.blue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildProfileListTile(
                    icon: Icons.payment_outlined,
                    title: 'Saved Cards',
                    subtitle: 'Manage your payment methods',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment management coming soon'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                  _buildProfileListTile(
                    icon: Icons.local_activity_outlined,
                    title: 'My Bookings',
                    subtitle: '$ticketCount tickets booked',
                    trailing: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFFE51937).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Color(0xFFE51937),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // We're already on tickets screen
                    },
                  ),
                  _buildProfileListTile(
                    icon: notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                    title: 'Notifications',
                    subtitle: notificationsEnabled ? 'Notifications enabled' : 'Notifications disabled',
                    trailing: Switch(
                      value: notificationsEnabled,
                      activeColor: Color(0xFFE51937),
                      onChanged: (value) {
                        // In a real app, this would toggle notifications
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notification settings updated'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: () {},
                  ),
                  // Theme preference
                  _buildProfileListTile(
                    icon: darkModeEnabled ? Icons.dark_mode : Icons.light_mode,
                    title: 'Theme',
                    subtitle: darkModeEnabled ? 'Dark mode enabled' : 'Light mode enabled',
                    trailing: Switch(
                      value: darkModeEnabled,
                      activeColor: Color(0xFFE51937),
                      onChanged: (value) {
                        // In a real app, this would update the theme
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Theme switching coming soon'),
                            backgroundColor: Colors.blue,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: () {},
                  ),
                  
                  // Location
                  _buildProfileListTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    subtitle: location,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Location settings coming soon'),
                          backgroundColor: Colors.blue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Settings
                  _buildProfileListTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences and security',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Settings page coming soon'),
                          backgroundColor: Colors.blue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildProfileListTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Support',
                    subtitle: 'Get help with your account',
                    onTap: () {
                      Navigator.pop(context);
                      // Create a basic ticket for support if no tickets available
                      final ticketForSupport =
                          _tickets.isNotEmpty ? _tickets.first : null;
                      _contactSupport(ticketForSupport);
                    },
                  ),

                  SizedBox(height: 20),

                  // Logout button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.red[700],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showLogoutConfirmation(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // App version
                  Center(
                    child: Text(
                      'App Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build profile list tiles
  Widget _buildProfileListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFFE51937).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Color(0xFFE51937),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE51937),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              // Here you would normally call a logout method
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green,
                ),
              );

              // Navigate to login page
              // In a real app, you would navigate to the login page
              // Navigator.of(context).pushReplacementNamed('/login');
            },
            child: Text('YES, LOGOUT'),
          ),
        ],
      ),
    );
  }

  // Helper for building stat items
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Helper for stat divider
  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white24,
    );
  }
}

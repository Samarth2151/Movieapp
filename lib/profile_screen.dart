import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart'; // Import for LoginScreen
import 'models/ticket_model.dart';
import 'tickets_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();

  // Current user from Firebase
  User? currentUser;
  
  // User preferences
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    // Get current user for the profile
    currentUser = FirebaseAuth.instance.currentUser;

    // Set controller values
    loadUserData();
  }

  void loadUserData() {
    // Use data from Firebase Auth if available, otherwise use placeholder data
    String name = "User Name";
    String email = "user@example.com";
    String mobile = "0000000000";

    // Try to get real user data if available
    if (currentUser != null) {
      name = currentUser!.displayName ?? "No Name";
      email = currentUser!.email ?? "No Email";
      mobile = currentUser!.phoneNumber ?? "0000000000";
    }

    mobileController.text = mobile;
    nameController.text = name;
    emailController.text = email;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.blue),
            onPressed: () {
              // Show the new profile bottom sheet instead of the old settings sheet
              _showProfileBottomSheet(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.maxFinite,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.1, 0.9],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 70, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    nameController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    emailController.text,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  _buildQuickAction(
                    icon: Icons.support_agent,
                    label: 'Support',
                    color: Colors.orange,
                    onTap: () {
                      _showSupportSheet(context);
                    },
                  ),
                  SizedBox(width: 20),
                  _buildQuickAction(
                    icon: Icons.language,
                    label: 'Language',
                    color: Colors.green,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => _buildLanguageSheet(context),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // User Stats Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '2,450',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        'Points',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.blue[200],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Member',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            buildProfileField(
                "Name", nameController, Icons.person_outline, true),
            buildProfileField(
                "Email", emailController, Icons.email_outlined, false),
            buildProfileField(
                "Mobile", mobileController, Icons.phone_android_outlined, true),
            const Divider(thickness: 1),
            const Padding(
              padding: EdgeInsets.only(left: 30, top: 10),
              child: Text('ACCOUNT'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_outlined,
                  size: 20,
                  color: Colors.red,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  // Navigate back to login screen after logout
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

  Widget buildProfileField(String label, TextEditingController controller,
      IconData icon, bool isEditable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: TextFormField(
            controller: controller,
            readOnly: !isEditable,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1),
              ),
              prefixIcon: Icon(icon, color: Colors.blue),
              suffixIcon: isEditable
                  ? Icon(Icons.edit_outlined, color: Colors.blue)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTickets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20),
          child: Text(
            'RECENT TICKETS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // Replace with actual ticket count
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: EdgeInsets.only(left: 20, right: index == 2 ? 20 : 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        height: 80,
                        color: Colors.blue,
                        child: Center(
                          child: Icon(Icons.movie, size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Movie Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cinema Name',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Seats: A1, A2',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(14),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Show profile bottom sheet with user information and options
  void _showProfileBottomSheet(BuildContext context) {
    // Get user data from Firebase or use mock data if not available
    final userData = {
      'name': nameController.text,
      'email': emailController.text,
      'phone': mobileController.text,
      'memberSince': 'January 2023',
      'ticketCount': '5', // This would come from a ticket service in a real app
      'premiumMember': true,
      'profileImage': null, // Would store image path in real app
      'notificationsEnabled': _notificationsEnabled,
      'darkModeEnabled': _darkModeEnabled,
      'language': 'English',
      'location': 'New York, USA',
    };

    final String userName = userData['name'] as String;
    final String userInitials = userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TicketsScreen()));
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
                        setState(() {
                          _notificationsEnabled = value;
                        });
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
                        setState(() {
                          _darkModeEnabled = value;
                        });
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
                      _showSupportSheet(context);
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
              FirebaseAuth.instance.signOut();
              // Navigate back to login screen after logout
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
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

  Future<void> _launchEmail(Ticket? ticket) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@bookmyshow.com',
      queryParameters: {
        'subject': ticket != null ? 'Support Request for Ticket: ${ticket.id}' : 'Customer Support Request',
        'body': ticket != null ? '''
Hello Support Team,

I need assistance with my ticket:
Movie: ${ticket.movieTitle}
Theater: ${ticket.theaterName}
Showtime: ${ticket.showtime}
Seats: ${ticket.seats.join(', ')}
Transaction ID: ${ticket.transactionId}

Thank you,
${nameController.text}
        ''' : '''
Hello Support Team,

I need assistance with my account.

Thank you,
${nameController.text}
        ''',
      },
    );

    try {
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1-800-MOVIES');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChatInterface() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Live Chat'),
        content: Text('Live chat feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportSheet(context) {
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
                _launchEmail(null);
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

  Widget _buildLanguageSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.language, color: Colors.blue),
            title: Text('English'),
            onTap: () {
              Navigator.pop(context);
              // Implement language change logic
            },
          ),
          ListTile(
            leading: Icon(Icons.language, color: Colors.blue),
            title: Text('Hindi'),
            onTap: () {
              Navigator.pop(context);
              // Implement language change logic
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'movie_details_screen.dart';
import 'tickets_screen.dart';
import 'buzz_screen.dart';

class BookMyShowScreen extends StatefulWidget {
  @override
  _BookMyShowScreenState createState() => _BookMyShowScreenState();
}

class _BookMyShowScreenState extends State<BookMyShowScreen> {
  final List<String> bannerImages = [
    'assets/cinema1.png',
    'assets/cinema2.png',
    'assets/cinema3.png',
  ];

  int currentBannerIndex = 0;
  PageController _bannerController = PageController();
  int _currentNavIndex = 0;

  final Map<String, Map<String, dynamic>> moviePosters = {
    'Dune: Part Two': {'imageUrl': 'assets/movies/dune_part_two.png', 'rating': '8.8/10'},
    'Oppenheimer': {'imageUrl': 'assets/movies/oppenheimer.png', 'rating': '8.5/10'},
    'The Batman': {'imageUrl': 'assets/movies/the_batman.png', 'rating': '9.0/10'},
    'Top Gun: Maverick': {'imageUrl': 'assets/movies/top_gun_maverick.png', 'rating': '8.7/10'},
    'RRR': {'imageUrl': 'assets/movies/rrr.png', 'rating': '8.9/10'},
    'KGF: Chapter 2': {'imageUrl': 'assets/movies/kgf_chapter_2.png', 'rating': '8.6/10'},
    'Avengers: Endgame': {'imageUrl': 'assets/movies/avengers_endgame.png', 'rating': '9.0/10'},
    'Joker': {'imageUrl': 'assets/movies/joker.png', 'rating': '8.8/10'},
    'Interstellar': {'imageUrl': 'assets/movies/interstellar.png', 'rating': '9.2/10'},
    'Inception': {'imageUrl': 'assets/movies/inception.png', 'rating': '9.1/10'},
  };

  @override
  void initState() {
    super.initState();
    // Auto-scroll the banner
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        if (currentBannerIndex < bannerImages.length - 1) {
          currentBannerIndex++;
        } else {
          currentBannerIndex = 0;
        }

        if (_bannerController.hasClients) {
          _bannerController.animateToPage(
            currentBannerIndex,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomNavHeight = kBottomNavigationBarHeight + bottomPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text('Movies Booking',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFE51937), // BookMyShow red
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 1));
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Change location coming soon')),
                        );
                      },
                      child: Row(
                        children: [
                          Text('Kolhapur',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500)),
                          Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Filter options coming soon')),
                        );
                      },
                      child: Row(
                        children: [
                          Text('Movie',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Banner Carousel
              SizedBox(
                height: isSmallScreen ? 150 : 200,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: bannerImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentBannerIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          bannerImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print('Banner image loading error: $error');
                            return Container(
                              color: Color(0xFFE51937),
                              child: Center(
                                child: Text(
                                  'Banner Image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Banner Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  bannerImages.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentBannerIndex == index
                          ? Color(0xFFE51937)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              // Categories
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Categories',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Movie Grid - Responsive
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        isSmallScreen ? 2 : (screenWidth < 900 ? 3 : 4),
                    childAspectRatio: 0.85,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: moviePosters.length,
                  itemBuilder: (context, index) {
                    final title = moviePosters.keys.elementAt(index);
                    final data = moviePosters[title]!;
                    return _buildMovieItem(
                        title, data['rating'], data['imageUrl']);
                  },
                ),
              ),
              SizedBox(height: bottomNavHeight + 16), // Adjusted bottom padding
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Color(0xFFE51937),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });

          // Handle navigation
          switch (index) {
            case 0: // Home
              // Already on home
              break;
            case 1: // Tickets
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TicketsScreen()),
              );
              break;
            case 2: // Buzz
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BuzzScreen()),
              );
              break;
            case 3: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_num_outlined), label: 'Tickets'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border), label: 'Buzz'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'Movies':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MovieDetailsScreen(
                title: 'Popular Movies',
                imageUrl: 'assets/movies/movie1.png',
                rating: '8.5/10',
              )),
            );
            break;
          case 'Events':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MovieDetailsScreen(
                title: 'Upcoming Events',
                imageUrl: 'assets/events/event1.png',
                rating: '4.5/5',
              )),
            );
            break;
          case 'Plays':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MovieDetailsScreen(
                title: 'Theater Plays',
                imageUrl: 'assets/plays/play1.png',
                rating: '4.2/5',
              )),
            );
            break;

        }
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 30, color: Color(0xFFE51937)),
            ),
            SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieItem(String title, String rating, String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Navigate to movie details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(
              title: title,
              imageUrl: imageUrl,
              rating: rating,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Movie poster error for $title: $error');
                      return Container(
                        color: Colors.grey[500],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.movie, size: 40, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                title,
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      rating,
                      style: TextStyle(color: Colors.green),
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
}

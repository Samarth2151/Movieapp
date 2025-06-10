import 'package:flutter/material.dart';

class BuzzScreen extends StatelessWidget {
  final List<Map<String, dynamic>> buzzItems = [
    {
      'title': 'Dune: Part Two Breaks Box Office Records',
      'description': 'The sci-fi epic has crossed 500M worldwide in just 2 weeks',
      'image': 'assets/movies/dune_part_two.png',
      'time': '2 hours ago'
    },
    {
      'title': 'Oppenheimer Nominated for 8 Oscars',
      'description': 'Christopher Nolan\'s biopic leads this year\'s nominations',
      'image': 'assets/movies/oppenheimer.png',
      'time': '5 hours ago'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buzz'),
        backgroundColor: Color(0xFFE51937),
      ),
      body: ListView.builder(
        itemCount: buzzItems.length,
        itemBuilder: (context, index) {
          final item = buzzItems[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: item['image'] != null 
                    ? Image.asset(
                        item['image'] as String,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.movie, color: Color(0xFFE51937));
                        },
                      )
                    : Icon(Icons.movie, color: Color(0xFFE51937)),
              ),
              title: Text(item['title'] ?? 'No title'),
              subtitle: Text(item['description'] ?? 'No description'),
            ),
          );
        },
      ),
    );
  }
}
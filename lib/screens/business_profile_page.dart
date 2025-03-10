import 'package:flutter/material.dart';

class BusinessProfilePage extends StatelessWidget {
  final String name;
  final String serviceType;
  final String tagline;
  final String description;
  final String profileImageUrl;
  final double rating;

  const BusinessProfilePage({
    Key? key,
    required this.name,
    required this.serviceType,
    required this.tagline,
    required this.description,
    required this.profileImageUrl,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.deepPurple.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Pic
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
              SizedBox(height: 16),

              // Name
              Text(
                name,
                style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),

              // Service Type
              Text(
                serviceType,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              SizedBox(height: 10),

              // Rating
              _buildStarRating(rating),
              SizedBox(height: 10),

              // Tagline
              Text(
                tagline,
                style: TextStyle(fontSize: 16, color: Colors.amberAccent, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Description
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.justify,
                ),
              ),
              SizedBox(height: 30),

              // Contact Button (future feature)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Contact feature coming soon!'),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Contact',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⭐ Build Star Ratings
  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: Colors.amber, size: 24),
        if (hasHalfStar) Icon(Icons.star_half, color: Colors.amber, size: 24),
        for (int i = 0; i < (5 - fullStars - (hasHalfStar ? 1 : 0)); i++)
          Icon(Icons.star_border, color: Colors.amber, size: 24),

        SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}

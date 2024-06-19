import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> members = [
      {
        'name': 'Shania Chairunnisa Santoso',
        'npm': '22082010062',
        'email': '22082010062@student.upnjatim.ac.id',
        'github': 'https://github.com/shaniach',
        'image': 'assets/shania.jpeg',
      },
      {
        'name': 'Vione Mangunsong',
        'npm': '22082010063',
        'email': '22082010055@student.upnjatim.ac.id',
        'github': 'https://github.com/szuify',
        'image': 'assets/vione.jpeg',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('About Us'),
        backgroundColor: Colors.orange,
      ),
      body: CarouselSlider(
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.75,
          enlargeCenterPage: true,
          enableInfiniteScroll: true,
          autoPlay: true,
        ),
        items: members.map((member) {
          return Builder(
            builder: (BuildContext context) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                margin: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                      ),
                      child: Image.asset(
                        member['image']!,
                        height: 250.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name']!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('NPM: ${member['npm']}'),
                          SizedBox(height: 8),
                          Text('Email: ${member['email']}'),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              // Navigate to the GitHub URL
                            },
                            child: Text(
                              member['github']!,
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../components/common/booking.dart'; // Import the BookingPage

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = '';
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  final Location _location = Location();
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchCurrentLocation();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userName = userDoc.get('name');
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    final locationData = await _location.getLocation();
    setState(() {
      _currentLocation = locationData;
      _addRandomMarkers();
    });
  }

  void _addRandomMarkers() async {
    final random = Random();
    final double variationFactor =
        0.002; // Adjust this factor to control closeness

    for (var i = 0; i < 5; i++) {
      double lat = _currentLocation!.latitude! +
          (random.nextDouble() - 0.5) * variationFactor;
      double lng = _currentLocation!.longitude! +
          (random.nextDouble() - 0.5) * variationFactor;

      BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), // Adjust size as needed
        'assets/taxi.png', // Path to your image file
      );

      _markers.add(
        Marker(
          markerId: MarkerId('marker_$i'),
          position: LatLng(lat, lng),
          icon: icon,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              margin: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.asset(
                  'assets/dashboard.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $_userName',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mau pergi kemana hari ini?',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.width * 0.5,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: _currentLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _currentLocation!.latitude!,
                            _currentLocation!.longitude!,
                          ),
                          zoom: 17,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: _markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookingPage()),
                  );
                },
                icon: Icon(Icons.book),
                label: Text(
                  'Book Now!',
                  style: TextStyle(fontSize: 35), // Adjust font size as needed
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFFFA726),
                  padding: EdgeInsets.symmetric(
                      horizontal: 48, vertical: 24), // Adjust padding as needed
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        36.0), // Adjust border radius as needed
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

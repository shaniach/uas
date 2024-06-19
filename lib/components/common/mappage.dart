import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;

  const MapPage({
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  BitmapDescriptor? pickupIcon;
  late SharedPreferences _prefs;
  bool isTripCompleted = false;
  int currentRouteIndex = 0;
  // Ambil instance FirebaseAuth untuk mengambil UID pengguna
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String apiKey =
      'AIzaSyACUKzAPKiUus0ZCocvitLlvTG4JCk4344'; // Replace with your actual API key

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _loadIcon();
    _fetchRoute();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      isTripCompleted = _prefs.getBool('isTripCompleted') ?? false;
      currentRouteIndex = _prefs.getInt('currentRouteIndex') ?? 0;
    });
  }

  Future<void> _loadIcon() async {
    pickupIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'assets/taxi.png',
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _fetchRoute() async {
    final startLat = widget.pickupLocation.latitude;
    final startLng = widget.pickupLocation.longitude;
    final endLat = widget.destinationLocation.latitude;
    final endLng = widget.destinationLocation.longitude;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        List<LatLng> decoded = _decodePoly(points); // Decode points here
        _startMarkerAnimation(decoded);
      } else {
        throw Exception('No route found');
      }
    } else {
      throw Exception('Failed to fetch route');
    }
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> decoded = [];

    int index = 0;
    int len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      double latDouble = lat / 1e5;
      double lngDouble = lng / 1e5;

      decoded.add(LatLng(latDouble, lngDouble));
    }

    return decoded;
  }

  void _startMarkerAnimation(List<LatLng> route) async {
    for (int i = currentRouteIndex; i < route.length; i++) {
      await Future.delayed(Duration(milliseconds: 500)); // Adjust speed here
      LatLng point = route[i];
      _moveMarker(point);
      await _prefs.setInt('currentRouteIndex', i); // Save current progress

      // Check if destination is reached
      if (i == route.length - 1) {
        _showTripCompletion();
      }
    }
  }

  void _moveMarker(LatLng location) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 17,
        ),
      ),
    );
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'pickup');
      _markers.add(
        Marker(
          markerId: MarkerId('pickup'),
          position: location,
          infoWindow: InfoWindow(title: 'Pickup Location'),
          icon: pickupIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  void _showTripCompletion() {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: widget.destinationLocation,
          infoWindow: InfoWindow(title: 'Destination Location'),
        ),
      );
      isTripCompleted = true;
      _prefs.setBool('isTripCompleted', true); // Save trip completion status
    });
  }

  void _clearSharedPreferences() {
    _prefs.remove('isTripCompleted');
    _prefs.remove('currentRouteIndex');
  }

  @override
  Widget build(BuildContext context) {
    bool showCompletionButton = isTripCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Route'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.pickupLocation,
              zoom: 17,
            ),
            polylines: _polylines,
            markers: _markers,
          ),
          if (showCompletionButton)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () async {
                  User? user =
                      _auth.currentUser; // Ambil user yang sedang login
                  String? uid = user?.uid; // Ambil UID dari user
                  // Query Firestore to find the document where status is 'Booked'
                  final QuerySnapshot snapshot = await FirebaseFirestore
                      .instance
                      .collection('trips')
                      .doc(uid)
                      .collection('user_trips')
                      .where('status', isEqualTo: 'Paid')
                      .get();

                  // Check if there's exactly one document found (assuming only one should match)
                  if (snapshot.size == 1) {
                    // Get the document reference
                    final DocumentSnapshot doc = snapshot.docs.first;

                    // Update the document's status to 'Paid'
                    await doc.reference.update({'status': 'Done'});

                    // Clear SharedPreferences
                    _clearSharedPreferences();

                    // Close the bottom sheet
                    Navigator.of(context).pop();

                    // Optionally, you can perform additional actions after payment completion
                    print('Payment completed. Status updated to Paid.');
                  } else {
                    // Handle error or no document found case
                    print(
                        'Error: No or multiple documents found with status "Booked".');
                  }
                },
                child: Text('Trip Completed'),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:taxify_apps/components/common/locationselection.dart';
import 'package:taxify_apps/components/common/pickuplocationselection.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _destinationController = TextEditingController();
  final _pickupLocationController = TextEditingController();

  String _currentStreet = '';
  LatLng? _destinationLatLng;
  LatLng? _pickupLocationLatLng;
  LocationData? _currentLocation;
  final Location _location = Location();
  bool _isBooking = false;
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  double _distanceInKm = 0;
  int _estimatedPrice = 0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    final locationData = await _location.getLocation();
    setState(() {
      _currentLocation = locationData;
      _getCurrentStreet();
    });
  }

  Future<void> _getCurrentStreet() async {
    final coordinates =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&addressdetails=1';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['address'] != null) {
        setState(() {
          _currentStreet = json['address']['road'] ?? json['display_name'];
          _pickupLocationController.text = _currentStreet;
          _pickupLocationLatLng = coordinates;
        });
      }
    }
  }

  Future<void> _selectDestination() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectionPage(
          initialLocation:
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _destinationController.text = result['address'];
        _destinationLatLng = result['location'];
      });
      _updateMapAndCalculateDistance();
    }
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickupLocationSelectionPage(
          initialLocation:
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickupLocationController.text = result['address'];
        _pickupLocationLatLng = result['location'];
      });
      _updateMapAndCalculateDistance();
    }
  }

  Future<void> _fetchRoute() async {
    final apiKey =
        'AIzaSyACUKzAPKiUus0ZCocvitLlvTG4JCk4344'; // Ganti dengan API key Google Maps Anda
    final startLat = _pickupLocationLatLng!.latitude;
    final startLng = _pickupLocationLatLng!.longitude;
    final endLat = _destinationLatLng!.latitude;
    final endLng = _destinationLatLng!.longitude;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        _decodePoly(points);
      }
    } else {
      throw Exception('Failed to fetch route');
    }
  }

  void _decodePoly(String encoded) {
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

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: decoded,
          color: Colors.blue,
          width: 5,
        ),
      );
    });
  }

  Future<void> _updateMapAndCalculateDistance() async {
    if (_pickupLocationLatLng != null && _destinationLatLng != null) {
      await _fetchRoute(); // Panggil fungsi untuk mendapatkan rute dari Google Directions API
      _calculateDistance();
    }
  }

  void _updatePolylines() {
    final polylineId = PolylineId('route');
    final List<LatLng> polylineCoordinates = [];

    // Add pickup location
    polylineCoordinates.add(_pickupLocationLatLng!);

    // Get intermediate points between pickup and destination
    List<LatLng> intermediates = _getPolylineCoordinates(
      _pickupLocationLatLng!,
      _destinationLatLng!,
      20, // Number of intermediate points (adjust as needed)
    );

    // Add intermediate points
    polylineCoordinates.addAll(intermediates);

    // Add destination
    polylineCoordinates.add(_destinationLatLng!);

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: polylineId,
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
        ),
      );
    });
  }

  List<LatLng> _getPolylineCoordinates(LatLng start, LatLng end, int points) {
    List<LatLng> polylineCoordinates = [];

    double latStep = (end.latitude - start.latitude) / (points + 1);
    double lngStep = (end.longitude - start.longitude) / (points + 1);

    for (int i = 1; i <= points; i++) {
      double interpolatedLat = start.latitude + latStep * i;
      double interpolatedLng = start.longitude + lngStep * i;
      polylineCoordinates.add(LatLng(interpolatedLat, interpolatedLng));
    }

    return polylineCoordinates;
  }

  void _calculateDistance() {
    if (_pickupLocationLatLng == null || _destinationLatLng == null) return;

    double distance = _coordinateDistance(
        _pickupLocationLatLng!.latitude,
        _pickupLocationLatLng!.longitude,
        _destinationLatLng!.latitude,
        _destinationLatLng!.longitude);

    setState(() {
      _distanceInKm = distance;
      _estimatedPrice = (_distanceInKm * 20000).toInt(); // 20.000 per km
    });
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _bookTaxi() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isBooking = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ensure that pickupLocationLatLng and destinationLatLng are not null
        if (_pickupLocationLatLng != null && _destinationLatLng != null) {
          final tripData = {
            'date': _dateController.text,
            'time': _timeController.text,
            'pickup_location': _pickupLocationController.text,
            'pickup_location_geo': GeoPoint(_pickupLocationLatLng!.latitude,
                _pickupLocationLatLng!.longitude),
            'destination': _destinationController.text,
            'destination_geo': GeoPoint(
                _destinationLatLng!.latitude, _destinationLatLng!.longitude),
            'distance': _distanceInKm,
            'price': _estimatedPrice,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Booked',
          };

          await FirebaseFirestore.instance
              .collection('trips')
              .doc(user.uid)
              .collection('user_trips')
              .add(tripData);
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Show an error message if locations are not selected
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Error'),
                content:
                    Text('Please select both pickup location and destination.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }

      setState(() {
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Taxi'),
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(new FocusNode());
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _dateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(new FocusNode());
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _timeController.text = pickedTime.format(context);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a time';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Pickup Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      controller: _pickupLocationController,
                      onTap: _selectPickupLocation,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a pickup location';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: _destinationController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onTap: _selectDestination,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a destination';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32.0),
                    _buildMapAndPriceSection(),
                    SizedBox(height: 16.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : _bookTaxi,
                        child: _isBooking
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Book Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMapAndPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.0),
        _pickupLocationLatLng != null && _destinationLatLng != null
            ? Container(
                height: 350,
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _pickupLocationLatLng!,
                    zoom: 14.0,
                  ),
                  onMapCreated: (controller) {
                    setState(() {
                      _mapController = controller;
                      _fetchMapData();
                    });
                  },
                  polylines: _polylines,
                  markers: {
                    Marker(
                      markerId: MarkerId('pickup'),
                      position: _pickupLocationLatLng!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(title: 'Pickup Location'),
                    ),
                    Marker(
                      markerId: MarkerId('destination'),
                      position: _destinationLatLng!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                      infoWindow: InfoWindow(title: 'Destination'),
                    ),
                  },
                ),
              )
            : Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    'Select pickup location and destination first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
        SizedBox(height: 16.0),
        Center(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Price',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(FontAwesomeIcons.route, color: Colors.blue),
                          SizedBox(width: 8.0),
                          Text(
                            'Distance:',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            '${_distanceInKm.toStringAsFixed(2)} km',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(FontAwesomeIcons.moneyBillAlt,
                              color: Colors.green),
                          SizedBox(width: 8.0),
                          Text(
                            'Estimated Price:',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            'IDR ${_estimatedPrice.toString()}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _fetchMapData() async {
    if (_pickupLocationLatLng != null && _destinationLatLng != null) {
      _updateMapAndCalculateDistance();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _destinationController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }
}

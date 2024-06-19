import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PickupLocationSelectionPage extends StatefulWidget {
  final LatLng initialLocation;

  PickupLocationSelectionPage({required this.initialLocation});

  @override
  _PickupLocationSelectionPageState createState() =>
      _PickupLocationSelectionPageState();
}

class _PickupLocationSelectionPageState
    extends State<PickupLocationSelectionPage> {
  GoogleMapController? _mapController;
  TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Lokasi Pickup'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Lokasi',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _onSearchSubmitted(_searchController.text),
                ),
              ),
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: widget.initialLocation,
                zoom: 15,
              ),
              onTap: _onMapTapped,
              markers: _markers,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                if (_selectedLocation != null) {
                  Navigator.pop(context, {
                    'address': _selectedAddress,
                    'location': _selectedLocation,
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Error'),
                      content: Text('Silakan pilih lokasi terlebih dahulu.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Lanjutkan'),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchSubmitted(String query) async {
    final url =
        'https://nominatim.openstreetmap.org/search?format=json&q=$query';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final firstResult = data[0];
        final lat = double.parse(firstResult['lat']);
        final lon = double.parse(firstResult['lon']);
        final address = firstResult['display_name'];

        setState(() {
          _selectedLocation = LatLng(lat, lon);
          _selectedAddress = address;
          _markers.clear(); // Clear previous markers
          _markers.add(Marker(
            markerId: MarkerId('selected-location'),
            position: LatLng(lat, lon),
          ));
        });

        _moveCameraToLocation(lat, lon);
      }
    }
  }

  void _onMapTapped(LatLng location) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&addressdetails=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['display_name'];

      setState(() {
        _selectedLocation = location;
        _selectedAddress = address;
        _searchController.text =
            address; // Update the text field with tapped address
        _markers.clear(); // Clear previous markers
        _markers.add(Marker(
          markerId: MarkerId('selected-location'),
          position: location,
        ));
      });

      _moveCameraToLocation(location.latitude, location.longitude);
    }
  }

  void _moveCameraToLocation(double lat, double lon) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: 17,
        ),
      ),
    );
  }
}

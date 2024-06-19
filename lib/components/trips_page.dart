import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxify_apps/components/common/mappage.dart';
import 'package:taxify_apps/components/common/paymentbottom.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil instance FirebaseAuth untuk mengambil UID pengguna
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser; // Ambil user yang sedang login
    String? uid = user?.uid; // Ambil UID dari user

    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(uid) // Gunakan UID pengguna yang sedang login
            .collection('user_trips')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No trips found.'));
          }

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return TripCard(data: data, uid: uid!);
            }).toList(),
          );
        },
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String uid; // Tambahkan variabel uid

  const TripCard({required this.data, required this.uid});
  @override
  Widget build(BuildContext context) {
    String status =
        data['status'] ?? 'Booked'; // Default to 'Booked' if status is not set

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(
                    text: 'Destination: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '${data['destination']}'),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.route,
                  size: 36,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Distance: ${data['distance'].toStringAsFixed(1)} km'),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.mapMarkerAlt,
                  size: 36,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Pickup Location: ${data['pickup_location']}'),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.moneyBillAlt,
                  size: 36,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Estimated Price: IDR ${data['price']}'),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.clock,
                  size: 36,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Time: ${data['time']}'),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.calendarAlt,
                  size: 36,
                  color: Colors.purple,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Date: ${data['date']}'),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Conditional rendering of the button based on trip status
            if (status == 'Booked')
              ElevatedButton(
                onPressed: () {
                  _showConfirmationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.taxi,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TEKAN BUTTON INI JIKA KAMU SUDAH DI DALAM TAKSI',
                          style: TextStyle(fontSize: 20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (status == 'Paid')
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Fetch trips with status 'Paid' for the current user
                    final userTripsCollection = FirebaseFirestore.instance
                        .collection('trips')
                        .doc(user.uid)
                        .collection('user_trips')
                        .where('status', isEqualTo: 'Paid')
                        .limit(
                            1); // Limit to 1 trip, assuming you only need one

                    final querySnapshot = await userTripsCollection.get();
                    if (querySnapshot.docs.isNotEmpty) {
                      final doc = querySnapshot.docs.first;
                      final data = doc.data();
                      final pickupGeoPoint =
                          data['pickup_location_geo'] as GeoPoint;
                      final destinationGeoPoint =
                          data['destination_geo'] as GeoPoint;

                      final LatLng pickupLocation = LatLng(
                          pickupGeoPoint.latitude, pickupGeoPoint.longitude);
                      final LatLng destinationLocation = LatLng(
                          destinationGeoPoint.latitude,
                          destinationGeoPoint.longitude);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPage(
                            pickupLocation: pickupLocation,
                            destinationLocation: destinationLocation,
                          ),
                        ),
                      );
                    } else {
                      // Handle case where no 'Paid' trips are found
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('No Paid Trips Found'),
                            content: Text(
                                'No trips with status "Paid" were found for the current user.'),
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
                  } else {
                    // Handle user not logged in
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Error'),
                          content: Text('User is not logged in.'),
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CEK PERJALANAN',
                          style: TextStyle(fontSize: 20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Conditional rendering for trip completion status
            if (status == 'Done')
              Container(
                color: Colors.green,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Trips Selesai',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('PERHATIAN!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tekan "Yes" jika ANDA benar-benar SUDAH berada dalam taxi.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showPaymentBottomSheet(context);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return PaymentBottomSheet(
          price: (data['price'] ?? 0).toDouble(),
          onCompletePayment: () async {
            // Query Firestore to find the document where status is 'Booked'
            final QuerySnapshot snapshot = await FirebaseFirestore.instance
                .collection('trips')
                .doc(uid)
                .collection('user_trips')
                .where('status', isEqualTo: 'Booked')
                .get();

            // Check if there's exactly one document found (assuming only one should match)
            if (snapshot.size == 1) {
              // Get the document reference
              final DocumentSnapshot doc = snapshot.docs.first;

              // Update the document's status to 'Paid'
              await doc.reference.update({'status': 'Paid'});

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
        );
      },
    );
  }
}

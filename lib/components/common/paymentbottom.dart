import 'package:flutter/material.dart';

class PaymentBottomSheet extends StatelessWidget {
  final double price;
  final Future<Null> Function() onCompletePayment;

  const PaymentBottomSheet({
    required this.price,
    required this.onCompletePayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Bayarkan Sejumlah Rp. ${price.toStringAsFixed(2)} ke QRIS Dibawah Ini',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Image.network(
              'https://firebasestorage.googleapis.com/v0/b/taxify-1c5ab.appspot.com/o/qris.png?alt=media&token=af406596-7a61-4b48-b3fb-b30f540f5671',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                // Call onCompletePayment when the button is pressed
                await onCompletePayment();
              },
              child: Text('Tekan Jika Anda Sudah Membayar'),
            ),
          ),
        ],
      ),
    );
  }
}

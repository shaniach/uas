import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/common/info_page.dart'; // Import the BookingPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseStorage _storage = FirebaseStorage.instance;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;

  String _userName = '';
  String _userEmail = '';
  String _userContact = '';
  String _userImageUrl = '';

  bool _isEditing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _contactController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      String uid = user.uid;

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.get('name') ?? '';
            _userEmail = userDoc.get('email') ?? '';
            _userContact = userDoc.get('contact') ?? '';
            _userImageUrl = userDoc.get('imageUrl') ?? '';
            _nameController.text = _userName;
            _emailController.text = _userEmail;
            _contactController.text = _userContact;
          });
        } else {
          print('User document does not exist');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    String uid = _auth.currentUser!.uid;

    try {
      await _firestore.collection('users').doc(uid).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'contact': _contactController.text,
      });

      setState(() {
        _userName = _nameController.text;
        _userEmail = _emailController.text;
        _userContact = _contactController.text;
        _isEditing = false; // Exit edit mode after saving changes
      });

      _showSuccessSnackBar('Profile updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
      _showErrorSnackBar('Failed to update profile');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File image) async {
    String uid = _auth.currentUser!.uid;
    setState(() {
      _isUploading = true;
    });

    try {
      Reference storageReference =
          _storage.ref().child('profile_images/$uid.jpg');
      UploadTask uploadTask = storageReference.putFile(image);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'imageUrl': downloadUrl,
      });

      setState(() {
        _userImageUrl = downloadUrl;
        _isUploading = false;
      });

      _showSuccessSnackBar('Profile picture updated successfully');
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Failed to update profile picture');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _isEditing ? _pickImage : _toggleEdit,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _userImageUrl.isNotEmpty
                      ? NetworkImage(_userImageUrl)
                      : null,
                  child: _userImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : _isUploading
                          ? CircularProgressIndicator()
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              readOnly: !_isEditing,
              decoration: InputDecoration(
                labelText: 'Contact',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isEditing ? _saveChanges : _toggleEdit,
                  child: Text(_isEditing ? 'Save Changes' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InfoPage()),
                );
              },
              child: Text('About Us'),
              style: ElevatedButton.styleFrom(
   foregroundColor: Colors.white, backgroundColor: Color(0xFFFFA726),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

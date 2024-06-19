import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:taxify_apps/components/common/page_header.dart';
import 'package:taxify_apps/components/common/page_heading.dart';
import 'package:taxify_apps/components/login_page.dart';
import 'package:taxify_apps/components/common/custom_form_button.dart';
import 'package:taxify_apps/components/common/custom_input_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  File? _profileImage;
  final _signupFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() => _profileImage = imageTemporary);
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  Future<void> _handleSignupUser() async {
    if (_signupFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting data..')),
      );

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        String? imageUrl;
        if (_profileImage != null) {
          UploadTask uploadTask = _storage
              .ref('profile_images/${userCredential.user!.uid}.jpg')
              .putFile(_profileImage!);

          TaskSnapshot snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        }

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'contact': _contactController.text,
          'imageUrl': imageUrl,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffEEF1F3),
        body: SingleChildScrollView(
          child: Form(
            key: _signupFormKey,
            child: Column(
              children: [
                const PageHeader(),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const PageHeading(
                        title: 'Sign-up Taxify App',
                      ),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_sharp,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                        controller: _nameController,
                        labelText: 'Name',
                        hintText: 'Your name',
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Name field is required!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Your email id',
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Email is required!';
                          }
                          if (!EmailValidator.validate(textValue)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                        controller: _contactController,
                        labelText: 'Contact no.',
                        hintText: 'Your contact number',
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Contact number is required!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomInputField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Your password',
                        obscureText: true,
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Password is required!';
                          }
                          return null;
                        },
                        suffixIcon: true,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      CustomFormButton(
                        innerText: 'Signup',
                        onPressed: _handleSignupUser,
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account ? ',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xff939393),
                                  fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () => {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginPage()))
                              },
                              child: const Text(
                                'Log-in',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xff748288),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

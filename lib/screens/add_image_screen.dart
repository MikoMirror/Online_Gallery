import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddImageScreen extends StatefulWidget {
  const AddImageScreen({Key? key}) : super(key: key);

  @override
  _AddImageScreenState createState() => _AddImageScreenState();
}

class _AddImageScreenState extends State<AddImageScreen> {
  File? _image;
  final picker = ImagePicker();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadImage() async {
    if (_image == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Upload image to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${user.uid}_${DateTime.now().toString()}.jpg');
      await ref.putFile(_image!);
      final url = await ref.getDownloadURL();

      // Save image info to Firestore
      await FirebaseFirestore.instance.collection('images').add({
        'userId': user.uid,
        'imageUrl': url,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear form and show success message
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _image = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Image'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: _image == null
                      ? Icon(Icons.add_photo_alternate, size: 50)
                      : Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: uploadImage,
                child: Text('Upload Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
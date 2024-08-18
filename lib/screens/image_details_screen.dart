import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ImageDetailsScreen extends StatefulWidget {
  final String imageId;
  final AppUser currentUser;

  const ImageDetailsScreen({
    Key? key,
    required this.imageId,
    required this.currentUser,
  }) : super(key: key);

  @override
  _ImageDetailsScreenState createState() => _ImageDetailsScreenState();
}

class _ImageDetailsScreenState extends State<ImageDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool get _isDesktop => kIsWeb || (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Implement more options functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('images')
            .doc(widget.imageId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text('Image not found'));
          }

          Map<String, dynamic> imageData = snapshot.data!.data() as Map<String, dynamic>;

          return _isDesktop ? _buildDesktopLayout(imageData) : _buildMobileLayout(imageData);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(Map<String, dynamic> imageData) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Hero(
            tag: 'image_${widget.imageId}',
            child: Image.network(
              imageData['imageUrl'],
              fit: BoxFit.contain,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageInfo(imageData),
                      SizedBox(height: 16),
                      _buildCommentsList(),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> imageData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'image_${widget.imageId}',
            child: Image.network(
              imageData['imageUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageInfo(imageData),
                SizedBox(height: 16),
                _buildCommentsList(),
                SizedBox(height: 16),
                _buildCommentInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageInfo(Map<String, dynamic> imageData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          imageData['title'],
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(imageData['userId'])
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            }
            if (userSnapshot.hasError || !userSnapshot.hasData) {
              return Text('Unknown user');
            }
            String authorName = userSnapshot.data!['nickname'] ?? 'Unknown user';
            return Text(
              'By $authorName',
              style: TextStyle(fontSize: 16, color: AppColors.primaryGray),
            );
          },
        ),
        SizedBox(height: 8),
        Text(
          'Posted on ${DateFormat('MMM d, yyyy').format(imageData['timestamp'].toDate())}',
          style: TextStyle(fontSize: 14, color: AppColors.primaryGray),
        ),
        SizedBox(height: 16),
        Text(
          imageData['description'] ?? 'No description',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('images')
          .doc(widget.imageId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No comments yet');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var commentData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(commentData['text']),
              subtitle: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(commentData['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Text('Loading...');
                  }
                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return Text('Unknown user');
                  }
                  String authorName = userSnapshot.data!['nickname'] ?? 'Unknown user';
                  return Text('By $authorName');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _addComment,
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('images')
          .doc(widget.imageId)
          .collection('comments')
          .add({
        'userId': widget.currentUser.uid,
        'text': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/image_details_screen.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';

class ImageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String imageId;
  final AppUser currentUser;
  final ValueNotifier<bool> likeNotifier;
  final Function(String) onLikeToggle;
  final VoidCallback onTap;

  const ImageCard({
    Key? key,
    required this.data,
    required this.imageId,
    required this.currentUser,
    required this.likeNotifier,
    required this.onLikeToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: AppColors.primaryGray.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              child: Stack(
                children: [
                  Image.network(
                    data['imageUrl'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildLikeButton(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  _buildAuthorName(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return AnimatedBuilder(
      animation: likeNotifier,
      builder: (context, child) {
        bool isLiked = likeNotifier.value;
        return IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.white,
          ),
          onPressed: () => onLikeToggle(imageId),
        );
      },
    );
  }

  Widget _buildAuthorName() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['userId'])
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading...');
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return Text('Unknown user');
        }
        return Text(
          userSnapshot.data!['nickname'] ?? 'Unknown user',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primaryGray,
          ),
        );
      },
    );
  }
}
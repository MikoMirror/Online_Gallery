import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../widgets/image_card.dart';

class LikedImagesView extends StatelessWidget {
  final AppUser currentUser;
  final Map<String, ValueNotifier<bool>> likeNotifiers;
  final Function(String) onLikeToggle;
  final Function(String) onImageTap;

  const LikedImagesView({
    Key? key,
    required this.currentUser,
    required this.likeNotifiers,
    required this.onLikeToggle,
    required this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('likes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No liked images yet'));
        }

        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            String imageId = snapshot.data!.docs[index].id;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('images').doc(imageId).get(),
              builder: (context, imageSnapshot) {
                if (imageSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!imageSnapshot.hasData || !imageSnapshot.data!.exists) {
                  return SizedBox.shrink(); // Image no longer exists
                }
                Map<String, dynamic> data = imageSnapshot.data!.data() as Map<String, dynamic>;
                likeNotifiers.putIfAbsent(imageId, () => ValueNotifier(true));
                return ImageCard(
                  data: data,
                  imageId: imageId,
                  currentUser: currentUser,
                  likeNotifier: likeNotifiers[imageId]!,
                  onLikeToggle: onLikeToggle,
                  onTap: () => onImageTap(imageId),
                );
              },
            );
          },
        );
      },
    );
  }
}
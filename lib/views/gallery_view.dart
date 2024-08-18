import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/image_card.dart';
import '../models/app_user.dart';

class GalleryView extends StatelessWidget {
  final bool isDesktop;
  final AppUser currentUser;
  final Map<String, ValueNotifier<bool>> likeNotifiers;
  final Function(String) onLikeToggle;
  final Function(String) onImageTap;

  const GalleryView({
    Key? key,
    required this.isDesktop,
    required this.currentUser,
    required this.likeNotifiers,
    required this.onLikeToggle,
    required this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('images')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200, // Set the maximum width for each item
            childAspectRatio: 0.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            String imageId = document.id;
            likeNotifiers.putIfAbsent(imageId, () => ValueNotifier(false));
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
  }
}
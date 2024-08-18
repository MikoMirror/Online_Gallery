import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../views/gallery_view.dart';
import '../widgets/image_card.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_navigation_bar.dart';
import '../widgets/custom_navigation_rail.dart';
import 'add_image_screen.dart';
import '../views/liked_images_view.dart';
import 'image_details_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MainScreen extends StatefulWidget {
  final AppUser user;

  const MainScreen({Key? key, required this.user}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, ValueNotifier<bool>> _likeNotifiers = {};

  bool get _isDesktop => kIsWeb || (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    _loadLikedImages();
  }

  void _loadLikedImages() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('likes')
          .get();

      for (var doc in querySnapshot.docs) {
        _likeNotifiers[doc.id] = ValueNotifier(true);
      }
      setState(() {});
    } catch (e) {
      // Handle error
      print('Failed to load liked images: $e');
    }
  }

  @override
  void dispose() {
    for (var notifier in _likeNotifiers.values) {
      notifier.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Glass'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _navigateToAddImage(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
      bottomNavigationBar: _isDesktop ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        CustomNavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          onAddPressed: _navigateToAddImage,
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Column(
            children: [
              CustomSearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _isSearching = value.isNotEmpty;
                  });
                },
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        CustomSearchBar(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _isSearching = value.isNotEmpty;
            });
          },
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return _buildSearchView();
    }

    switch (_selectedIndex) {
      case 1:
        return LikedImagesView(
          currentUser: widget.user,
          likeNotifiers: _likeNotifiers,
          onLikeToggle: _toggleLike,
          onImageTap: _navigateToImageDetails,
        );
      case 2:
        return _buildProfileView();
      default:
        return _buildGalleryView();
    }
  }

  Widget _buildSearchView() {
    // Implement search functionality
    return Center(child: Text('Search results')); // Implement actual search logic here
  }

  Widget _buildProfileView() {
    // Implement profile view
    return Center(child: Text('Profile')); // Implement actual profile view here
  }

  Widget _buildGalleryView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('images').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var images = snapshot.data!.docs;

        return MasonryGridView.count(
          crossAxisCount: _isDesktop ? 4 : 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: images.length,
          itemBuilder: (context, index) {
            var imageData = images[index].data() as Map<String, dynamic>;
            var imageId = images[index].id;

            if (!_likeNotifiers.containsKey(imageId)) {
              _likeNotifiers[imageId] = ValueNotifier(false);
            }

            return ImageCard(
              data: imageData,
              imageId: imageId,
              currentUser: widget.user,
              likeNotifier: _likeNotifiers[imageId]!,
              onLikeToggle: _toggleLike,
              onTap: () => _navigateToImageDetails(imageId),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return CustomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  void _toggleLike(String imageId) async {
    final userLikesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('likes')
        .doc(imageId);

    try {
      // Toggle the local state
      if (_likeNotifiers.containsKey(imageId)) {
        _likeNotifiers[imageId]!.value = !_likeNotifiers[imageId]!.value;
      } else {
        _likeNotifiers[imageId] = ValueNotifier(true);
      }

      // Update Firestore
      if (_likeNotifiers[imageId]!.value) {
        await userLikesRef.set({'timestamp': FieldValue.serverTimestamp()});
        print('Added like for image: $imageId');
      } else {
        await userLikesRef.delete();
        print('Removed like for image: $imageId');
      }

      // Trigger a rebuild
      setState(() {});
    } catch (e) {
      print('Error toggling like: $e');
      // Revert the local state if the operation failed
      _likeNotifiers[imageId]!.value = !_likeNotifiers[imageId]!.value;
      setState(() {});
    }
  }

  void _navigateToAddImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddImageScreen(user: widget.user),
      ),
    );
  }

  void _navigateToImageDetails(String imageId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailsScreen(
          imageId: imageId,
          currentUser: widget.user,
        ),
      ),
    );
  }
}
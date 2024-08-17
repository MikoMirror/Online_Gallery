import 'package:flutter/material.dart';
import '../widgets/custom_search_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_image_screen.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

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
  final Set<String> _likedImageIds = {};
  final Map<String, ValueNotifier<bool>> _likeNotifiers = {};

  bool get _isDesktop => kIsWeb || (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    _loadLikedImages();
  }

  void _loadLikedImages() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('likes')
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        _likeNotifiers[doc.id] = ValueNotifier(true);
      }
      setState(() {}); // Trigger a rebuild after loading
    });
  }

  @override
  void dispose() {
    for (var notifier in _likeNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pinterest Clone'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddImageScreen(user: widget.user),
                ),
              );
            },
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
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.home),
              label: Text('Home'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.favorite),
              label: Text('Likes'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person),
              label: Text('Profile'),
            ),
          ],
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddImageScreen(user: widget.user),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
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
        _buildHeader(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.primaryGray.withOpacity(0.1),
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return _buildSearchView();
    }
    switch (_selectedIndex) {
      case 0:
        return _buildGalleryView();
      case 1:
        return _buildLikedImagesView();
      case 2:
        return _buildProfileView();
      default:
        return _buildGalleryView();
    }
  }

  Widget _buildSearchView() {
    // Implement search functionality
    return Center(child: Text('Search results'));
  }

  Widget _buildGalleryView() {
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _isDesktop ? 4 : 2,
            childAspectRatio: 0.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return _buildImageCard(data, document.id);
          },
        );
      },
    );
  }

  Widget _buildImageCard(Map<String, dynamic> data, String imageId) {
    _likeNotifiers.putIfAbsent(imageId, () => ValueNotifier(_likedImageIds.contains(imageId)));

    return Hero(
      tag: 'image_$imageId',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: AppColors.primaryGray.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      data['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildLikeButton(imageId),
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
                  FutureBuilder<DocumentSnapshot>(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton(String imageId) {
    return AnimatedBuilder(
      animation: _likeNotifiers[imageId]!,
      builder: (context, child) {
        bool isLiked = _likeNotifiers[imageId]!.value;
        return IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.white,
          ),
          onPressed: () => _toggleLike(imageId),
        );
      },
    );
  }

  void _toggleLike(String imageId) {
    final userLikesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('likes')
        .doc(imageId);

    _likeNotifiers[imageId]!.value = !_likeNotifiers[imageId]!.value;

    if (_likeNotifiers[imageId]!.value) {
      userLikesRef.set({'timestamp': FieldValue.serverTimestamp()});
    } else {
      userLikesRef.delete();
    }
  }

  Widget _buildLikedImagesView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
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

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No liked images yet'));
        }

        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _isDesktop ? 4 : 2,
            childAspectRatio: 0.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot likeDocument = snapshot.data!.docs[index];
            String imageId = likeDocument.id;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('images')
                  .doc(imageId)
                  .get(),
              builder: (context, imageSnapshot) {
                if (imageSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (imageSnapshot.hasError || !imageSnapshot.hasData) {
                  return Card(child: Center(child: Text('Image not found')));
                }
                Map<String, dynamic> imageData = imageSnapshot.data!.data() as Map<String, dynamic>;
                return _buildImageCard(imageData, imageId);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileView() {
    // Implement profile view
    return Center(child: Text('Profile'));
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Likes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
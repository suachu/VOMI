import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vomi/services/user_location_service.dart';
import 'package:vomi/views/bottom_nav.dart';
import 'package:vomi/views/main/map_places.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(36.9915, 127.1008),
    zoom: 14.2,
  );
  static const double _myLocationZoom = 15.5;
  static const int _maxPopupPosts = 2;
  static const Set<String> _publicScopes = {'전체공개', '전체 공개', '전체'};
  static const Set<String> _friendVisibleScopes = {
    '전체공개',
    '전체 공개',
    '전체',
    '친구공개',
    '친구 공개',
    '친구',
  };
  static const String _fallbackPostImage = 'assets/images/dog1.png';

  // Marker mapping from your images:
  // 31 = not visited, 32 = visited.
  static const String _visitedMarkerAsset = 'assets/images/32.png';
  static const String _notVisitedMarkerAsset = 'assets/images/31.png';

  BitmapDescriptor? _visitedIcon;
  BitmapDescriptor? _notVisitedIcon;
  AppleMapController? _mapController;
  TrackingMode _trackingMode = TrackingMode.none;
  bool _iconsLoadAttempted = false;
  final UserLocationService _locationService = const UserLocationService();
  List<MapPlace> _places = mapPlaces;
  MapPlace? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iconsLoadAttempted) {
      return;
    }
    _iconsLoadAttempted = true;
    _loadAnnotationIcons();
  }

  Future<void> _loadAnnotationIcons() async {
    final ImageConfiguration config = createLocalImageConfiguration(context);
    try {
      final BitmapDescriptor visited = await BitmapDescriptor.fromAssetImage(
        config,
        _visitedMarkerAsset,
      );
      final BitmapDescriptor notVisited = await BitmapDescriptor.fromAssetImage(
        config,
        _notVisitedMarkerAsset,
      );
      if (mounted) {
        setState(() {
          _visitedIcon = visited;
          _notVisitedIcon = notVisited;
        });
      }
    } catch (e, st) {
      debugPrint('Failed to load marker icons: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        _showLocationMessage('31.png 또는 32.png 이미지를 불러오지 못했습니다.');
      }
    }
  }

  Future<void> _loadPlaces() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    try {
      final places = await _locationService.loadMapPlaces(uid);
      if (!mounted) return;
      setState(() {
        _places = places;
      });
    } catch (e, st) {
      debugPrint('Failed to load locations: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Set<Annotation> get _annotations {
    final BitmapDescriptor? visitedIcon = _visitedIcon;
    final BitmapDescriptor? notVisitedIcon = _notVisitedIcon;
    if (visitedIcon == null || notVisitedIcon == null) {
      return <Annotation>{};
    }

    return _places
        .map(
          (MapPlace place) => Annotation(
            annotationId: AnnotationId(place.id),
            position: LatLng(place.latitude, place.longitude),
            icon: place.visited ? visitedIcon : notVisitedIcon,
            infoWindow: InfoWindow.noText,
            onTap: () => _togglePlacePopup(place),
          ),
        )
        .toSet();
  }

  Future<void> _moveToMyLocation() async {
    final AppleMapController? controller = _mapController;
    if (controller == null) {
      return;
    }

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationMessage('위치 서비스가 꺼져 있어요. 설정에서 켜주세요.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationMessage('위치 권한이 필요합니다.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage('위치 권한이 영구 거부되어 설정에서 허용이 필요합니다.');
        await Geolocator.openAppSettings();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          _myLocationZoom,
        ),
      );
    } on MissingPluginException {
      await _fallbackToFollowMode(controller);
      _showLocationMessage('앱을 완전히 재실행하면 현재 위치 이동이 정상 동작합니다.');
    } catch (_) {
      await _fallbackToFollowMode(controller);
      _showLocationMessage('현재 위치를 가져오지 못했습니다.');
    }
  }

  Future<void> _fallbackToFollowMode(AppleMapController controller) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _trackingMode = TrackingMode.follow;
    });
    await controller.animateCamera(CameraUpdate.zoomTo(_myLocationZoom));
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      return;
    }
    setState(() {
      _trackingMode = TrackingMode.none;
    });
  }

  void _showLocationMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _togglePlacePopup(MapPlace place) {
    setState(() {
      if (_selectedPlace?.id == place.id) {
        _selectedPlace = null;
      } else {
        _selectedPlace = place;
      }
    });
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  DateTime _parseCreatedAt(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildPostsStream() {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final scopes = isLoggedIn ? _friendVisibleScopes : _publicScopes;
    return FirebaseFirestore.instance
        .collection('posts')
        .where('scope', whereIn: scopes.toList())
        .limit(50)
        .snapshots();
  }

  String _normalizeScope(dynamic rawScope) {
    if (rawScope == null) return '';
    return '$rawScope'.replaceAll(' ', '').trim();
  }

  bool _matchesLocation(String location, String placeTitle) {
    if (location.isEmpty || placeTitle.isEmpty) return false;
    return location.contains(placeTitle) || placeTitle.contains(location);
  }

  String _emojiAssetForIndex(int index) {
    return switch (index) {
      0 => 'assets/images/love.png',
      1 => 'assets/images/emotion_neutral.png',
      2 => 'assets/images/sad.png',
      3 => 'assets/images/emotion_proud.png',
      4 => 'assets/images/emotion_happy.png',
      _ => 'assets/images/smiling.png',
    };
  }

  List<_MapPlacePost> _postsForPlace(
    List<Map<String, dynamic>> docs,
    MapPlace place,
  ) {
    final filtered = docs.where((data) {
      final scope = _normalizeScope(data['scope']);
      if (!_publicScopes.contains(scope)) return false;
      final location = (data['location'] as String?)?.trim() ?? '';
      return _matchesLocation(location, place.title);
    }).toList();

    filtered.sort((a, b) => _parseCreatedAt(b['createdAt'])
        .compareTo(_parseCreatedAt(a['createdAt'])));

    return filtered.take(_maxPopupPosts).map((data) {
      final title = (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : '제목 없음';
      final excerpt = (data['content'] as String?)?.trim() ?? '';
      final createdAt = _parseCreatedAt(data['createdAt']);
      final scopeLabel = (data['scope'] as String?)?.trim().isNotEmpty == true
          ? (data['scope'] as String).trim()
          : '전체공개';
      final imageUrls = (data['imageUrls'] as List?) ?? [];
      final imageUrl = imageUrls.isNotEmpty ? '${imageUrls.first}' : null;
      final emotionIndex = data['emotionIndex'] as int? ?? 0;

      return _MapPlacePost(
        title: title,
        dateLabel: _formatDate(createdAt),
        scopeLabel: scopeLabel,
        excerpt: excerpt.isNotEmpty ? excerpt : '내용이 없습니다.',
        image: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : const AssetImage(_fallbackPostImage),
        emojiAsset: _emojiAssetForIndex(emotionIndex),
        likeCount: data['likeCount'] as int? ?? 0,
        commentCount: data['commentCount'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildPostsStream(),
        builder: (context, snapshot) {
          final postDocs =
              snapshot.data?.docs.map((doc) => doc.data()).toList() ??
              const <Map<String, dynamic>>[];

          return Stack(
            children: [
              Positioned.fill(
                child: isIOS
                    ? AppleMap(
                        initialCameraPosition: _initialPosition,
                        onMapCreated: (AppleMapController controller) {
                          _mapController = controller;
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        trackingMode: _trackingMode,
                        compassEnabled: false,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        pitchGesturesEnabled: true,
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                EagerGestureRecognizer.new,
                              ),
                            },
                        mapType: MapType.standard,
                        annotations: _annotations,
                        onTap: (_) {
                          if (_selectedPlace == null) return;
                          setState(() {
                            _selectedPlace = null;
                          });
                        },
                      )
                    : Container(
                        color: const Color(0xFFECE8DD),
                        alignment: Alignment.center,
                        child: const Text(
                          'Apple Maps is available on iOS only.',
                          style: TextStyle(
                            color: Color(0xFF7C828A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const _TopSearchBar(),
              _MapRightControls(onLocationTap: _moveToMyLocation),
              if (_selectedPlace != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedPlace = null),
                    child: const SizedBox.expand(),
                  ),
                ),
              if (_selectedPlace != null)
                Builder(
                  builder: (context) {
                    final posts = _postsForPlace(postDocs, _selectedPlace!);
                    return _MapPlacePopup(
                      title: _selectedPlace!.title,
                      posts: posts,
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPlacePopup extends StatelessWidget {
  const _MapPlacePopup({
    required this.title,
    required this.posts,
  });

  final String title;
  final List<_MapPlacePost> posts;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.62;
    final bottomPadding = BottomNavBar.navH + bottomInset + 18;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedSlide(
        offset: const Offset(0, 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 200),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF232A31),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const _PopupSectionTitle(title: '사용자 후기'),
                          const SizedBox(height: 10),
                          if (posts.isNotEmpty) ...[
                            ...posts.map(
                              (post) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MapPostCard(post: post),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ] else ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 10),
                              child: Text(
                                '사용자 후기가 아직 없어요.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF98A0A7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    child: CustomPaint(
                      painter: _PopupPointerPainter(),
                      size: const Size(28, 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupSectionTitle extends StatelessWidget {
  const _PopupSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF3E4650),
      ),
    );
  }
}

class _MapPostCard extends StatelessWidget {
  const _MapPostCard({required this.post});

  final _MapPlacePost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F2F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F262C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF4D6),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        post.emojiAsset,
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${post.dateLabel} · ${post.scopeLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF98A0A7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.excerpt,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF4C545B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Color(0xFFA7AFB6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA7AFB6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.mode_comment_outlined,
                      size: 16,
                      color: Color(0xFFA7AFB6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA7AFB6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image(
              image: post.image,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.12), 6, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPlacePost {
  const _MapPlacePost({
    required this.title,
    required this.dateLabel,
    required this.scopeLabel,
    required this.excerpt,
    required this.image,
    required this.emojiAsset,
    required this.likeCount,
    required this.commentCount,
  });

  final String title;
  final String dateLabel;
  final String scopeLabel;
  final String excerpt;
  final ImageProvider image;
  final String emojiAsset;
  final int likeCount;
  final int commentCount;
}

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar();

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      left: 24,
      right: 24,
      top: topPadding + 18,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF7E8690), width: 1.3),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      '활동 이름, 모집기관 등을 입력하세요',
                      style: TextStyle(
                        color: Color(0xFFA5ABB2),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.search, size: 34, color: Color(0xFF3B434B)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.favorite_border, size: 40, color: Color(0xFF646D74)),
        ],
      ),
    );
  }
}

class _MapRightControls extends StatelessWidget {
  const _MapRightControls({required this.onLocationTap});

  final Future<void> Function() onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 125,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onLocationTap,
              icon: const Icon(
                Icons.navigation_rounded,
                size: 26,
                color: Color(0xFF1086FF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

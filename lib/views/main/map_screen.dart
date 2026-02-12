import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vomi/services/user_location_service.dart';
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
            infoWindow: InfoWindow(
              title: place.title,
              snippet: place.visited ? '방문 완료' : '미방문',
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      body: Stack(
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
                    gestureRecognizers: <
                        Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        EagerGestureRecognizer.new,
                      ),
                    },
                    mapType: MapType.standard,
                    annotations: _annotations,
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
          _MapRightControls(
            onLocationTap: _moveToMyLocation,
          ),
        ],
      ),
    );
  }
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
  const _MapRightControls({
    required this.onLocationTap,
  });

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

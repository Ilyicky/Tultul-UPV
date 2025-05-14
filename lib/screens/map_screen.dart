import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/building_service.dart';
import '../models/building.dart';
import '../services/location_service.dart';
import '../services/directions_service.dart';
import '../widgets/pulsing_circle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'building_image_screen.dart';
import 'dart:math';
import 'building_details_screen.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  bool _followingUser = true;
  static const double _defaultZoom = 18.0;
  late AnimationController _animationController;
  Building? _selectedBuilding;
  List<LatLng> _routePoints = [];
  final DirectionsService _directionsService = DirectionsService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _setupLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    _animationController.reset();

    Animation<double> animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _animationController.forward();
  }

  void _zoomIn() {
    final newZoom = min(_mapController.camera.zoom + 1, 20.0);
    animatedMapMove(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final newZoom = max(_mapController.camera.zoom - 1, 3.0);
    animatedMapMove(_mapController.camera.center, newZoom);
  }

  Future<void> _updateRoute() async {
    if (_currentLocation != null && _selectedBuilding != null &&
        _selectedBuilding!.latitude != null && _selectedBuilding!.longitude != null) {
      final points = await _directionsService.getRoutePoints(
        _currentLocation!,
        LatLng(_selectedBuilding!.latitude!, _selectedBuilding!.longitude!),
      );
      if (mounted) {
        setState(() {
          _routePoints = points;
        });
      }
    }
  }

  Future<void> _setupLocation() async {
    final hasPermission = await LocationService.requestPermission();
    if (hasPermission) {
      final location = await LocationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() => _currentLocation = location);
        animatedMapMove(location, _defaultZoom);
      }

      // Listen to location updates
      LocationService.getLocationStream().listen((location) {
        if (mounted) {
          setState(() => _currentLocation = location);
          if (_followingUser) {
            animatedMapMove(location, _defaultZoom);
          }
          // Update route when location changes
          _updateRoute();
        }
      });
    }
  }

  String _calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    final meters = distance.as(LengthUnit.Meter, start, end);
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  double _calculateZoomLevel(LatLng start, LatLng end) {
    const Distance distance = Distance();
    final meters = distance.as(LengthUnit.Meter, start, end);
    
    // Adjust zoom level based on distance
    if (meters < 100) {
      return 18.0; // Very close, zoom in
    } else if (meters < 500) {
      return 17.0;
    } else if (meters < 1000) {
      return 16.0;
    } else if (meters < 2000) {
      return 15.0;
    } else {
      return 14.0; // Far away, zoom out more
    }
  }

  void _showBuildingDetails(Building building, BuildContext context) {
    if (building.latitude != null && building.longitude != null) {
      setState(() {
        _selectedBuilding = building;
      });
      _updateRoute(); // Get route when building is selected
      animatedMapMove(
        LatLng(building.latitude!, building.longitude!),
        _defaultZoom,
      );
      setState(() => _followingUser = false);
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (building.imageUrl != null && building.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  building.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    building.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_currentLocation != null && building.latitude != null && building.longitude != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _calculateDistance(
                        _currentLocation!,
                        LatLng(building.latitude!, building.longitude!),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (building.popular_names?.isNotEmpty ?? false)
              Text(
                'Also known as: ${building.popular_names}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),
            Text('College: ${building.college}'),
            Text('Address: ${building.address}'),
            const SizedBox(height: 8),
            Text(
              building.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (building.latitude != null && building.longitude != null) {
                        setState(() {
                          _selectedBuilding = building;
                        });
                        _updateRoute();
                        if (_currentLocation != null) {
                          final bounds = LatLngBounds.fromPoints([
                            _currentLocation!,
                            LatLng(building.latitude!, building.longitude!),
                          ]);
                          final zoomLevel = _calculateZoomLevel(
                            _currentLocation!,
                            LatLng(building.latitude!, building.longitude!),
                          );
                          _mapController.move(
                            bounds.center,
                            zoomLevel,
                          );
                        } else {
                          animatedMapMove(
                            LatLng(building.latitude!, building.longitude!),
                            _defaultZoom,
                          );
                        }
                        setState(() => _followingUser = false);
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('View in Map'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuildingDetailsScreen(
                            building: building,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Polyline> _buildPolylines() {
    if (_routePoints.isEmpty) {
      return [];
    }

    return [
      Polyline(
        points: _routePoints,
        color: Colors.blue,
        strokeWidth: 4.0,
        strokeCap: StrokeCap.round,
        borderColor: Colors.blue.withOpacity(0.4),
        borderStrokeWidth: 6.0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view the map'));
    }

    final buildingService = BuildingService();

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<Building>>(
            stream: buildingService.buildings,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final buildings = snapshot.data ?? [];

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(10.640280, 122.228076),
                  initialZoom: _defaultZoom,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() => _followingUser = false);
                    }
                  },
                  minZoom: 3,
                  maxZoom: 20,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://api.mapbox.com/styles/v1/sharenlangga/cmal2bba200zr01rfbvi4evi6/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoic2hhcmVubGFuZ2dhIiwiYSI6ImNtYWtnczExNTE5ZDEyaW9wdTV0N3VhcXkifQ.Q0YFI9A6P6yJf01p0XbLCw",
                    tileProvider: NetworkTileProvider(),
                    maxZoom: 20,
                    keepBuffer: 5,
                    tileBuilder: (context, widget, tile) => widget,
                  ),
                  PolylineLayer(
                    polylines: _buildPolylines(),
                  ),
                  MarkerLayer(
                    markers: [
                      ...buildings
                          .where((b) => b.latitude != null && b.longitude != null)
                          .map((building) {
                            return Marker(
                              point: LatLng(
                                building.latitude!,
                                building.longitude!,
                              ),
                              width: 20,
                              height: 20,
                              child: GestureDetector(
                                onTap: () => _showBuildingDetails(building, context),
                                child: Icon(
                                  Icons.location_on,
                                  color: building == _selectedBuilding ? Colors.blue : Colors.red,
                                  size: 20,
                                ),
                              ),
                            );
                          })
                          .toList(),
                      if (_currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          width: 60,
                          height: 60,
                          child: const PulsingCircle(
                            size: 60,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: "location",
                  onPressed: () {
                    if (_currentLocation != null) {
                      setState(() {
                        _followingUser = true;
                        _selectedBuilding = null;
                        _routePoints = []; // Clear route points
                      });
                      animatedMapMove(_currentLocation!, _defaultZoom);
                    }
                  },
                  child: Icon(
                    _followingUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "zoomIn",
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "zoomOut",
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

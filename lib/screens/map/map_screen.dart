import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

//App Screens
import 'package:tultul_upv/screens/main_screen.dart';
import 'package:tultul_upv/screens/buildings/details/building_details_screen.dart';
import 'package:tultul_upv/screens/rooms/room_instructions_screen.dart';

//Services
import 'package:tultul_upv/services/location_service.dart';
import 'package:tultul_upv/services/directions_service.dart';
import 'package:tultul_upv/services/building_service.dart';

//Models
import 'package:tultul_upv/models/building.dart';

//Constants
import 'package:tultul_upv/widgets/pulsing_circle.dart';


class MapScreen extends StatefulWidget {
  final Building? building;
  final String? targetRoomId;
  final String? targetFloorId;

  const MapScreen({
    super.key,
    this.building,
    this.targetRoomId,
    this.targetFloorId,
  });

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
  final BuildingService _buildingService = BuildingService();
  bool _isNavigating = false;
  static const double _indoorNavigationThreshold = 50.0; // in meters

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.building != null) 
    {
      _selectedBuilding = widget.building;

      // Show building details after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedBuilding != null) 
        {
          _showBuildingDetails(_selectedBuilding!, context);
        }
      });
    }
    _setupLocation(); //ask for location permission and get current location
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
    final newZoom = min(_mapController.camera.zoom + 1, 20.0); // 20 is the max zoom in
    animatedMapMove(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final newZoom = max(_mapController.camera.zoom - 1, 3.0); // 3 is the min zoom out
    animatedMapMove(_mapController.camera.center, newZoom);
  }

  Future<void> _updateRoute() async {
    if (_currentLocation != null &&
        _selectedBuilding != null &&
        _selectedBuilding!.latitude != null &&
        _selectedBuilding!.longitude != null) 
    {
      // request route points from mapbox between current loc and selected building
      final points = await _directionsService.getRoutePoints(
        _currentLocation!,
        LatLng(_selectedBuilding!.latitude!, _selectedBuilding!.longitude!),
      );

      if (mounted) 
      {
        setState(() {
          _routePoints = points;
        });
      }
    }
  }

  Future<void> _setupLocation() async {
    final hasPermission = await LocationService.requestPermission();
    if (hasPermission) 
    {
      final location = await LocationService.getCurrentLocation();

      if (location != null && mounted) 
      {
        setState(() => _currentLocation = location);

        if (_selectedBuilding != null) 
        {
          _updateRoute();

          if (_selectedBuilding!.latitude != null &&
              _selectedBuilding!.longitude != null) 
          {
            final bounds = LatLngBounds.fromPoints([
              location,
              LatLng(
                _selectedBuilding!.latitude!,
                _selectedBuilding!.longitude!,
              ),
            ]);

            final zoomLevel = _calculateZoomLevel(
              location,
              LatLng(
                _selectedBuilding!.latitude!,
                _selectedBuilding!.longitude!,
              ),
            );
            
            _mapController.move(bounds.center, zoomLevel);
          }
        } else {
          animatedMapMove(location, _defaultZoom);
        }
      }

      
      LocationService.getLocationStream().listen((location) {
        if (mounted) 
        {
          setState(() => _currentLocation = location); // update location
          if (_followingUser) 
          {
            animatedMapMove(location, _defaultZoom); // animate map to new location
          }
          _updateRoute(); // update route so that path is accurate
        }
      });
    }
  }

  // Future<void> _getCurrentLocation() async {
  //   try {
  //     final position = await LocationService.getCurrentLocation();
  //     if (position != null) {
  //       setState(() {
  //         _currentLocation = LatLng(position.latitude, position.longitude);
  //         _followingUser = true;
  //       });
  //       animatedMapMove(_currentLocation!, _defaultZoom);
  //     } else {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text(
  //               'Could not get current location. Please try again.',
  //             ),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text(
  //             'Error getting current location. Please check location permissions.',
  //           ),
  //         ),
  //       );
  //     }
  //   }
  // }

  String _calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();

    // calculate distance between user loc and selected building
    final meters = distance.as(LengthUnit.Meter, start, end);
    if (meters < 1000) 
    {
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
      return 18.0; // very close, more zoom
    } else if (meters < 500) {
      return 17.0;
    } else if (meters < 1000) {
      return 16.0;
    } else if (meters < 2000) {
      return 15.0;
    } else {
      return 14.0; // far away, less zoom
    }
  }

  void _startNavigation(Building building) {
    if (building.latitude != null && building.longitude != null) 
    {
      setState(() {
        _selectedBuilding = building;
        _isNavigating = true;
        _followingUser = true;
      });

      _updateRoute();
      if (_currentLocation != null) 
      {
        final bounds = LatLngBounds.fromPoints([
          _currentLocation!,
          LatLng(building.latitude!, building.longitude!),
        ]);

        final zoomLevel = _calculateZoomLevel(
          _currentLocation!,
          LatLng(building.latitude!, building.longitude!),
        );
        _mapController.move(bounds.center, zoomLevel);
      }
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _selectedBuilding = null;
      _routePoints = [];
      _followingUser = true;
    });
    if (_currentLocation != null) 
    {
      animatedMapMove(_currentLocation!, _defaultZoom);
    }
  }

  // Check if the user is near the selected buildling and should start indoor navigation
  void _checkIndoorNavigation() {
    if (_currentLocation != null &&
        _selectedBuilding != null &&
        _selectedBuilding!.latitude != null &&
        _selectedBuilding!.longitude != null) 
    {
      const Distance distance = Distance();
      final meters = distance.as(
        LengthUnit.Meter,
        _currentLocation!,
        LatLng(_selectedBuilding!.latitude!, _selectedBuilding!.longitude!),
      );

      // if the distance is less than 50m, show the room instructions
      if (meters <= _indoorNavigationThreshold) 
      {
      
        if (widget.targetRoomId != null && widget.targetFloorId != null) 
        {
          // Get the room details first
          _buildingService
              .getRooms(_selectedBuilding!.buildingId, widget.targetFloorId!)
              .first
              .then((rooms) {
                // find the target room from the list of rooms
                final targetRoom = rooms.firstWhere(
                  (room) => room.roomId == widget.targetRoomId,
                  orElse: () => throw Exception('Room not found'),
                );

                if (mounted) 
                {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => RoomInstructionsScreen(room: targetRoom),
                    ),
                  );
                }
              })
              .catchError((error) {
                // If room not found, show the building details instead
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BuildingDetailsScreen(
                            building: _selectedBuilding!,
                            showIndoorNavigation: true,
                          ),
                    ),
                  );
                }
              });
        } else {
          // No specific room target, just show building details
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BuildingDetailsScreen(
                    building: _selectedBuilding!,
                    showIndoorNavigation: true,
                  ),
            ),
          );
        }
        _stopNavigation();
      }
    }
  }

  void _showBuildingDetails(Building building, BuildContext context) {
    if (building.latitude != null && building.longitude != null) 
    {
      // Just center the map on the building without starting navigation
      animatedMapMove(
        LatLng(building.latitude!, building.longitude!),
        _defaultZoom,
      );

      setState(() {
        _followingUser = false;
        _selectedBuilding = building; // Just set the selected building
      });
    }

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
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
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.error), // error icon if image is not found
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
                    if (_currentLocation != null &&
                        building.latitude != null &&
                        building.longitude != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (building.popularNames?.isNotEmpty ?? false)
                  Text(
                    'Also known as: ${building.popularNames}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                // Text('College: ${building.college}'),
                // Text('Address: ${building.address}'),
                // const SizedBox(height: 8),
                // Text(
                //   building.description,
                //   style: Theme.of(context).textTheme.bodyMedium,
                // ),
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
                          _startNavigation(building);
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Start Navigation'),
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
                              builder:
                                  (context) => BuildingDetailsScreen(
                                    building: building,
                                    showIndoorNavigation: false,
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
    //final isAdmin = context.watch<UserProvider>().user?.isAdmin() ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
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
                  initialCenter:
                      _currentLocation ?? const LatLng(10.640280, 122.228076),
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
                    urlTemplate:
                        "https://api.mapbox.com/styles/v1/sharenlangga/cmal2bba200zr01rfbvi4evi6/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoic2hhcmVubGFuZ2dhIiwiYSI6ImNtYWtnczExNTE5ZDEyaW9wdTV0N3VhcXkifQ.Q0YFI9A6P6yJf01p0XbLCw",
                    tileProvider: NetworkTileProvider(),
                    maxZoom: 20,
                    keepBuffer: 5,
                    tileBuilder: (context, widget, tile) => widget,
                  ),
                  PolylineLayer(polylines: _buildPolylines()),
                  MarkerLayer(
                    markers: [
                      ...buildings
                          .where(
                            (b) => b.latitude != null && b.longitude != null,
                          )
                          .map((building) {
                            return Marker(
                              point: LatLng(
                                building.latitude!,
                                building.longitude!,
                              ),
                              width: 20,
                              height: 20,
                              child: GestureDetector(
                                onTap: () {
                                  _showBuildingDetails(building, context);
                                },
                                child: Icon(
                                  Icons.location_on,
                                  color:
                                      building == _selectedBuilding
                                          ? Colors.blue
                                          : Colors.red,
                                  size: 20,
                                ),
                              ),
                            );
                          }),
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
            top: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const MainScreen(
                          initialIndex: 1, // Search tab index
                        ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Search buildings...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 160,
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
                        _routePoints = [];
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
          if (_isNavigating &&
              _selectedBuilding != null &&
              _currentLocation != null)
            Positioned(
              left: 16,
              bottom: 40,
              child: Container(
                width: MediaQuery.of(context).size.width - 32,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedBuilding!.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (_selectedBuilding!
                                      .popularNames
                                      ?.isNotEmpty ??
                                  false)
                                Text(
                                  'Also known as: ${_selectedBuilding!.popularNames!.join(", ")}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _stopNavigation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<LatLng>(
                      stream: LocationService.getLocationStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          // Use current location if available while waiting for updates
                          if (_currentLocation != null) {
                            final distance = const Distance().as(
                              LengthUnit.Meter,
                              _currentLocation!,
                              LatLng(
                                _selectedBuilding!.latitude!,
                                _selectedBuilding!.longitude!,
                              ),
                            );
                            return Row(
                              children: [
                                const Icon(Icons.directions_walk, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  distance < 1000
                                      ? '${distance.toStringAsFixed(0)}m remaining'
                                      : '${(distance / 1000).toStringAsFixed(1)}km remaining',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const Row(
                            children: [
                              Icon(Icons.gps_fixed, size: 20),
                              SizedBox(width: 8),
                              Text('Getting your location...'),
                              SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          );
                        }
                        final currentLocation = snapshot.data!;
                        final distance = const Distance().as(
                          LengthUnit.Meter,
                          currentLocation,
                          LatLng(
                            _selectedBuilding!.latitude!,
                            _selectedBuilding!.longitude!,
                          ),
                        );

                        // Check if we should switch to indoor navigation
                        if (distance <= _indoorNavigationThreshold) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _checkIndoorNavigation();
                          });
                        }

                        return Row(
                          children: [
                            const Icon(Icons.directions_walk, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              distance < 1000
                                  ? '${distance.toStringAsFixed(0)}m remaining'
                                  : '${(distance / 1000).toStringAsFixed(1)}km remaining',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

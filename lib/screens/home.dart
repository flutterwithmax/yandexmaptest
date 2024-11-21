import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:testapp/locations.dart';
import 'package:testapp/data/data.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:testapp/models/map_point.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController; // Changed to nullable
  double _mapZoom = 12.0; // Initial zoom level

  @override
  void dispose() {
    _mapController?.dispose(); // Ensure proper cleanup of the controller
    super.dispose();
  }

  Future<void> _initLocationLayer() async {
    final locationPermissionIsGranted =
        await Permission.location.request().isGranted;

    if (locationPermissionIsGranted && _mapController != null) {
      await _mapController!.toggleUserLayer(visible: true);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет доступа к местоположению пользователя'),
          ),
        );
      });
    }
  }

  CameraPosition? _userLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yandex Mapkit Demo')),
      body: Stack(
        children: [
          YandexMap(
            onUserLocationAdded: (view) async {
              if (_mapController == null) {} // Check if controller is null
              // Get user location
              _userLocation = await _mapController!.getUserCameraPosition();
              // If location found, center the map on this point
              if (_userLocation != null) {
                await _mapController!.moveCamera(
                  CameraUpdate.newCameraPosition(
                    _userLocation!.copyWith(zoom: 10),
                  ),
                  animation: const MapAnimation(
                    type: MapAnimationType.linear,
                    duration: 0.3,
                  ),
                );
              }

              return view.copyWith(
                pin: view.pin.copyWith(
                  opacity: 1,
                ),
              );
            },
            onMapCreated: (controller) async {
              _mapController = controller;
              await _initLocationLayer();
            },
            onCameraPositionChanged: (cameraPosition, _, __) {
              setState(() {
                _mapZoom = cameraPosition.zoom;
              });
            },
            mapObjects: [
              _getClusterizedCollection(
                placemarks: _getPlacemarkObjects(context),
              ),
            ],
          ),
          Positioned(
            right: 10,
            bottom: 150,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () async {
                if (_mapController != null) {
                  await _mapController!.moveCamera(
                    CameraUpdate.newCameraPosition(
                      _userLocation!.copyWith(zoom: 14.0),
                    ),
                    animation: const MapAnimation(
                      type: MapAnimationType.linear,
                      duration: 0.3,
                    ),
                  );
                }
              },
              elevation: 3, // Set elevation
              shape: const CircleBorder(), // Make the button round
              child: SvgPicture.asset(
                'assets/images/cursor.svg', // Set the SVG icon
                width: 24, // Optional: Set width for the icon
                height: 24, // Optional: Set height for the icon
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Метод для получения коллекции кластеризованных маркеров
  ClusterizedPlacemarkCollection _getClusterizedCollection({
    required List<PlacemarkMapObject> placemarks,
  }) {
    return ClusterizedPlacemarkCollection(
      mapId: const MapObjectId('clusterized-1'),
      placemarks: placemarks,
      radius: 50,
      minZoom: 15,
      onClusterAdded: (self, cluster) async {
        return cluster.copyWith(
          appearance: cluster.appearance.copyWith(
            opacity: 1.0,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromBytes(
                  await ClusterIconPainter(cluster.size).getClusterIconBytes(),
                ),
              ),
            ),
          ),
        );
      },
      onClusterTap: (self, cluster) async {
        if (_mapController != null) {
          await _mapController!.moveCamera(
            animation: const MapAnimation(
              type: MapAnimationType.linear,
              duration: 0.3,
            ),
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: cluster.placemarks.first.point,
                zoom: _mapZoom + 1,
              ),
            ),
          );
        }
      },
    );
  }

  /// Метод для генерации точек на карте
  List<MapPoint> _getMapPoints() {
    return getMapPoints; // Assuming `getMapPoints` is a function you have defined elsewhere.
  }

  /// Метод для генерации объектов маркеров для отображения на карте
  List<PlacemarkMapObject> _getPlacemarkObjects(BuildContext context) {
    return _getMapPoints()
        .map(
          (point) => PlacemarkMapObject(
            mapId: MapObjectId('MapObject $point'),
            point: Point(latitude: point.latitude, longitude: point.longitude),
            opacity: 1,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromAssetImage(
                  'assets/images/mark_large.png',
                ),
                scale: 0.5,
              ),
            ),
            onTap: (_, __) async {
              // Move the camera to the tapped placemark with animation
              if (_mapController != null) {
                await _mapController!.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: Point(
                          latitude: point.latitude, longitude: point.longitude),
                      zoom: _mapZoom +
                          1, // Zoom in slightly when moving to the placemark
                    ),
                  ),
                  animation: const MapAnimation(
                    type: MapAnimationType.linear,
                    duration: 0.3,
                  ),
                );
              }

              // Show the modal after camera animation is complete
              showModalBottomSheet(
                context: context,
                builder: (context) => _ModalBodyView(
                  point: point,
                ),
              );
            },
          ),
        )
        .toList();
  }
}

/// Содержимое модального окна с информацией о точке на карте
class _ModalBodyView extends StatelessWidget {
  const _ModalBodyView({required this.point});

  final MapPoint point;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(point.name, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          Text(
            '${point.latitude}, ${point.longitude}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

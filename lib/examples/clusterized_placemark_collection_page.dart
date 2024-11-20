import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '/examples/widgets/control_button.dart';
import '/examples/widgets/map_page.dart';

class ClusterizedPlacemarkCollectionPage extends MapPage {
  const ClusterizedPlacemarkCollectionPage({Key? key})
      : super('ClusterizedPlacemarkCollection example', key: key);

  @override
  Widget build(BuildContext context) {
    return _ClusterizedPlacemarkCollectionExample();
  }
}

class _ClusterizedPlacemarkCollectionExample extends StatefulWidget {
  @override
  _ClusterizedPlacemarkCollectionExampleState createState() =>
      _ClusterizedPlacemarkCollectionExampleState();
}

class _ClusterizedPlacemarkCollectionExampleState
    extends State<_ClusterizedPlacemarkCollectionExample> {
  final List<MapObject> mapObjects = [];

  final int kPlacemarkCount = 500;
  final Random seed = Random();
  final MapObjectId mapObjectId =
      const MapObjectId('clusterized_placemark_collection');
  final MapObjectId largeMapObjectId =
      const MapObjectId('large_clusterized_placemark_collection');
  Future<Uint8List> _buildClusterAppearance(Cluster cluster) async {
    const canvasSize = Size(200, 200); // Canvas size
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Load your custom PNG image
    final ByteData imageData =
        await rootBundle.load('assets/images/custom.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final image = await decodeImageFromList(imageBytes);

    // Scale the image to double its size
    final double scale = 2.0;
    final double scaledWidth = image.width * scale;
    final double scaledHeight = image.height * scale;

    // Calculate the scaled image's position (centered on the canvas)
    final imageOffset = Offset(
      (canvasSize.width - scaledWidth) / 2,
      (canvasSize.height - scaledHeight) / 2,
    );

    // Save the canvas state and apply scaling
    canvas.save();
    canvas.translate(imageOffset.dx, imageOffset.dy);
    canvas.scale(scale);

    // Draw the image
    canvas.drawImage(image, Offset.zero, Paint());

    // Restore the canvas state to prevent scaling the text
    canvas.restore();

    // Set up the text painter for the cluster size
    final textPainter = TextPainter(
      text: TextSpan(
        text: cluster.size.toString(), // Cluster size
        style: const TextStyle(
            color: ui.Color.fromARGB(255, 240, 239, 239), fontSize: 30),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Calculate the text position (centered on the canvas)
    final textOffset = Offset(
      (canvasSize.width - textPainter.width) / 2,
      (canvasSize.height - textPainter.height) / 2 - 10,
    );
    textPainter.paint(canvas, textOffset);

    // Generate the final image
    final finalImage = await recorder
        .endRecording()
        .toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
    final pngBytes = await finalImage.toByteData(format: ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  double _randomDouble() {
    return (500 - seed.nextInt(1000)) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: YandexMap(mapObjects: mapObjects)),
          const SizedBox(height: 20),
          Expanded(
              child: SingleChildScrollView(
                  child: Column(children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ControlButton(
                    onPressed: () async {
                      if (mapObjects.any((el) => el.mapId == mapObjectId)) {
                        return;
                      }

                      final mapObject = ClusterizedPlacemarkCollection(
                        mapId: mapObjectId,
                        radius: 30,
                        minZoom: 15,
                        onClusterAdded: (ClusterizedPlacemarkCollection self,
                            Cluster cluster) async {
                          return cluster.copyWith(
                              appearance: cluster.appearance.copyWith(
                                  icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                      image: BitmapDescriptor.fromAssetImage(
                                          'lib/assets/cluster.png'),
                                      scale: 1))));
                        },
                        onClusterTap: (ClusterizedPlacemarkCollection self,
                            Cluster cluster) {
                          print('Tapped cluster');
                        },
                        placemarks: [
                          PlacemarkMapObject(
                              mapId: const MapObjectId('placemark_1'),
                              point: const Point(
                                  latitude: 55.756, longitude: 37.618),
                              consumeTapEvents: true,
                              onTap: (PlacemarkMapObject self, Point point) =>
                                  print('Tapped placemark at $point'),
                              icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                  image: BitmapDescriptor.fromAssetImage(
                                      'lib/assets/place.png'),
                                  scale: 1))),
                          PlacemarkMapObject(
                              mapId: const MapObjectId('placemark_2'),
                              point: const Point(
                                  latitude: 59.956, longitude: 30.313),
                              icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                  image: BitmapDescriptor.fromAssetImage(
                                      'lib/assets/place.png'),
                                  scale: 1))),
                          PlacemarkMapObject(
                              mapId: const MapObjectId('placemark_3'),
                              point: const Point(
                                  latitude: 39.956, longitude: 30.313),
                              icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                  image: BitmapDescriptor.fromAssetImage(
                                      'lib/assets/place.png'),
                                  scale: 1))),
                        ],
                        onTap: (ClusterizedPlacemarkCollection self,
                                Point point) =>
                            print('Tapped me at $point'),
                      );

                      setState(() {
                        mapObjects.add(mapObject);
                      });
                    },
                    title: 'Add'),
                ControlButton(
                    onPressed: () async {
                      if (!mapObjects.any((el) => el.mapId == mapObjectId)) {
                        return;
                      }

                      final mapObject =
                          mapObjects.firstWhere((el) => el.mapId == mapObjectId)
                              as ClusterizedPlacemarkCollection;

                      setState(() {
                        mapObjects[mapObjects.indexOf(mapObject)] =
                            mapObject.copyWith(placemarks: [
                          PlacemarkMapObject(
                              mapId: const MapObjectId('placemark_2'),
                              point: const Point(
                                  latitude: 59.956, longitude: 30.313),
                              icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                  image: BitmapDescriptor.fromAssetImage(
                                      'lib/assets/place.png'),
                                  scale: 1))),
                          PlacemarkMapObject(
                              mapId: const MapObjectId('placemark_3'),
                              point: const Point(
                                  latitude: 39.956, longitude: 31.313),
                              icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                  image: BitmapDescriptor.fromAssetImage(
                                      'lib/assets/place.png'),
                                  scale: 1))),
                          PlacemarkMapObject(
                              mapId: const MapObjectId('placemark_4'),
                              point: const Point(
                                  latitude: 59.945933, longitude: 30.320045),
                              icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                  image: BitmapDescriptor.fromAssetImage(
                                      'lib/assets/place.png'),
                                  scale: 1))),
                        ]);
                      });
                    },
                    title: 'Update'),
                ControlButton(
                    onPressed: () async {
                      setState(() {
                        mapObjects.removeWhere((el) => el.mapId == mapObjectId);
                      });
                    },
                    title: 'Remove')
              ],
            ),
            Text('Set of $kPlacemarkCount placemarks'),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ControlButton(
                      onPressed: () async {
                        if (mapObjects
                            .any((el) => el.mapId == largeMapObjectId)) {
                          return;
                        }

                        final largeMapObject = ClusterizedPlacemarkCollection(
                          mapId: largeMapObjectId,
                          radius: 30,
                          minZoom: 15,
                          onClusterAdded: (ClusterizedPlacemarkCollection self,
                              Cluster cluster) async {
                            return cluster.copyWith(
                                appearance: cluster.appearance.copyWith(
                                    opacity: 0.75,
                                    icon: PlacemarkIcon.single(
                                        PlacemarkIconStyle(
                                            image: BitmapDescriptor.fromBytes(
                                                await _buildClusterAppearance(
                                                    cluster)),
                                            scale: 1))));
                          },
                          onClusterTap: (ClusterizedPlacemarkCollection self,
                              Cluster cluster) {
                            print('Tapped cluster');
                          },
                          placemarks: List<PlacemarkMapObject>.generate(
                              kPlacemarkCount, (i) {
                            return PlacemarkMapObject(
                                mapId: MapObjectId('placemark_$i'),
                                point: Point(
                                    latitude: 55.756 + _randomDouble(),
                                    longitude: 37.618 + _randomDouble()),
                                icon: PlacemarkIcon.single(PlacemarkIconStyle(
                                    image: BitmapDescriptor.fromAssetImage(
                                        'lib/assets/place.png'),
                                    scale: 1)));
                          }),
                          onTap: (ClusterizedPlacemarkCollection self,
                                  Point point) =>
                              print('Tapped me at $point'),
                        );

                        setState(() {
                          mapObjects.add(largeMapObject);
                        });
                      },
                      title: 'Add'),
                  ControlButton(
                      onPressed: () async {
                        setState(() {
                          mapObjects.removeWhere(
                              (el) => el.mapId == largeMapObjectId);
                        });
                      },
                      title: 'Remove')
                ])
          ])))
        ]);
  }
}

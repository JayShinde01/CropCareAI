import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class NdviMapScreen extends StatefulWidget {
  const NdviMapScreen({super.key});

  @override
  State<NdviMapScreen> createState() => _NdviMapScreenState();
}

class _NdviMapScreenState extends State<NdviMapScreen> {
  // CHANGE: Use PC IP if testing on phone
  final String serverHost = 'http://localhost:8000';

  final MapController _mapController = MapController();
  LatLng _center = LatLng(18.9155, 72.833);

  List<LatLng> polygonPoints = [];

  String? proxyBase;
  String? eeTileUrlTemplate;

  double? totalHectares;
  double? diseasedHectares;
  double? avgNdvi;

  bool loading = false;

  // Add point on tap
  void _addPoint(LatLng p) {
    setState(() => polygonPoints.add(p));
  }

  // Clear drawing
  void _clearAll() {
    setState(() {
      polygonPoints.clear();
      proxyBase = null;
      eeTileUrlTemplate = null;
      totalHectares = null;
      diseasedHectares = null;
      avgNdvi = null;
    });
  }

  // Convert drawn points to GeoJSON
  Map<String, dynamic> _buildGeoJson() {
    List<List<double>> coords =
        polygonPoints.map((p) => [p.longitude, p.latitude]).toList();

    if (coords.isNotEmpty && coords.first != coords.last) {
      coords.add(coords.first); // close polygon
    }

    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "Polygon", "coordinates": [coords]}
        }
      ]
    };
  }

  // Send AOI to backend
  Future<void> _sendAoi() async {
    if (polygonPoints.length < 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Draw at least 3 points')));
      return;
    }

    setState(() => loading = true);

    final geojson = _buildGeoJson();

    try {
      final resp = await http.post(
        Uri.parse('$serverHost/map/ndvi'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"geometry": geojson}),
      );

      final body = jsonDecode(resp.body);

      proxyBase = body["proxy_tile_base"];
      if (proxyBase == null) throw Exception("No proxy_tile_base");

      eeTileUrlTemplate = "$serverHost$proxyBase/{z}/{x}/{y}.png";

      var m = body["metrics"];
      totalHectares = (m["total_wheat_area_ha"] as num).toDouble();
      diseasedHectares = (m["diseased_area_ha"] as num).toDouble();
      avgNdvi = (m["avg_ndvi"] as num).toDouble();

      _zoomToPolygon();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  // Zoom to polygon
  void _zoomToPolygon() {
    if (polygonPoints.isEmpty) return;

    double minLat =
        polygonPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat =
        polygonPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng =
        polygonPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng =
        polygonPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    _mapController.fitBounds(
      LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      ),
      options: const FitBoundsOptions(padding: EdgeInsets.all(40)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // MARKERS
    final markers = polygonPoints
        .asMap()
        .entries
        .map(
          (e) => Marker(
            point: e.value,
            width: 30,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  "${e.key + 1}",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        )
        .toList();

    // POLYGON LAYER
    final polygonLayer = polygonPoints.length >= 3
        ? PolygonLayer(
            polygons: [
              Polygon(
                points: polygonPoints,
                color: Colors.green.withOpacity(0.2),
                borderColor: Colors.green,
                borderStrokeWidth: 3,
              )
            ],
          )
        : const PolygonLayer(polygons: []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("NDVI Map Viewer"),
        actions: [
          IconButton(onPressed: _clearAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _center,
                zoom: 15,
                onTap: (tapPosition, latlng) => _addPoint(latlng),
              ),
              children: [
                TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                if (eeTileUrlTemplate != null)
                  TileLayer(
                    urlTemplate: eeTileUrlTemplate!,
                    tileProvider: NetworkTileProvider(),
                  ),
                polygonLayer,
                MarkerLayer(markers: markers),
              ],
            ),
          ),

          // METRICS + BUTTONS
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: loading ? null : _sendAoi,
                      child: loading
                          ? const Text("Processing...")
                          : const Text("Finish & Send"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _clearAll,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text("Clear"),
                    ),
                    Expanded(
                      child: Text(
                        polygonPoints.isEmpty
                            ? "Tap to draw AOI"
                            : "${polygonPoints.length} points",
                        textAlign: TextAlign.right,
                      ),
                    )
                  ],
                ),

                if (totalHectares != null) ...[
                  const SizedBox(height: 10),
                  Text("🌾 Total Wheat Area (ha): ${totalHectares!.toStringAsFixed(2)}"),
                  Text("🚨 Diseased Area (ha): ${diseasedHectares!.toStringAsFixed(2)}"),
                  Text("🌱 Avg NDVI: ${avgNdvi!.toStringAsFixed(3)}"),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}

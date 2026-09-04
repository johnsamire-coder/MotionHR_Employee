import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng _selectedPoint = const LatLng(30.0444, 31.2357);
  String _selectedAddress = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _loadingAddress = false;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _selectedPoint = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_selectedPoint, 15.0);
        _reverseGeocode(_selectedPoint);
      }
    } catch (_) {}
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);

    try {
      String normalizedQuery = query.trim();
      final lower = normalizedQuery.toLowerCase();

      final hasEgyptArabic = normalizedQuery.contains('مصر');
      final hasEgyptEnglish = lower.contains('egypt');

      if (!hasEgyptArabic && !hasEgyptEnglish) {
        normalizedQuery = isAr ? '$normalizedQuery, مصر' : '$normalizedQuery, Egypt';
      }

      final locations = await locationFromAddress(normalizedQuery);

      final List<Map<String, dynamic>> results = [];

      for (final loc in locations.take(8)) {
        String displayName =
            isAr ? 'موقع مقترح داخل مصر' : 'Suggested location in Egypt';

        try {
          final placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = <String>[];
            if ((p.name ?? '').isNotEmpty) parts.add(p.name!);
            if ((p.street ?? '').isNotEmpty) parts.add(p.street!);
            if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
            if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
            if ((p.administrativeArea ?? '').isNotEmpty) parts.add(p.administrativeArea!);
            if ((p.country ?? '').isNotEmpty) parts.add(p.country!);

            final cleaned = parts
                .where((e) => e.trim().isNotEmpty)
                .toList();

            if (cleaned.isNotEmpty) {
              displayName = cleaned.join(', ');
            }
          }
        } catch (_) {}

        results.add({
          'display_name': displayName,
          'lat': loc.latitude,
          'lon': loc.longitude,
        });
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    }

    if (mounted) setState(() => _searching = false);
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lng = result['lon'] as double;
    final address = result['display_name'] as String;

    setState(() {
      _selectedPoint = LatLng(lat, lng);
      _selectedAddress = address;
      _searchResults = [];
      _searchCtrl.clear();
    });

    _mapController.move(_selectedPoint, 15.0);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _loadingAddress = true);

    try {
      final placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[];
        if ((p.name ?? '').isNotEmpty) parts.add(p.name!);
        if ((p.street ?? '').isNotEmpty) parts.add(p.street!);
        if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
        if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
        if ((p.administrativeArea ?? '').isNotEmpty) parts.add(p.administrativeArea!);
        if ((p.country ?? '').isNotEmpty) parts.add(p.country!);

        setState(() {
          _selectedAddress = parts
              .where((e) => e.trim().isNotEmpty)
              .join(', ');
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingAddress = false);
  }

  void _onMapTap(dynamic tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
      _searchResults = [];
    });
    _reverseGeocode(point);
  }

  void _confirm() {
    Navigator.pop(
      context,
      LocationPickerResult(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        address: _selectedAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'اختر الموقع' : 'Pick Location'),
        backgroundColor: Color(0xFF1A0A3E),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              isAr ? 'تأكيد' : 'OK',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: isAr ? 'ابحث عن مكان داخل مصر...' : 'Search for a place in Egypt...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) => _searchPlaces(v),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (_, i) {
                  final r = _searchResults[i];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Color(0xFF1A0A3E)),
                    title: Text(
                      r['display_name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    dense: true,
                    onTap: () => _selectSearchResult(r),
                  );
                },
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 13.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.motionhr_employee',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loadingAddress)
                  const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                else if (_selectedAddress.isNotEmpty)
                  Text(
                    _selectedAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    isAr ? 'ابحث أو اضغط على الخريطة لاختيار موقع داخل مصر' : 'Search or tap the map to select a location in Egypt',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _getCurrentLocation,
        backgroundColor: Color(0xFF1A0A3E),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

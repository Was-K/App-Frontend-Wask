import 'dart:math' as math;

import 'geolocation_platform_stub.dart'
    if (dart.library.js_interop) 'geolocation_platform_web.dart'
    if (dart.library.io) 'geolocation_platform_io.dart';

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.district,
  });

  final double latitude;
  final double longitude;
  final String? district;
}

class LimaDistrictCenter {
  const LimaDistrictCenter({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

typedef GeolocationFetcher = Future<({double latitude, double longitude})?>
    Function();

class GeolocationService {
  GeolocationService({GeolocationFetcher? fetcher})
      : _fetcher = fetcher ?? fetchPlatformCoordinates;

  final GeolocationFetcher _fetcher;

  static const List<LimaDistrictCenter> limaDistricts = <LimaDistrictCenter>[
    LimaDistrictCenter(
      name: 'Miraflores',
      latitude: -12.1211,
      longitude: -77.0293,
    ),
    LimaDistrictCenter(
      name: 'San Isidro',
      latitude: -12.0910,
      longitude: -77.0226,
    ),
    LimaDistrictCenter(
      name: 'Lince',
      latitude: -12.0845,
      longitude: -77.0352,
    ),
    LimaDistrictCenter(
      name: 'Jesus Maria',
      latitude: -12.0752,
      longitude: -77.0498,
    ),
    LimaDistrictCenter(
      name: 'Barranco',
      latitude: -12.1449,
      longitude: -77.0218,
    ),
    LimaDistrictCenter(
      name: 'Surco',
      latitude: -12.1292,
      longitude: -76.9918,
    ),
    LimaDistrictCenter(
      name: 'San Borja',
      latitude: -12.0942,
      longitude: -76.9994,
    ),
    LimaDistrictCenter(
      name: 'Magdalena',
      latitude: -12.0908,
      longitude: -77.0715,
    ),
    LimaDistrictCenter(
      name: 'Pueblo Libre',
      latitude: -12.0785,
      longitude: -77.0622,
    ),
    LimaDistrictCenter(
      name: 'San Miguel',
      latitude: -12.0772,
      longitude: -77.0928,
    ),
    LimaDistrictCenter(
      name: 'La Molina',
      latitude: -12.0789,
      longitude: -76.9436,
    ),
  ];

  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double deg) => deg * (math.pi / 180.0);

  static String inferLimaDistrict(double lat, double lng) {
    var best = limaDistricts.first;
    var bestDist = double.infinity;
    for (final candidate in limaDistricts) {
      final dist = distanceKm(lat, lng, candidate.latitude, candidate.longitude);
      if (dist < bestDist) {
        bestDist = dist;
        best = candidate;
      }
    }
    return best.name;
  }

  static GeoPoint fallbackCoordinatesForDistrict(String district) {
    final normalized = _normalize(district);
    for (final candidate in limaDistricts) {
      if (_normalize(candidate.name) == normalized) {
        return GeoPoint(
          latitude: candidate.latitude,
          longitude: candidate.longitude,
          district: candidate.name,
        );
      }
    }
    final fallback = limaDistricts.first;
    return GeoPoint(
      latitude: fallback.latitude,
      longitude: fallback.longitude,
      district: fallback.name,
    );
  }

  Future<GeoPoint> getCurrentLocation() async {
    final coords = await _fetcher();
    if (coords == null) {
      throw StateError('No se pudo obtener tu ubicacion actual.');
    }
    final district = inferLimaDistrict(coords.latitude, coords.longitude);
    return GeoPoint(
      latitude: coords.latitude,
      longitude: coords.longitude,
      district: district,
    );
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }
}

import 'package:location/location.dart';

Future<({double latitude, double longitude})?> fetchPlatformCoordinates() async {
  final location = Location();

  var serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      throw StateError('Activa el GPS de tu dispositivo para continuar.');
    }
  }

  var permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted &&
        permissionGranted != PermissionStatus.grantedLimited) {
      throw StateError('Permiso de ubicacion denegado.');
    }
  }

  final data = await location.getLocation();
  final lat = data.latitude;
  final lng = data.longitude;
  if (lat == null || lng == null) {
    return null;
  }
  return (latitude: lat, longitude: lng);
}

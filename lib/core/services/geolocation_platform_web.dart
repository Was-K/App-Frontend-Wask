import 'dart:async';
import 'dart:js_interop';

@JS('navigator.geolocation')
external JSObject? get _navigatorGeolocation;

@JS('navigator.geolocation.getCurrentPosition')
external void _getCurrentPosition(
  JSFunction success,
  JSFunction error,
  JSObject options,
);

@JS()
@anonymous
extension type _GeoOptions._(JSObject _) implements JSObject {
  external factory _GeoOptions({
    bool enableHighAccuracy,
    int timeout,
    int maximumAge,
  });
}

extension type _GeoPosition._(JSObject _) implements JSObject {
  external _GeoCoordinates get coords;
}

extension type _GeoCoordinates._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
}

extension type _GeoError._(JSObject _) implements JSObject {
  external int get code;
  external String get message;
}

Future<({double latitude, double longitude})?> fetchPlatformCoordinates() {
  if (_navigatorGeolocation == null) {
    return Future<({double latitude, double longitude})?>.error(
      StateError('Tu navegador no soporta geolocalizacion.'),
    );
  }

  final completer = Completer<({double latitude, double longitude})?>();

  void onSuccess(_GeoPosition position) {
    if (!completer.isCompleted) {
      completer.complete((
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
      ));
    }
  }

  void onError(_GeoError error) {
    if (!completer.isCompleted) {
      final msg = error.code == 1
          ? 'Permiso de ubicacion denegado en el navegador.'
          : 'No pudimos obtener tu ubicacion actual.';
      completer.completeError(StateError(msg));
    }
  }

  _getCurrentPosition(
    onSuccess.toJS,
    onError.toJS,
    _GeoOptions(
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 30000,
    ),
  );

  return completer.future;
}

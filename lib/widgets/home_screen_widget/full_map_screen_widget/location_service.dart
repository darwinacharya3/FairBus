import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/bus_stop.dart';

class LocationService {
  final Location _location = Location();
  
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      final userLocation = await _location.getLocation();
      return LatLng(userLocation.latitude!, userLocation.longitude!);
    } catch (_) {
      return null;
    }
  }

  Stream<LatLng> getLocationStream() {
    return _location.onLocationChanged.map(
      (loc) => LatLng(loc.latitude!, loc.longitude!),
    );
  }

  Future<LatLng?> getCoordinatesFromLocation(String locationName) async {
    try {
      // First check if it's a predefined bus stop
      final busStop = BusStopData.findBusStopByName(locationName);
      if (busStop != null) {
        return busStop.location;
      }

      // If not a bus stop, try geocoding
      List<geocoding.Location> locations = await geocoding.locationFromAddress(
          "$locationName, Kathmandu, Nepal");
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
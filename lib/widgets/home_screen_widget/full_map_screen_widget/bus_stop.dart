import 'package:latlong2/latlong.dart';

class BusStop {
  final String name;
  final LatLng location;

  const BusStop({required this.name, required this.location});
}

class BusStopData {
  static const List<BusStop> stops = [
    BusStop(name: "Balkhu", location: LatLng(27.6843, 85.3012)),
    BusStop(name: "Ekantakuna", location: LatLng(27.6660, 85.3100)),
    BusStop(name: "Satdobato", location: LatLng(27.6591, 85.3253)),
    BusStop(name: "Gwarko", location: LatLng(27.6677, 85.3333)), // Gwarko
    BusStop(name: "Koteshwor", location: LatLng(27.6789, 85.3494)), // Koteshwor
    BusStop(name: "Tinkune", location: LatLng(27.6862, 85.3480)), // Tinkune
    BusStop(name: "Airport", location: LatLng(27.695, 85.3545)), // Airport
    BusStop(name: "Gaushala", location: LatLng(27.7084, 85.3435)), // Gaushala
    BusStop(name: "Chabahil", location: LatLng(27.7173, 85.3466)), // Chabahil
    BusStop(name: "Gopikrishna Hall", location: LatLng(27.7211, 85.3459)), // Gopikrishna Hall
    BusStop(name: "Dhumbarai", location: LatLng(27.7320, 85.3440)), // Dhumbarai
    BusStop(name: "Chakrapath", location: LatLng(27.74, 85.3370)), // Chakrapath
    BusStop(name: "Basundhara", location: LatLng(27.742, 85.3334)), // Basundhara
    BusStop(name: "Samakhusi", location: LatLng(27.7352, 85.3181)), // Samakhusi
    BusStop(name: "Gangabu", location: LatLng(27.7346, 85.3145)), // Gangabu
    BusStop(name: "Machhapokhari", location: LatLng(27.7353, 85.3058)), // Machhapokhari
    BusStop(name: "Balaju", location: LatLng(27.7358, 85.3051)),
    BusStop(name: "Kalanki", location: LatLng(27.6933, 85.2816)),
    BusStop(name: "Banasthali", location: LatLng(27.7249, 85.2982)), // Banasthali
    BusStop(name: "Swoyambhu", location: LatLng(27.7161, 85.2836)), // Swoyambhu
    BusStop(name: "Sitapaila", location: LatLng(27.7077, 85.2825)), // Sitapaila
    BusStop(name: "Bafal", location: LatLng(27.7011, 85.2816)), // Bafal
    
  ];

  //   // Define static stops with their coordinates
//    final List<Map<String, dynamic>> busStops = [
//     const {"name": "Balkhu", "location": LatLng(27.6843, 85.3012)}, // Balkhu
//     const {"name": "Ekantakuna", "location": LatLng(27.6660, 85.3100)}, // Ekantakuna
//     const {"name": "Satdobato", "location": LatLng(27.6591, 85.3253)}, // Satdobato
//     const {"name": "Gwarko", "location": LatLng(27.6677, 85.3333)}, // Gwarko
//     const {"name": "Koteshwor", "location": LatLng(27.6789, 85.3494)}, // Koteshwor
//     const {"name": "Tinkune", "location": LatLng(27.6862, 85.3480)}, // Tinkune
//     const {"name": "Airport", "location": LatLng(27.695, 85.3545)}, // Airport
//     const {"name": "Gaushala", "location": LatLng(27.7084, 85.3435)}, // Gaushala
//     const {"name": "Chabahil", "location": LatLng(27.7173, 85.3466)}, // Chabahil
//     const {"name": "Gopikrishna Hall", "location": LatLng(27.7211, 85.3459)}, // Gopikrishna Hall
//     const {"name": "Dhumbarai", "location": LatLng(27.7320, 85.3440)}, // Dhumbarai
//     const {"name": "Chakrapath", "location": LatLng(27.74, 85.3370)}, // Chakrapath
//     const {"name": "Basundhara", "location": LatLng(27.742, 85.3334)}, // Basundhara
//     const {"name": "Samakhusi", "location": LatLng(27.7352, 85.3181)}, // Samakhusi
//     const {"name": "Gangabu", "location": LatLng(27.7346, 85.3145)}, // Gangabu
//     const {"name": "Machhapokhari", "location": LatLng(27.7353, 85.3058)}, // Machhapokhari
//     const {"name": "Balaju", "location": LatLng(27.7273, 85.3047)}, // Balaju
//     const {"name": "Banasthali", "location": LatLng(27.7249, 85.2982)}, // Banasthali
//     const {"name": "Swoyambhu", "location": LatLng(27.7161, 85.2836)}, // Swoyambhu
//     const {"name": "Sitapaila", "location": LatLng(27.7077, 85.2825)}, // Sitapaila
//     const {"name": "Bafal", "location": LatLng(27.7011, 85.2816)}, // Bafal
//     const {"name": "Kalanki", "location": LatLng(27.6933, 85.2816)}, // Kalanki
//   ];

  static BusStop? findBusStopByName(String name) {
    try {
      return stops.firstWhere(
        (stop) => stop.name.toLowerCase() == name.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }
}


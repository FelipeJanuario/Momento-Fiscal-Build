import 'package:google_maps_flutter/google_maps_flutter.dart';

class Location {
  List<double>? center;
  List<List<double>>? box;
  int? count;
  String? debtValue;
  String? geohash;

  Location({
    required this.center,
    required this.box,
    required this.count,
    required this.debtValue,
    required this.geohash,
  });

  Location.fromJson(Map<String, dynamic> json) {
    if (json["center"] != null &&
        json["center"] is List &&
        json["center"].length >= 2) {
      center = List<double>.from(
          json["center"].map((x) => double.parse(x.toString())));
    } else {
      center = null;
    }

    if (json["box"] != null && json["box"] is List && json["box"].length == 2) {
      box = (json["box"] as List)
          .map((coords) =>
              List<double>.from(coords.map((x) => double.parse(x.toString()))))
          .toList();
    } else {
      box = null;
    }

    geohash = json["geohash"];
    count = json["count"];
    debtValue = json["debt_value"];
  }

  Marker? toMarker({
    required BitmapDescriptor? customIcon,
    required void Function()? onTap,
  }) {
    if (center != null && center!.length >= 2) {
      return Marker(
        markerId: MarkerId(center.toString()),
        position: LatLng(center![0], center![1]),
        onTap: onTap,
        icon: customIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    } else {
      return null;
    }
  }
}

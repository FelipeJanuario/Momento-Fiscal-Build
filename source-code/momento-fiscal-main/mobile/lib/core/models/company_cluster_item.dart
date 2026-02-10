import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:momentofiscal/core/models/company.dart';

class CompanyClusterItem with ClusterItem {
  final Company company;
  final LatLng position;

  CompanyClusterItem({
    required this.company,
    required this.position,
  });

  @override
  LatLng get location => position;

  @override
  String get geohash => '';
}

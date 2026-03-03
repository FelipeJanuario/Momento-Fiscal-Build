import 'package:latlong2/latlong.dart';
import 'package:momentofiscal/core/models/company.dart';

class CompanyClusterItem {
  final Company company;
  final LatLng position;

  CompanyClusterItem({
    required this.company,
    required this.position,
  });

  LatLng get location => position;
}

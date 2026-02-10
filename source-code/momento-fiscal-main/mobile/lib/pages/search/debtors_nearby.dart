import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momentofiscal/pages/location/indebted_companies_page.dart';

class DebtorsNearby extends StatefulWidget {
  const DebtorsNearby({super.key});

  @override
  createState() => _DebtorsNearbyState();
}

class _DebtorsNearbyState extends State<DebtorsNearby> {
  LocationPermission? permission;
  double? _latStarting, _latEnding, _longStarting, _longEnding;
  bool isLoading = false;

  Future<void> checkLocationPermission() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _getNearbyDebtors() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // Verificar serviço de localização (apenas mobile)
    if (!kIsWeb) {
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ative o GPS do seu dispositivo.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation);
        double currentLatitude = position.latitude;
        double currentLongitude = position.longitude;

        setState(() {
          _latStarting = currentLatitude - 0.1;
          _latEnding = currentLatitude + 0.1;
          _longStarting = currentLongitude - 0.1;
          _longEnding = currentLongitude + 0.1;
        });

        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              var indebtedCompaniesPage = IndebtedCompaniesPage(
                latEnding: _latEnding!,
                latStarting: _latStarting!,
                longStarting: _longStarting!,
                longEnding: _longEnding!,
              );
              return indebtedCompaniesPage;
            },
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Permissão de localização não concedida.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                  fixedSize: const Size.fromWidth(500),
                  backgroundColor: Colors.transparent,
                ),
                onPressed: isLoading ? null : _getNearbyDebtors,
                icon: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : Icon(
                        Icons.map,
                        color: Theme.of(context).primaryColor,
                      ),
                label: Text(
                  'Maiores devedores próximos a mim',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

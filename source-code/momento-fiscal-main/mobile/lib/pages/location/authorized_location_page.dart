import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/pages/location/search_by_location_osm_page.dart';

class AuthorizedLocation extends StatelessWidget {
  const AuthorizedLocation({super.key});

  void initPermissions(context) async {
    LocationPermission permission;
    bool isPermission = false;

    // Em Web, não precisa verificar se o serviço está habilitado
    // O navegador gerencia isso automaticamente
    if (!kIsWeb) {
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ative o GPS do seu dispositivo.')),
        );
        return;
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Caso o app não possua permissão de acesso à localização, pedir acesso.
      permission = await Geolocator.requestPermission();
      
      // Se ainda estiver denied após requestPermission, mostrar mensagem
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de localização permanentemente negada. Habilite nas configurações do navegador.'),
        ),
      );
      return;
    }

    // Após a permissão concedida
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchByLocationOsmPage()),
      );
      isPermission = true;
      storage.write(key: "isPermission", value: isPermission.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Colors.white,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.asset('assets/images/gps.jpeg'),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        textAlign: TextAlign.center,
                        'Para funcionamento do aplicativo é necessário permitir a utilização do GPS',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        initPermissions(context);
                      },
                      style: ElevatedButton.styleFrom(
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 45)),
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

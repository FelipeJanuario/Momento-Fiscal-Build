import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/location.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/location/location_compaines_rails.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';

// Classe simples para agrupar empresas
class CompanyCluster {
  final LatLng position;
  final List<Company> companies;

  CompanyCluster({required this.position, required this.companies});

  bool get isMultiple => companies.length > 1;
  int get count => companies.length;
}

class SearchByLocationPage extends StatefulWidget {
  const SearchByLocationPage({super.key});

  @override
  State<SearchByLocationPage> createState() => _SearchByLocationPageState();
}

class _SearchByLocationPageState extends State<SearchByLocationPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  Set<Circle> circles = {};
  double _currentZoom = 10.4746;

  late BitmapDescriptor currentPositionIcon;
  List<Company> companies = [];
  int currentPage = 1;
  bool showCard = false;
  bool isLoading = false;
  bool isMoreLoading = false;
  late Future<void> company;
  double? _longStarting;
  double? _latStarting;
  double? _longEnding;
  double? _latEnding;
  String? _previousGeohash;
  LatLng? _currentCameraCenter;
  String? _selectedDebtNature;

  CameraPosition cameraPosition = const CameraPosition(
    target: LatLng(-15.793938, -47.882813),
    zoom: 10.4746,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentUserIcon();
    _getCurrentUserPosition();
    // ignore: void_checks
    company = Future.value([]);
  }

  // Agrupa empresas próximas em clusters baseado no zoom
  List<CompanyCluster> _clusterCompanies(List<Company> companies, double zoom) {
    if (companies.isEmpty) return [];

    // Quanto maior o zoom, menor o raio de agrupamento
    double clusterRadius = 0.1 / math.pow(2, zoom - 10);
    if (zoom >= 17) {
      // Sem clustering em zoom alto
      return companies.map((c) {
        final coords = c.address?.geographicCoordinate?.coordinates;
        if (coords != null && coords.length == 2) {
          return CompanyCluster(
            position: LatLng(coords[1], coords[0]),
            companies: [c],
          );
        }
        return null;
      }).whereType<CompanyCluster>().toList();
    }

    List<CompanyCluster> clusters = [];
    List<Company> remaining = List.from(companies);

    while (remaining.isNotEmpty) {
      final first = remaining.removeAt(0);
      final firstCoords = first.address?.geographicCoordinate?.coordinates;
      if (firstCoords == null || firstCoords.length != 2) continue;

      final firstLat = firstCoords[1];
      final firstLng = firstCoords[0];

      List<Company> clusterCompanies = [first];
      double sumLat = firstLat;
      double sumLng = firstLng;

      remaining.removeWhere((company) {
        final coords = company.address?.geographicCoordinate?.coordinates;
        if (coords == null || coords.length != 2) return false;

        final lat = coords[1];
        final lng = coords[0];
        final distance = math.sqrt(
          math.pow(lat - firstLat, 2) + math.pow(lng - firstLng, 2),
        );

        if (distance < clusterRadius) {
          clusterCompanies.add(company);
          sumLat += lat;
          sumLng += lng;
          return true;
        }
        return false;
      });

      clusters.add(CompanyCluster(
        position: LatLng(
          sumLat / clusterCompanies.length,
          sumLng / clusterCompanies.length,
        ),
        companies: clusterCompanies,
      ));
    }

    return clusters;
  }

  Future<void> _updateMarkersFromCompanies(List<Company> companies) async {
    final clusters = _clusterCompanies(companies, _currentZoom);

    Set<Marker> newMarkers = {};

    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final icon = await _getClusterIcon(cluster.count, cluster.isMultiple);

      newMarkers.add(Marker(
        markerId: MarkerId('cluster_$i'),
        position: cluster.position,
        icon: icon,
        onTap: () {
          if (cluster.isMultiple) {
            _showCompaniesInCluster(cluster.companies);
          } else {
            _showCompanyDetails(cluster.companies.first);
          }
        },
      ));
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  Future<BitmapDescriptor> _getClusterIcon(int count, bool isCluster) async {
    if (!isCluster) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = const Color(0xFF00897B);
    const double radius = 35.0;

    // Desenha círculo
    canvas.drawCircle(const Offset(radius, radius), radius, paint);

    // Desenha borda branca
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(radius, radius), radius, borderPaint);

    // Desenha texto
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          fontSize: 24.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final img = await pictureRecorder.endRecording().toImage(
      (radius * 2).toInt(),
      (radius * 2).toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getCurrentUserIcon() async {
    // ignore: deprecated_member_use
    currentPositionIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/images/current_location.png',
    );
  }

  Future<BitmapDescriptor> createCustomMarkerIcon(
      String textCountCompany, String textDebit, String iconPath) async {
    const double width = 200;
    const double height = 120;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final shadowRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 6, width, height),
      const Radius.circular(24),
    );
    canvas.drawRRect(shadowRect, shadowPaint);

    // Gradiente de fundo
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00897B), // Teal escuro
          Color(0xFF00695C), // Teal mais escuro
        ],
      ).createShader(const Rect.fromLTWH(0, 0, width, height));
    
    final roundedRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(24),
    );
    canvas.drawRRect(roundedRect, gradientPaint);

    // Borda branca suave
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(roundedRect, borderPaint);

    // Ícone com fundo circular branco
    final iconCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(35, 40), 30, iconCirclePaint);

    final ByteData data = await rootBundle.load(iconPath);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 40);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    canvas.drawImageRect(
      frameInfo.image,
      Rect.fromLTWH(0, 0, frameInfo.image.width.toDouble(),
          frameInfo.image.height.toDouble()),
      const Rect.fromLTWH(15, 20, 40, 40),
      Paint(),
    );

    // Texto de contagem com sombra
    final shadowTextPainter1 = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: textCountCompany,
        style: TextStyle(
          fontSize: 38.0,
          color: Colors.black.withOpacity(0.2),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    shadowTextPainter1.layout();
    shadowTextPainter1.paint(canvas, Offset((width - shadowTextPainter1.width) / 1.35 + 2, 22));

    final textPainter1 = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: '',
        children: [],
      ),
    );
    textPainter1.text = TextSpan(
      text: textCountCompany,
      style: const TextStyle(
        fontSize: 38.0,
        color: Colors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
    );
    textPainter1.layout();
    textPainter1.paint(canvas, Offset((width - textPainter1.width) / 1.35, 20));

    // Texto de débito com sombra e formatação melhor
    final shadowTextPainter2 = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: textDebit,
        style: TextStyle(
          fontSize: 20.0,
          color: Colors.black.withOpacity(0.2),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    shadowTextPainter2.layout();
    shadowTextPainter2.paint(canvas, Offset((width - shadowTextPainter2.width) / 2 + 1, 81));

    final textPainter2 = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: textDebit,
        style: const TextStyle(
          fontSize: 20.0,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
    textPainter2.layout();
    textPainter2.paint(canvas, Offset((width - textPainter2.width) / 2, 80));

    final img = await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), height.toInt());
    final dataBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    // ignore: deprecated_member_use
    return BitmapDescriptor.fromBytes(dataBytes!.buffer.asUint8List());
  }

  Future<void> _getCurrentUserPosition() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    final LatLng newPosition = LatLng(position.latitude, position.longitude);
    _setNewCameraPosition(newPosition);

    final userMarker = Marker(
      markerId: const MarkerId('Current user position'),
      position: newPosition,
      icon: currentPositionIcon,
    );
    setState(() {
      _markers.clear();
      _markers.add(userMarker);
    });
  }

  void _setNewCameraPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: position,
        zoom: 15.4746,
      )),
    );
  }

  void _addCentralCircle() {
    if (_currentCameraCenter == null) return;

    setState(() {
      circles.clear();
      circles.add(Circle(
        circleId: const CircleId('center_circle'),
        center: _currentCameraCenter!,
        radius: 1000,
        strokeColor: const Color(0xFF00897B),
        strokeWidth: 3,
        fillColor: const Color(0xFF00897B).withOpacity(0.12),
      ));
    });
  }

  void _onCameraIdle() async {
    _addCentralCircle();

    setState(() {
      isLoading = true;
    });

    final GoogleMapController controller = await _controller.future;
    final visibleRegion = await controller.getVisibleRegion();

    try {
      // Se usar base local, carrega empresas diretamente
      if (LocationCompaniesRails.useLocalDatabase) {
        final List<Company> companiesInRegion =
            await LocationCompaniesRails().getInLocation(
          longStarting: visibleRegion.southwest.longitude,
          latStarting: visibleRegion.southwest.latitude,
          longEnding: visibleRegion.northeast.longitude,
          latEnding: visibleRegion.northeast.latitude,
          page: 1,
        );

        setState(() {
          companies = companiesInRegion;
        });

        // Atualiza marcadores com clustering
        await _updateMarkersFromCompanies(companiesInRegion);
      } else {
        // Modo antigo: usa clusters do biddings analyser
        final List<Location> locations =
            await LocationCompaniesRails().getCountInLocation(
          longStarting: visibleRegion.southwest.longitude,
          latStarting: visibleRegion.northeast.latitude,
          longEnding: visibleRegion.northeast.longitude,
          latEnding: visibleRegion.southwest.latitude,
          debtNature: _selectedDebtNature,
        );

        // Antiga lógica de Location removida - agora usando clustering com Company direto
      }
    } catch (e) {
      // Lidar com erros, se necessário
      print('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        isLoading = false; // Desativa o loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Busca por Localização',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboadPage()),
            );
          },
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showInfoDialog,
            tooltip: 'Informação',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: cameraPosition,
            zoomControlsEnabled: false,
            markers: _markers,
            circles: circles,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            onCameraIdle: _onCameraIdle,
            onCameraMove: (position) {
              if (_currentCameraCenter == position.target && _currentZoom == position.zoom) return;

              setState(() {
                _currentCameraCenter = position.target;
                _currentZoom = position.zoom;
              });
            },
          ),
          if (isLoading)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: const ui.Color.fromARGB(97, 255, 255, 255),
                  borderRadius: BorderRadius.circular(2633),
                ),
                padding: const EdgeInsets.all(16),
                child: const CircularProgressIndicator(),
              ),
            ),
          // Positioned(
          //   top: 16,
          //   left: 16,
          //   child: FloatingActionButton(
          //     onPressed: _showAutocompleteDialog,
          //     tooltip: 'Buscar Natureza da Dívida',
          //     child: const Icon(Icons.search),
          //   ),
          // ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: _getCurrentUserPosition,
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: Icon(
                  Icons.gps_fixed, // Ícone GPS fixo
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _showAutocompleteDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Row(
  //           mainAxisAlignment: MainAxisAlignment.end,
  //           children: [
  //             IconButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               icon: const Icon(
  //                 Icons.close,
  //                 color: Colors.black54,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: SizedBox(
  //           height: 200,
  //           width: double.infinity,
  //           child: Column(
  //             children: [
  //               const Text(
  //                 'Selecione a Natureza da Dívida',
  //                 style:
  //                     TextStyle(fontSize: 20, fontWeight: ui.FontWeight.bold),
  //               ),
  //               DropdownButton<String>(
  //                 value: _selectedDebtNature,
  //                 icon: const Icon(Icons.arrow_downward),
  //                 isExpanded: true,
  //                 items: List.generate(
  //                   _kOptions.length,
  //                   (index) => DropdownMenuItem(
  //                     value: _kOptions[index],
  //                     child: Text(_kOptions[index]),
  //                   ),
  //                 ),
  //                 onChanged: (value) {
  //                   setState(() {
  //                     _selectedDebtNature = value;
  //                   });

  //                   Navigator.of(context).pop();
  //                   _onCameraIdle();
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             style: ElevatedButton.styleFrom(
  //               elevation: 3,
  //               backgroundColor: colorPrimaty,
  //               padding: const EdgeInsets.symmetric(horizontal: 30),
  //             ),
  //             child: const Text(
  //               'Limpar',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //             onPressed: () {
  //               setState(() => _selectedDebtNature = null);
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             style: ElevatedButton.styleFrom(
  //               elevation: 3,
  //               backgroundColor: colorTertiary,
  //               padding: const EdgeInsets.symmetric(horizontal: 30),
  //             ),
  //             child: const Text(
  //               'Fechar',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // static const List<String> _kOptions = <String>[
  //   'AGUARDANDO CADASTRAMENTO DE EMBARGOS',
  //   'AGUARDANDO CONFIRMACAO DO SIM',
  //   'AJUIZ PARCELADA',
  //   'AJUIZADA',
  //   'AJUIZAMENTO   DISTRIBUICAO',
  //   'AJUIZAMENTO   DISTRIBUICAO DE ACAO DE DEPOSITO',
  //   'ARQUIVAMENTO PROVISORIO DA ACAO',
  //   'ATIVA A SER AJUIZADA',
  //   'ATIVA A SER COBRADA',
  //   'ATIVA AJUIZADA',
  //   'ATIVA AJUIZADA - ART. 910 CPC - CONTENCIOSO FAZENDA PUBLICA',
  //   'ATIVA AJUIZADA - ART. 910 CPC - PRECATORIO',
  //   'ATIVA AJUIZADA - GARANTIA - CARTA FIANCA',
  //   'ATIVA AJUIZADA - GARANTIA - DEPOSITO',
  //   'ATIVA AJUIZADA - GARANTIA - NJP',
  //   'ATIVA AJUIZADA - GARANTIA - PENHORA',
  //   'ATIVA AJUIZADA - GARANTIA - SEGURO GARANTIA',
  //   'ATIVA AJUIZADA AGUARD NEG LEI 11.941-C/ PARC ANT-TODOS DEBITOS ATENDEM',
  //   'ATIVA AJUIZADA AGUARD NEG LEI 11.941/12.996 - P FISICA RESP',
  //   'ATIVA AJUIZADA AGUARD NEG LEI 12.996/14 - TODOS DEBITOS ATENDEM',
  //   'ATIVA AJUIZADA AGUARD NEG PAG A VISTA LEI 11941/09-PREJUIZO FISCAL',
  //   'ATIVA AJUIZADA AGUARD NEG PAG A VISTA LEI 12.996/14 - PREJUIZO FISCAL',
  //   'ATIVA AJUIZADA COM EXIBILIDADE SUSPENSA - ANALISE MP 449',
  //   'ATIVA AJUIZADA COM EXIBILIDADE SUSPENSA - ANALISE SV 008',
  //   'ATIVA AJUIZADA COM EXIG. SUSPENSA - PARC SIMPLES NACIONAL 2007',
  //   'ATIVA AJUIZADA COM EXIGIB. SUSPENSA - LEI 11.775/2008-RENEG. ANUAL',
  //   'ATIVA AJUIZADA COM EXIGIB. SUSPENSA - LEI 11.775/2008-RENEG. SEMESTRAL',
  //   'ATIVA AJUIZADA COM EXIGIBILIDADE DO CREDITO SUSPENSA-DECISAO JUDICIAL',
  //   'ATIVA AJUIZADA COM EXIGIBILIDADE SUSPENSA - ART 1 MP 303/06',
  //   'ATIVA AJUIZADA COM EXIGIBILIDADE SUSPENSA - MORATORIA PROSUS',
  //   'ATIVA AJUIZADA COM EXIGIBILIDADE SUSPENSA - PARCELAMENTO IES-PROIES',
  //   'ATIVA AJUIZADA COM EXIGIBILIDADE SUSPENSA PARCELADA MP574 - PASEP',
  //   'ATIVA AJUIZADA COM PETICAO DE ARQUIVAMENTO EMITIDA',
  //   'ATIVA AJUIZADA COM PROCESSO A ARQUIVAR',
  //   'ATIVA AJUIZADA DESBLOQUEADA PARA NEGOCIACAO LEI 11.941/2009',
  //   'ATIVA AJUIZADA EM PROCESSO DE NEGOCIACAO NO SISPAR',
  //   'ATIVA AJUIZADA EXIG SUSP-DECLARACAO INCLUSAO CONSOL PARC LEI 11.941',
  //   'ATIVA AJUIZADA EXIG SUSP-INDICADA P/ INCLUSAO CONSOL PARC LEI 11.941',
  //   'ATIVA AJUIZADA EXIGIBILIDADE CREDITO SUSPENSA-PARC TIMEMANIA CLUBES',
  //   'ATIVA AJUIZADA NEGOCIADA NO SISPAR',
  //   'ATIVA AJUIZADA NEGOCIADA NO SISPAR - BLOQUEADA',
  //   'ATIVA AJUIZADA OP PGVISTA MP470 PREJ FISC BCN CSLL AGUARD CONFIRM',
  //   'ATIVA AJUIZADA OPCAO MP470 E PRORELIT PREJ FISC BCN CSLL AGUARD CONFIR',
  //   'ATIVA AJUIZADA OPCAO PAGAMENTO A VISTA LEI 12.996/2014',
  //   'ATIVA AJUIZADA OPCAO PAGAMENTO A VISTA MP470',
  //   'ATIVA AJUIZADA OPCAO PARCELAMENTO MP470',
  //   'ATIVA AJUIZADA PAG A VISTA LEI 11941/09-PREJ FISCAL AGUARD CONFIRM.',
  //   'ATIVA AJUIZADA PAG A VISTA LEI 12996/14-PREJ FISCAL AGUARD CONFIRM',
  //   'ATIVA AJUIZADA PARC LEI 11941/09 ART 1-DIVIDAS SEM PARCEL. ANTERIOR',
  //   'ATIVA AJUIZADA PARC LEI 11941/09 ART 2-APROV. INDEVIDO CREDITO IPI',
  //   'ATIVA AJUIZADA PARC LEI 11941/09 ART 3-SALDO REMANESCENTE PARCEL',
  //   'ATIVA AJUIZADA PARCELADA LEI 12.865/13 - ART.40',
  //   'ATIVA AJUIZADA PARCELADA LEI 12996/14',
  //   'ATIVA AJUIZADA PARCELADA TIMEMANIA-DEM ENT',
  //   'ATIVA CADASTRADA',
  //   'ATIVA COM AJUIZAMENTO A SER PROSSEGUIDO',
  //   'ATIVA COM AJUIZAMENTO A SER SUSPENSO EM RAZAO DO REFIS',
  //   'ATIVA COM AJUIZAMENTO SUSPENSO EM RAZAO DA LEI 10.684/2003 - PAES',
  //   'ATIVA COM AJUIZAMENTO SUSPENSO PARA ANALISE DA RFB',
  //   'ATIVA COM AJUIZAMENTO SUSPENSO PARA ANALISE DO ORGAO DE ORIGEM',
  //   'ATIVA COM PARCELAMENTO RESCINDIDO E AJUIZAMENTO A SER PROSSEGUIDO',
  //   'ATIVA COM PARCELAMENTO SIMPLIFICADO',
  //   'ATIVA COM PARCELAMENTO SIMPLIFICADO E AJUIZAMENTO A SER CANCELADO',
  //   'ATIVA COM PARCELAMENTO SIMPLIFICADO E AJUIZAMENTO A SER SUSPENSO',
  //   'ATIVA COM PARCELAMENTO SIMPLIFICADO RESCINDIDO E AJUIZAM A PROSSEGUIR',
  //   'ATIVA EM COBRANCA',
  //   'ATIVA ENCAMINHADA PARA AJUIZAMENTO',
  //   'ATIVA ENCAMINHADA PARA JUSTICA AGUARDANDO DISTRIBUICAO - EFDV',
  //   'ATIVA NAO AJUIZ AGUARD NEG LEI 12.996/14 - TODOS DEBITOS ATENDEM',
  //   'ATIVA NAO AJUIZ EXIG SUSP-INDICADA P/ INCLUSAO CONSOL PARC LEI 11.941',
  //   'ATIVA NAO AJUIZ OPCAO MP470 E PRORELIT PREJ FISC BCN CSLL AGUAR CONFIR',
  //   'ATIVA NAO AJUIZ PAG A VISTA LEI 11941/09-PREJ FISCAL AGUARD CONFIRM.',
  //   'ATIVA NAO AJUIZ PAG A VISTA LEI 12996/14-PREJ FISCAL AGUARD CONFIRM',
  //   'ATIVA NAO AJUIZ PARC LEI 11941/09 ART 1-DIVIDAS SEM PARCEL. ANTERIOR',
  //   'ATIVA NAO AJUIZ PARC LEI 11941/09 ART 2-APROV. INDEVIDO CREDITO IPI',
  //   'ATIVA NAO AJUIZ PARC LEI 11941/09 ART 3-SALDO REMANESCENTE PARCEL',
  //   'ATIVA NAO AJUIZADA COM EXIBILIDADE SUSPENSA - ANALISE MP 449',
  //   'ATIVA NAO AJUIZADA COM EXIBILIDADE SUSPENSA - ANALISE SV 008',
  //   'ATIVA NAO AJUIZADA COM EXIGIB. SUSP.- LEI 11.775/2008-RENEG. ANUAL',
  //   'ATIVA NAO AJUIZADA COM EXIGIB. SUSP.- LEI 11.775/2008-RENEG. SEMESTRAL',
  //   'ATIVA NAO AJUIZADA PARCELADA LEI 12.865/13 - ART.40',
  //   'ATIVA NAO AJUIZADA PARCELADA LEI 12996/14',
  //   'ATIVA NAO AJUIZADA PARCELADA TIMEMANIA-DEM ENT',
  //   'ATIVA NAO AJUIZAVEL',
  //   'ATIVA NAO AJUIZAVEL - GARANTIA - NJP',
  //   'ATIVA NAO AJUIZAVEL AGUARD NEG LEI 11.941/12.996 - P FISICA RESP',
  //   'ATIVA NAO AJUIZAVEL COM AJUIZAMENTO A CANCELAR',
  //   'ATIVA NAO AJUIZAVEL COM EXIG. SUSPENSA - PARC SIMPLES NACIONAL 2007',
  //   'ATIVA NAO AJUIZAVEL COM EXIGIBILIDADE DO CREDITO SUSPENSA-DEC.JUDICIAL',
  //   'ATIVA NAO AJUIZAVEL COM EXIGIBILIDADE SUSPENSA - ART 1 MP 303/06',
  //   'ATIVA NAO AJUIZAVEL COM EXIGIBILIDADE SUSPENSA - MORATORIA PROSUS',
  //   'ATIVA NAO AJUIZAVEL COM EXIGIBILIDADE SUSPENSA PARCELADA MP574 - PASEP',
  //   'ATIVA NAO AJUIZAVEL EM COBRANCA',
  //   'ATIVA NAO AJUIZAVEL EM PROCESSO DE NEGOCIACAO NO SISPAR',
  //   'ATIVA NAO AJUIZAVEL EM RAZAO DA LEI 10.684/2003 - PAES',
  //   'ATIVA NAO AJUIZAVEL EM RAZAO DO REFIS',
  //   'ATIVA NAO AJUIZAVEL GARANTIA - DEPOSITO JUDICIAL',
  //   'ATIVA NAO AJUIZAVEL NEGOCIADA NO SISPAR',
  //   'ATIVA NAO AJUIZAVEL NEGOCIADA NO SISPAR - BLOQUEADA',
  //   'ATIVA NAO AJUIZAVEL OP PGVISTA MP470 PREJ FISC BCN CSLL AGUARD CONFIRM',
  //   'ATIVA NAO AJUIZAVEL PARA ANALISE DO ORGAO DE ORIGEM',
  //   'ATIVA NAO PRIORIZADA PARA AJUIZAMENTO',
  //   'ATIVA PARCELADA TIMEMANIA-DEM ENT COM AJUIZAMENTO A SER SUSPENSO',
  //   'ATIVA PREPARADA PARA AJUIZAMENTO ELETRONICO',
  //   'CADASTRAMENTO DE CREDITO DE SUCUMBEMCIA',
  //   'CITACAO DO DEVEDOR',
  //   'CITACAO DO S  SOCIO S',
  //   'COM JUIZ PARA DESPACHO',
  //   'COM JUIZ PARA PROLACAO DE SENTENCA',
  //   'COM JUIZ PARA SENTENCA',
  //   'CONTRA RAZOES AO RECURSO',
  //   'CREDITO COM RESIDUO DE HONORARIOS  PREJUIZO FISCAL',
  //   'CREDITO COM RESIDUO DE PARCELAMENTO',
  //   'CREDITO EM COBRANCA AMIGAVEL COM VALOR ATE 10000 R',
  //   'CREDITO EM DILIGENCIA NA AREA ADMINISTRATIVA',
  //   'CREDITO EM GRAU DE AVOCATORIA',
  //   'CREDITO INSCRITO EM ANALISE PARA AJUIZAMENTO',
  //   'CREDITO PARCELADO COM ERRO MIGRADO',
  //   'CREDITO PREVIDENCIARIO SUB JUDICE',
  //   'CREDITO REATIVADO PELA FUNCAO DE DESAPROPRIACAO',
  //   'D I    DECLARADA INCOMPETENCIA DO JUIZO   REMETIDO',
  //   'DECRETACAO DE FALENCIA',
  //   'DESISTENCIA DA ACAO POR AJUIZAMENTO INDEVIDO',
  //   'DESISTENCIA DE ACAO',
  //   'DESPACHO INTERLOCUTORIO',
  //   'DEVOLUCAO PARA DESMEMBRAMENTO DE CRED  INSCRITO SE',
  //   'EM NEGOCIACAO NO SISPAR',
  //   'EMBARGADA',
  //   'EMBARGOS DE TERCEIROS',
  //   'EMBARGOS DO DEVEDOR',
  //   'EMISSAO DE PECAS PROCESSUAIS',
  //   'ENC PROTESTO',
  //   'ENCAMINHAMENTO PARA INCLUSAO EM PARCELAMENTO ADMIN',
  //   'ENCERRAMENTO DA FALENCIA',
  //   'EXPEDICAO   CUMPRIMENTO DE CARTA PRECATORIA',
  //   'HASTA PUBLICA   DESIGNADA',
  //   'IMPUGNACAO AOS EMBARGOS',
  //   'INCL  EM PARC  MP 457 LEI 11960 12058 09',
  //   'INCLUIDO EM PARCELAMENTO SIMP  LEI 10 522',
  //   'INCLUSAO EM PARCELAMENTO ESPECIAL LEI 12 996',
  //   'INDICADO INCLUSAO CONS  PARC  LEI 11941',
  //   'INSCR PARCELADA',
  //   'INSCRICAO DE CREDITO EM DIVIDA ATIVA',
  //   'INSCRITA',
  //   'INTIMACAO',
  //   'Incl  em Parcelam  Esp  Lei 11 941  pend  impediti',
  //   'Incl  em Parcelam  Esp  Lei 11 941  pend  nao impe',
  //   'Inclusao em Parcelamento Especial Lei 11 941',
  //   'LEVANTAMENTO DE DEPOSITO',
  //   'MORATORIA PROSUS',
  //   'NEGOCIADO NO SISPAR',
  //   'OPCAO REFIS EXIGIBILIDADE SUSPENSA',
  //   'OUTROS AJUIZADA',
  //   'OUTROS INSCRITA',
  //   'PARCELAMENTO CANCELADO',
  //   'PARCELAMENTO CONVENCIONAL MANUAL',
  //   'PARCELAMENTO DA LEI 10684 03',
  //   'PARCELAMENTO DA LEI 12 810 2013',
  //   'PARCELAMENTO DE CLUBE DE FUTEBOL',
  //   'PARCELAMENTO DE ORGAO PUBLICO',
  //   'PARCELAMENTO DE PREFEITURA  MUNICIPIO',
  //   'PARCELAMENTO DE PREFEITURA DA MP 1571 97',
  //   'PARCELAMENTO EXTRAJUDICIAL',
  //   'PARCELAMENTO JUDICIAL',
  //   'PARCELAMENTO MANUAL',
  //   'PARCELAMENTO PR-FORMALIZADO',
  //   'PARCELAMENTO RESCINDIDO',
  //   'PARCELAMENTO SEM GARANTIA',
  //   'PARCWEB ? Outros parcelamentos',
  //   'PEDIDO DE ARRESTO',
  //   'PEDIDO DE CARTA PRECATORIA',
  //   'PEDIDO DE CONCORDATA PREVENTIVA',
  //   'PEDIDO DE CONCORDATA SUSPENSIVA',
  //   'PEDIDO DE DECRETACAO DE PRISAO DO DEPOSITARIO INFI',
  //   'PEDIDO DE PENHORA E OU REFORCO DE PENHORA',
  //   'PEDIDO DE RESTITUICAO',
  //   'PEDIDO HABILITACAO OU PAGAMENTO   RESERVA',
  //   'PENHORA REGULAR E SUFICIENTE',
  //   'PERICIA',
  //   'PETICIONADA',
  //   'PRE AJUIZAMENTO   DISTRIBUICAO  ELETRONICO AUTOMAT',
  //   'PRE INSCRICAO DE CREDITO',
  //   'PRE INSCRICAO DE CREDITO DE LDCG DCG',
  //   'PRE PARCELAMENTO',
  //   'PRECATORIO   REQUISITORIO  ORGAOS PUBLICOS',
  //   'PROTESTADA',
  //   'RECEBIDO EM RAZAO DA DECLARACAO DE INCOMPETENCIA D',
  //   'RECEBIMENTO DA RFB APOS ANALISE',
  //   'RECURSO E   OU APELACOES',
  //   'RESCISAO   CANCELAMENTO DE PARCELAMENTO MANUAL',
  //   'RESCISAO DE PARCELAMENTO DE SUCUMBENCIA',
  //   'RESCISAO EXCLUSAO DE CREDITOS DE PARCELAMENTOS ESP',
  //   'RETIFICACAO DE PARCELAMENTO',
  //   'RETIFICACAO DE PARCELAMENTO PARA ALTERACAO DO CALC',
  //   'RETIFICACAO DE PARCELAMENTO SEM CONSOLIDACAO DO PA',
  //   'RETORNO A PROCURADORIA   CANCELAMENTO RESCISAO   F',
  //   'RETORNO A RFB PARA ANALISE',
  //   'RETORNO DA AVOCATORIA',
  //   'RETORNO DA DILIGENCIA',
  //   'REVOGACAO DA PRISAO DO DEPOSITARIO INFIEL',
  //   'SENTENCA',
  //   'SIDAT   BLOQUEADO PARA COBRANCA',
  //   'SUBIDA DOS AUTOS',
  //   'SUSPENSAO DA ACAO ART 40 LEI 6830 80',
  //   'SUSPENSAO DA ACAO PARA RETIFICACAO DO CREDITO',
  //   'SUSPENSAO DE EXIGIBILIDADE COM DEPOSITO',
  //   'SUSPENSAO DE EXIGIBILIDADE SEM DEPOSITO',
  //   'SUSPENSAO E   OU SOBRESTAMENTO DA ACAO',
  //   'TRANSFERIDA',
  // ];

  void _showCompaniesInCluster(List<Company> companies) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Resultado (${companies.length})',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF5C6BC0),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showCompanyDetails(company);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.fantasyName ?? company.corporateName ?? 'Sem nome',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C6BC0),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (company.corporateName != null &&
                          company.corporateName != company.fantasyName)
                        Text(
                          company.corporateName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        company.cnpj ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (company.address != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${company.address!.street ?? ''}, ${company.address!.number ?? ''} - ${company.address!.neighborhood ?? ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (company.debtsValue != null && company.debtsValue! > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Dívidas: R\$ ${company.debtsValue!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCompanyDetails(Company company) {
    bool isLoadingDebt = false;
    Map<String, dynamic>? debtData;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Color(0xFF00897B), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            company.fantasyName ?? company.corporateName ?? 'Sem nome',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.badge, 'CNPJ', company.cnpj ?? 'N/A'),
                    if (company.address != null) ...[
                      _buildDetailRow(
                        Icons.location_on,
                        'Endereço',
                        '${company.address!.street ?? ''}, ${company.address!.number ?? ''} - ${company.address!.neighborhood ?? ''}',
                      ),
                      _buildDetailRow(Icons.mail, 'CEP', company.address!.zipCode ?? 'N/A'),
                    ],
                    if (company.email != null)
                      _buildDetailRow(Icons.email, 'E-mail', company.email!),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Botão para consultar dívidas no Serpro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: isLoadingDebt
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search, color: Colors.white),
                        label: Text(
                          isLoadingDebt ? 'Consultando...' : 'Consultar Dívidas (Serpro)',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onPressed: isLoadingDebt
                            ? null
                            : () async {
                                if (company.cnpj == null) return;

                                setModalState(() {
                                  isLoadingDebt = true;
                                  errorMessage = null;
                                  debtData = null;
                                });

                                try {
                                  final result = await _consultarDividaSerpro(company.cnpj!);
                                  setModalState(() {
                                    debtData = result;
                                    isLoadingDebt = false;
                                  });
                                } catch (e) {
                                  setModalState(() {
                                    errorMessage = e.toString();
                                    isLoadingDebt = false;
                                  });
                                }
                              },
                      ),
                    ),

                    // Resultado da consulta
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (debtData != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: debtData!['temDivida'] == true
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: debtData!['temDivida'] == true
                                ? Colors.red.withOpacity(0.3)
                                : Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  debtData!['temDivida'] == true
                                      ? Icons.warning_amber
                                      : Icons.check_circle,
                                  color: debtData!['temDivida'] == true
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    debtData!['temDivida'] == true
                                        ? 'Empresa possui dívidas'
                                        : 'Nenhuma dívida encontrada',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: debtData!['temDivida'] == true
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (debtData!['valor'] != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Valor total: R\$ ${debtData!['valor']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (debtData!['detalhes'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                debtData!['detalhes'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Fechar',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _consultarDividaSerpro(String cnpj) async {
    // Remove formatação do CNPJ
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');

    try {
      // TODO: Implementar chamada real à API do Serpro
      // Por enquanto, simulando resposta
      await Future.delayed(const Duration(seconds: 2));

      // Simular consulta (substituir por chamada real à API)
      // final response = await http.get(
      //   Uri.parse('https://api.serpro.gov.br/consulta-divida/$cnpjLimpo'),
      //   headers: {
      //     'Authorization': 'Bearer SEU_TOKEN_AQUI',
      //   },
      // );

      // Por enquanto, retorna dados simulados
      return {
        'temDivida': false,
        'valor': null,
        'detalhes': 'Consulta realizada com sucesso. Fonte: Serpro',
      };
    } catch (e) {
      throw 'Erro ao consultar API do Serpro: $e';
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Informação'),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          content: const Text(
            'No mapa, são marcados pontos que indicam a localização aproximada de empresas devedoras. '
            'A visualização na tela está restrita a um máximo de 50.000 devedores.',
          ),
          actions: <Widget>[
            TextButton(
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: colorTertiary,
                padding: const EdgeInsets.symmetric(horizontal: 30),
              ),
              child:
                  const Text('Fechar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

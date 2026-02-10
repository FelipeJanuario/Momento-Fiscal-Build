import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/location/location_compaines_rails.dart';
import 'package:momentofiscal/core/services/geocoding/reverse_geocoding_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';

/// Página de busca por localização usando OpenStreetMap (100% gratuito)
/// Fluxo: GPS -> CEP (via Nominatim) -> Empresas por prefixo CEP
class SearchByLocationOsmPage extends StatefulWidget {
  const SearchByLocationOsmPage({super.key});

  @override
  State<SearchByLocationOsmPage> createState() => _SearchByLocationOsmPageState();
}

class _SearchByLocationOsmPageState extends State<SearchByLocationOsmPage> {
  final MapController _mapController = MapController();
  
  // Estado
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _userCep;
  LatLng? _userPosition;
  int _cepDigits = 2; // FIXO: Busca ampla com 2 dígitos
  
  // Geocodificação em background
  bool _isGeocodingInProgress = false;
  int _geocodedCount = 0;
  int _pendingGeocode = 0;
  
  // Busca de dívidas SERPRO em background
  bool _isLoadingDebts = false;
  int _debtsLoadedCount = 0;
  int _debtsTotalCount = 0;
  
  // Posição inicial (Brasília)
  static const LatLng _initialPosition = LatLng(-15.793938, -47.882813);
  static const double _initialZoom = 12.0;

  @override
  void initState() {
    super.initState();
    print('[OSM] initState chamado');
    _getCurrentUserPosition();
  }

  /// Obtém posição do usuário via GPS e busca CEP via Nominatim
  Future<void> _getCurrentUserPosition() async {
    print('[OSM] _getCurrentUserPosition iniciado');
    setState(() => _isLoading = true);
    
    try {
      // Verifica permissões
      print('[OSM] Verificando permissões...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('[OSM] Permissão: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permissão de localização negada');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showError('Permissão de localização permanentemente negada');
        return;
      }
      
      // Obtém posição
      print('[OSM] Obtendo posição GPS...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('[OSM] Posição: ${position.latitude}, ${position.longitude}');
      
      final userLatLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _userPosition = userLatLng;
      });
      
      // Move mapa para posição do usuário
      _mapController.move(userLatLng, 14.0);
      
      // Obtém CEP via geocodificação reversa (Nominatim - gratuito)
      print('[OSM] Buscando CEP via Nominatim...');
      final cep = await ReverseGeocodingService.getCepFromCoordinates(
        position.latitude,
        position.longitude,
      );
      print('[OSM] CEP retornado: $cep');
      
      if (cep != null) {
        setState(() => _userCep = cep);
        print('[OSM] CEP encontrado: $cep, buscando empresas...');
        
        // Busca empresas por prefixo de CEP
        await _loadCompaniesByCep(cep);
      } else {
        _showError('Não foi possível obter o CEP da sua localização');
      }
      
    } catch (e) {
      print('[OSM] Erro: $e');
      _showError('Erro ao obter localização: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Carrega empresas por prefixo de CEP
  Future<void> _loadCompaniesByCep(String cep) async {
    print('[OSM] _loadCompaniesByCep($cep) iniciado');
    setState(() => _isLoading = true);
    
    try {
      final companies = await LocationCompaniesRails().getInLocationByCep(
        cep: cep,
        digits: _cepDigits,
        page: 1,
        pageSize: 100, // Limite de 100 empresas para performance
      );
      
      setState(() => _companies = companies);
      
      print('[OSM] ${companies.length} empresas encontradas');
      log('[SearchByLocationOsmPage] ${companies.length} empresas encontradas');
      
      if (companies.isEmpty) {
        _showMessage('Nenhuma empresa encontrada na região do CEP ${cep.substring(0, _cepDigits)}xxx');
      } else {
        // Conta quantas empresas precisam de geocodificação
        final semCoordenadas = companies.where((c) => c.latitude == null || c.longitude == null).length;
        final comCoordenadas = companies.length - semCoordenadas;
        
        print('[OSM] $comCoordenadas com coordenadas, $semCoordenadas sem coordenadas');
        log('[SearchByLocationOsmPage] $comCoordenadas com coordenadas, $semCoordenadas sem');
        
        // Se há empresas sem coordenadas, inicia geocodificação em background
        if (semCoordenadas > 0) {
          print('[OSM] Iniciando geocodificação de $semCoordenadas empresas...');
          _geocodeCompaniesInBackground();
        }
        
        // Inicia busca de dívidas SERPRO em background
        _fetchDebtsInBackground();
      }
      
    } catch (e) {
      print('[OSM] Erro ao carregar empresas: $e');
      log('[SearchByLocationOsmPage] Erro ao carregar empresas: $e');
      _showError('Erro ao carregar empresas');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Geocodifica empresas sem coordenadas em background
  /// Respeita limite de 1 requisição/segundo do Nominatim
  /// OTIMIZADO: Processa 3 empresas em paralelo
  Future<void> _geocodeCompaniesInBackground() async {
    print('[OSM] _geocodeCompaniesInBackground chamado');
    if (_isGeocodingInProgress) return;
    
    final companiesWithoutCoords = _companies
        .where((c) => c.latitude == null || c.longitude == null)
        .toList();
    
    print('[OSM] Empresas sem coordenadas: ${companiesWithoutCoords.length}');
    if (companiesWithoutCoords.isEmpty) return;
    
    setState(() {
      _isGeocodingInProgress = true;
      _pendingGeocode = companiesWithoutCoords.length;
      _geocodedCount = 0;
    });
    
    log('[SearchByLocationOsmPage] Iniciando geocodificação de ${companiesWithoutCoords.length} empresas...');
    
    // Processa em lotes de 3 empresas por vez
    const batchSize = 3;
    
    for (int i = 0; i < companiesWithoutCoords.length; i += batchSize) {
      final batch = companiesWithoutCoords.skip(i).take(batchSize).toList();
      
      // Processa o lote em paralelo
      await Future.wait(
        batch.map((company) => _geocodeSingleCompany(company)),
      );
      
      // Aguarda 1.5 segundos entre lotes (3 empresas a cada 1.5s = ~2 empresas/seg)
      if (i + batchSize < companiesWithoutCoords.length) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }
    
    if (mounted) {
      setState(() => _isGeocodingInProgress = false);
      log('[SearchByLocationOsmPage] Geocodificação concluída: $_geocodedCount empresas');
    }
  }

  /// Geocodifica uma única empresa
  Future<void> _geocodeSingleCompany(Company company) async {
    try {
      final coords = await ReverseGeocodingService.geocodeCompanyAddress(
        street: company.address?.street,
        number: company.address?.number,
        neighborhood: company.address?.neighborhood,
        city: company.address?.city,
        state: company.address?.state,
        cep: company.address?.zipCode,
      );
      
      if (coords != null && mounted) {
        // Atualiza a empresa na lista
        final index = _companies.indexWhere((c) => c.id == company.id);
        if (index != -1) {
          setState(() {
            _companies[index].latitude = coords[0];
            _companies[index].longitude = coords[1];
            _geocodedCount++;
          });
          
          // Salva no backend
          _saveCoordinatesToBackend(company.id!, coords[0], coords[1]);
        }
      }
      
    } catch (e) {
      log('[SearchByLocationOsmPage] Erro ao geocodificar ${company.fantasyName}: $e');
    }
  }

  /// Salva coordenadas no backend
  Future<void> _saveCoordinatesToBackend(String companyId, double lat, double lng) async {
    try {
      final url = Uri.http(
        'localhost:3000',
        '/api/v1/debtors/$companyId/coordinates',
      );
      
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': lat,
          'longitude': lng,
        }),
      );
      
      if (response.statusCode == 200) {
        print('[OSM] Coordenadas salvas no backend para empresa $companyId');
      } else {
        print('[OSM] Erro ao salvar coordenadas: ${response.statusCode}');
      }
    } catch (e) {
      print('[OSM] Erro ao salvar coordenadas no backend: $e');
    }
  }

  /// Busca dívidas SERPRO para todas as empresas em background
  /// Usa endpoint batch para eficiência
  Future<void> _fetchDebtsInBackground() async {
    if (_companies.isEmpty || _isLoadingDebts) return;
    
    print('[OSM] Iniciando busca de dívidas SERPRO para ${_companies.length} empresas...');
    
    setState(() {
      _isLoadingDebts = true;
      _debtsTotalCount = _companies.length;
      _debtsLoadedCount = 0;
    });
    
    try {
      // Extrai CNPJs das empresas
      final cnpjs = _companies
          .where((c) => c.cnpj != null && c.cnpj!.isNotEmpty)
          .map((c) => c.cnpj!)
          .toList();
      
      if (cnpjs.isEmpty) {
        print('[OSM] Nenhum CNPJ para buscar dívidas');
        return;
      }
      
      // Busca em batch (máximo 50 por vez)
      final service = LocationCompaniesRails();
      Map<String, DebtInfo> allResults = {};
      
      // Processa em lotes de 50
      for (int i = 0; i < cnpjs.length; i += 50) {
        final batch = cnpjs.skip(i).take(50).toList();
        final results = await service.fetchBatchDebts(batch);
        allResults.addAll(results);
        
        if (mounted) {
          setState(() {
            _debtsLoadedCount = allResults.length;
          });
        }
      }
      
      print('[OSM] Dívidas recebidas: ${allResults.length} resultados');
      
      // Atualiza empresas com os valores de dívida
      if (mounted && allResults.isNotEmpty) {
        setState(() {
          for (int i = 0; i < _companies.length; i++) {
            final cnpj = _companies[i].cnpj;
            if (cnpj != null) {
              // Normaliza CNPJ para 14 dígitos
              final cnpjNormalized = cnpj.replaceAll(RegExp(r'\D'), '').padLeft(14, '0');
              final debtInfo = allResults[cnpjNormalized];
              if (debtInfo != null) {
                _companies[i].debtsValue = debtInfo.debtValue;
                _companies[i].debtsCount = debtInfo.debtCount;
              }
            }
          }
        });
        
        // Conta empresas com dívidas
        final comDividas = _companies.where((c) => (c.debtsValue ?? 0) > 0).length;
        print('[OSM] $comDividas empresas com dívidas encontradas');
        log('[SearchByLocationOsmPage] $comDividas empresas com dívidas');
      }
      
    } catch (e) {
      print('[OSM] Erro ao buscar dívidas: $e');
      log('[SearchByLocationOsmPage] Erro ao buscar dívidas: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDebts = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Mostra detalhes de uma empresa em um bottom sheet
  /// Busca dados completos via API incluindo dívidas SERPRO
  void _showCompanyDetails(Company company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CompanyDetailsSheet(company: company),
    );
  }

  /// Mostra dialog de configuração de dígitos do CEP
  void _showCepDigitsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raio de busca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quantidade de dígitos do CEP para busca:'),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2 (amplo)')),
                ButtonSegment(value: 3, label: Text('3 (médio)')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 5, label: Text('5 (próximo)')),
              ],
              selected: {_cepDigits},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() => _cepDigits = newSelection.first);
                Navigator.pop(context);
                if (_userCep != null) {
                  _loadCompaniesByCep(_userCep!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra info sobre o sistema
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Busca por CEP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userCep != null) ...[
              Text('Seu CEP: ${_userCep!.substring(0, 5)}-${_userCep!.substring(5)}'),
              const SizedBox(height: 8),
            ],
            Text('Prefixo de busca: ${_userCep?.substring(0, _cepDigits) ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Empresas encontradas: ${_companies.length}'),
            const SizedBox(height: 16),
            const Text(
              'CEPs brasileiros são geográficos: mesmos dígitos iniciais = mesma região.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Constrói marcadores das empresas com coordenadas
  /// Cor baseada no valor de dívidas:
  /// - Verde: sem dívidas
  /// - Amarelo: dívidas até R$10k
  /// - Laranja: dívidas até R$100k
  /// - Vermelho: dívidas acima de R$100k
  List<Marker> _buildCompanyMarkers() {
    final markers = <Marker>[];
    
    for (final company in _companies) {
      // Só adiciona marcador se a empresa tiver coordenadas
      if (company.latitude != null && company.longitude != null) {
        final debtValue = company.debtsValue ?? 0;
        final markerColor = _getMarkerColor(debtValue);
        final hasDebt = debtValue > 0;
        
        markers.add(
          Marker(
            point: LatLng(company.latitude!, company.longitude!),
            width: hasDebt ? 50 : 40,
            height: hasDebt ? 50 : 40,
            child: GestureDetector(
              onTap: () => _showCompanyDetails(company),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: hasDebt ? 50 : 40,
                    height: hasDebt ? 50 : 40,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      hasDebt ? Icons.warning_rounded : Icons.business,
                      color: Colors.white,
                      size: hasDebt ? 24 : 20,
                    ),
                  ),
                  // Badge com valor da dívida
                  if (hasDebt)
                    Positioned(
                      bottom: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            _formatValueShort(debtValue),
                            style: TextStyle(
                              color: markerColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    
    log('[SearchByLocationOsmPage] ${markers.length} empresas com coordenadas para mostrar no mapa');
    return markers;
  }

  /// Retorna cor do marcador baseado no valor de dívida
  Color _getMarkerColor(double debtValue) {
    if (debtValue <= 0) return Colors.green;
    if (debtValue < 10000) return Colors.amber;
    if (debtValue < 100000) return Colors.orange;
    return Colors.red;
  }
  
  /// Formata valor para exibição curta no marcador
  String _formatValueShort(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Busca por Localização',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            if (_userCep != null)
              Text(
                'CEP: ${_userCep!.substring(0, _cepDigits)}... (${_companies.length} empresas)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
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
            icon: const Icon(Icons.tune),
            onPressed: _showCepDigitsDialog,
            tooltip: 'Ajustar raio',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showInfoDialog,
            tooltip: 'Informação',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa OpenStreetMap (100% gratuito)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: _initialZoom,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              // Tiles do OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.gov.df.momentofiscal',
              ),
              
              // Marcador da posição do usuário
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              
              // Marcadores das empresas com clustering
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(50, 50),
                  markers: _buildCompanyMarkers(),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: colorPrimaty,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Buscando empresas...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Indicador de geocodificação em background
          if (_isGeocodingInProgress)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Geocodificando: $_geocodedCount / $_pendingGeocode empresas',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Indicador de busca de dívidas SERPRO em background
          if (_isLoadingDebts)
            Positioned(
              top: _isGeocodingInProgress ? 56 : 8,
              left: 8,
              right: 8,
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Buscando dívidas SERPRO: $_debtsLoadedCount / $_debtsTotalCount',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Botão de GPS
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'gps',
              onPressed: _getCurrentUserPosition,
              backgroundColor: Colors.white,
              child: const Icon(Icons.gps_fixed, color: Colors.black87),
            ),
          ),
          
          // Lista de empresas (bottom sheet)
          if (_companies.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.1,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_companies.length} empresas na região',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_userCep != null)
                              Chip(
                                label: Text('CEP: ${_userCep!.substring(0, _cepDigits)}...'),
                                backgroundColor: colorPrimaty.withOpacity(0.1),
                              ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Lista
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          itemCount: _companies.length,
                          itemBuilder: (context, index) {
                            final company = _companies[index];
                            final hasCoords = company.latitude != null && company.longitude != null;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasCoords ? colorPrimaty : Colors.grey,
                                  child: Icon(
                                    hasCoords ? Icons.location_on : Icons.location_off,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  company.fantasyName ?? company.corporateName ?? company.name ?? 'Sem nome',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (company.cnpj != null)
                                      Text(
                                        'CNPJ: ${company.cnpj}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    if (company.address?.city != null)
                                      Text(
                                        '${company.address!.city} - ${company.address!.state ?? ''}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Mostra dívida ou indicador de "sem dívida"
                                    if (company.debtsValue != null && company.debtsValue! > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getMarkerColor(company.debtsValue!).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _getMarkerColor(company.debtsValue!),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.warning_rounded,
                                              color: _getMarkerColor(company.debtsValue!),
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'R\$ ${_formatValue(company.debtsValue!)}',
                                              style: TextStyle(
                                                color: _getMarkerColor(company.debtsValue!),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (company.debtsCount != null)
                                      // Empresa verificada, sem dívidas
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 12,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Regular',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => _showCompanyDetails(company),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }
}

/// Widget Stateful para sheet de detalhes da empresa
/// Busca dados completos da API incluindo dívidas SERPRO
class _CompanyDetailsSheet extends StatefulWidget {
  final Company company;
  
  const _CompanyDetailsSheet({required this.company});

  @override
  State<_CompanyDetailsSheet> createState() => _CompanyDetailsSheetState();
}

class _CompanyDetailsSheetState extends State<_CompanyDetailsSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _details;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await LocationCompaniesRails().getCompanyDetails(
        widget.company.id.toString(),
      );
      
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar detalhes: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'R\$ 0,00';
    
    double numValue;
    if (value is String) {
      numValue = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    } else if (value is num) {
      numValue = value.toDouble();
    } else {
      return 'R\$ 0,00';
    }
    
    if (numValue >= 1000000) {
      return 'R\$ ${(numValue / 1000000).toStringAsFixed(2)}M';
    } else if (numValue >= 1000) {
      return 'R\$ ${(numValue / 1000).toStringAsFixed(2)}K';
    }
    return 'R\$ ${numValue.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        if (_isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Consultando dados e dívidas...'),
              ],
            ),
          );
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          );
        }

        final empresa = _details?['empresa'] as Map<String, dynamic>? ?? {};
        final dividas = _details?['dividas'] as List<dynamic>? ?? [];
        final totalDividas = _details?['total_dividas'] as num? ?? 0;
        final fonteDados = _details?['fonte_dados'] as String? ?? '';
        final dataConsulta = _details?['data_consulta'] as String? ?? '';

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Nome da empresa
              Text(
                widget.company.fantasyName ?? widget.company.corporateName ?? 'N/A',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // CNPJ
              if (widget.company.cnpj != null)
                Text(
                  'CNPJ: ${widget.company.cnpj}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 12),

              // Dados da empresa (capital social, porte, etc)
              if (empresa.isNotEmpty) ...[
                _buildInfoCard(
                  'Informações da Empresa',
                  [
                    if (empresa['capital_social'] != null)
                      _buildInfoRow('Capital Social', _formatCurrency(empresa['capital_social'])),
                    if (empresa['porte_empresa'] != null)
                      _buildInfoRow('Porte', empresa['porte_empresa'].toString()),
                    if (empresa['natureza_juridica'] != null)
                      _buildInfoRow('Natureza Jurídica', empresa['natureza_juridica'].toString()),
                    if (empresa['situacao_cadastral'] != null)
                      _buildInfoRow('Situação', empresa['situacao_cadastral'].toString()),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Endereço
              if (widget.company.address != null) ...[
                _buildInfoCard(
                  'Endereço',
                  [
                    Text(
                      '${widget.company.address?.street ?? ''}, ${widget.company.address?.number ?? 'S/N'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${widget.company.address?.neighborhood ?? ''} - ${widget.company.address?.city ?? ''}/${widget.company.address?.state ?? ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'CEP: ${widget.company.address?.zipCode ?? ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Total de dívidas
              if (totalDividas > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'DÍVIDA ATIVA TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(totalDividas),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      if (fonteDados.isNotEmpty || dataConsulta.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${fonteDados.isNotEmpty ? 'Fonte: $fonteDados' : ''} ${dataConsulta.isNotEmpty ? '• Consulta: $dataConsulta' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Lista de dívidas detalhadas
              if (dividas.isNotEmpty) ...[
                const Text(
                  'Detalhamento das Dívidas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...dividas.map((divida) => _buildDividaCard(divida as Map<String, dynamic>)),
              ],

              // Mensagem se não houver dívidas
              if (dividas.isEmpty && totalDividas == 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Nenhuma dívida ativa encontrada',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botão fechar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimaty,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividaCard(Map<String, dynamic> divida) {
    final valor = divida['valor'] ?? divida['valor_consolidado'] ?? 0;
    final inscricao = divida['inscricao'] ?? divida['numero_inscricao'] ?? '';
    final orgao = divida['orgao_origem'] ?? divida['orgao'] ?? '';
    final natureza = divida['natureza_divida'] ?? divida['natureza'] ?? '';
    final dataInscricao = divida['data_inscricao'] ?? '';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Inscrição: $inscricao',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatCurrency(valor),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (orgao.isNotEmpty)
            Text(
              'Órgão: $orgao',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          if (natureza.isNotEmpty)
            Text(
              'Natureza: $natureza',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          if (dataInscricao.isNotEmpty)
            Text(
              'Data: $dataInscricao',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

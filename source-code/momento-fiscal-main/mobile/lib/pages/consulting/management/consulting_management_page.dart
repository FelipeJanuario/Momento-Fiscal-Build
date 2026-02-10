import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/consulting_management_card.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/pages/location/authorized_location_page.dart';
import 'package:momentofiscal/pages/location/search_by_location_osm_page.dart';

class ConsultingManagementPage extends StatefulWidget {
  final bool isConsultant;
  const ConsultingManagementPage({super.key, required this.isConsultant});

  @override
  State<ConsultingManagementPage> createState() =>
      _ConsultingManagementPageState();
}

class _ConsultingManagementPageState extends State<ConsultingManagementPage> {
  TextEditingController searchCodController = TextEditingController();
  TextEditingController searchClientController = TextEditingController();
  TextEditingController searchCreatedAtController = TextEditingController();
  TextEditingController searchUpdateAtController = TextEditingController();
  TextEditingController searchLimitDebtController = TextEditingController();
  LocationPermission? permission;

  List<Consulting> consultings = [];
  int currentPage = 1;
  bool isLoading = false;
  bool isMoreLoading = false;
  Timer? _debounce;
  String? _selectedStatus;
  final ScrollController _scrollController = ScrollController();
  String? role;
  List<bool> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadConsultings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchCodController.dispose();
    searchClientController.dispose();
    searchCreatedAtController.dispose();
    searchUpdateAtController.dispose();
    searchLimitDebtController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> checkLocationPermission() async {
    final LocationPermission permissionResult =
        await Geolocator.checkPermission();
    setState(() {
      permission = permissionResult;
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 250 && !isMoreLoading) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _loadConsultings(loadMore: true);
      });
    }
  }

  void _loadConsultings({bool loadMore = false}) async {
    String? id = await storage.read(key: 'id');
    role = await storage.read(key: 'role');

    checkLocationPermission();

    if (loadMore) {
      setState(() {
        isMoreLoading = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    final Map<String, dynamic> filters = {
      'query[consultant_id]': widget.isConsultant == true ? id : '',
      'query[id]': searchCodController.text,
      'query[client.name]': searchClientController.text,
      'query[created_at]': searchCreatedAtController.text.isNotEmpty
          ? DateFormat("yyyy-MM-dd").format(
              DateFormat("dd/MM/yyyy").parse(searchCreatedAtController.text))
          : '',
      'query[sent_at]': searchUpdateAtController.text.isNotEmpty
          ? DateFormat("yyyy-MM-dd").format(
              DateFormat("dd/MM/yyyy").parse(searchUpdateAtController.text))
          : '',
      'query[status]': _selectedStatus ?? '',
      'query[value]': searchLimitDebtController.text.isNotEmpty
          ? _removeCurrencyMask(searchLimitDebtController.text)
          : '',
    };

    filters.removeWhere((key, value) => value.isEmpty);

    ConsultingRailsService()
        .getConsultings(
      page: currentPage,
      queryParameters: filters,
    )
        .then((newConsultings) {
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          consultings.addAll(newConsultings);
          favorites
              .addAll(List.generate(newConsultings.length, (index) => false));
          isMoreLoading = false;
        } else {
          consultings = newConsultings;
          favorites = List.generate(consultings.length, (index) => false);
          isLoading = false;
        }
        currentPage++;
      });
      _reorganizeFavorites();
    }).catchError((error, stackTrace) {
      if (!mounted) return; // Verifique se o widget ainda está montado
      setState(() {
        isLoading = false;
        isMoreLoading = false;
      });
      log('Error loading consultings: $error',
          error: error, stackTrace: stackTrace);
      throw Exception(error);
    });
  }

  void _reorganizeFavorites() async {
    final List<Consulting> favoriteConsultings = [];
    final List<Consulting> nonFavoriteConsultings = [];

    for (int i = 0; i < consultings.length; i++) {
      if (favorites[i]) {
        favoriteConsultings.add(consultings[i]);
      } else {
        nonFavoriteConsultings.add(consultings[i]);
      }
    }

    consultings = [...favoriteConsultings, ...nonFavoriteConsultings];
    favorites = [
      ...favorites.where((fav) => fav),
      ...favorites.where((fav) => !fav)
    ];
  }

  String _removeCurrencyMask(String value) {
    return value.replaceAll('.', '').replaceAll(',', '.');
  }

  void _onFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      currentPage = 1;
      _loadConsultings();
    });
  }

  void _showAdvancedSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtro de pesquisa'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: searchCodController,
                  decoration: const InputDecoration(
                    labelText: 'Código da Consultoria',
                  ),
                  onChanged: (value) => _onFilterChanged(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: searchClientController,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  onChanged: (value) => _onFilterChanged(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: searchCreatedAtController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Criação',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  inputFormatters: [formatterDate],
                  onChanged: (value) => _onFilterChanged(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: searchUpdateAtController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Envio',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  inputFormatters: [formatterDate],
                  onChanged: (value) => _onFilterChanged(),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: dropdownItemsStatus,
                  decoration: const InputDecoration(
                    label: Text('Status'),
                    hintText: 'Selecione o status',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    _onFilterChanged();
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: searchLimitDebtController,
                  decoration: const InputDecoration(
                    labelText: 'Valor da dívida?',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  onChanged: (value) => _onFilterChanged(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFields();
              },
              child: const Text('Limpar Campos'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Pesquisar'),
            ),
          ],
        );
      },
    );
  }

  void _clearFields() {
    searchCodController.clear();
    searchClientController.clear();
    searchCreatedAtController.clear();
    searchUpdateAtController.clear();
    searchLimitDebtController.clear();
    setState(() {
      _selectedStatus = null;
      currentPage = 1;
      _loadConsultings();
    });
  }

  final List<DropdownMenuItem<String>> dropdownItemsStatus = [
    const DropdownMenuItem(value: null, child: Text('Todas')),
    const DropdownMenuItem(value: 'not_started', child: Text('Não iniciadas')),
    const DropdownMenuItem(value: 'waiting', child: Text('Aguardando Proposta')),
    const DropdownMenuItem(value: 'approved', child: Text('Aprovadas')),
    const DropdownMenuItem(value: 'in_progress', child: Text('Em Progresso')),
    const DropdownMenuItem(value: 'finished', child: Text('Finalizadas')),
    const DropdownMenuItem(value: 'failed', child: Text('Reprovadas')),
    const DropdownMenuItem(
        value: 'waiting_for_user_creation',
        child: Text('Aguardando Cliente Vincular')),
  ];

  void _toggleFavorite(int index) async {
    Consulting consulting = consultings[index];

    setState(() {
      consulting.isFavorite = !consulting.isFavorite;
    });

    try {
      await ConsultingRailsService().patchConsulting(
        consultingId: consulting.id!,
        updatedFields: {"is_favorite": consulting.isFavorite},
      );

      _reorganizeFavorites();
    } catch (error) {
      setState(() {
        consulting.isFavorite = !consulting.isFavorite;
      });
      log('Error updating favorite status: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Consultoria'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 15),
              Center(
                child: SizedBox(
                  height: 100,
                  child: Image.asset('assets/images/momentofiscalcolorido.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: colorTertiary,
                ),
                onPressed: _showAdvancedSearchDialog,
                child: const Text(
                  'Pesquisa Avançada',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Empresas para consultoria',
                style: labelStyle,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          permission == LocationPermission.whileInUse
                              ? const SearchByLocationOsmPage()
                              : const AuthorizedLocation(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    Text('Criar Proposta'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: consultings.length + 1,
                        itemBuilder: (context, index) {
                          if (index == consultings.length) {
                            return isMoreLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : const SizedBox.shrink();
                          }
                          return ConsultingManagementCard(
                            consultingManagement: consultings[index],
                            userRole: role ?? '',
                            onFavoriteToggle: () => _toggleFavorite(index),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

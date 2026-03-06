import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/consulting_card.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/models/institution.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/debt/debt_rails_service.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';
import 'package:momentofiscal/core/services/institution/institution_rails_service.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/pages/proposal/create_proposal_client_page.dart';
import 'package:momentofiscal/pages/proposal/import_hash_client_page.dart';
import 'package:momentofiscal/pages/proposal/view_proposal_client_page.dart';

class MyProposalClientPage extends StatefulWidget {
  const MyProposalClientPage({super.key});

  @override
  State<MyProposalClientPage> createState() => _MyProposalClientPageState();
}

class _MyProposalClientPageState extends State<MyProposalClientPage> {
  TextEditingController searchCodController = TextEditingController();
  TextEditingController searchClientController = TextEditingController();
  TextEditingController searchCreatedAtController = TextEditingController();
  TextEditingController searchUpdateAtController = TextEditingController();
  TextEditingController searchLimitDebtController = TextEditingController();
  String? _selectedStatus;

  List<Consulting> consultings = [];
  bool isLoading = false;
  bool isMoreLoading = false;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  int currentPage = 1;
  String? id;
  String? role;
  List<Institution> institutions = [];
  List<Debt>? debts = [];

  @override
  void initState() {
    super.initState();
    loadConsultingUser();
    verifyInstitutionUser();
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

  void _onScroll() {
    if (_scrollController.position.extentAfter < 250 &&
        !isMoreLoading &&
        hasMoreData) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        loadConsultingUser(loadMore: true);
      });
    }
  }

  void loadConsultingUser({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        isMoreLoading = true;
      });
    } else {
      setState(() {
        isLoading = true;
        currentPage = 1;
      });
    }

    String? id = await storage.read(key: "id");

    // Montando os parâmetros de filtro
    final Map<String, dynamic> filters = {
      'query[client_id]': id,
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

    // Remover entradas vazias ou nulas
    filters.removeWhere((key, value) => value.isEmpty);

    try {
      final responseConsultings = await ConsultingRailsService().getConsultings(
        page: currentPage,
        queryParameters: filters,
      );

      if (responseConsultings.isEmpty) {
        setState(() {
          hasMoreData = false;
        });
      } else {
        setState(() {
          if (loadMore) {
            consultings.addAll(responseConsultings);
          } else {
            consultings = responseConsultings;
          }
          currentPage++;
        });
      }
    } catch (e) {
      Exception("Error consulting client $e");
    } finally {
      setState(() {
        isLoading = false;
        isMoreLoading = false;
      });
    }
  }

  Future verifyInstitutionUser({String cnpj = ''}) async {
    String? cpf = await storage.read(key: 'cpf');
    id = await storage.read(key: "id");
    role = await storage.read(key: 'role');
    try {
      final newInstitutions = await InstitutionRailsService()
          .getAllInstitution(responsibleCpf: cpf!, cnpj: cnpj);
      setState(() {
        institutions = newInstitutions;
      });
    } catch (e) {
      Exception("Erro load in request Institution $e");
    }
  }

  Future<void> _fetchDebts({required String cnpj}) async {
    final fetchedDebts = await DebtsRails().getDebts(cnpj);
    setState(() {
      debts = fetchedDebts;
    });
  }

  void _onFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      currentPage = 1;
      loadConsultingUser();
    });
  }

  double _calculateTotalDebt(List<Debt>? debts) {
    if (debts == null || debts.isEmpty) return 0.0;
    return debts.fold(0.0, (sum, debt) {
      final value = double.tryParse(debt.value.toString()) ?? 0.0;
      return sum + value;
    });
  }

  String _removeCurrencyMask(String value) {
    return value.replaceAll('.', '').replaceAll(',', '.');
  }

  void _clearFields() {
    setState(() {
      searchCodController.clear();
      searchClientController.clear();
      searchCreatedAtController.clear();
      searchUpdateAtController.clear();
      searchLimitDebtController.clear();
      _selectedStatus = null;
    });
    _onFilterChanged();
  }

  final List<DropdownMenuItem<String>> dropdownItemsStatus = [
    const DropdownMenuItem(value: null, child: Text('Todos')),
    const DropdownMenuItem(value: 'not_started', child: Text('Não iniciada')),
    const DropdownMenuItem(value: 'waiting', child: Text('Aguardando')),
    const DropdownMenuItem(value: 'approved', child: Text('Aprovado')),
    const DropdownMenuItem(value: 'in_progress', child: Text('Em Progresso')),
    const DropdownMenuItem(value: 'finished', child: Text('Finalizado')),
    const DropdownMenuItem(value: 'failed', child: Text('Reprovada')),
    const DropdownMenuItem(
        value: 'waiting_for_user_creation',
        child: Text('Aguardando Cliente Vincular')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Propostas',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: Image.asset('assets/images/momentofiscalcolorido.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Pesquisa Avançada'),
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
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: searchClientController,
                                decoration: const InputDecoration(
                                  labelText: 'Cliente',
                                ),
                                onChanged: (value) => _onFilterChanged(),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: searchCreatedAtController,
                                decoration: const InputDecoration(
                                  labelText: 'Data de Criação',
                                ),
                                onChanged: (value) => _onFilterChanged(),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: searchUpdateAtController,
                                decoration: const InputDecoration(
                                  labelText: 'Data de Envio',
                                ),
                                onChanged: (value) => _onFilterChanged(),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                items: dropdownItemsStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                ),
                                iconSize: 20, // Ajuste o tamanho do ícone
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  _onFilterChanged();
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: searchLimitDebtController,
                                decoration: const InputDecoration(
                                  labelText: 'Limite de Endividamento',
                                ),
                                onChanged: (value) => _onFilterChanged(),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _clearFields();
                              Navigator.of(context).pop();
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
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      const Color.fromARGB(255, 4, 74, 132), // Cor do texto
                ),
                child: const Text('Pesquisa Avançada'),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () async {
                      return showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: const Center(
                                    child: Text("Minhas Empresas")),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 300,
                                  child: institutions.isNotEmpty
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: institutions.length,
                                          itemBuilder: (context, index) {
                                            final institution =
                                                institutions[index];
                                            return Column(
                                              children: [
                                                if (institutions != []) ...[
                                                  Hero(
                                                    tag:
                                                        "institution${institution.id}",
                                                    child: Card.outlined(
                                                      child: ListTile(
                                                        onTap: () async {
                                                          await _fetchDebts(
                                                              cnpj: formatNumberInCnpj(
                                                                  institution
                                                                      .cnpj));

                                                          // ignore: use_build_context_synchronously
                                                          Navigator.of(context)
                                                              .pop();

                                                          final totalDebt =
                                                              _calculateTotalDebt(
                                                                  debts);

                                                          // ignore: use_build_context_synchronously
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  CreateProposalClientPage(
                                                                      idUser:
                                                                          id!,
                                                                      debtValue:
                                                                          totalDebt),
                                                            ),
                                                          );
                                                        },
                                                        leading: Container(
                                                          width: 50,
                                                          height: 50,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: const Icon(
                                                            Icons.business,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        title: Text(
                                                          formatNumberInCnpj(
                                                              institution.cnpj),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            );
                                          },
                                        )
                                      : const Center(
                                          child: Text(
                                              'Nenhuma instituição cadastrada'),
                                        ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add),
                        Text('Solicitar Proposta'),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: () async {
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ImportHashClientPage(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.post_add_rounded),
                          Text('Desbloquear'),
                        ],
                      ))
                ],
              ),
              SizedBox(
                height: 450,
                child: isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator()) // Indicador de carregamento inicial
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: consultings.length +
                            (hasMoreData ? 1 : 0), // Adicionar 1 para o loader
                        itemBuilder: (context, index) {
                          if (index == consultings.length) {
                            // Loader no final da lista
                            return isMoreLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : const SizedBox.shrink();
                          }
                          return ConsultingCard(
                              trailing: PopupMenuButton<String>(
                                onSelected: (String value) {
                                  switch (value) {
                                    case 'Visualizar Proposta':
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ViewProposalClientPage(
                                                  consulting:
                                                      consultings[index]),
                                        ),
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return {
                                    'Visualizar Proposta',
                                  }.map((String choice) {
                                    return PopupMenuItem<String>(
                                      value: choice,
                                      child: Text(choice),
                                    );
                                  }).toList();
                                },
                                icon: const Icon(Icons.more_vert),
                              ),
                              consultingManagement: consultings[index]);
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

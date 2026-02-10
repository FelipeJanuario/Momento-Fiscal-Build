import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:momentofiscal/components/api_cnpj_card.dart';
import 'package:momentofiscal/components/debt_cpf_card.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/api_cnpj.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/models/institution.dart';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/models/serpro.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/debt/debt_rails_service.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/location/location_compaines_rails.dart';
import 'package:momentofiscal/core/services/brasilApi/brasil_api_service.dart';
import 'package:momentofiscal/core/services/institution/institution_rails_service.dart';
import 'package:momentofiscal/core/services/processDataCrawlers/fetch_tj_data.dart';
import 'package:momentofiscal/core/services/processDataCrawlers/process_jusbrasil_service.dart';
import 'package:momentofiscal/core/services/serpro/serpro_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:momentofiscal/pages/search/debtors_nearby.dart';

class CnpjCpfPage extends StatefulWidget {
  final String? cnpjCpf;

  const CnpjCpfPage({this.cnpjCpf, super.key});

  @override
  State<CnpjCpfPage> createState() => _CnpjCpfPageState();
}

class _CnpjCpfPageState extends State<CnpjCpfPage> {
  final _formKey = GlobalKey<FormState>();
  List<Debt>? debts = [];
  int totalDebtsCount = 0;
  double totalDebtsValue = 0.0;
  List<Serpro>? serproList = [];
  List<Jusbrasil> jusbrasilList = [];
  List<Institution> institutions = [];
  final TextEditingController cnpjController = TextEditingController();
  ApiCnpj? apiCnpj;
  Company? company;
  bool isLoading = false;
  bool isCpf = false;
  late MaskedInputFormatter _cpfCnpjFormatter;
  StreamSubscription<List<Jusbrasil>>? _streamSubscription;

  String? id;
  String? role;
  bool isInstitution = false;

  @override
  void initState() {
    super.initState();

    verificycnpjCpfIsEmpty();
    verifyInstitutionUser();
    cnpjController.text = widget.cnpjCpf ?? "";
    _updateFormatter();
  }

  @override
  void dispose() {
    cnpjController.dispose();
    // _streamSubscription!.cancel();
    super.dispose();
  }

  void _updateFormatter() {
    if (cnpjController.text.isEmpty) {
      _cpfCnpjFormatter = MaskedInputFormatter('####################');
    } else if (cnpjController.text.length <= 13) {
      _cpfCnpjFormatter = MaskedInputFormatter('000.000.000-00');
    } else {
      _cpfCnpjFormatter = MaskedInputFormatter('00.000.000/0000-00');
    }
  }

  Future verificycnpjCpfIsEmpty() async {
    setState(() {
      cnpjController.text = widget.cnpjCpf ?? "";
    });

    if (cnpjController.text.isNotEmpty) {
      setState(() {
        _fetchData();
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
        isInstitution = newInstitutions.isNotEmpty;
      });
    } catch (e) {
      Exception("Erro load in request Institution $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      debts = [];
      apiCnpj = null;
    });

    final textLength = cnpjController.text.length;

    setState(() {
      isCpf = textLength == 14;
    });
    try {
      if (isCpf) {
        await _findoutPersonName();

        // if (serproList == null) {
        //   return _showError("Pessoa Física não possui débito");
        // }

        await _fetchDebts();
      } else {
        await Future.wait([_fetchCompany(), _fetchCnpjData(), _fetchDebts()]);
      }

      await verifyInstitutionUser(cnpj: removeMask(cnpjController.text));
    } catch (e) {
      _showError(
        'O serviço do Jusbrasil está temporariamente indisponível. Por favor, tente novamente em alguns minutos.'
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _findoutPersonName() async {
    serproList = await SerproService()
        .getCpfSerpro(cpf: removeMask(cnpjController.text));

    Stream<List<Jusbrasil>> stream =
        ProcessJusbrasil().getProcessesCpfCnpjStream(
      cpfCnpj: cnpjController.text,
    );

    if (!mounted) {
      return;
    }

    _streamSubscription = stream.listen((fetchedJusbrasilList) {
      setState(() {
        jusbrasilList = fetchedJusbrasilList;
      });
    });
  }

  Future<void> _fetchDebts() async {
    final result = await DebtsRails().getDebtsWithTotals(cnpjController.text);

    setState(() {
      debts = result['debts'] as List<Debt>?;
      totalDebtsCount = result['total_count'] as int;
      totalDebtsValue = result['total_value'] as double;
    });
  }

  Future<void> _fetchCnpjData() async {
    final responseApi =
        await BrasilApiService().getCnpj(formatCnpj(cnpjController.text));
    final responseBody = json.decode(responseApi.body);

    if (responseApi.statusCode == 400) {
      _handleCnpjError(responseBody['message']);
    } else if (responseApi.statusCode == 200) {
      _handleCnpjSuccess(responseBody);
    }
  }

  Future<void> _fetchCompany() async {
    final response = await LocationCompaniesRails().getCompanyByCnpj(
      cnpjController.text,
    );

    if (response.isEmpty) {
      return;
    }

    setState(() {
      company = response.first;
    });
  }

  void _handleCnpjError(String message) {
    setState(() {
      apiCnpj = null;
      debts = [];
    });
    _showError(message);
  }

  void _handleCnpjSuccess(dynamic responseBody) {
    final fetchedDebts = debts;
    setState(() {
      try {
        apiCnpj = ApiCnpj.fromJson(responseBody);
        debts = fetchedDebts;
      } catch (e) {
        Exception('Erro ao processar o JSON: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca por CNPJ e CPF'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            _streamSubscription?.cancel();
            jusbrasilList.clear();

            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(
                builder: (context) => const DashboadPage(),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 100,
                    child: Image.asset(
                        'assets/images/momentofiscalcolorido.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  _buildSearchCard(),
                  const SizedBox(height: 10),
                  if (apiCnpj != null || (isCpf && debts!.isNotEmpty))
                    const Text('Informações do CPF/CNPJ', style: textTitle),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!isLoading) _buildInfoSection(),
                ],
              ),
            ),
          ),
          if (!isLoading && !(apiCnpj != null || (isCpf && debts!.isNotEmpty)))
            const DebtorsNearby(),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card.outlined(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Busca por CPF/CNPJ', style: textTitle),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    key: const ValueKey('cpfCnpj'),
                    controller: cnpjController,
                    onChanged: (cpfCnpj) {
                      setState(() {
                        if (cpfCnpj.isEmpty) {
                          _cpfCnpjFormatter =
                              MaskedInputFormatter('####################');
                        } else if (cpfCnpj.length <= 13) {
                          _cpfCnpjFormatter =
                              MaskedInputFormatter('000.000.000-00');
                        } else {
                          _cpfCnpjFormatter =
                              MaskedInputFormatter('00.000.000/0000-00');
                        }
                      });
                    },
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: true),
                    decoration: const InputDecoration(
                      label: Text('CPF ou CNPJ'),
                      hintText: 'Digite seu CPF ou CNPJ',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    inputFormatters: [_cpfCnpjFormatter],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu CPF ou CNPJ';
                      } else if (value.length == 14) {
                        return validatorCpf(value);
                      } else if (value.length == 18) {
                        return validatorCnpj(value);
                      } else {
                        return 'CPF/CNPJ inválido';
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (institutions.isNotEmpty)
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
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: institutions.length,
                                    itemBuilder: (context, index) {
                                      final institution = institutions[index];
                                      return Column(
                                        children: [
                                          Hero(
                                            tag: "institution${institution.id}",
                                            child: Card.outlined(
                                              child: ListTile(
                                                onTap: () {
                                                  Navigator.of(context).pop();
                                                  cnpjController.text =
                                                      formatNumberInCnpj(
                                                          institution.cnpj);
                                                },
                                                leading: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text('Buscar meu CNPJ'),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Theme.of(context).primaryColor,
                    fixedSize: const Size.fromWidth(500),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState?.validate() ?? false) {
                      _fetchData();
                      FetchTjPjeData().call();
                    }
                    // _streamSubscription!.cancel();
                    jusbrasilList.clear();
                  },
                  child: const Text('Buscar',
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    if (apiCnpj != null && !isCpf) {
      return Column(
        children: [
          ApiCnpjCard(
            company: company ?? Company(),
            apiCnpj: apiCnpj!,
            idUser: id!,
            role: role,
            debts: debts,
            totalDebtValue: totalDebtsValue,
            isInstitution: isInstitution,
            isConsultant:
                role == "consultant" || role == "admin" ? true : false,
          ),
        ],
      );
    } else if (isCpf) {
      return Column(
        children: [
          DebtsCpfCard(
            debts: debts,
            jusBrasil: jusbrasilList,
            isCpfNotSerpro: cnpjController.text,
            isConsultant:
                role == "consultant" || role == "admin" ? true : false,
          ),
        ],
      );
    } else {
      return const Column(
        children: [Text("Dado não encontrado")],
      );
    }
  }
}

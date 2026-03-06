import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/company_card.dart';
import 'package:momentofiscal/components/tj_card.dart';
import 'package:momentofiscal/core/models/api_cnpj.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/location/location_compaines_rails.dart';
import 'package:momentofiscal/core/services/processDataCrawlers/process_jusbrasil_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/pages/search/cnpj_cpf_page.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class FinancialAnalysisPage extends StatefulWidget {
  final ApiCnpj? apiCnpj;
  final List<Debt>? debts;
  final String? isCpfNotSerpro;
  final Company? company;

  const FinancialAnalysisPage({
    super.key,
    this.apiCnpj,
    this.debts,
    this.isCpfNotSerpro,
    this.company,
  });

  @override
  // ignore: library_private_types_in_public_api
  _FinancialAnalysisPageState createState() => _FinancialAnalysisPageState();
}

class _FinancialAnalysisPageState extends State<FinancialAnalysisPage> {
  Company? company;

  List<String> subscriptionList = [];
  List<Jusbrasil> jusbrasilList = [];
  bool isLoading = true;
  double progress = 0.0;
  num countProcess = 0;
  num totalValue = 0;
  String? role;
  String? iosSubscription;
  Map<String, int> tribunalProcesses = {};
  Map<String, num> tribunalValuesSum = {};
  StreamSubscription<List<Jusbrasil>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.debts != null) {
      // Fazer para o card de debitos
    } else if (widget.apiCnpj != null) {
      _fetchCompanyData();
    }
    _fetchData();
  }

  @override
  void dispose() {
    subscriptionList.clear();
    jusbrasilList.clear();
    _streamSubscription?.cancel();

    super.dispose();
  }

  Future<void> _fetchCompanyData() async {
    final locationCompanies = LocationCompaniesRails();
    List<Company>? fetchedCompanies =
        (await locationCompanies.getCompanyByCnpj(widget.apiCnpj!.cnpj))
            .cast<Company>();

    if (fetchedCompanies.isNotEmpty) {
      setState(() {
        company = fetchedCompanies.first;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });
    String? subscriptionType = await storage.read(key: 'subscription');
    iosSubscription = await storage.read(key: 'iosSubscription');
    role = await storage.read(key: 'role');

    if (subscriptionType != null) {
      // Remover os colchetes e os espaços extras, e depois dividir a string
      subscriptionList = subscriptionType
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .toList();
    }

    var processJusbrasil = ProcessJusbrasil(); // Instância da classe
    Stream<List<Jusbrasil>> stream = processJusbrasil.getProcessesCpfCnpjStream(
      cpfCnpj: widget.debts != null
          ? widget.debts!.first.cpfCnpj ?? ""
          : widget.isCpfNotSerpro != null
              ? widget.isCpfNotSerpro!
              : widget.apiCnpj!.cnpj,
    );

    _streamSubscription = stream.listen((fetchedJusbrasilList) {
      setState(() {
        jusbrasilList = fetchedJusbrasilList;

        // Atualiza os valores totais e os mapas de tribunal
        totalValue = jusbrasilList
            .expand((item) => item.content ?? [])
            .expand((contentItem) => contentItem.tramitacoes)
            .fold(
                0.0, (sum, tramitacao) => sum + (tramitacao.valorAcao ?? 0.0));

        Map<String, int> tribunalProcesse = {};
        Map<String, num> tribunalValues = {};

        for (var item in jusbrasilList.expand((x) => x.content ?? [])) {
          String sigla = item.siglaTribunal;
          tribunalProcesse[sigla] = (tribunalProcesse[sigla] ?? 0) + 1;

          double totalValor = item.tramitacoes.fold(
              0.0, (sum, tramitacao) => sum + (tramitacao.valorAcao ?? 0.0));
          tribunalValues[sigla] = (tribunalValues[sigla] ?? 0.0) + totalValor;
        }

        tribunalProcesses = tribunalProcesse;
        tribunalValuesSum = tribunalValues;
      });
    }, onDone: () {
      setState(() {
        isLoading = false;
      });
    }, onError: (error) {
        final errorMessage = error.toString();

        if (errorMessage.contains('500') || errorMessage.contains('504')) {
          _showErrorMessage(
            'O serviço do Jusbrasil está temporariamente indisponível. '
            'Por favor, tente novamente em alguns minutos.',
          );
        }

        if (errorMessage.contains('404') || errorMessage.contains("not found")) {
          _showErrorMessage('Processo não encontrado para o CPF/CNPJ fornecido.');
        }

      setState(() {
        isLoading = false;
      });
      Exception("Error: $error");
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int get debtCount => widget.debts != null
      ? widget.debts!.length
      : company?.debtsCount ?? 0;

  String get riskLevelLabel {
    if (debtCount <= 5) {
      return 'Baixo Risco';
    } else if (debtCount < 10) {
      return 'Médio Risco';
    } else {
      return 'Alto Risco';
    }
  }

  Color get riskColor {
    if (debtCount <= 5) {
      return Colors.green;
    } else if (debtCount < 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Financeira/Judicial',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            _streamSubscription?.cancel();
            jusbrasilList.clear();

            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(
                builder: (context) => const CnpjCpfPage(),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
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
              const SizedBox(height: 25),
              if (company != null) ...[
                CompanyCard(
                  company: company!,
                  elevation: 0,
                ),
              ] else if (widget.debts != null) ...[
                Card(
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      widget.debts!.first.debtedName ?? "",
                      style: const TextStyle(
                          fontSize: 15,
                          color: colorPrimaty,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('CPF: ${widget.debts!.first.cpfCnpj ?? ""}')
                      ],
                    ),
                  ),
                )
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      startAngle: 180,
                      endAngle: 0,
                      minimum: 0,
                      maximum: 15,
                      showLabels: false,
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0,
                          endValue: 5,
                          color: Colors.green,
                          startWidth: 10,
                          endWidth: 10,
                        ),
                        GaugeRange(
                          startValue: 5,
                          endValue: 10,
                          color: Colors.orange,
                          startWidth: 10,
                          endWidth: 10,
                        ),
                        GaugeRange(
                          startValue: 10,
                          endValue: 15,
                          color: Colors.red,
                          startWidth: 10,
                          endWidth: 10,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: widget.debts != null
                              ? widget.debts!.length.toDouble()
                              : company?.debtsCount?.toDouble() ?? 0,
                          needleColor: riskColor,
                          lengthUnit: GaugeSizeUnit.factor,
                          needleLength: 0.6,
                          needleStartWidth: 1,
                          needleEndWidth: 2,
                        )
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: SizedBox(
                            height: 65,
                            width: 200,
                            child: Column(
                              children: [
                                const SizedBox(height: 25),
                                // Exibindo apenas a classificação de risco
                                Text(
                                  riskLevelLabel,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: riskColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          angle: 90,
                          positionFactor: 0.4,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Área Fiscal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    isLoading
                        ? Row(
                            children: [
                              Text(NumberFormat.simpleCurrency(locale: 'pt_BR')
                                  .format(totalValue)),
                              const SizedBox(width: 10),
                              const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.0),
                              ),
                            ],
                          )
                        : Text(
                            NumberFormat.simpleCurrency(locale: 'pt_BR')
                                .format(totalValue),
                            style:
                                const TextStyle(fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Área Trabalhista',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Não informado'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Área Bancária',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Não informado'),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text('Tribunais', style: textTitle),
              const SizedBox(height: 20),
              if (isLoading) ...[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Carregando Dados...'),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ],
                ),
                const SizedBox(height: 10)
              ],
              tribunalProcesses.isEmpty
                  ? const SizedBox()
                  : Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      const Text('Total de processos: '),
                      Text(jusbrasilList.first.total.toString())
                    ]),
              tribunalProcesses.isEmpty
                  ? const SizedBox()
                  : const SizedBox(height: 10),
              tribunalProcesses.isEmpty
                  ? const Text('Não possui processos')
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        height: tribunalProcesses.length * 220,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 248, 248, 248),
                              Color.fromARGB(255, 255, 255, 255),
                              Color.fromARGB(255, 255, 255, 255),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView.builder(
                            physics:
                                const NeverScrollableScrollPhysics(), // Desativa o scroll
                            itemCount: tribunalProcesses.length,

                            itemBuilder: (context, index) {
                              String tribunal =
                                  tribunalProcesses.keys.elementAt(index);
                              int countProcess = tribunalProcesses[tribunal]!;
                              num totalValue =
                                  tribunalValuesSum[tribunal] ?? 0.0;

                              return TjCard(
                                tribunal: tribunal,
                                isLoading: false,
                                progress: 0.0,
                                countProcess: countProcess,
                                totalValueAction: totalValue,
                                listJusbrasil: jusbrasilList
                                    .expand(
                                      (item) => item.content ?? [],
                                    )
                                    .where((process) =>
                                        process.siglaTribunal == tribunal)
                                    .toList(),
                                company: company,
                                listDebts: widget.debts,
                                role: role!,
                                subscriptionList: subscriptionList,
                                iosSubscription: iosSubscription,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 25),
              // Center(
              //   child: ElevatedButton(
              //     onPressed: () {
              //       Navigator.of(context).push(MaterialPageRoute(
              //           builder: (context) => CreateProposalPage()));
              //     },
              //     style: ElevatedButton.styleFrom(
              //       elevation: 0,
              //       backgroundColor: Theme.of(context).colorScheme.primary,
              //     ),
              //     child: const Text(
              //       'Soluções Aplicáveis',
              //       style: TextStyle(
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/api_cnpj.dart';
import 'package:momentofiscal/core/models/async_list.dart';
import 'package:momentofiscal/core/models/tj_process.dart';
import 'package:momentofiscal/core/services/processDataCrawlers/fetch_tj_data.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';

class ProceduralSummaryPage extends StatefulWidget {
  final ApiCnpj apiCnpj;
  const ProceduralSummaryPage({super.key, required this.apiCnpj});

  @override
  State<ProceduralSummaryPage> createState() => _ProceduralSummaryPageState();
}

class _ProceduralSummaryPageState extends State<ProceduralSummaryPage> {
  List<TjProcess> tjProcess = [];
  bool isLoading = true;
  double progress = 0.0;
  num countProcess = 0;
  num totalValue = 0;
  Timer? _timer;
  final int _updateInterval = 100;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    isActive = true;
    startLoading();
    fetchData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    isActive = false;
    totalValue = 0;
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      AsyncList asyncList = FetchTjEjacData().call(
          cpfCnpj: removeMask(widget.apiCnpj.cnpj),
          baseUrl: 'https://esaj.tjsp.jus.br');

      while (isActive) {
        if (asyncList.isFinished) {
          setState(() {
            countProcess = tjProcess.length;
            tjProcess = asyncList.items as List<TjProcess>;
            isLoading = false;
          });
          break;
        }

        setState(() {
          countProcess = tjProcess.length;
          tjProcess = asyncList.items as List<TjProcess>;
          progress = asyncList.progress;
          calculateTotalValue();
        });

        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void startLoading() {
    _timer = Timer.periodic(Duration(milliseconds: _updateInterval), (timer) {
      setState(() {
        // Limita o progresso a 100%
        if (progress >= 1.0) {
          progress = 1.0;
          _timer?.cancel();
        }
      });
    });
  }

  void calculateTotalValue() {
    totalValue =
        tjProcess.fold(0, (sum, process) => sum + (process.value ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Análise Processual',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (isLoading)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Carregando dados...", style: textTitle),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    // Exibe a porcentagem de carregamento
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              const SizedBox(height: 15),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Valor Passivo em Processos',
                      style: textTitle,
                    ),
                    const Text('Parte Passiva'),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 3,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          NumberFormat.simpleCurrency(locale: 'pt_BR')
                              .format(totalValue),
                          style: textTitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text('$countProcess processos que o CNPJ foi citado.'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: ListView.builder(
                  itemCount: tjProcess.length,
                  itemBuilder: (context, index) {
                    final process = tjProcess[index];

                    // ignore: unnecessary_null_comparison
                    if (process == null ||
                        process.code == null ||
                        process.participationType == null ||
                        process.interestedPartyName == null) {
                      return const SizedBox();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Nº: ",
                                      style: textTitle,
                                    ),
                                    Expanded(
                                      child: Text(
                                        process.code!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${process.participationType} ",
                                      style: textTitle,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "${process.interestedPartyName}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                    "${process.processClass} ${process.receivedLocation}"),
                                Text(
                                  "Recebido em: ${process.receivedAt}",
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "Total: ",
                                      style: textTitle,
                                    ),
                                    Text(
                                      NumberFormat.simpleCurrency(
                                              locale: 'pt_BR')
                                          .format(process.value),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

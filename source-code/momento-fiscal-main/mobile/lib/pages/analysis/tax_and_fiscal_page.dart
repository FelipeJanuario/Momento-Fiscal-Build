import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/debts/debt_nature_list.dart';
import 'package:momentofiscal/core/models/api_cnpj.dart';
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/search/cnpj_cpf_page.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TaxAndFiscalPage extends StatefulWidget {
  final ApiCnpj? apiCnpj;
  final List<Debt>? listDebts;
  final double totalDebt;
  const TaxAndFiscalPage(
      {super.key, this.apiCnpj, this.listDebts, required this.totalDebt});

  @override
  State<TaxAndFiscalPage> createState() => _TaxAndFiscalPageState();
}

class _TaxAndFiscalPageState extends State<TaxAndFiscalPage> {
  late List<bool> _isTextVisibleList;

  @override
  void initState() {
    super.initState();

    _isTextVisibleList =
        List<bool>.filled(widget.listDebts?.length ?? 0, false);
  }

  String capitalizeFirstLetters(String input) {
    if (input.isEmpty) return input;

    input = input.toLowerCase();
    return input[0].toUpperCase() + input.substring(1);
  }

  int get debtCount => widget.listDebts?.length ?? 0;

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
        title: const Text('Análise Fiscal e Tributária'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => CnpjCpfPage(
                      cnpjCpf: widget.listDebts != null
                          ? widget.listDebts!.first.cpfCnpj ?? ""
                          : cnpjMask(widget.apiCnpj?.cnpj ?? ""))),
            );
          },
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      Center(
                        child: SizedBox(
                          height: 100,
                          child: Image.asset(
                              'assets/images/momentofiscalcolorido.png',
                              fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 15),
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
                                  value: debtCount.toDouble(),
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
                      if (widget.apiCnpj != null) ...[
                        Row(
                          children: [
                            const Text(
                              'CNPJ: ',
                              style: textTitle,
                            ),
                            Text(
                              formatNumberInCnpj(widget.apiCnpj!.cnpj),
                              style: const TextStyle(fontSize: 16),
                            )
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Domicílio do Devedor: ',
                          style: textTitle,
                        ),
                        Text(
                            '${widget.apiCnpj!.complement}, ${widget.apiCnpj!.district}, ${widget.apiCnpj!.county}'),
                        const SizedBox(height: 5),
                        const Text(
                          'Atividade Econômica (CNAE): ',
                          style: textTitle,
                        ),
                        Text(widget.apiCnpj!.descriptionCnae,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 5),
                      ] else if (widget.listDebts != null) ...[
                        Row(
                          children: [
                            const Text(
                              'CPF: ',
                              style: textTitle,
                            ),
                            Text(
                              widget.listDebts!.first.cpfCnpj ?? "",
                              style: const TextStyle(fontSize: 16),
                            )
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Nome do Devedor: ',
                          style: textTitle,
                        ),
                        Text(widget.listDebts!.first.debtedName ?? ""),
                        const SizedBox(height: 8),
                      ] else ...[
                        Container()
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Valor Total da Dívida: ',
                                  style: textTitle,
                                ),
                                TextSpan(
                                  text: NumberFormat.simpleCurrency(
                                          locale: 'pt_BR')
                                      .format(widget.totalDebt),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text('Natureza da Dívida da Empresa',
                          style: textTitle),
                      if (widget.apiCnpj != null) ...[
                        DebtNatureList(
                          cnpjCpf: widget.apiCnpj!.cnpj,
                        ),
                      ] else if (widget.listDebts != null) ...[
                        SizedBox(
                          height: widget.listDebts!.length * 50,
                          child: SingleChildScrollView(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.listDebts?.length,
                              itemBuilder: (context, index) {
                                final debt = widget.listDebts![index];
                                final value =
                                    debt.value.toString();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Row(
                                      key: const Key('debtsExpanded'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            capitalizeFirstLetters(
                                                debt.registrationStatus ?? ""),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                value,
                                                textAlign: TextAlign.end,
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  _isTextVisibleList[index]
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                          .keyboard_arrow_down,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _isTextVisibleList[index] =
                                                        !_isTextVisibleList[
                                                            index];
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_isTextVisibleList[index])
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  const TextSpan(
                                                    text: 'Unidade: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: debt.responsibleUnit ?? "",
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                            const SizedBox(height: 5),
                                            Container(
                                              height: 1,
                                              width: double.infinity,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'N° de Inscrição:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  debt.registrationNumber ?? "",
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'N° do Processo:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  debt.mainRevenue ?? "",
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Situação:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  debt.debtState ?? "",
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Regularidade:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  debt.registrationStatusType ?? "",
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Data Inscrição:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  debt.registrationDate ?? "",
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

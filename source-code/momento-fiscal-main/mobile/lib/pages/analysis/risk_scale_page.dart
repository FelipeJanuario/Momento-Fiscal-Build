import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/api_cnpj.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/analysis/procedural_summary_page.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RiskScalePage extends StatelessWidget {
  final ApiCnpj apiCnpj;
  const RiskScalePage({super.key, required this.apiCnpj});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escala de Risco'),
        backgroundColor: Theme.of(context).primaryColor.withAlpha(153),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          SizedBox(
            height: 150,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  startAngle: 180,
                  endAngle: 0,
                  minimum: 0,
                  maximum: 150,
                  ranges: <GaugeRange>[
                    GaugeRange(
                      startValue: 0,
                      endValue: 30,
                      color: Colors.green,
                      startWidth: 10,
                      endWidth: 10,
                    ),
                    GaugeRange(
                      startValue: 30,
                      endValue: 60,
                      color: Colors.lightGreen,
                      startWidth: 10,
                      endWidth: 10,
                    ),
                    GaugeRange(
                      startValue: 60,
                      endValue: 90,
                      color: Colors.yellow,
                      startWidth: 10,
                      endWidth: 10,
                    ),
                    GaugeRange(
                      startValue: 90,
                      endValue: 120,
                      color: Colors.orange,
                      startWidth: 10,
                      endWidth: 10,
                    ),
                    GaugeRange(
                      startValue: 120,
                      endValue: 150,
                      color: Colors.red,
                      startWidth: 10,
                      endWidth: 10,
                    ),
                  ],
                  pointers: const <GaugePointer>[
                    NeedlePointer(
                      value: 90,
                      lengthUnit: GaugeSizeUnit.factor,
                      needleLength: 0.6,
                      needleStartWidth: 1, // Largura da agulha na base
                      needleEndWidth: 2, // Largura da agulha na ponta
                    )
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Container(
                        height: 40,
                        width: 200,
                        decoration: const BoxDecoration(
                            color: Color.fromARGB(90, 158, 158, 158),
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Risco ', style: TextStyle(fontSize: 25)),
                            Text(
                              '90.0',
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
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
          const Text('Grupos Empresáriais que este CNPJ faz parte',
              style: textTitle),
          const Text('N° de empresas que o CNPJ faz parte e N° são ativas'),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12))),
                      child: const Text(
                        'CNPJ do Grupo Empresarial',
                        style: textTitle,
                        textAlign: TextAlign.center,
                      )),
                  SizedBox(
                    height: examplesFilial.length * 70,
                    child: ListView.builder(
                      itemCount: examplesFilial.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(examplesFilial[index].companyName),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text('Situação : '),
                                      Text(examplesFilial[index]
                                          .registrationStatus)
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Container(
                              height: 1,
                              color: Colors.grey[300],
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => ProceduralSummaryPage(
                          apiCnpj: apiCnpj,
                        )),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              fixedSize: const Size.fromWidth(350),
            ),
            child: const Text(
              'Análise Processual',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}

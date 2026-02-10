import 'package:flutter/material.dart';
import 'package:momentofiscal/components/company_card.dart';
import 'package:momentofiscal/core/models/api_cnpj.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/serpro.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RiskScaleDialog extends StatelessWidget {
  final ApiCnpj? apiCnpj;
  final Company? company;
  final List<Serpro>? listSerpro;
  final List<String> subscriptionList;
  final String? iosSubscription;
  // final String role;

  const RiskScaleDialog({
    super.key,
    this.apiCnpj,
    this.company,
    this.listSerpro,
    required this.subscriptionList,
    required this.iosSubscription,
    // required this.role,
  });

  int get debtCount =>
      listSerpro != null ? listSerpro!.length : company?.debtsCount ?? 0;

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
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                      value: listSerpro != null
                          ? listSerpro!.length.toDouble()
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
                        height: 60,
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
          const SizedBox(height: 20),
          if (company != null) ...[
            CompanyCard(
              company: company!,
              elevation: 0,
            )
          ] else if (listSerpro != null)
            ...[]
          else ...[
            Container()
          ],
          const SizedBox(height: 20),
          // ElevatedButton(
          //   onPressed: () {
          //     if (subscriptionList.contains('debt_report') && role != "admin" ||
          //         iosSubscription == 'free' && role != "admin" ||
          //         iosSubscription == 'bronze' && role != "admin") {
          //       cardUpgradePlans(
          //         context: context,
          //         text:
          //             'Seu plano atual não permite acessar esta funcionalidade. Faça o upgrade para continuar.',
          //       );
          //     } else {
          //       Navigator.of(context).push(
          //         MaterialPageRoute(
          //           builder: (context) =>
          //               ProceduralSummaryPage(apiCnpj: apiCnpj),
          //         ),
          //       );
          //     }
          //   },
          //   style: ElevatedButton.styleFrom(
          //     elevation: 3,
          //     backgroundColor:
          //         subscriptionList.contains('debt_report') && role != "admin" ||
          //                 iosSubscription == 'free' && role != "admin" ||
          //                 iosSubscription == 'bronze' && role != "admin"
          //             ? Colors.purple
          //             : Colors.blue,
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text(
          //         'ANÁLISE PROCESSUAL',
          //         style: TextStyle(
          //           color: Colors.white,
          //         ),
          //       ),
          //       const SizedBox(width: 5),
          //       subscriptionList.contains('debt_report') && role != "admin" ||
          //               iosSubscription == 'free' && role != "admin" ||
          //               iosSubscription == 'bronze' && role != "admin"
          //           ? const Icon(
          //               Icons.lock_outline,
          //               color: Colors.white,
          //             )
          //           : const Text('')
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

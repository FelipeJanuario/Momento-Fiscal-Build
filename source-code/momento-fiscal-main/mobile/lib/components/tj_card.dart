import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/card_upgrade_plans.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/debt.dart';

import 'package:momentofiscal/pages/analysis/process_page.dart';

class TjCard extends StatelessWidget {
  final String tribunal;
  final bool isLoading;
  final double progress;
  final num countProcess;
  final num totalValueAction;
  final List<dynamic> listJusbrasil;
  final Company? company;
  final List<Debt>? listDebts;
  final List<String> subscriptionList;
  final String? iosSubscription;
  final String role;

  const TjCard({
    super.key,
    required this.tribunal,
    required this.isLoading,
    required this.progress,
    required this.countProcess,
    required this.totalValueAction,
    required this.listJusbrasil,
    this.company,
    this.listDebts,
    required this.subscriptionList,
    this.iosSubscription,
    required this.role,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Visualizar Análise Processual',
              style: TextStyle(fontSize: 11),
            ),
            IconButton(
                onPressed: () {
                  if (subscriptionList.contains('debt_report') &&
                          role != "admin" ||
                      iosSubscription == 'free' && role != "admin" ||
                      iosSubscription == 'bronze' && role != "admin") {
                    cardUpgradePlans(
                      context: context,
                      text:
                          'Seu plano atual não permite acessar esta funcionalidade. Faça o upgrade para continuar.',
                    );
                  } else {}
                  if (listJusbrasil.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProcessPage(
                            listProcess: listJusbrasil,
                            company: company,
                            listDebts: listDebts,
                            tribunal: tribunal,
                            countProcess: countProcess),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          title: Text('Nenhum Processo encontrado'),
                        );
                      },
                    );
                  }
                },
                icon: Icon(
                  Icons.remove_red_eye_rounded,
                  color: Colors.blue[200],
                ))
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: const BorderRadius.all(Radius.circular(12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tribunal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                tribunal,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: const BorderRadius.all(Radius.circular(12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quantidade N°',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              isLoading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    )
                  : Text(
                      countProcess.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: const BorderRadius.all(Radius.circular(12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Valor em Ação',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              isLoading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    )
                  : Text(
                      NumberFormat.simpleCurrency(locale: 'pt_BR')
                          .format(totalValueAction),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

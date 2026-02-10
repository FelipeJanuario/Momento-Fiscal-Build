import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/debts/debt_nature_list_item.dart';
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/debt/debt_rails_service.dart';

// ignore: must_be_immutable
class DebtNatureList extends StatefulWidget {
  final String cnpjCpf;

  const DebtNatureList({super.key, required this.cnpjCpf});

  @override
  State<DebtNatureList> createState() => _DebtNatureListState();
}

class _DebtNatureListState extends State<DebtNatureList> {
  bool loading = false;
  List<Debt> debts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDebts();
  }

  String formatCnpjCpf(String document) {
    if (document.length == 11) {
      return '${document.substring(0, 3)}.${document.substring(3, 6)}.${document.substring(6, 9)}-${document.substring(9)}';
    } else if (document.length == 14) {
      return '${document.substring(0, 2)}.${document.substring(2, 5)}.${document.substring(5, 8)}/${document.substring(8, 12)}-${document.substring(12)}';
    }
    return document;
  }

  Future<void> _fetchDebts() async {
    setState(() {
      loading = true;
    });

    String formattedDocument = formatCnpjCpf(widget.cnpjCpf);

    final fetchedDebts = await DebtsRails().getDebts(formattedDocument);

    setState(() {
      debts = fetchedDebts;
      loading = false;
    });
  }

  double _calculateTotalDebt() {
    if (debts.isEmpty) return 0.0;
    return debts.fold(0.0, (sum, debt) {
      final value = double.tryParse(debt.value.toString()) ?? 0.0;
      return sum + value;
    });
  }

  String capitalizeFirstLetters(String input) {
    if (input.isEmpty) return input;
    input = input.toLowerCase();
    return input[0].toUpperCase() + input.substring(1);
  }

  List<Debt> get previdenciaryDebts =>
      debts.where((debt) => debt.isPrevidenciary == "true").toList();

  List<Debt> get fgtsDebts =>
      debts.where((debt) => debt.isFgts == 'true').toList();

  List<Debt> get otherDebts => debts
      .where(
          (debt) => debt.isFgts != 'true' && debt.isPrevidenciary != 'true')
      .toList();

  @override
  Widget build(BuildContext context) {
    final totalDebt = _calculateTotalDebt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (previdenciaryDebts.isNotEmpty)
          ExpansionTile(
            tilePadding: const EdgeInsets.all(0),
            dense: true,
            title:
                const Text("Previdenciárias", style: TextStyle(fontSize: 16)),
            subtitle: Text("${previdenciaryDebts.length} debitos",
                style: const TextStyle(
                    fontSize: 12, color: Color.fromRGBO(0, 0, 0, 0.7))),
            trailing: Text(
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(
                previdenciaryDebts.fold(
                  0.0,
                  (sum, debt) {
                    final value = double.tryParse(debt.value.toString()) ?? 0.0;
                    return sum + value;
                  },
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(
                    color: Color.fromARGB(132, 223, 215, 215),
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: ListView.builder(
                  primary: false,
                  itemCount: previdenciaryDebts.length,
                  itemBuilder: (context, index) {
                    final debt = previdenciaryDebts[index];

                    return DebtNatureListItem(debt: debt);
                  },
                ),
              ),
            ],
          ),
        if (fgtsDebts.isNotEmpty)
          ExpansionTile(
            tilePadding: const EdgeInsets.all(0),
            dense: true,
            title: const Text("FGTS"),
            subtitle: Text("${fgtsDebts.length} debitos",
                style: const TextStyle(
                    fontSize: 12, color: Color.fromRGBO(0, 0, 0, 0.7))),
            trailing: Text(
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(
                fgtsDebts.fold(
                  0.0,
                  (sum, debt) {
                    final value = double.tryParse(debt.value.toString()) ?? 0.0;
                    return sum + value;
                  },
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(
                    color: Color.fromARGB(132, 223, 215, 215),
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: ListView.builder(
                  primary: false,
                  itemCount: fgtsDebts.length,
                  itemBuilder: (context, index) {
                    final debt = fgtsDebts[index];

                    return DebtNatureListItem(debt: debt);
                  },
                ),
              ),
            ],
          ),
        if (otherDebts.isNotEmpty)
          ExpansionTile(
            tilePadding: const EdgeInsets.all(0),
            dense: true,
            title: const Text("Outras"),
            subtitle: Text("${otherDebts.length} debitos",
                style: const TextStyle(
                    fontSize: 12, color: Color.fromRGBO(0, 0, 0, 0.7))),
            trailing: Text(
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(
                otherDebts.fold(
                  0.0,
                  (sum, debt) {
                    final value = double.tryParse(debt.value.toString()) ?? 0.0;
                    return sum + value;
                  },
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(
                    color: Color.fromARGB(132, 223, 215, 215),
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: ListView.builder(
                  primary: false,
                  itemCount: otherDebts.length,
                  itemBuilder: (context, index) {
                    final debt = otherDebts[index];

                    return DebtNatureListItem(debt: debt);
                  },
                ),
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Valor Total da Dívida:   ',
                  ),
                  TextSpan(
                    text: NumberFormat.simpleCurrency(locale: 'pt_BR')
                        .format(totalDebt),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

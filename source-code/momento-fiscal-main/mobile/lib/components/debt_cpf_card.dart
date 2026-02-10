import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/analysis/financial_analysis_page.dart';
import 'package:momentofiscal/pages/analysis/tax_and_fiscal_page.dart';

class DebtsCpfCard extends StatefulWidget {
  final List<Debt>? debts;
  final List<Jusbrasil> jusBrasil;
  final String? isCpfNotSerpro;
  final bool isConsultant;

  const DebtsCpfCard({
    super.key,
    required this.debts,
    required this.jusBrasil,
    required this.isCpfNotSerpro,
    this.isConsultant = false,
  });

  @override
  State<DebtsCpfCard> createState() => _DebtsCpfCardState();
}

class _DebtsCpfCardState extends State<DebtsCpfCard> {
  late String cpf;
  late String cpfName;

  @override
  void initState() {
    super.initState();
    cpf = widget.isCpfNotSerpro ?? ''; // Inicializa o CPF apenas uma vez.
    cpfName = getCpfName(removeMask(widget.isCpfNotSerpro ?? ''));
  }

  double _calculateTotalDebt(List<Debt> debts) {
    return debts.fold(0.0, (sum, debt) {
      final value = double.tryParse(debt.value.toString()) ?? 0.0;
      return sum + value;
    });
  }

  String getCpfName(String cpf) {
    // Itera pela estrutura aninhada para buscar o nome associado ao CPF
    for (var content in widget.jusBrasil) {
      for (var tramitacao in content.content ?? []) {
        for (var parte in tramitacao.tramitacoes) {
          for (var result in parte.partes) {
            for (var doc in result.documentosPrincipais) {
              if (doc.tipo == "CPF" && doc.numero == cpf) {
                return result.nome ?? 'Nome não encontrado';
              }
            }
          }
        }
      }
    }
    return 'Nome não encontrado';
  }

  Widget _cpfDetailsNotFoundCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text(
                  'Informação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.jusBrasil.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nome: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(child: Text(cpfName)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CPF: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(child: Text(cpf)),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Análise Fiscal/Tributária: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextSpan(
                    text: widget.jusBrasil.isEmpty
                        ? 'Não encontrados.'
                        : 'Não encontrados.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Análise Financeira/Judicial: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextSpan(
                    text: widget.jusBrasil.isEmpty
                        ? 'Não encontrados.'
                        : '${widget.jusBrasil.first.total.toString()} encontrados',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _cardActions()
          ],
        ),
      ),
    );
  }

  Widget _cardActions({double totalDebt = 0.0}) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Escolha uma análise'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Análise Fiscal e Tributária'),
                      tileColor: widget.debts == null
                          ? Colors.grey[300]
                          : Colors.green[100],
                      trailing:
                          const Icon(Icons.arrow_forward, color: Colors.green),
                      onTap: () {
                        if (widget.debts == null) {
                          return;
                        }
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TaxAndFiscalPage(
                                listDebts: widget.debts,
                                totalDebt: totalDebt),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: const Text('Análise Financeira/Judicial'),
                      tileColor: Colors.green[100],
                      trailing:
                          const Icon(Icons.arrow_forward, color: Colors.green),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FinancialAnalysisPage(
                              debts: widget.debts,
                              isCpfNotSerpro: widget.isCpfNotSerpro,
                            ),
                          ),
                        );
                      },
                    ),
                    // if (widget.isConsultant)
                    //   ListTile(
                    //     title: const Text('Criar Proposta'),
                    //     tileColor: Colors.blue[100],
                    //     trailing: const Icon(Icons.arrow_forward,
                    //         color: Colors.blue),
                    //     onTap: () {
                    //       Navigator.of(context).pop();
                    //       Navigator.of(context).push(
                    //         MaterialPageRoute(
                    //           builder: (context) =>
                    //               CreateProposalPage(
                    //             debtValue: totalDebt,
                    //             cnpj: apiCnpj.cnpj,
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //   ),
                  ],
                ),
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          fixedSize: const Size.fromWidth(500),
        ),
        child: const Text(
          'Diagnóstico',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.debts == null || widget.debts!.isEmpty) {
      return _cpfDetailsNotFoundCard();
    }

    final totalDebt = _calculateTotalDebt(widget.debts ?? []);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nome: ', style: textTitle),
                  Expanded(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Text(
                        widget.debts != null && widget.debts!.isNotEmpty
                            ? widget.debts!.first.debtedName ?? ''
                            : '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CPF: ', style: textTitle),
                  Expanded(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Text(
                        widget.debts != null && widget.debts!.isNotEmpty
                            ? widget.debts!.first.cpfCnpj ?? ''
                            : '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantidade de Dívida: ', style: textTitle),
                  Expanded(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Text(
                        widget.debts != null
                            ? widget.debts!.length.toString()
                            : '',
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Color.fromARGB(255, 208, 207, 207)),
              const Text('Valor Total das dívidas Fiscal e Tributária:',
                  style: textTitle),
              Text(
                NumberFormat.simpleCurrency(locale: 'pt_BR').format(totalDebt),
              ),
              const SizedBox(height: 10),
              _cardActions(totalDebt: totalDebt),
            ],
          ),
        ),
      ),
    );
  }
}

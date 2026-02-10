import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/api_cnpj.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/analysis/financial_analysis_page.dart';
import 'package:momentofiscal/pages/analysis/tax_and_fiscal_page.dart';
import 'package:momentofiscal/pages/consulting/management/create_proposal_page.dart';
import 'package:momentofiscal/pages/proposal/create_proposal_client_page.dart';

class ApiCnpjCard extends StatelessWidget {
  final ApiCnpj apiCnpj;
  final Company company;
  final String? role;
  final String idUser;
  final bool isInstitution;
  final bool isConsultant;

  final List<Debt>? debts;
  final double totalDebtValue;
  
  const ApiCnpjCard(
      {super.key,
      required this.apiCnpj,
      required this.company,
      required this.role,
      required this.idUser,
      required this.debts,
      required this.totalDebtValue,
      required this.isInstitution,
      this.isConsultant = false});

  String capitalizeFirstLetters(String input) {
    if (input.isEmpty) return input;

    input = input.toLowerCase();

    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Use o valor total passado como parâmetro em vez de calcular
    final totalDebt = totalDebtValue;
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
                children: [
                  const Text('Razão Social: ', style: textTitle),
                  Expanded(
                    child: Text(
                      apiCnpj.reasonSocial,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Porte: ', style: textTitle),
                  Text(apiCnpj.companySize),
                ],
              ),
              Row(
                children: [
                  const Text('Capital Social: ', style: textTitle),
                  Text(
                    NumberFormat.simpleCurrency(locale: 'pt_BR')
                        .format(apiCnpj.shareCapital),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Situação Cadastral: ', style: textTitle),
                  Text(
                    apiCnpj.registrationStatus,
                    style: TextStyle(
                        color: apiCnpj.registrationStatus == 'INAPTA'
                            ? Colors.red
                            : Colors.black),
                  )
                ],
              ),
              Row(
                children: [
                  const Text('Telefone: ', style: textTitle),
                  Text(apiCnpj.phone)
                ],
              ),
              Row(
                children: [
                  const Text('Endereço: ', style: textTitle),
                  Expanded(
                      child: Text(
                    '${apiCnpj.district}, ${apiCnpj.county}',
                    overflow: TextOverflow.ellipsis,
                  ))
                ],
              ),
              Text(apiCnpj.complement),
              Row(
                children: [
                  const Text('CEP: ', style: textTitle),
                  Text(apiCnpj.cep)
                ],
              ),
              const SizedBox(height: 10),
              const Text('Sócios:', style: textTitle),
              ...apiCnpj.socios.map(
                (socio) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(socio.name),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Idade: ${socio.age}',
                          style: textPlaceholder,
                        ),
                        const SizedBox(width: 15),
                        Text('CPF: ${socio.cpf}', style: textPlaceholder),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Qualificação: ${socio.qualification}',
                            style: textPlaceholder,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    Text(
                        'Data de Entrada: ${DateFormat("dd/MM/yyyy").format(DateTime.parse(socio.entryDate))}',
                        style: textPlaceholder)
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Valor Total das Dívidas Fiscal e Tributária: ',
                  style: textTitle),
              Text(
                NumberFormat.simpleCurrency(locale: 'pt_BR')
                    .format(totalDebtValue),
              ),
              const SizedBox(height: 10),
              Center(
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
                                title:
                                    const Text('Análise Fiscal e Tributária'),
                                tileColor: Colors.green[100],
                                trailing: const Icon(Icons.arrow_forward,
                                    color: Colors.green),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => TaxAndFiscalPage(
                                          apiCnpj: apiCnpj,
                                          listDebts: debts,
                                          totalDebt: totalDebt),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              ListTile(
                                title:
                                    const Text('Análise Financeira/Judicial'),
                                tileColor: Colors.green[100],
                                trailing: const Icon(Icons.arrow_forward,
                                    color: Colors.green),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FinancialAnalysisPage(
                                              apiCnpj: apiCnpj,
                                              company: company),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              if (isInstitution)
                                ListTile(
                                  title: const Text('Solicitar Proposta'),
                                  tileColor: Colors.blue[100],
                                  trailing: const Icon(Icons.arrow_forward,
                                      color: Colors.blue),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateProposalClientPage(
                                                idUser: idUser,
                                                debtsCount: company.debtsCount,
                                                debtValue: totalDebt),
                                      ),
                                    );
                                  },
                                ),
                              if (isConsultant)
                                ListTile(
                                  title: const Text('Criar Proposta'),
                                  tileColor: Colors.blue[100],
                                  trailing: const Icon(Icons.arrow_forward,
                                      color: Colors.blue),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateProposalPage(
                                          debtValue: totalDebt,
                                          debtsCount: company.debtsCount,
                                          cnpj: apiCnpj.cnpj,
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

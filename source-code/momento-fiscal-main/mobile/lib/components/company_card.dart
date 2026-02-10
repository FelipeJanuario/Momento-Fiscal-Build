import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/search/cnpj_cpf_page.dart';

class CompanyCard extends StatelessWidget {
  final Company company;
  final double elevation;
  const CompanyCard({super.key, required this.company, this.elevation = 1});

  @override
  Widget build(BuildContext context) {
    String formatZipCode(String zipCode) {
      if (zipCode.length == 8) {
        return '${zipCode.substring(0, 5)}-${zipCode.substring(5)}';
      }
      return zipCode;
    }

    return InkWell(
      onTap: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CnpjCpfPage(cnpjCpf: company.cnpj),
          ),
        );
      },
      child: Card(
        elevation: elevation,
        color: Colors.white,
        child: ListTile(
          title: Text(
            company.fantasyName ??
                company.corporateName ??
                "NOME NÃO REGISTRADO",
            style: const TextStyle(
                fontSize: 15, color: colorPrimaty, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              company.cnpj != null
                  ? Text(
                      "CNPJ: ${company.cnpj!}",
                      style: textPlaceholder,
                    )
                  : const SizedBox(height: 2),
              company.email != null
                  ? Text(
                      "Email: ${company.email!}",
                      style: textPlaceholder,
                    )
                  : const SizedBox(height: 0),
              company.activityStartDate != null
                  ? Text(
                      "Data de Ativação: ${DateFormat("dd/MM/yyyy").format(company.activityStartDate!)}",
                      style: textPlaceholder,
                    )
                  : const SizedBox(height: 0),
              company.address != null
                  ? Text(
                      "Endereço: ${company.address!.place ?? ''}, ${company.address!.neighborhood}, ${company.address!.state}, ${formatZipCode(company.address!.zipCode ?? '')}",
                      style: textPlaceholder,
                    )
                  : const SizedBox(height: 0),
              company.debtsCount != null
                  ? Text(
                      "Quantidade dívidas: ${company.debtsCount!}",
                      style: textPlaceholder,
                    )
                  : const SizedBox(height: 0),
              company.debtsValue != null
                  ? Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Valor da Dívida:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: NumberFormat.simpleCurrency(locale: 'pt_BR')
                                .format(company.debtsValue ?? 0.0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )
                  : const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

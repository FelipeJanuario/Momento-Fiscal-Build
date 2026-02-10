import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/institution.dart';
import 'package:momentofiscal/core/services/institution/institution_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/institution/new_institution_page.dart';

class InstitutionCard extends StatelessWidget {
  final Institution institution;
  final Function(String) onDismissed;

  const InstitutionCard(
      {super.key, required this.institution, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Dismissible(
      key: Key(institution.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Theme.of(context).colorScheme.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
        child: const Icon(
          Icons.edit,
          color: Colors.white,
          size: 40,
        ),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 40,
        ),
      ),
      confirmDismiss: (direction) {
        if (direction == DismissDirection.endToStart) {
          return showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
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
              content: const SizedBox(
                height: 60,
                child: Column(
                  children: [
                    Text(
                      "Tem certeza?",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text("Quer remover a empresa?"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(false);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorPrimaty,
                  ),
                  child: const Text(
                    "Não",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorTertiary,
                  ),
                  child: const Text(
                    "Sim",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else {
          return showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
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
              content: const SizedBox(
                height: 60,
                child: Column(
                  children: [
                    Text(
                      "Editar Instituição",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text("Deseja editar a instituição?"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(false);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorPrimaty,
                  ),
                  child: const Text(
                    "Não",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            NewInstitutionPage(institution: institution),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorTertiary,
                  ),
                  child: const Text(
                    "Sim",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          InstitutionRailsService().deleteInstitution(institution.id);
          onDismissed(institution.id);
        }
      },
      child: Card(
        elevation: 1,
        child: ListTile(
          leading: SizedBox(
            width: 50,
            height: 50,
            child: Image.asset('assets/images/momento_fiscal_logo.png'),
          ),
          title: Text(formatNumberInCnpj(institution.cnpj)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Responsável: ${institution.responsibleName}'),
              Text(
                  'Limite da dívida: ${formatCurrency.format(institution.limitDebt)}')
            ],
          ),
        ),
      ),
    );
  }
}

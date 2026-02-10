import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/consulting.dart';

class ConsultingCard extends StatelessWidget {
  final Consulting consultingManagement;
  final Widget? trailing;

  const ConsultingCard(
      {super.key, required this.consultingManagement, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "consulting_management_${consultingManagement.id}",
      child: Card.outlined(
        child: ListTile(
          leading: Image.asset('assets/images/momento_fiscal_logo.png',
              fit: BoxFit.cover),
          trailing: trailing,
          title: Text('Código da Consultória: ${consultingManagement.id}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                  'Cliente: ${consultingManagement.clientName ?? "Aguardando Usuário"}'),
              Text(
                  'Consultor: ${consultingManagement.consultantName ?? "Não Foi Atribuído"}'),
              Row(
                children: [
                  const Text('Status: '),
                  Text(
                    consultingManagement.status == "not_started"
                        ? "Não iniciada"
                        : consultingManagement.status == "waiting"
                            ? "Aguardando Proposta"
                            : consultingManagement.status == "approved"
                                ? "Aprovada"
                                : consultingManagement.status == "in_progress"
                                    ? "Em progresso"
                                    : consultingManagement.status == "finished"
                                        ? "Finalizadas"
                                        : consultingManagement.status ==
                                                "waiting_for_user_creation"
                                            ? "Aguardando Cliente Vincular"
                                            : "Reprovadas",
                    style: TextStyle(
                      color: consultingManagement.status == "not_started"
                          ? Colors.red
                          : consultingManagement.status == "waiting"
                              ? const Color.fromARGB(255, 243, 224, 48)
                              : consultingManagement.status == "approved"
                                  ? Colors.green
                                  : consultingManagement.status == "in_progress"
                                      ? Colors.blue
                                      : consultingManagement.status ==
                                              "finished"
                                          ? const Color.fromARGB(
                                              255, 12, 75, 14)
                                          : consultingManagement.status ==
                                                  "waiting_for_user_creation"
                                              ? const Color.fromARGB(
                                                  255, 243, 224, 48)
                                              : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              Text(
                  'Valor: R\$${NumberFormat.decimalPattern('pt_BR').format(consultingManagement.limitDebt)}'),
              Text(
                  'Data de criação: ${consultingManagement.createdAt != null ? DateFormat("dd/MM/yyyy").format(consultingManagement.createdAt!) : "N/A"}'),
            ],
          ),
        ),
      ),
    );
  }
}

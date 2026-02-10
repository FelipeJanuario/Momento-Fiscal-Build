import 'package:flutter/material.dart';
import 'package:momentofiscal/components/consulting_card.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/consulting/management/assign_consulting_page.dart';
import 'package:momentofiscal/pages/consulting/management/consulting_management_page.dart';
import 'package:momentofiscal/pages/consulting/management/create_proposal_page.dart';
import 'package:momentofiscal/pages/consulting/management/track_progress_page.dart';

class ConsultingManagementCard extends StatelessWidget {
  final Consulting consultingManagement;
  final String userRole;
  final VoidCallback onFavoriteToggle;

  const ConsultingManagementCard({
    super.key,
    required this.consultingManagement,
    required this.userRole,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ConsultingCard(
          consultingManagement: consultingManagement,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: Icon(
              consultingManagement.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: consultingManagement.isFavorite
                  ? const Color.fromARGB(255, 78, 75, 75)
                  : null,
            ),
            onPressed: onFavoriteToggle, // Chama a função de toggle
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'Atribuir Consultoria':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AssignConsultingPage(
                          consulting: consultingManagement),
                    ),
                  );
                  break;
                case 'Remover Consultoria':
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Remover a consultoria?"),
                        content: Text(
                            "Deseja remover a consultoria ${consultingManagement.id} de sua responsabilidade?"),
                        actions: [
                          TextButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              backgroundColor: colorPrimaty,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Não",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              backgroundColor: colorTertiary,
                            ),
                            onPressed: () async {
                              await ConsultingRailsService().patchConsulting(
                                  consultingId: consultingManagement.id!,
                                  updatedFields: {
                                    "consultant_id": '',
                                    "status": "not_started"
                                  });

                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ConsultingManagementPage(
                                    isConsultant: true,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Sim",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  break;
                case 'Excluir Consultoria':
                  showDialog(
                    context: context,
                    builder: (context) {
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
                        content: SizedBox(
                          height: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Excluir a consultoria?",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Deseja excluir a consultoria ${consultingManagement.id} do cliente ${consultingManagement.clientName ?? "Não atribuído"}? Ao realizar esta ação a consultoria será excluída definitivamente",
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              backgroundColor: colorPrimaty,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              backgroundColor: colorTertiary,
                            ),
                            onPressed: () async {
                              await ConsultingRailsService().delete(
                                id: consultingManagement.id.toString(),
                              );

                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ConsultingManagementPage(
                                    isConsultant: false,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Confirmar",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  break;
                case 'Acompanhar Andamento':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TrackProgressPage(
                          consultingManagement: consultingManagement),
                    ),
                  );
                  break;
                case 'Editar Proposta':
                  if (userRole != 'admin' &&
                      consultingManagement.status != 'waiting') {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          title: Text("Edição não permitida"),
                          content: Text(
                            "Consultores podem editar somente propostas que possuam solicitação de revisão.",
                          ),
                        );
                      },
                    );
                  } else if (consultingManagement.consultantId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateProposalPage(
                            consulting: consultingManagement),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
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
                          content: const SizedBox(
                            height: 100,
                            child: Column(
                              children: [
                                Text(
                                  "Atribuir uma consultoria",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    "Para poder editar uma consultoria é necessário atribuir a um consultor"),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 3,
                                backgroundColor: colorTertiary,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AssignConsultingPage(
                                        consulting: consultingManagement),
                                  ),
                                );
                              },
                              child: const Text(
                                "Atribuir",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              // Lista de opções para o menu
              List<String> choices = [
                'Acompanhar Andamento',
              ];

              if (consultingManagement.status != "waiting_for_user_creation") {
                choices.add('Editar Proposta');
              }

              if (userRole == 'admin') {
                choices.insert(0, 'Atribuir Consultoria');
                choices.insert(1, "Excluir Consultoria");
              }

              if (userRole == "consultant") {
                if (consultingManagement.status !=
                    "waiting_for_user_creation") {
                  choices.insert(0, 'Remover Consultoria');
                }
              }

              return choices.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: TextStyle(
                      color: choice == 'Excluir Consultoria' ||
                              choice == "Remover Consultoria"
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                );
              }).toList();
            },
            icon: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }
}

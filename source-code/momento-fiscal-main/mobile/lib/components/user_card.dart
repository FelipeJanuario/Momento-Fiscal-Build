import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/user.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/services/invation/invitation_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/consulting/clients/consulting_page.dart';
import 'package:momentofiscal/pages/consulting/clients/edit_clients_page.dart';

class UserCard extends StatefulWidget {
  final User user;
  final String? typeRole;
  const UserCard({super.key, required this.user, this.typeRole});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool hasInvitation = false;
  late Map<String, dynamic> invitationResponse;

  @override
  void initState() {
    super.initState();
    _checkUserInvitation();
  }

  Future<void> _checkUserInvitation() async {
    try {
      final response =
          await InvitationRailsService().checkInvitation(widget.user.email);
      if (response.statusCode == 200) {
        setState(() {
          invitationResponse = json.decode(response.body);
          hasInvitation = true;
        });
      }
    } catch (e) {
      // Tratar erro caso necessário
      Exception("Error check invitation $e");
    }
  }

  void showAlertUser(
      {required String typeUser,
      required String typeUserText,
      required String role}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Deseja torná-lo um $typeUser?"),
          content: Text(
              "Ao confirmar, o $typeUserText ${widget.user.name} terá acesso de $typeUser ao aplicativo."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  elevation: 5,
                  backgroundColor: colorPrimaty,
                  padding: const EdgeInsets.symmetric(horizontal: 30)),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                await AuthRailsService().patchUser(
                  widget.user.id,
                  widget.user.name,
                  widget.user.cpf,
                  widget.user.email,
                  widget.user.phone,
                  widget.user.birthDate,
                  role,
                  widget.user.sex,
                );

                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => ConsultingPage(
                            typePageRole: widget.typeRole == "consultant"
                                ? "consultant"
                                : "client",
                          )),
                );
              },
              style: ElevatedButton.styleFrom(
                  elevation: 5,
                  backgroundColor: colorTertiary,
                  padding: const EdgeInsets.symmetric(horizontal: 30)),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void onSelected(BuildContext context, int item) {
    switch (item) {
      case 0:
        showDialog(
          context: context,
          builder: (context) {
            String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(
              DateTime.parse(invitationResponse['created_at']),
            );
            String formatteAccepted = DateFormat('dd/MM/yyyy HH:mm').format(
              DateTime.parse(widget.user.createdAt ?? ''),
            );
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: const Center(child: Text("Dados do convite")),
                content: SizedBox(
                  height: 170,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "O convite foi enviado por ${invitationResponse['send_invitation']}"),
                      Text("No dia $formattedDate"),
                      Text("Foi aceito no dia $formatteAccepted")
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
                      "Voltar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            });
          },
        );
        break;
      case 1:
        showAlertUser(
          typeUser: "administrador",
          typeUserText: "consultor",
          role: "admin",
        );
        break;
      case 2:
        showAlertUser(
          typeUser: "consultor",
          typeUserText:
              widget.typeRole == "consultant" ? "administrador" : "cliente",
          role: "consultant",
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.user.id),
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
                height: 50,
                child: Column(
                  children: [
                    Text(
                      "Tem certeza?",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text("Quer excluir o usuário?"),
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
                  child:
                      const Text("Não", style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorTertiary,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                  },
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
                    Text("Editar Usuário",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Deseja editar o usuário?"),
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
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorTertiary,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EditClientsPage(user: widget.user),
                      ),
                    );
                  },
                  child:
                      const Text("Sim", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          AuthRailsService().deleteUser(widget.user.id).then((_) {
            if (widget.typeRole == 'consultant') {
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              // ignore: use_build_context_synchronously
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConsultingPage(
                    typePageRole: 'consultant',
                  ),
                ),
              );
            } else if (widget.typeRole == 'client') {
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              // ignore: use_build_context_synchronously
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConsultingPage(
                    typePageRole: 'client',
                  ),
                ),
              );
            }
          });
        }
      },
      child: Card(
        elevation: 1,
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          title: Text('Nome: ${widget.user.name}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (widget.user.role == 'client')
                Text('CPF: ${formatCpf(widget.user.cpf)}'),
              Text('E-mail: ${widget.user.email}'),
              if (widget.user.role == 'client')
                Text('Telefone: ${widget.user.phone}'),
              Text(
                'Função: ${widget.user.role == 'consultant' ? "Consultor" : widget.user.role == "admin" ? "Administrador" : "Cliente"}',
              ),
              Text(
                'Última Atividade: ${DateFormat("dd/MM/yyyy").format(DateTime.parse(widget.user.updateAt!))}',
              ),
            ],
          ),
          trailing: PopupMenuButton<int>(
            onSelected: (item) => onSelected(context, item),
            itemBuilder: (context) => [
              if (hasInvitation)
                const PopupMenuItem<int>(
                  value: 0,
                  child: ListTile(
                    leading: Icon(Icons.remove_red_eye),
                    title: Text('Quem convidou'),
                  ),
                ),
              if (widget.user.role == "consultant")
                const PopupMenuItem<int>(
                  value: 1,
                  child: ListTile(
                    leading: Icon(Icons.manage_accounts_sharp),
                    title: Text('Tornar Administrador'),
                  ),
                ),
              if (widget.user.role == "admin" || widget.user.role == "client")
                const PopupMenuItem<int>(
                  value: 2,
                  child: ListTile(
                    leading: Icon(Icons.account_circle_sharp),
                    title: Text('Tornar Consultor'),
                  ),
                ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ),
      ),
    );
  }
}

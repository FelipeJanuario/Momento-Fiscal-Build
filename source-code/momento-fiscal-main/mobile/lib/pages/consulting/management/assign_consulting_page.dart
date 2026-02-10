import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/models/user.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/consulting/management/consulting_management_page.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';

class AssignConsultingPage extends StatefulWidget {
  const AssignConsultingPage({super.key, required this.consulting});

  final Consulting consulting;

  @override
  State<AssignConsultingPage> createState() => _AssignConsultingPageState();
}

class _AssignConsultingPageState extends State<AssignConsultingPage> {
  final _formKey = GlobalKey<FormState>();
  Consulting get consulting => widget.consulting;
  List<User> users = [];
  int currentPage = 1;
  bool isLoading = false;
  String? userRole;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    userRole = await storage.read(key: 'role');

    setState(() {
      isLoading = true;
    });
    try {
      var newUsers = await AuthRailsService().getAllUsers(
          page: currentPage, queryParameters: {"query[role]": "consultant"});
      setState(() {
        if (currentPage == 1) {
          users = newUsers;
        } else {
          users.addAll(newUsers);
        }
        currentPage++;
      });
    } catch (error) {
      throw Exception('Failed to load users');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<DropdownMenuItem<String>> getDropdownItems() {
    return users.map((user) {
      return DropdownMenuItem<String>(
        value: user.id,
        child: Text(user.name),
      );
    }).toList();
  }

  _clickButton(BuildContext context) async {
    bool formValidate = _formKey.currentState!.validate();
    if (!formValidate) return;

    try {
      var updateConsulting = await ConsultingRailsService().patchConsulting(
          consultingId: widget.consulting.id!,
          updatedFields: {
            "consultant_id": consulting.consultantId,
            "status": "in_progress"
          });

      if (updateConsulting.statusCode == 200) {
        return showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Consultoria Atribuida"),
              content: Text(
                  "A consultora de número ${consulting.id} foi atribuída ao consultor"),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ConsultingManagementPage(
                            isConsultant:
                                userRole == "consultant" ? true : false),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorTertiary,
                  ),
                  child: const Text(
                    "Confirmar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      Exception("Error in update consultig consultant_id $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atribuir Consultorias'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Center(
              child: SizedBox(
                height: 100,
                child: Image.asset('assets/images/momentofiscalcolorido.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 70),
            const Text(
              'Membros Ativos',
              style: labelStyle,
            ),
            const SizedBox(height: 10),
            if (!isLoading)
              Form(
                key: _formKey,
                child: DropdownButtonFormField<String>(
                  value: users.any((user) => user.id == consulting.consultantId)
                      ? consulting.consultantId
                      : null,
                  items: getDropdownItems(),
                  onChanged: (String? newValue) {
                    setState(() {
                      consulting.consultantId = newValue;
                    });
                  },
                  hint: const Text('Selecione um usuário'),
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => validatorDropdown(value),
                ),
              ),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  _clickButton(context);
                },
              ),
            ])
          ],
        ),
      ),
    );
  }
}

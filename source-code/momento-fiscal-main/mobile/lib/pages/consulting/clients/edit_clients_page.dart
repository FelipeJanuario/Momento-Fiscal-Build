import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/user.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/text_fields.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';

class EditClientsPage extends StatefulWidget {
  final User? user;
  const EditClientsPage({super.key, required this.user});

  @override
  State<EditClientsPage> createState() => _EditClientsPageState();
}

class _EditClientsPageState extends State<EditClientsPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController typeUserController = TextEditingController();
  DateTime? isBirthDate;
  String? sex;

  MaskedInputFormatter phoneInCellFormatter = MaskedInputFormatter(
    '(##) ####-####',
    allowedCharMatcher: RegExp(r'^[0-9]*$'),
  );

  final Map<String, String> roleMap = {
    'client': 'Cliente',
    'consultant': 'Consultor',
    'admin': 'Administrador'
  };

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      editResquest();
    }
  }

  void editResquest() {
    nameController.text = widget.user!.name;
    cpfController.text = formatCpf(widget.user!.cpf);
    emailController.text = widget.user!.email;
    phoneController.text = widget.user!.phone;
    sex = widget.user!.sex;
    isBirthDate = DateFormat("yyyy-MM-dd").parse(widget.user!.birthDate);
    typeUserController.text = roleMap[widget.user!.role] ?? '';

    birthDateController.text = DateFormat("dd/MM/yyyy").format(isBirthDate!);
  }

  Future<void> _clickButton(BuildContext context) async {
    bool formValidate = _formKey.currentState!.validate();
    if (!formValidate) return;

    var editUser = await AuthRailsService().patchUser(
        widget.user!.id,
        nameController.text,
        removeMask(cpfController.text),
        emailController.text,
        phoneController.text,
        birthDateController.text,
        widget.user!.role,
        sex!);
    if (editUser.statusCode == 200) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Usuário atualizada com sucesso!'),
              content: const Text('Sucesso.'),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: colorTertiary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const DashboadPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text('Entendi',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      );
    } else if (editUser.statusCode == 422) {
      _showError(json.decode(editUser.body).toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  final List<DropdownMenuItem<String>> _dropdownItems = [
    const DropdownMenuItem(value: 'male', child: Text('Masculino')),
    const DropdownMenuItem(value: 'female', child: Text('Feminino')),
    const DropdownMenuItem(value: 'other', child: Text('Outro')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    textFormField(
                      controller: nameController,
                      validator: (value) => validatorName(value),
                      hint: 'Digite seu nome completo',
                      label: 'Nome',
                      icons: Icons.person,
                      size: 50.0,
                    ),
                    const SizedBox(height: 20),
                    textFormField(
                      controller: cpfController,
                      validator: (value) {
                        return null;
                      },
                      hint: 'Digite o seu CPF',
                      label: 'CPF',
                      readOnly: true,
                      icons: Icons.account_box,
                      inputFormatters: [formatterCpf],
                      size: 50.0,
                    ),
                    const SizedBox(height: 20),
                    textFormField(
                      controller: emailController,
                      validator: (value) => validatorEmail(value),
                      hint: 'Digite o seu e-mail',
                      label: 'E-mail',
                      icons: Icons.email,
                      size: 50.0,
                    ),
                    const SizedBox(height: 20),
                    textFormField(
                        controller: phoneController,
                        validator: (value) => validatorCellPhone(value),
                        hint: 'Digite o seu n° de celular',
                        label: 'Telefone/Celular',
                        icons: Icons.phone,
                        textInputType: TextInputType.number,
                        size: 50.0,
                        onChanged: (phone) {
                          setState(() {
                            if (phone.length > 13) {
                              phoneInCellFormatter = MaskedInputFormatter(
                                '(##) #####-####',
                                allowedCharMatcher: RegExp(r'^[0-9]*$'),
                              );
                            } else {
                              phoneInCellFormatter = MaskedInputFormatter(
                                '(##) ####-####',
                                allowedCharMatcher: RegExp(r'^[0-9]*$'),
                              );
                            }
                          });
                        },
                        inputFormatters: [phoneInCellFormatter]),
                    const SizedBox(height: 20),
                    textFormField(
                      controller: typeUserController,
                      validator: (value) => validatorName(value),
                      readOnly: true,
                      hint: '',
                      label: 'Tipo de usuário:',
                      size: 25.0,
                      icons: Icons.person_pin_circle_sharp,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: sex,
                      items: _dropdownItems,
                      onChanged: (value) {
                        setState(() {
                          sex = value;
                        });
                      },
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(
                        label: Text('Sexo'),
                        hintText: 'Selecione o seu sexo',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => validatorDropdown(value),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      readOnly: true,
                      controller: birthDateController,
                      onTap: () => dateBirthInput(context, (newDate) {
                        String formattedDate =
                            DateFormat("dd/MM/yyyy").format(newDate);
                        setState(() {
                          birthDateController.text = formattedDate;
                          isBirthDate = newDate;
                        });
                      }, null),
                      decoration: InputDecoration(
                        label: const Text('Data de nascimento'),
                        hintText: birthDateController.text.isEmpty
                            ? 'Selecione a data de nascimento'
                            : birthDateController.text,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => validatorBirthDate(isBirthDate),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Theme.of(context).primaryColor,
                    fixedSize: const Size.fromWidth(200)),
                child: const Text(
                  'Atualizar',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  _clickButton(context);
                }),
          ],
        ),
      ),
    );
  }
}

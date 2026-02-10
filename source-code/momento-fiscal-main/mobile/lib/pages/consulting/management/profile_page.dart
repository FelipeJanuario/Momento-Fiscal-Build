import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/user.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/text_fields.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController birthController = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController oabSubscriptionController = TextEditingController();
  TextEditingController oabStateController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController typeUserController = TextEditingController();
  DateTime? isBirthDate;
  String? sex;
  String? roleUser;
  User? user;
  String? id;
  MaskedInputFormatter phoneInCellFormatter = MaskedInputFormatter(
    '(##) ####-####',
    allowedCharMatcher: RegExp(r'^[0-9]*$'),
  );

  @override
  void initState() {
    super.initState();

    editRequest();
  }

  void editRequest() async {
    id = await storage.read(key: 'id');

    await AuthRailsService().getUser(id: id!).then((value) {
      nameController.text = value.name;
      emailController.text = value.email;
      oabSubscriptionController.text = value.oabSubscription;
      oabStateController.text = value.oabState;
      isBirthDate = DateFormat("yyyy-MM-dd").parse(value.birthDate);
      birthController.text = DateFormat("dd/MM/yyyy").format(isBirthDate!);
      cpfController.text = formatCpf(value.cpf);
      phoneController.text = value.phone;
      typeUserController.text = roleMap[value.role] ?? '';
      setState(() {
        roleUser = value.role;
        sex = value.sex;
      });
    });
  }

  _clickButton(BuildContext context) async {
    bool formValidate = _formKey.currentState!.validate();
    if (!formValidate) return;

    if (id == null) {
      _showError('Erro: ID do usuário não encontrado. Faça login novamente.');
      return;
    }

    var editUser = await AuthRailsService().patchUser(
        id!,
        nameController.text,
        removeMask(cpfController.text),
        emailController.text,
        phoneController.text,
        birthController.text,
        roleUser!,
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

  final Map<String, String> roleMap = {
    'client': 'Cliente',
    'consultant': 'Consultor',
    'admin': 'Administrador'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: colorPrimaty,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color.fromRGBO(0, 163, 166, 1),
      body: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: Image.asset('assets/images/momentofiscalbranco.png',
                fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    textFormField(
                      controller: nameController,
                      validator: (value) => validatorName(value),
                      hint: '',
                      label: 'Nome Completo:',
                      icons: Icons.person,
                      size: 50.0,
                      labelColor: const Color.fromARGB(255, 244, 244, 244),
                    ),
                    const SizedBox(height: 10),
                    textFormField(
                        controller: emailController,
                        validator: (value) => validatorEmail(value),
                        hint: '',
                        label: 'Endereço de E-mail:',
                        size: 50.0,
                        labelColor: const Color.fromARGB(255, 244, 244, 244),
                        icons: Icons.email),
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data de Nascimento:',
                          textAlign: TextAlign.start,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      readOnly: true,
                      controller: birthController,
                      onTap: () => dateBirthInput(context, (newDate) {
                        String formattedDate =
                            DateFormat("dd/MM/yyyy").format(newDate);
                        setState(() {
                          birthController.text = formattedDate;
                          isBirthDate = newDate;
                        });
                      }, isBirthDate),
                      decoration: InputDecoration(
                        hintText: birthController.text.isEmpty
                            ? 'Selecione a data de nascimento'
                            : birthController.text,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => validatorBirthDate(isBirthDate),
                    ),
                    const SizedBox(height: 10),
                    textFormField(
                      controller: cpfController,
                      validator: (value) => validatorName(value),
                      hint: '',
                      label: 'CPF:',
                      size: 25.0,
                      readOnly: true,
                      icons: Icons.edit_document,
                      labelColor: const Color.fromARGB(255, 244, 244, 244),
                    ),
                    const SizedBox(height: 10),
                    if (oabSubscriptionController.text.isNotEmpty)
                      textFormField(
                          controller: oabSubscriptionController,
                          hint: '',
                          label: 'Número da OAB:',
                          readOnly: true,
                          size: 50.0,
                          labelColor: const Color.fromARGB(255, 244, 244, 244),
                          icons: Icons.auto_stories_rounded),
                    const SizedBox(height: 10),
                    if (oabStateController.text.isNotEmpty)
                      textFormField(
                          controller: oabStateController,
                          hint: '',
                          label: 'Estado da OAB:',
                          readOnly: true,
                          size: 50.0,
                          labelColor: const Color.fromARGB(255, 244, 244, 244),
                          icons: Icons.auto_stories_rounded),
                    const SizedBox(height: 10),
                    textFormField(
                        controller: phoneController,
                        validator: (value) => validatorCellPhone(value),
                        hint: 'Digite o seu n° de celular',
                        label: 'Telefone/Celular',
                        icons: Icons.phone,
                        textInputType: TextInputType.number,
                        size: 50.0,
                        labelColor: const Color.fromARGB(255, 244, 244, 244),
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
                    const SizedBox(height: 10),
                    textFormField(
                      controller: typeUserController,
                      validator: (value) => validatorName(value),
                      readOnly: true,
                      hint: '',
                      label: 'Tipo de usuário:',
                      size: 25.0,
                      icons: Icons.person_pin_circle_sharp,
                      labelColor: const Color.fromARGB(255, 244, 244, 244),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sexo:',
                          textAlign: TextAlign.start,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: sex,
                      items: _dropdownItems,
                      onChanged: (value) {
                        setState(() {
                          sex = value;
                        });
                      },
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Center(
                                      child: Text('Deseja Excluir?'),
                                    ),
                                    content: const Text(
                                        'Ao confirmar sua conta será excluída permanentemente, deseja confirmar?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 3,
                                          backgroundColor: colorPrimaty,
                                        ),
                                        child: const Text(
                                          "Cancelar",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          AuthRailsService().deleteUser(id!);

                                          Navigator.of(context).pop(true);
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                                  MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              const AuthPage()),
                                                  (Route<dynamic> route) =>
                                                      false);
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
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.delete_outlined,
                                  color: Color.fromARGB(255, 194, 43, 33),
                                  size: 28,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Excluir Conta',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )),
                        ElevatedButton(
                          onPressed: () {
                            _clickButton(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 64, 15, 154),
                            minimumSize: const Size(150, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Editar',
                              style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20)
        ],
      )),
    );
  }
}

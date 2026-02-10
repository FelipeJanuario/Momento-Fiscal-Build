import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/terms_of_use.dart';
import 'package:momentofiscal/core/models/auth_form_data.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/services/invation/invitation_rails_service.dart';
import 'package:momentofiscal/core/utilities/states_brasil.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/text_fields.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _authFormData = AuthFormData();
  final birthDateController = TextEditingController();
  bool hasCertificate = false;
  bool _termsAccepted = false;
  String? role;
  bool obscurePassword = true;
  bool obscureConfirmedPassword = true;

  MaskedInputFormatter phoneInCellFormatter = MaskedInputFormatter(
    '(##) #####-####',
    allowedCharMatcher: RegExp(r'^[0-9]*$'),
  );

  final List<DropdownMenuItem<String>> _dropdownItems = [
    const DropdownMenuItem(value: 'male', child: Text('Masculino')),
    const DropdownMenuItem(value: 'female', child: Text('Feminino')),
    const DropdownMenuItem(value: 'other', child: Text('Outro')),
  ];

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_termsAccepted) {
      if (!_termsAccepted) {
        _showError('Você deve aceitar os termos de uso.');
      }
      return;
    }

    try {
      final checkInvitationResponse = await InvitationRailsService()
          .checkInvitation(_authFormData.email.text);

      if (checkInvitationResponse.statusCode == 200) {
        setState(() {
          role = "consultant";
        });
      } else {
        setState(() {
          role = "client";
        });
      }

      // Signup - Formatar data como YYYY-MM-DD
      String formattedBirthDate = _authFormData.birthDate != null 
          ? '${_authFormData.birthDate!.year}-${_authFormData.birthDate!.month.toString().padLeft(2, '0')}-${_authFormData.birthDate!.day.toString().padLeft(2, '0')}'
          : '';
      
      var signupTrue = await AuthRailsService().signup(
          _authFormData.name.text,
          _authFormData.email.text,
          removeMask(_authFormData.cpf.text),
          _authFormData.phone.text,
          _authFormData.sex!,
          formattedBirthDate,
          _authFormData.oabSubscription.text == ''
              ? null
              : _authFormData.oabSubscription.text,
          _authFormData.oabState,
          _authFormData.password.text,
          _authFormData.confirmedPassword.text,
          role!);

      // .then((_) async {
      if (role == "consultant") {
        await InvitationRailsService()
            .updateInvitationStatus(_authFormData.email.text, "accepted");
      }
      // });

      if (signupTrue.statusCode == 200 || signupTrue.statusCode == 201) {
        showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Cadastro realizado com sucesso!'),
                content: const Text(
                    'Seja bem-vindo ao Momento Fiscal. Para realizar o login, utilize seu CPF e senha.'),
                actions: [
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      backgroundColor: colorTertiary,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const AuthPage()));
                    },
                    child: const Text('Entendi',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            });
      } else if (signupTrue.statusCode == 422) {
        final errors = json.decode(signupTrue.body)['errors'];
        final formattedErrors = errors.entries.map((entry) {
          if (entry.key == 'oab_subscription') {
            final errorMessage = entry.value.join(', ');
            if (errorMessage == 'já está em uso para este estado') {
              return 'OAB já está em uso para este estado';
            } else {
              return 'Oab não encontrada na base da OAB';
            }
          } else {
            // Para outros erros, formate normalmente
            return '${entry.key}: ${entry.value.join(', ')}';
          }
        }).join('\n');

        _showError('Validação falhou: $formattedErrors');
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: colorPrimaty,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
              child: Image.asset(
                'assets/images/momentofiscalbranco.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              margin: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        key: const ValueKey('name'),
                        controller: _authFormData.name,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          label: Text('Nome'),
                          hintText: 'Digite o seu nome completo',
                        ),
                        validator: (value) => validatorName(value),
                      ),
                      TextFormField(
                        key: const ValueKey('email'),
                        controller: _authFormData.email,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          label: Text('E-mail'),
                          hintText: 'Digite o seu e-mail',
                        ),
                        validator: (value) => validatorEmail(value),
                      ),
                      TextFormField(
                        key: const ValueKey('cpf'),
                        controller: _authFormData.cpf,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        inputFormatters: [formatterCpf],
                        decoration: const InputDecoration(
                          label: Text('CPF'),
                          hintText: 'Digite o seu CPF',
                        ),
                        validator: (value) => validatorCpf(value),
                      ),
                      TextFormField(
                        key: const ValueKey('phone'),
                        controller: _authFormData.phone,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          label: Text('Telefone/Celular'),
                          hintText: "Digite o seu número de telefone/celular",
                        ),
                        inputFormatters: [
                          MaskedInputFormatter(
                            '(##) #####-####',
                            allowedCharMatcher: RegExp(r'^[0-9]*$'),
                          )
                        ],
                        validator: (value) => validatorCellPhone(value),
                      ),
                      DropdownButtonFormField<String>(
                        items: _dropdownItems,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (value) {
                          setState(() {
                            _authFormData.sex = value;
                          });
                        },
                        decoration: const InputDecoration(
                            label: Text('Sexo'),
                            hintText: 'Selecione o seu sexo'),
                        validator: (value) => validatorDropdown(value),
                      ),
                      TextFormField(
                        readOnly: true,
                        controller: birthDateController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onTap: () => dateBirthInput(context, (newDate) {
                          String formattedDate =
                              DateFormat("dd/MM/yyyy").format(newDate);
                          setState(() {
                            _authFormData.birthDate = newDate;
                            birthDateController.text = formattedDate;
                          });
                        }, null),
                        decoration: InputDecoration(
                            label: const Text('Data de nascimento'),
                            hintText: _authFormData.birthDate == null
                                ? 'Selecione a data de nascimento'
                                : DateFormat('dd/MM/yyyy')
                                    .format(_authFormData.birthDate!)),
                        validator: (value) =>
                            validatorBirthDate(_authFormData.birthDate),
                      ),
                      SwitchListTile(
                        title: const Text('Você possui OAB?'),
                        value: hasCertificate,
                        onChanged: (value) {
                          setState(() {
                            hasCertificate = value;
                            if (!hasCertificate) {
                              _authFormData.oabSubscription.text = '';
                            }
                          });
                        },
                      ),
                      if (hasCertificate)
                        TextFormField(
                          key: const ValueKey('oabSubscription'),
                          controller: _authFormData.oabSubscription,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (value) {
                            setState(() {
                              _authFormData.oabSubscription.text = value;
                            });
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          inputFormatters: [
                            MaskedInputFormatter(
                              '##########',
                              allowedCharMatcher: RegExp(r'^[0-9]*$'),
                            )
                          ],
                          decoration: const InputDecoration(
                            labelText: 'OAB nº',
                            hintText: 'Digite o número da sua OAB',
                          ),
                          validator: (value) => validatorLenghtOab(value),
                        ),
                      if (hasCertificate)
                        DropdownButtonFormField<String>(
                          items: dropdownItemsStatesBrasil,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (selectedStates) {
                            setState(() {
                              _authFormData.oabState = selectedStates;
                            });
                          },
                          decoration: const InputDecoration(
                            label: Text('Estado da OAB'),
                            hintText: 'Selecione o estado da OAB',
                          ),
                          validator: (value) => validatorDropdown(value),
                          menuMaxHeight: 250,
                        ),
                      TextFormField(
                        key: const ValueKey('password'),
                        controller: _authFormData.password,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          label: const Text('Senha'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) =>
                            validatorPassword(value, loginValid: true),
                      ),
                      TextFormField(
                        key: const ValueKey('confirmedPassword'),
                        controller: _authFormData.confirmedPassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        obscureText: obscureConfirmedPassword,
                        decoration: InputDecoration(
                          label: const Text('Confirmação de senha'),
                          hintText: 'Confirme a senha que foi digitada',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmedPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConfirmedPassword =
                                    !obscureConfirmedPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => validatorConfimedPassword(
                            value, _authFormData.password.text),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          termsOfUse(
                            context: context,
                            onPressedIsTerm: () {
                              setState(() {
                                _termsAccepted = true;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined),
                            SizedBox(width: 5),
                            Text(
                              'Termo de Uso',
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (newValue) {
                                setState(() {
                                  _termsAccepted = newValue ?? false;
                                });
                              },
                            ),
                            const Text(
                              'Eu li e concordo com os termos de uso',
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: colorTertiary,
                          padding: const EdgeInsets.symmetric(horizontal: 45),
                        ),
                        child: const Text(
                          'Cadastrar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AuthPage(),
                            ),
                          );
                        },
                        child: const Text('Já possui conta?'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

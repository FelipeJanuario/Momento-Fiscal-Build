import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:momentofiscal/components/terms_of_use.dart';
import 'package:momentofiscal/core/services/institution/institution_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';

class CreateInstitutionPage extends StatefulWidget {
  const CreateInstitutionPage({super.key});

  @override
  State<CreateInstitutionPage> createState() => _CreateInstitutionPageState();
}

class _CreateInstitutionPageState extends State<CreateInstitutionPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController responsibleNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController cnpjController = TextEditingController();
  TextEditingController responsibleCpfController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController cellPhoneController = TextEditingController();
  TextEditingController limitDebtController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmedPasswordController = TextEditingController();
  bool _termsAccepted = false;
  bool obscurePassword = true;
  bool obscureConfirmedPassword = true;

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
      var createInstitution = await InstitutionRailsService().createInstitution(
        responsibleName: responsibleNameController.text,
        email: emailController.text,
        cnpj: removeMask(cnpjController.text),
        responsibleCpf: removeMask(responsibleCpfController.text),
        phone: phoneController.text,
        cellPhone: cellPhoneController.text,
        limitDebt: double.parse(
            formatNumber(limitDebtController.text).replaceAll(',', '.')),
        userPassword: passwordController.text,
        userPasswordConfirmation: confirmedPasswordController.text,
      );

      if (createInstitution.statusCode == 201) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Empresa cadastrada com sucesso!'),
                content: const Text(
                    'A nova empresa foi cadastrada com sucesso. Faça login que CPF do Majoritário.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const AuthPage()));
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 2,
                        backgroundColor: colorTertiary,
                        padding: const EdgeInsets.symmetric(horizontal: 20)),
                    child: const Text(
                      'Entendi',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else if (createInstitution.statusCode == 422) {
        final errors = jsonDecode(createInstitution.body);
        final errorMessages = errors.entries
            .map((entry) => "${entry.value.join(', ')}")
            .join('\n');
        _showError(errorMessages);
      } else {
        _showError(createInstitution.body.toString());
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorTertiary,
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
                        controller: responsibleNameController,
                        decoration: const InputDecoration(
                          label: Text('Responsável pela Plataforma'),
                          hintText: 'Digite o seu nome completo',
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) => validatorName(value),
                      ),
                      TextFormField(
                        key: const ValueKey('cnpj'),
                        controller: cnpjController,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        inputFormatters: [formatterCnpj],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          label: Text('CNPJ da empresa'),
                          hintText: 'Digite o seu CNPJ',
                        ),
                        validator: (value) => validatorCnpj(value),
                      ),
                      TextFormField(
                        key: const ValueKey('cpf'),
                        controller: responsibleCpfController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        inputFormatters: [formatterCpf],
                        decoration: const InputDecoration(
                          label: Text('CPF do sócio Majoritário'),
                          hintText: 'Digite o seu CPF',
                        ),
                        validator: (value) => validatorCpf(value),
                      ),
                      TextFormField(
                        key: const ValueKey('email'),
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          label: Text('E-mail Para Contato'),
                          hintText: 'Digite o seu e-mail',
                        ),
                        validator: (value) => validatorEmail(value),
                      ),
                      TextFormField(
                        key: const ValueKey('phone'),
                        controller: phoneController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        decoration: const InputDecoration(
                          label: Text('Telefone'),
                          hintText: 'Digite o seu telefone',
                        ),
                        validator: (value) => validatorPhone(value),
                        inputFormatters: [formatterPhone],
                      ),
                      TextFormField(
                        key: const ValueKey('cell'),
                        controller: cellPhoneController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        decoration: const InputDecoration(
                          label: Text('Celular'),
                          hintText: 'Digite o seu celular',
                        ),
                        validator: (value) => validatorCellPhone(value),
                        inputFormatters: [formatterCellPhone],
                      ),
                      TextFormField(
                        key: const ValueKey('limitDbt'),
                        controller: limitDebtController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          label: Text('Limite da Dívida'),
                          hintText: 'Exemplo: R\$ 1000,00',
                        ),
                        validator: (value) => validatorMoney(value),
                        inputFormatters: [
                          CurrencyInputFormatter(
                            thousandSeparator: ThousandSeparator.Period,
                            mantissaLength: 2,
                          )
                        ],
                      ),
                      TextFormField(
                        key: const ValueKey('password'),
                        controller: passwordController,
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
                        controller: confirmedPasswordController,
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
                            value, passwordController.text),
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
                      const SizedBox(height: 15),
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

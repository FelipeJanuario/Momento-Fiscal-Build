import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/login/reset_password/confirm_code_page.dart';

class ResetPasswordCard extends StatefulWidget {
  const ResetPasswordCard({super.key});

  @override
  State<ResetPasswordCard> createState() => _ResetPasswordCardState();
}

class _ResetPasswordCardState extends State<ResetPasswordCard> {
  final _form = GlobalKey<FormState>();
  TextEditingController textCpf = TextEditingController();

  bool foundCpf = false;
  String? _errorMessage;

  MaskedInputFormatter _cpfCnpjFormatter = MaskedInputFormatter(
    '###.###.###-##',
    allowedCharMatcher: RegExp(r'^[0-9]*$'),
  );

  void _showError(String msg) {
    setState(() {
      _errorMessage = msg;
      foundCpf = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Center(
                    child: Text('Problemas para entrar?'),
                  ),
                  content: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Text(
                          'Insira seu CPF e enviaremos um link ao seu e-mail para você voltar a acessar a sua conta.',
                        ),
                        Form(
                          key: _form,
                          child: Column(
                            children: [
                              TextFormField(
                                key: const ValueKey('cpfCnpj'),
                                controller: textCpf,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (cpfCnpj) {
                                  setState(() {
                                    textCpf.text = cpfCnpj;
                                    if (cpfCnpj.length > 13) {
                                      _cpfCnpjFormatter = MaskedInputFormatter(
                                        '##.###.###/####-##',
                                        allowedCharMatcher: RegExp(r'^[0-9]*$'),
                                      );
                                    } else {
                                      _cpfCnpjFormatter = MaskedInputFormatter(
                                        '###.###.###-##',
                                        allowedCharMatcher: RegExp(r'^[0-9]*$'),
                                      );
                                    }
                                  });
                                },
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        signed: true, decimal: true),
                                decoration: const InputDecoration(
                                    label: Text('CPF/CNPJ'),
                                    hintText: 'Digite seu CPF/CNPJ'),
                                inputFormatters: [_cpfCnpjFormatter],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira seu CPF ou CNPJ';
                                  } else if (value.length == 14) {
                                    return validatorCpf(value);
                                  } else if (value.length == 18) {
                                    return validatorCnpj(value);
                                  } else {
                                    return 'CPF/CNPJ inválido';
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            textCpf.text = "";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                            elevation: 5,
                            backgroundColor: colorPrimaty,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30)),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white),
                        )),
                    TextButton(
                      onPressed: () async {
                        var forgotPassword = await AuthRailsService()
                            .forgotPassword(textCpf.text);

                        if (forgotPassword.statusCode == 200) {
                          setState(() {
                            foundCpf = true;
                            _errorMessage = null;
                          });

                          var responseBody = json.decode(forgotPassword.body);

                          // ignore: use_build_context_synchronously
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ConfirmCodePage(
                                email: responseBody['email'],
                                verifyCode: responseBody['code'],
                              ),
                            ),
                          );
                        } else if (forgotPassword.statusCode == 404) {
                          setState(() {
                            _showError(
                              'Usuário/Empresa não encontrado',
                            );
                          });
                        } else {
                          setState(() {
                            foundCpf = false;
                            _errorMessage = "";
                          });
                        }

                        _form.currentState!.validate();
                      },
                      style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: colorTertiary,
                          padding: const EdgeInsets.symmetric(horizontal: 45)),
                      child: const Text(
                        'Enviar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: const Text('Esqueceu a senha?'),
    );
  }
}

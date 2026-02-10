import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String code;
  const ResetPasswordPage({super.key, required this.code});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  _clickButton(BuildContext context) async {
    bool formValidate = _formKey.currentState!.validate();

    if (!formValidate) {
      return;
    }
    try {
      var updatePassword = await AuthRailsService().updatePassword(
        code: widget.code,
        newPassword: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      if (updatePassword.statusCode == 200) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Senha trocada com sucesso!"),
            content: const Text(
                "Sua nova senha foi alterada, faça login novamente no sistema"),
            actions: [
              TextButton(
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: colorTertiary,
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const AuthPage(),
                    ),
                  );
                },
                child: const Text(
                  "Fazer Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      } else if (updatePassword.statusCode == 422) {
        setState(() {
          _errorMessage = json.decode(updatePassword.body)['error'].toString();
        });
      }
    } catch (e) {
      Exception('Erro ao atualizar a senha: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trocar Senha',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Por favor, preencha os campos abaixo com a nova senha e a confirmação da senha.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Digite a nova senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a nova senha';
                      }
                      return validatorPassword(value);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Senha',
                      hintText: 'Confirme sua senha',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      backgroundColor: colorSecundary,
                    ),
                    child: const Text(
                      'Trocar a Senha',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      _clickButton(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:momentofiscal/components/reset_password_card.dart';
import 'package:momentofiscal/core/models/auth_form_data.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:momentofiscal/pages/login/create_institution_page.dart';
import 'package:momentofiscal/pages/login/create_user_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authFormData = AuthFormData();
  TextEditingController textDate = TextEditingController();

  MaskedInputFormatter _cpfCnpjFormatter = MaskedInputFormatter(
    '###.###.###-##',
    allowedCharMatcher: RegExp(r'^[0-9]*$'),
  );
  MaskedInputFormatter phoneInCellFormatter = MaskedInputFormatter(
    '+## (##) ####-####',
    allowedCharMatcher: RegExp(r'^[0-9]*$'),
  );

  bool isLoading = false;
  bool loginValid = true;
  bool obscurePassword = true;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  void _submit({required BuildContext context}) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      var loginResult = await AuthRailsService()
          .login(_authFormData.cpfCnpj.text, _authFormData.password.text);
      if (loginResult.statusCode == 200) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboadPage(),
          ),
        );
      } else {
        setState(() {
          loginValid = false;
        });
      }
    } catch (error, stackTrace) {
      // Mostrar erro detalhado no console
      print('========== LOGIN ERROR ==========');
      print('Error: $error');
      print('Stack trace: $stackTrace');
      print('=================================');
      debugPrint('Login error: $error');
      _showError('Erro ao fazer login. Verifique suas credenciais e tente novamente.');
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: Image.asset(
                      "assets/images/annanerydashboard.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    margin: const EdgeInsets.all(25),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextFormField(
                                    key: const ValueKey('cpfCnpj'),
                                    controller: _authFormData.cpfCnpj,
                                    onChanged: (cpfCnpj) {
                                      setState(() {
                                        if (cpfCnpj.length > 13) {
                                          _cpfCnpjFormatter =
                                              MaskedInputFormatter(
                                            '##.###.###/####-##',
                                            allowedCharMatcher:
                                                RegExp(r'^[0-9]*$'),
                                          );
                                        } else {
                                          _cpfCnpjFormatter =
                                              MaskedInputFormatter(
                                            '###.###.###-##',
                                            allowedCharMatcher:
                                                RegExp(r'^[0-9]*$'),
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
                                  TextFormField(
                                    key: const ValueKey('password'),
                                    controller: _authFormData.password,
                                    onChanged: (password) {
                                      setState(() {
                                        loginValid = true;
                                      });
                                    },
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
                                    validator: (value) => validatorPassword(
                                        value,
                                        loginValid: loginValid),
                                  ),
                                  const SizedBox(height: 15),
                                  const ResetPasswordCard(),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      _submit(context: context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 5,
                                      backgroundColor: colorTertiary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 45),
                                    ),
                                    child: const Text(
                                      'Entrar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateUserPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                        'Criar uma nova conta usuário?'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateInstitutionPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                        'Criar uma nova conta empresa?'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              decoration:
                  const BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.5)),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

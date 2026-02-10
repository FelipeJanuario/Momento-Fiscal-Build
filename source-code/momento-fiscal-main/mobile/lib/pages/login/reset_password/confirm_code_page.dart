import 'package:flutter/material.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/login/reset_password/reset_password_page.dart';

class ConfirmCodePage extends StatefulWidget {
  final String email;
  final String verifyCode;
  const ConfirmCodePage(
      {super.key, required this.email, required this.verifyCode});

  @override
  State<ConfirmCodePage> createState() => _ConfirmCodePageState();
}

class _ConfirmCodePageState extends State<ConfirmCodePage> {
  // Controladores para cada campo
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  String _code = '';
  bool isCodeValid = false;

  @override
  void dispose() {
    // Limpa os controladores e os FocusNodes quando a página for destruída
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextField({required String value, required int index}) {
    if (value.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus(); // Fecha o teclado no último campo
      }
    }
  }

  // Função para capturar o valor digitado em todos os campos
  void _getCode() {
    setState(() {
      _code = _controllers.map((controller) => controller.text).join();
    });
    // Você pode adicionar a lógica para enviar ou verificar o código aqui.
    if (_code == widget.verifyCode) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ResetPasswordPage(code: _code)),
      );
      setState(() {
        isCodeValid = false;
      });
    } else {
      setState(() {
        isCodeValid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Código de Verificação',
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
              'Por favor, digite o código que enviamos agora para:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.email, // Substitua pelo email do usuário
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24),
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: '',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    onChanged: (value) {
                      _nextField(value: value, index: index);
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCode,
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: colorSecundary,
              ),
              child: const Text(
                'Confirmar Código',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (isCodeValid) ...[
              const SizedBox(height: 15),
              Text(
                'Código digitado inválido',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            ],
            const SizedBox(height: 20),
            const Text(
              'Não encontrou?\nConfira a aba Promoções do seu e-mail',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

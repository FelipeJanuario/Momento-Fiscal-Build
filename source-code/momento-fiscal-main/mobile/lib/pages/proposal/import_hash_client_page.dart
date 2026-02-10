import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/proposal/my_proposal_client_page.dart';

class ImportHashClientPage extends StatefulWidget {
  const ImportHashClientPage({super.key});

  @override
  State<ImportHashClientPage> createState() => _ImportHashClientPageState();
}

class _ImportHashClientPageState extends State<ImportHashClientPage> {
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

  void _getCode() async {
    setState(() {
      _code = _controllers.map((controller) => controller.text).join();
    });

    if (_code.length < 6) {
      setState(() {
        isCodeValid = true;
      });
    } else {
      try {
        var response = await ConsultingRailsService().postImportHash(_code);

        if (response.statusCode == 200) {
          var responseBody = json.decode(response.body);
          Consulting consulting = Consulting.fromJson(responseBody);
          setState(() {
            isCodeValid = false;
          });
          showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Proposta Importada"),
                content: Text(
                    "A proposta de número ${consulting.id} foi atribuída com sucesso. Para visualizar acesse em Minhas Propostas"),
                actions: [
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      backgroundColor: colorTertiary,
                    ),
                    onPressed: () async {
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MyProposalClientPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Minhas Proposta",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        } else if (response.statusCode == 404) {
          setState(() {
            isCodeValid = true;
          });
        }
      } catch (e) {
        Exception("Error method import_hash $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Desbloquear Propostas',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                child: Image.asset('assets/images/momentofiscalcolorido.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 40),
              const Text(
                'Para desbloquear a proposta, insira o código de 6 dígitos encontrado no documento do consultor no campo abaixo:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
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
                      textCapitalization: TextCapitalization.characters,
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
                'Não encontrou?\nEntre em contato com seu consultor',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

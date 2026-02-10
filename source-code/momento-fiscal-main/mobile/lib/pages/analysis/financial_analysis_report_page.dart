import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class FinancialAnalysisReportPage extends StatefulWidget {
  const FinancialAnalysisReportPage({super.key});

  @override
  State<FinancialAnalysisReportPage> createState() =>
      _FinancialAnalysisReportPageState();
}

class _FinancialAnalysisReportPageState
    extends State<FinancialAnalysisReportPage> {
  bool passiveTaxManagement = false;
  bool taxPlanning = false;
  bool bankPassiveReductionManagement = false;
  bool physicalAssetsRecovery = false;
  bool businessReconstruction = false;
  QuillController controller = QuillController.basic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Soluções'),
        backgroundColor: Theme.of(context).primaryColor.withAlpha(153),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 15),
              Center(
                child: SizedBox(
                  height: 100,
                  child: Image.asset('assets/images/momentofiscalcolorido.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Gestão e Redução Passivo Tributário'),
                value: passiveTaxManagement,
                onChanged: (value) {
                  setState(() {
                    passiveTaxManagement = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Planejamento Tributário'),
                value: taxPlanning,
                onChanged: (value) {
                  setState(() {
                    taxPlanning = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Gestão de Redução Passivo Bancário'),
                value: bankPassiveReductionManagement,
                onChanged: (value) {
                  setState(() {
                    bankPassiveReductionManagement = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Recuperção de Ativos Físcais'),
                value: physicalAssetsRecovery,
                onChanged: (value) {
                  setState(() {
                    physicalAssetsRecovery = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Reconstrução Empresarial'),
                value: businessReconstruction,
                onChanged: (value) {
                  setState(() {
                    businessReconstruction = value;
                  });
                },
              ),
              Container(
                color: Colors.grey[200],
                child: QuillSimpleToolbar(
                  controller: controller,
                  config: const QuillSimpleToolbarConfig(
                    toolbarSectionSpacing: 4,
                    showFontFamily: false,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                ),
                padding: const EdgeInsets.all(10),
                child: QuillEditor.basic(
                  controller: controller,
                  config: const QuillEditorConfig(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text(
                      'Salvar e Gerar PDF',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text(
                      'Enviar Relatório',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

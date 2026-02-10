import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/consulting.dart';

class TrackProgressPage extends StatelessWidget {
  final Consulting consultingManagement;

  const TrackProgressPage({super.key, required this.consultingManagement});

  // Função que mapeia o status para uma descrição legível e retorna o ícone e a cor
  Map<String, dynamic> getStatusDetails(String status) {
    switch (status) {
      case "not_started":
        return {
          'description': 'Não Atribuída',
          'color': Colors.grey,
          'icon': Icons.hourglass_empty_outlined
        };
      case "waiting":
        return {
          'description': 'Aguardando Proposta',
          'color': Colors.amber,
          'icon': Icons.hourglass_top_outlined
        };
      case "approved":
        return {
          'description': 'Proposta Enviada',
          'color': Colors.green,
          'icon': Icons.check_circle_outline
        };
      case "in_progress":
        return {
          'description': 'Solução em andamento',
          'color': Colors.blue,
          'icon': Icons.autorenew_outlined
        };
      case "finished":
        return {
          'description': 'Solução finalizada',
          'color': Colors.green,
          'icon': Icons.checklist_outlined
        };
      case "failed":
        return {
          'description': 'Proposta recusada',
          'color': Colors.red,
          'icon': Icons.cancel_outlined
        };
      default:
        return {
          'description': 'Status desconhecido',
          'color': Colors.grey,
          'icon': Icons.help_outline
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhar Andamento'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Consultorias',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  // Exemplo de diferentes status
                  buildConsultingItem('1', 'not_started', consultingManagement),
                  buildConsultingItem('2', 'finished', consultingManagement),
                  buildConsultingItem('3', 'waiting', consultingManagement),
                  buildConsultingItem('4', 'in_progress', consultingManagement),
                  buildConsultingItem('5', 'failed', consultingManagement),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para construir o item da consultoria
  Widget buildConsultingItem(
      String code, String status, Consulting consultingManagement) {
    final statusDetails = getStatusDetails(status);
    bool isCurrentConsulting = consultingManagement.status == status;

    return Card(
      elevation: isCurrentConsulting ? 6 : 3,
      shape: const RoundedRectangleBorder(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusDetails['color'],
          child: Icon(
            statusDetails['icon'],
            color: Colors.white,
          ),
        ),
        title: Text('Código: ${consultingManagement.id}'),
        subtitle: Text(statusDetails['description']),
        tileColor: isCurrentConsulting
            ? statusDetails['color'].withOpacity(0.2)
            : Colors.white,
        trailing: isCurrentConsulting
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }
}

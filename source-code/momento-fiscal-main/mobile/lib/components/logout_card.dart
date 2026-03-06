import 'package:flutter/material.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';

void logoutCard(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Você realmente quer sair?'),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: colorPrimaty,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: colorTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 30),
            ),
            onPressed: () async {
              await AuthRailsService().logout();

              // ignore: use_build_context_synchronously
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (Route<dynamic> route) => false);
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

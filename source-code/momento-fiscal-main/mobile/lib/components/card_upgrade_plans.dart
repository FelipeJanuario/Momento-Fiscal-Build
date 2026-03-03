import 'package:flutter/material.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/plans/verify_plans_page.dart';

void cardUpgradePlans({required BuildContext context, required String text}) {
  showDialog(
    // ignore: use_build_context_synchronously
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Column(
          children: [
            Center(
              child: SizedBox(
                height: 80,
                child: Image.asset('assets/images/momentofiscalcolorido.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            const Center(child: Text('Upgrade necessário')),
          ],
        ),
        content: Text(
          text,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: colorTertiary,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const VerifyPlansPage()),
                );
              },
              child: const Text(
                'Selecionar Plano',
                style: TextStyle(color: Colors.white),
              ))
        ],
      );
    },
  );
}

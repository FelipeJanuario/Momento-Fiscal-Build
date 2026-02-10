import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/debt.dart';

class DebtNatureListItem extends StatelessWidget {
  final Debt debt;
  final Widget? trailing;

  const DebtNatureListItem({super.key, required this.debt, this.trailing});

  double get value => double.tryParse(debt.value.toString()) ?? 0.0;

  String capitalizeFirstLetters(String input) {
    if (input.isEmpty) return input;

    input = input.toLowerCase();

    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      hoverColor: Colors.grey[200],
      onTap: () => {},
      title: Text(
        capitalizeFirstLetters(debt.registrationNumber!),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Text(
        capitalizeFirstLetters(debt.registrationStatus!),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      isThreeLine: true,
      trailing: trailing ??
          Text(
            NumberFormat.simpleCurrency(locale: 'pt_BR').format(value),
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
    );
  }
}

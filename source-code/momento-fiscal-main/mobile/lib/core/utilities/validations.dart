import 'package:intl/intl.dart';

validatorName(value) {
  final name = value ?? '';
  if (name.trim().length < 4) {
    return 'Nome deve ter no mínimo 4 caracteres';
  }
  return null;
}

validatorCpf(value) {
  if (value!.isEmpty) {
    return 'Por favor, digite seu CPF';
  }
  const pattern = r'^\d{3}\.\d{3}\.\d{3}\-\d{2}$';
  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(value)) {
    return 'Por favor, digite um CPF válido';
  }

  return null;
}

validatorEmail(value, {bool? foundEmail}) {
  if (value!.isEmpty) {
    return 'Por favor, digite um e-mail.';
  }
  const pattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(value)) {
    return 'Por favor, digite um e-mail válido.';
  }

  if (foundEmail != null && !foundEmail) {
    return "E-mail não encontrado";
  }

  return null;
}

validatorPassword(value, {bool? loginValid}) {
  final password = value ?? '';

  if (value!.isEmpty) {
    return 'Por favor, digite uma senha.';
  }

  if (password.length < 6) {
    return 'Senha deve ter no mínimo 6 caracteres';
  }

  if (password.length > 8) {
    return 'Senha deve ter máximo 8 caracteres';
  }

  if (loginValid != null && !loginValid) {
    return 'CPF/Senha inválido';
  }
  return null;
}

validatorPhone(value) {
  if (value!.isEmpty) {
    return 'Por favor, digite seu número';
  }
  const pattern = r'^\(\d{2}\) \d{4}\-\d{4}$';

  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(value)) {
    return 'Por favor, digite um número de telefone válido';
  }
}

String? validatorCellPhone(String? value) {
  if (value!.isEmpty) {
    return 'Por favor, digite seu número';
  }

  const pattern = r'^\(\d{2}\) \d{4,5}\-\d{4}$';

  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(value)) {
    return 'Por favor, digite um número de telefone válido';
  }

  return null;
}

validatorDropdown(value) {
  if (value == null) {
    return 'Selecione uma das opções';
  }
  return null;
}

String? validatorBirthDate(DateTime? value) {
  if (value == null) {
    return 'Selecione a data de nascimento';
  }

  if (value.isAfter(DateTime.now())) {
    return 'A data de nascimento não pode ser no futuro';
  }

  int age = DateTime.now().year - value.year;

  if (DateTime.now().month < value.month ||
      (DateTime.now().month == value.month && DateTime.now().day < value.day)) {
    age--;
  }

  if (age < 18) {
    return 'A idade mínima é de 18 anos';
  }

  return null;
}

validatorLenghtOab(value) {
  if (value!.isEmpty) {
    return "Por favor, digite a sequência da sua OAB";
  }

  // if (value.length < 5) {
  //   return "OAB deve ter no mínimo 5 caracteres";
  // }

  return null;
}

validatorConfimedPassword(value, password) {
  if (value!.isEmpty) {
    return "Por favor, digite a confirmação de senha";
  }

  if (value != password) {
    return 'As senhas não conferem';
  }
  return null;
}

validatorCnpj(value) {
  if (value!.isEmpty) {
    return 'Por favor, digite seu CNPJ';
  }

  const pattern = r'^\d{2}\.\d{3}\.\d{3}/\d{4}\-\d{2}$';
  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(value)) {
    return 'Por favor, digite um CNPJ válido';
  }

  return null;
}

validatorMoney(value) {
  if (value == null || value.isEmpty) {
    return 'Por favor, digite um valor.';
  }

  const pattern = r'^\d{1,3}(\.\d{3})*(,\d{2})?$';
  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(value)) {
    return 'Por favor, digite um valor válido.';
  }

  return null;
}

String formatNumber(String formattedNumber) {
  String sanitizedNumber =
      formattedNumber.replaceAll('.', '').replaceAll(',', '');

  if (sanitizedNumber.length > 2) {
    int length = sanitizedNumber.length;
    sanitizedNumber =
        '${sanitizedNumber.substring(0, length - 2)},${sanitizedNumber.substring(length - 2)}';
  } else {
    sanitizedNumber = '0,${sanitizedNumber.padLeft(2, '0')}';
  }

  return sanitizedNumber;
}

String formatCnpj(String cnpj) {
  return cnpj.replaceAll(RegExp(r'[^0-9]'), '');
}

String formatNumberInCnpj(String cnpj) {
  return "${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}";
}

String removeMask(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

String formatCpf(String cpf) {
  String sanitizedCpf = cpf.replaceAll(RegExp(r'\D'), '');

  if (sanitizedCpf.length != 11) {
    throw const FormatException('CPF deve conter 11 dígitos.');
  }

  return "${sanitizedCpf.substring(0, 3)}."
      "${sanitizedCpf.substring(3, 6)}."
      "${sanitizedCpf.substring(6, 9)}-"
      "${sanitizedCpf.substring(9, 11)}";
}

String cnpjMask(String cnpj) {
  if (cnpj.isEmpty) return "";

  String digitsOnly = cnpj.replaceAll(RegExp(r'\D'), '');

  String maskedCnpj =
      "${digitsOnly.substring(0, 2)}.${digitsOnly.substring(2, 5)}."
      "${digitsOnly.substring(5, 8)}/${digitsOnly.substring(8, 12)}-"
      "${digitsOnly.substring(12, 14)}";

  return maskedCnpj;
}

String formatPrice(String unitAmountDecimal) {
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final value = int.parse(unitAmountDecimal) / 100;
  return formatter.format(value);
}

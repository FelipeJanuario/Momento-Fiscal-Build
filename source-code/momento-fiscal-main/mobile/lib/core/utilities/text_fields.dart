import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';

void dateBirthInput(BuildContext context,
    void Function(DateTime) onDateTimeChanged, DateTime? initialDateTime) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          child: CupertinoDatePicker(
            initialDateTime: initialDateTime ?? DateTime(2000),
            onDateTimeChanged: onDateTimeChanged,
            use24hFormat: true,
            mode: CupertinoDatePickerMode.date,
            minimumYear: DateTime.now().year - 100,
            maximumYear: DateTime.now().year,
          ),
        );
      });
}

Widget textFormField({
  bool password = false,
  IconData? icons,
  required TextEditingController controller,
  FormFieldValidator<String>? validator,
  required String hint,
  required String label,
  required double size,
  double? width,
  Key? key,
  TextInputType? textInputType,
  bool? readOnly,
  Function(String)? onChanged,
  inputFormatters,
  Color labelColor = Colors.black,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(color: labelColor, fontSize: 14),
      ),
      const SizedBox(height: 10),
      Container(
        width: width,
        alignment: Alignment.topLeft,
        child: TextFormField(
          key: key,
          onChanged: onChanged,
          controller: controller,
          validator: validator,
          obscureText: password,
          inputFormatters: inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: textInputType,
          readOnly: readOnly ?? false,
          decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.0),
            ),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: readOnly != null && readOnly
                ? Colors.grey.withAlpha(204)
                : Colors.white,
            counterText: '',
            contentPadding: const EdgeInsets.only(top: 14.0, left: 0.0),
            hintText: hint,
            hintStyle: textStylePlaceholder,
            prefixIcon: Icon(
              icons,
              color: const Color.fromARGB(204, 73, 70, 68),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget dropdownInput({
  String? value,
  required List<DropdownMenuItem<String>>? items,
  required String hint,
  required String label,
  Function(String?)? onChanged,
  String? Function(String?)? validator,
  Key? key,
  IconData? icons,
  Color labelColor = Colors.white,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(color: labelColor, fontSize: 14),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        key: key,
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 0.0),
          ),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          contentPadding: const EdgeInsets.only(top: 14.0, left: 14.0),
          hintStyle: textStylePlaceholder,
          prefixIcon: Icon(
            icons,
            color: const Color.fromARGB(204, 73, 70, 68),
          ),
        ),
        hint: Align(
          alignment: Alignment.center,
          child: Text(hint, style: textStylePlaceholder),
        ),
      ),
    ],
  );
}

void showDialogForExistingPlan(BuildContext context, String platform) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text("Plano ativo em outra plataforma"),
        content: Text("Você já possui um plano ativo na plataforma $platform. "
            "Por favor, utilize a mesma plataforma para continuar sua assinatura."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: colorTertiary,
            ),
            child: const Text("Ok", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

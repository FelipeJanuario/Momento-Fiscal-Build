import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

const colorPrimaty = Color.fromRGBO(0, 163, 166, 1);
const colorSecundary = Color.fromRGBO(129, 51, 116, 1);
const colorTertiary = Color.fromRGBO(52, 70, 147, 1);
const colorLabel = Color(0xFF424242);
const colorPlaceholder = Color(0xFF757575);
const colorTitle = Color(0xFF212121);

var formatterCpf = MaskTextInputFormatter(
  mask: '###.###.###-##',
  filter: {"#": RegExp(r'^[0-9]*$')},
  type: MaskAutoCompletionType.lazy,
);

var formatterCellPhone = MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: {"#": RegExp(r'^[0-9]*$')},
  type: MaskAutoCompletionType.lazy,
);

var formatterPhone = MaskTextInputFormatter(
  mask: '(##) ####-####',
  filter: {"#": RegExp(r'^[0-9]*$')},
  type: MaskAutoCompletionType.lazy,
);

var formatterCnpj = MaskTextInputFormatter(
  mask: '##.###.###/####-##',
  filter: {"#": RegExp(r'^[0-9]*$')},
  type: MaskAutoCompletionType.lazy,
);

var formatterDate = MaskTextInputFormatter(
  mask: '##/##/####',
  filter: {"#": RegExp(r'^[0-9]*$')},
  type: MaskAutoCompletionType.lazy,
);

const labelStyle = TextStyle(
  color: colorLabel,
  fontSize: 16.0,
);

const textStylePlaceholder = TextStyle(
  color: colorPlaceholder,
  fontSize: 14.0,
  fontFamily: 'inter',
);

const textPlaceholder = TextStyle(
  color: colorPlaceholder,
  fontSize: 13.0,
  fontFamily: 'inter',
);

const textTitle = TextStyle(
  color: colorTitle,
  fontSize: 16.0,
  fontFamily: 'inter',
  fontWeight: FontWeight.bold,
);

const textTitleTermOfUse = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
const textTermOfUse = TextStyle(fontSize: 12);

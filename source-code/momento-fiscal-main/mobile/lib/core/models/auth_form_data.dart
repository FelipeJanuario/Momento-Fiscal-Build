import 'dart:io';

import 'package:flutter/material.dart';

enum AuthMode { signup, login }

class AuthFormData {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController cpf = TextEditingController();
  TextEditingController cpfCnpj = TextEditingController();
  TextEditingController phone = TextEditingController();
  String? sex;
  DateTime? birthDate;
  TextEditingController oabSubscription = TextEditingController();
  String? oabState;
  TextEditingController password = TextEditingController();
  TextEditingController confirmedPassword = TextEditingController();
  File? image;

//   AuthMode mode = AuthMode.login;

//   bool get isLogin {
//     return mode == AuthMode.login;
//   }

//   bool get isSignup {
//     return mode == AuthMode.signup;
//   }

//   void toggleAuthMode() {
//     mode = isLogin ? AuthMode.signup : AuthMode.login;
//   }
}

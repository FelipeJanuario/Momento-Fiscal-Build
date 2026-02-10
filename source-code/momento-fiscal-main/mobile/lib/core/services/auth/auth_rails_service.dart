import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/models/user.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AuthRailsService {
  static User? _currentUser;

  User? get currentUser {
    return _currentUser;
  }

  //signup Multipartfile para envio de imagem também na resposta
  // Future<bool> signup(String name, String email, String cpf, String phone,
  //     String sex, String password, File? image, BuildContext? context) async {
  //   var url = '${ApiConstants.baseUrl}/signup';

  //   var request = http.MultipartRequest('POST', Uri.parse(url));
  //   request.fields['user[name]'] = name;
  //   request.fields['user[email]'] = email;
  //   request.fields['user[cpf]'] = cpf;
  //   request.fields['user[phone]'] = phone;
  //   request.fields['user[sex]'] = sex;
  //   request.fields['user[password]'] = password;

  //   if (image != null) {
  //     var imageStream = http.ByteStream(Stream.castFrom(image.openRead()));
  //     var length = await image.length();

  //     var multipartFile = http.MultipartFile(
  //       'user[avatar][path]',
  //       imageStream,
  //       length,
  //       filename: image.path.split('/').last,
  //     );

  //     request.files.add(multipartFile);
  //   }

  //   var response = await request.send();

  //   if (response.statusCode == 201) {
  //     _currentUser = User(
  //       id: Random().nextInt(10),
  //       name: name,
  //       email: email,
  //       cpf: cpf,
  //       imageUrl: image?.path ?? "assets/images/avatar.png",
  //     );

  //     return true;
  //   } else {
  //     showDialog(
  //       // ignore: use_build_context_synchronously
  //       context: context!, // Você precisa obter o contexto de alguma forma
  //       builder: (context) {
  //         return AlertDialog(
  //           title: const Text('E-mail já está em uso'),
  //           content: const Text(
  //               'O e-mail informado já está sendo utilizado por outro usuário.'),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('Ok'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //     return false;
  //   }
  // }

  Future signup(
      String name,
      String email,
      String cpf,
      String phone,
      String sex,
      String birthDate,
      String? oabSubscription,
      String? oabState,
      String password,
      String confirmedPassword,
      String role) async {
    Map params = {
      "user": {
        "name": name,
        "cpf": removeMask(cpf),
        "email": email,
        "password": password,
        "password_confirmation": confirmedPassword,
        "phone": phone,
        "birth_date": birthDate,
        "sex": sex,
        "oab_subscription": oabSubscription,
        "oab_state": oabState,
        "role": role
      }
    };

    var url = '${ApiConstants.baseUrl}/authentication/users.json';
    var body = json.encode(params);

    var headers = {
      'Content-Type': 'application/json',
    };

    var response =
        await http.post(Uri.parse(url), body: body, headers: headers);

    return response;
  }

  Future<void> _saveUserToCache(User user) async {
    try {
      print('[CACHE] Iniciando salvamento no cache...');
      print('[CACHE] user.id: ${user.id}');
      print('[CACHE] Plataforma: ${kIsWeb ? "Web" : "Mobile"}');
      
      await storage.write(key: 'id', value: user.id);
      print('[CACHE] id salvo');
      await storage.write(key: 'name', value: user.name);
      await storage.write(key: 'email', value: user.email);
      await storage.write(key: 'role', value: user.role);
      await storage.write(key: 'cpf', value: user.cpf);
      await storage.write(key: 'birthDate', value: user.birthDate);
      await storage.write(key: 'oabState', value: user.oabState);
      await storage.write(key: 'oabSubscription', value: user.oabSubscription);
      await storage.write(key: 'phone', value: user.phone);
      await storage.write(key: 'sex', value: user.sex);
      await storage.write(key: 'token', value: user.token);
      await storage.write(key: 'customerId', value: user.idStripe);
      await storage.write(key: 'iosPlan', value: user.iosPlan ?? '');
      await storage.write(key: 'updateAt', value: user.updateAt ?? '');
      await storage.write(key: 'createdAt', value: user.createdAt ?? '');
      print('[CACHE] Todos os campos salvos com sucesso');
    } catch (e, stackTrace) {
      print('[CACHE] ERRO ao salvar: $e');
      print('[CACHE] StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _clearUserFromCache() async {
    await storage.deleteAll();
    print('[CACHE] Cache limpo');
  }

  Future<User?> loadUserFromCache() async {
    String? id = await storage.read(key: 'id');
    String? name = await storage.read(key: 'name');
    String? email = await storage.read(key: 'email');
    String? cpf = await storage.read(key: 'cpf');
    String? birthDate = await storage.read(key: 'birthDate');
    String? oabState = await storage.read(key: 'oabState');
    String? oabSubscription = await storage.read(key: 'oabSubscription');
    String? phone = await storage.read(key: 'phone');
    String? sex = await storage.read(key: 'sex');
    String? token = await storage.read(key: 'token');
    String? customerId = await storage.read(key: 'customerId');
    String? iosPlan = await storage.read(key: 'iosPlan');
    String? role = await storage.read(key: 'role');
    String? updateAt = await storage.read(key: 'updateAt');
    String? createdAt = await storage.read(key: 'createdAt');
    print('[CACHE] Carregado do cache');

    if (id != null && token != null) {
      _currentUser = User(
        id: id,
        name: name ?? '',
        email: email ?? '',
        cpf: cpf ?? '',
        birthDate: birthDate ?? '',
        oabState: oabState ?? '',
        oabSubscription: oabSubscription ?? '',
        phone: phone ?? '',
        sex: sex ?? '',
        role: role ?? '',
        token: token,
        idStripe: customerId ?? '',
        iosPlan: iosPlan ?? '',
        updateAt: updateAt ?? '',
        createdAt: createdAt ?? '',
      );
      return _currentUser;
    }

    _currentUser = null;
    return null; // Caso o usuário não esteja logado ou dados estejam faltando
  }

  Future login(String cpfCnpj, String password) async {
    try {
      String cleanCpfCnpj = removeMask(cpfCnpj);

      Map params = {
        "user": {"identity": cleanCpfCnpj, "password": password}
      };

      var url = '${ApiConstants.baseUrl}/authentication/users/sign_in.json';

      var body = json.encode(params);

      var headers = {
        'Content-Type': 'application/json',
      };

      print('[LOGIN] Fazendo request para: $url');
      
      var response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );

      print('[LOGIN] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[LOGIN] Parsing response body...');
        final responseData = json.decode(response.body);
        
        print('[LOGIN] Response data keys: ${responseData.keys}');
        print('[LOGIN] Criando User.fromJson...');
        _currentUser = User.fromJson(responseData);
        
        print('[LOGIN] User criado com id: ${_currentUser?.id}');
        
        if (!kIsWeb && Platform.isIOS) {
          print('[LOGIN] Configurando Purchases (iOS)...');
          if (_currentUser != null) {
            Purchases.logIn(_currentUser!.id);
          }
        }
        
        print('[LOGIN] Salvando user no cache...');
        if (_currentUser != null) {
          await _saveUserToCache(_currentUser!);
          print('[LOGIN] User salvo no cache com sucesso');
        }
      } else {
        print('[LOGIN] ERRO: Status code ${response.statusCode}');
        print('[LOGIN] Response body: ${response.body}');
      }
      return response;
    } catch (e, stackTrace) {
      print('[LOGIN] ERRO: $e');
      print('[LOGIN] StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future logout() async {
    String? token = await storage.read(key: 'token');

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': "Bearer $token"
    };

    var url = '${ApiConstants.baseUrl}/authentication/users/sign_out.json';

    var response = await http.delete(Uri.parse(url), headers: headers);

    _currentUser = null;
    await _clearUserFromCache();
    if (!kIsWeb && Platform.isIOS) {
      Purchases.logOut();
    }

    return response;
  }

  Future forgotPassword(String cpf) async {
    Map params = {
      "user": {"identity": removeMask(cpf)}
    };

    var url = '${ApiConstants.baseUrl}/authentication/users/password.json';

    var body = json.encode(params);

    var headers = {
      'Content-Type': 'application/json',
    };

    var response = await http.post(
      Uri.parse(url),
      body: body,
      headers: headers,
    );
    return response;
  }

  Future updatePassword(
      {required String code,
      required String newPassword,
      required String confirmPassword}) async {
    Map params = {
      "user": {
        "reset_password_token": code,
        "password": newPassword,
        "password_confirmation": confirmPassword
      }
    };

    var url = '${ApiConstants.baseUrl}/authentication/users/password.json';

    var body = json.encode(params);

    var headers = {
      'Content-Type': 'application/json',
    };

    var response = await http.put(
      Uri.parse(url),
      body: body,
      headers: headers,
    );

    if (response.statusCode == 200) {
      // Se a requisição foi bem-sucedida
    } else {
      // Se algo deu errado
    }

    return response;
  }

  Future getUser({required String id}) async {
    String? token = await storage.read(key: 'token');

    var url = '${ApiConstants.baseUrl}/users/$id';

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      var user = User.fromJson(responseBody);
      return user;
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<List<User>> getAllUsers({
    int page = 1,
    int perPage = 10,
    Map<String, dynamic>? queryParameters,
  }) async {
    String? token = await storage.read(key: 'token');

    var url = "${ApiConstants.baseUrl}/users?page=$page&per_page=$perPage";

    if (queryParameters != null && queryParameters.isNotEmpty) {
      String queryString = queryParameters.entries.map((entry) {
        if (entry.value is List) {
          // Para listas, converta para múltiplos parâmetros com o mesmo nome
          return entry.value
              .map((value) =>
                  "${Uri.encodeComponent(entry.key)}[]=${Uri.encodeComponent(value)}")
              .join("&");
        } else {
          return "${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}";
        }
      }).join("&");

      url += "&$queryString";
    }

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      int total = responseBody['pagination_params']['total'];
      await storage.write(
          key: 'countLenghtUsers', value: total.toString());

      List<User> listUsers = [];
      for (var user in responseBody['data']) {
        listUsers.add(User.fromJson(user));
      }
      return listUsers;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future patchUser(String id, String name, String cpf, String email,
      String phone, String birthDate, String role, String sex) async {
    Map params = {
      "user": {
        "name": name,
        "cpf": cpf,
        "email": email,
        "phone": phone,
        "birth_date": birthDate,
        "role": role,
        "sex": sex,
      }
    };

    String? token = await storage.read(key: 'token');

    var url = '${ApiConstants.baseUrl}/users/$id';

    var body = json.encode(params);

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response =
        await http.patch(Uri.parse(url), headers: headers, body: body);

    if (_currentUser != null && _currentUser!.id == id) {
      _currentUser = User.fromJson(json.decode(response.body));
      await _saveUserToCache(_currentUser!);
    }

    return response;
  }

  Future deleteUser(String id) async {
    String? token = await storage.read(key: 'token');

    var url = "${ApiConstants.baseUrl}/users/$id";

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.delete(Uri.parse(url), headers: headers);
    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future patchMapUser({
    required String id,
    required Map<String, dynamic> updatedFields,
  }) async {
    String url = '${ApiConstants.baseUrl}/users/$id';

    String? token = await storage.read(key: 'token');

    Map<String, dynamic> body = {
      "user": updatedFields,
    };

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.patch(
      Uri.parse(url),
      body: json.encode(body),
      headers: headers,
    );

    return response;
  }
}

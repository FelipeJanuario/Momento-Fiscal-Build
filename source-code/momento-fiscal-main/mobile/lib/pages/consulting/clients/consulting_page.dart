import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:momentofiscal/components/user_card.dart';
import 'package:momentofiscal/core/models/user.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/services/invation/invitation_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultingPage extends StatefulWidget {
  final String typePageRole;
  const ConsultingPage({super.key, required this.typePageRole});

  @override
  State<ConsultingPage> createState() => _ConsultingPageState();
}

class _ConsultingPageState extends State<ConsultingPage> {
  List<User> users = [];
  int currentPage = 1;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameInEmailController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? countLengthUsers;

  final _formAlert = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInstitutions();
  }

  void _showError(String msg) {
    setState(() {
      _errorMessage = msg;
    });
  }

  Future<void> _loadInstitutions({String? nameInEmail}) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<User> filteredUsers = [];
      if (widget.typePageRole == 'consultant') {
        var userConsultantAdmin = await AuthRailsService()
            .getAllUsers(page: currentPage, perPage: 10, queryParameters: {
          "query[text_search]": nameInEmail ?? "",
          "query[role]": ["consultant", "admin"],
        });

        filteredUsers = userConsultantAdmin;
      } else if (widget.typePageRole == 'client') {
        var userClient = await AuthRailsService()
            .getAllUsers(page: currentPage, perPage: 10, queryParameters: {
          "query[text_search]": nameInEmail ?? "",
          "query[role]": ['client'],
        });

        filteredUsers = userClient;
      }

      countLengthUsers = await storage.read(key: 'countLenghtUsers');

      setState(() {
        if (currentPage == 1) {
          users = filteredUsers;
        } else {
          users.addAll(filteredUsers);
        }
        currentPage++;
      });
    } catch (error) {
      throw Exception('Failed to load users');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500 && !isLoading) {
      _loadInstitutions(nameInEmail: _nameInEmailController.text);
    }
  }

  void _onSearch() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      currentPage = 1;
      users.clear();
    });
    _loadInstitutions(nameInEmail: _nameInEmailController.text);
  }

  Future<void> _sendMessageToWhatsApp() async {
    String androidLink =
        "https://play.google.com/store/apps/details?id=br.com.momentofiscal";
    String iosLink = "https://apps.apple.com/app/momento-fiscal/id6636497263";
    String message = """
      Olá, estou te convidando a baixar o app Momento Fiscal e fazer parte desta equipe.

Links para Download:
    Android: 
      $androidLink

    IOS: 
      $iosLink
      """;
    String encodedMessage = Uri.encodeComponent(message);
    String phoneNumber = "";

    String url = "https://wa.me/$phoneNumber?text=$encodedMessage";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Não foi possível abrir o WhatsApp.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.typePageRole == 'consultant'
              ? 'Painel de Consultores'
              : "Painel de Clientes",
          style: const TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
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
          const Text(
            'Verifique se já possui um consultor; caso contrário, envie o convite',
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameInEmailController,
                decoration: InputDecoration(
                  labelText: 'Filtrar por nome ou e-mail',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _nameInEmailController.clear();

                      setState(() {
                        currentPage = 1;
                        users.clear();
                      });

                      _loadInstitutions();
                    },
                  ),
                ),
                validator: (value) => validatorName(value),
                onFieldSubmitted: (value) {
                  _onSearch();
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _onSearch,
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    backgroundColor: colorPrimaty,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                  ),
                  child: const Text(
                    'Pesquisar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                if (widget.typePageRole == "consultant")
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(builder: (context, setState) {
                            return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              content: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Envie um convite',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                        'O convite será enviado para o e-mail da pessoa com as devidas instruções.'),
                                    Form(
                                      key: _formAlert,
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            key: const ValueKey('email'),
                                            controller: _emailController,
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            decoration: const InputDecoration(
                                                label: Text('Email'),
                                                hintText: 'Digite seu e-mail'),
                                            validator: (value) =>
                                                validatorEmail(value),
                                          )
                                        ],
                                      ),
                                    ),
                                    if (_errorMessage != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 3,
                                    backgroundColor: colorPrimaty,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _emailController.text = "";
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
                                  ),
                                  onPressed: () async {
                                    bool formValidate =
                                        _formAlert.currentState!.validate();
                                    if (!formValidate) return;

                                    try {
                                      var result =
                                          await InvitationRailsService()
                                              .createInvation(
                                                  email: _emailController.text);

                                      if (result.statusCode == 201) {
                                        setState(() {
                                          _errorMessage = null;
                                        });

                                        // ignore: use_build_context_synchronously
                                        Navigator.of(context).pop();
                                        _emailController.text = "";

                                        showDialog(
                                          // ignore: use_build_context_synchronously
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Convite Enviado'),
                                              content: Text(
                                                  'O convite foi enviado ao e-mail ${_emailController.text} com as devidas instruções'),
                                              actions: [
                                                TextButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    elevation: 3,
                                                    backgroundColor:
                                                        colorTertiary,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _emailController.text = "";
                                                  },
                                                  child: const Text(
                                                    'Entendi',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                )
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        setState(() {
                                          _showError(json
                                              .decode(result.body)['error']
                                              .toString());
                                        });
                                      }
                                    } catch (e) {
                                      Exception('Erro create invation $e');
                                    }
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 2.0),
                                      Text(
                                        'Enviar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    bool formValidate =
                                        _formAlert.currentState!.validate();
                                    if (!formValidate) return;

                                    try {
                                      var result =
                                          await InvitationRailsService()
                                              .createInvation(
                                        email: _emailController.text,
                                      );

                                      if (result.statusCode == 201) {
                                        setState(() {
                                          _errorMessage = null;
                                        });

                                        _sendMessageToWhatsApp();

                                        // ignore: use_build_context_synchronously
                                        Navigator.of(context).pop();
                                        _emailController.text = "";
                                      } else {
                                        setState(() {
                                          _showError(json
                                              .decode(result.body)['error']
                                              .toString());
                                        });
                                      }
                                    } catch (e) {
                                      Exception(
                                          'Erro ao redirecionar para o WhatsApp $e');
                                    }
                                  },
                                  child: Image.asset(
                                    'assets/images/whatsappiconblack1.png',
                                    height: 35,
                                    width: 35,
                                  ),
                                ),
                              ],
                            );
                          });
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: colorSecundary,
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                    ),
                    child: const Text(
                      'Convidar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${countLengthUsers ?? 0} Membros',
            style: labelStyle,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: users.length,
              itemBuilder: (context, index) {
                return UserCard(
                  user: users[index],
                  typeRole: widget.typePageRole,
                );
              },
            ),
          ),
          if (isLoading)
            const Column(
              children: [
                SizedBox(height: 30),
                Center(child: CircularProgressIndicator()),
              ],
            ),
          if (!isLoading && users.isEmpty)
            const Center(child: Text('Nenhum consultor encontrado')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:momentofiscal/components/institution_card.dart';
import 'package:momentofiscal/core/models/institution.dart';
import 'package:momentofiscal/core/services/institution/institution_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';

class InstitutionPage extends StatefulWidget {
  const InstitutionPage({super.key});

  @override
  State<InstitutionPage> createState() => _InstitutionPageState();
}

class _InstitutionPageState extends State<InstitutionPage> {
  List<Institution> institutions = [];
  int currentPage = 1;
  bool isLoading = false;
  bool isMoreLoading = false;
  final ScrollController _scrollController = ScrollController();
  late Future<void> _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initialLoadFuture = _loadInstitutions(initial: true);
  }

  Future<void> _loadInstitutions({bool initial = false}) async {
    if (initial) {
      setState(() {
        isLoading = true;
      });
    } else {
      setState(() {
        isMoreLoading = true;
      });
    }

    try {
      final newInstitutions =
          await InstitutionRailsService().getAllInstitution(page: currentPage);
      setState(() {
        institutions.addAll(newInstitutions);
        currentPage++;
      });
    } catch (error) {
      // Handle error
      throw Exception('Failed to load institutions');
    } finally {
      if (initial) {
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isMoreLoading = false;
        });
      }
    }
  }

  void _removeInstitution(String id) {
    setState(() {
      institutions.removeWhere((institution) => institution.id == id);
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500 && !isMoreLoading) {
      _loadInstitutions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Empresas Cadastradas',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: Image.asset('assets/images/momentofiscalcolorido.png',
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lista de empresas disponíveis',
              style: textTitle,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<void>(
                future: _initialLoadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text('Failed to load institutions'));
                  } else {
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: institutions.length + 1,
                      itemBuilder: (context, index) {
                        if (index == institutions.length) {
                          return isMoreLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        }
                        return InstitutionCard(
                          institution: institutions[index],
                          onDismissed: _removeInstitution,
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

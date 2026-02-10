import 'dart:async';
import 'package:flutter/material.dart';
import 'package:momentofiscal/components/company_card.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/services/biddingAnalyser/location/location_compaines_rails.dart';
import 'package:momentofiscal/pages/location/search_by_location_osm_page.dart';

// ignore: must_be_immutable
class IndebtedCompaniesPage extends StatefulWidget {
  late List<Company> companies;
  final double longStarting;
  final double latStarting;
  final double longEnding;
  final double latEnding;

  IndebtedCompaniesPage({
    super.key,
    var companies,
    required this.longStarting,
    required this.latStarting,
    required this.longEnding,
    required this.latEnding,
  }) {
    this.companies = companies ?? <Company>[];
  }

  @override
  State<IndebtedCompaniesPage> createState() => _IndebtedCompaniesPageState();
}

class _IndebtedCompaniesPageState extends State<IndebtedCompaniesPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Company> _companies = [];
  Timer? _debounceTimer;
  int currentPage = 1;
  bool isLoading = true;
  bool isMoreLoading = false;
  bool showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _loadCompany();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >= 400) {
      setState(() {
        showBackToTopButton = true;
      });
    } else {
      setState(() {
        showBackToTopButton = false;
      });
    }
    if (_scrollController.position.extentAfter < 200 && !isMoreLoading) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), _loadCompany);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadCompany() async {
    setState(() {
      isLoading = currentPage == 1;
      isMoreLoading = currentPage != 1;
    });
    try {
      final newCompanies = await LocationCompaniesRails().getInLocation(
        longStarting: widget.longStarting,
        latStarting: widget.latStarting,
        longEnding: widget.longEnding,
        latEnding: widget.latEnding,
        page: currentPage,
      );

      setState(() {
        _companies.addAll(newCompanies);
        currentPage++;
      });
    } catch (error) {
      debugPrint('Failed to load companies: $error');
    } finally {
      setState(() {
        isLoading = false;
        isMoreLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Empresas Endividadas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          SizedBox(
            height: 100,
            child: Image.asset('assets/images/momentofiscalcolorido.png',
                fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _companies.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _companies.length) {
                        return CompanyCard(company: _companies[index]);
                      } else if (isMoreLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Container();
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: showBackToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }
}

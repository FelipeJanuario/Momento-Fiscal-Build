import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:momentofiscal/core/exceptions/http_request_exception.dart';
import 'package:momentofiscal/core/models/async_list.dart';

import 'package:momentofiscal/core/models/tj_process.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';

class FetchTjEjacData {
  final int maxRetries = 5;

  AsyncList<TjProcess> call(
      {required String cpfCnpj, required String baseUrl}) {
    if (cpfCnpj.length != 11 && cpfCnpj.length != 14) {
      throw ArgumentError('CPF ou CNPJ inválido');
    }

    var asyncList = AsyncList<TjProcess>(total: 900);

    _fetchData(asyncList, cpfCnpj, baseUrl);

    return asyncList;
  }

  Future<int> _getTotalPages(String cpfCnpj, String baseUrl) async {
    var url =
        '$baseUrl/cpopg/search.do?cbPesquisa=DOCPARTE&dadosConsulta.valorConsulta=$cpfCnpj&cdForo=-1&paginaConsulta=1';
    var document = await _fetchHtml(url);
    var text = document
            .querySelector('.resultadoPaginacao')
            ?.text
            .replaceAll(RegExp(r'\D'), '') ??
        '1';
    return (int.parse(text) / 25).ceil();
  }

  void _fetchData(
      AsyncList<TjProcess> list, String cpfCnpj, String baseUrl) async {
    var totalPages = await _getTotalPages(cpfCnpj, baseUrl);
    list.setTotal(totalPages);

    for (var page = 1; page <= totalPages; page++) {
      // Interrompe a execução se o usuário desativar
      String? isDesative = await storage.read(key: 'isDesative');
      if (isDesative == 'true') {
        await storage.delete(key: 'isDesative');
        Logger.log("Processo interrompido pelo usuário.");
        break;
      }

      // Fetch HTML da página
      var url =
          '$baseUrl/cpopg/search.do?cbPesquisa=DOCPARTE&dadosConsulta.valorConsulta=$cpfCnpj&cdForo=-1&paginaConsulta=$page';
      var document = await _fetchHtml(url);

      // Parse dados e descarte o que não é necessário
      var parsedData = await _parseToJson(document, baseUrl);
      list.addAll(parsedData);

      // Atualiza progresso
      list.addStep();
    }

    list.setSteps(totalPages);
  }

  Future<Document> _fetchHtml(String url, {int retryCount = 0}) async {
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
        },
      );

      if (response.statusCode != 200) {
        if (retryCount >= maxRetries) {
          throw HttpRequestException(
              'Erro ao buscar dados, status code: ${response.statusCode}');
        }
        return _fetchHtml(url, retryCount: retryCount + 1);
      }

      return parser.parse(response.body);
    } catch (e) {
      Logger.log('Erro ao buscar HTML: $e');
      rethrow;
    }
  }

  Future<List<TjProcess>> _parseToJson(
      Document document, String baseUrl) async {
    var elements = document.querySelectorAll('.row.home__lista-de-processos');
    var processes = <TjProcess>[];

    for (var element in elements) {
      var process = _parseElement(element, baseUrl);
      processes.add(process);

      // Carregar detalhes (sob demanda)
      await _fetchDetails(url: process.url!, process: process);
    }

    return processes;
  }

  TjProcess _parseElement(Element element, String baseUrl) {
    return TjProcess(
      code: element.querySelector('a.linkProcesso')?.text.trim(),
      url: baseUrl +
          (element.querySelector('a.linkProcesso')!.attributes['href'] ?? ''),
      processType: element.querySelector('.classeProcesso')?.text.trim(),
      participationType:
          element.querySelector('.tipoDeParticipacao')?.text.trim(),
      interestedPartyName: element.querySelector('.nomeParte')?.text.trim(),
      mainSubject:
          element.querySelector('.assuntoPrincipalProcesso')?.text.trim(),
      receivedAt: element
          .querySelector('.dataLocalDistribuicaoProcesso')
          ?.text
          .split('-')[0]
          .trim(),
      receivedLocation: element
          .querySelector('.dataLocalDistribuicaoProcesso')
          ?.text
          .split('-')[1]
          .trim(),
    );
  }

  Future<void> _fetchDetails({
    required String url,
    required TjProcess process,
    int retryCount = 0,
  }) async {
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        if (retryCount >= maxRetries) return;
        await _fetchDetails(
            url: url, process: process, retryCount: retryCount + 1);
      }

      var document = parser.parse(response.body);
      var elements = document.querySelector('.unj-entity-header');

      if (elements != null) {
        process.code = elements.querySelector('#numeroProcesso')?.text.trim();
        process.processClass =
            elements.querySelector('#classeProcesso')?.text.trim();
        process.subject =
            elements.querySelector('#assuntoProcesso')?.text.trim();
        process.value = _parseBRLValue(
            elements.querySelector('#valorAcaoProcesso')?.text.trim());
      }
    } catch (e) {
      Logger.log('Erro ao buscar detalhes: $e');
    }
  }

  double _parseBRLValue(String? value) {
    if (value == null || !RegExp(r'\d').hasMatch(value)) return 0.0;
    return double.parse(
        value.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.'));
  }
}

class FetchTjPjeData {
  final int maxRetries = 5;

  void call() async {
    var baseUrl =
        'https://pje-consultapublica.tjdft.jus.br/consultapublica/ConsultaPublica/listView.seam';

    var data = {
      'AJAXREQUEST': '_viewRoot',
      'fPP:numProcesso-inputNumeroProcessoDecoration:numProcesso-inputNumeroProcesso':
          '',
      'mascaraProcessoReferenciaRadio': 'on',
      'fPP:j_id163:processoReferenciaInput': '',
      'fPP:dnp:nomeParte': '',
      'fPP:j_id181:nomeAdv': '',
      'fPP:j_id190:classeJudicial': '',
      'fPP:j_id190:sgbClasseJudicial_selection': '',
      'tipoMascaraDocumento': 'on',
      'fPP:dpDec:documentoParte': '59.104.422/0001-50',
      'fPP:Decoration:numeroOAB': '',
      'fPP:Decoration:j_id224': '',
      'fPP:Decoration:estadoComboOAB':
          'org.jboss.seam.ui.NoSelectionConverter.noSelectionValue',
      'fPP:dataAutuacaoDecoration:dataAutuacaoInicioInputDate': '',
      'fPP:dataAutuacaoDecoration:dataAutuacaoInicioInputCurrentDate':
          '12/2024',
      'fPP:dataAutuacaoDecoration:dataAutuacaoFimInputDate': '',
      'fPP:dataAutuacaoDecoration:dataAutuacaoFimInputCurrentDate': '12/2024',
      'fPP': 'fPP',
      'autoScroll': '',
      'javax.faces.ViewState': 'j_id3',
      'fPP:j_id245': 'fPP:j_id245',
      'AJAX:EVENTS_COUNT': '1',
      // Adicione todos os outros campos necessários
    };

    // Cabeçalhos da requisição
    var headers = {
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'User-Agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    };

    try {
      var document = await fetchData(
        baseUrl: baseUrl,
        data: data,
        headers: headers,
      );

      var results = parseHtml(document);

      // Exibe os resultados extraídos
      for (var result in results) {
        Logger.log(result.toString());
      }
    } catch (e) {
      Exception('Erro: $e');
    }
  }

  Future<Document> fetchData({
    required String baseUrl,
    required Map<String, String> data,
    required Map<String, String> headers,
  }) async {
    try {
      var response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: data,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Erro ao buscar dados do PJe, status code: ${response.statusCode}');
      }

      return parser.parse(response.body);
    } catch (e) {
      Logger.log('Erro ao buscar dados do PJe: $e');
      rethrow;
    }
  }

  List<Map<String, String>> parseHtml(Document document) {
    // Substitua os seletores abaixo de acordo com a estrutura HTML da resposta.
    var elements = document.querySelectorAll('.classe-especifica-linha');
    var results = <Map<String, String>>[];

    for (var element in elements) {
      var result = {
        'numeroProcesso':
            element.querySelector('.numeroProcesso')?.text.trim() ?? '',
        'nomeParte': element.querySelector('.nomeParte')?.text.trim() ?? '',
        'dataAutuacao':
            element.querySelector('.dataAutuacao')?.text.trim() ?? '',
        // Adicione mais campos conforme necessário
      };
      results.add(result);
    }

    return results;
  }
}

import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/async_list.dart';
import 'package:momentofiscal/core/services/processDataCrawlers/fetch_tj_data.dart';
import 'package:momentofiscal/core/utilities/validations.dart';

Future getAc({
  required ValueNotifier<AsyncList?> asyncListNotifier,
  required String cnpj,
  required ValueNotifier<bool> isActiveNotifier,
  required VoidCallback? whileIsActive,
  required VoidCallback? finalWhileIsActive,
  required VoidCallback? catchError,
}) async {
  try {
    asyncListNotifier.value = FetchTjEjacData()
        .call(cpfCnpj: removeMask(cnpj), baseUrl: 'https://esaj.tjac.jus.br');

    while (isActiveNotifier.value) {
      if (asyncListNotifier.value?.isFinished == true) {
        whileIsActive?.call();
        break;
      }

      finalWhileIsActive?.call();

      await Future.delayed(const Duration(seconds: 1));
      if (!isActiveNotifier.value) break;
    }
  } catch (e) {
    catchError?.call();
  }
}

Future getSp({
  required ValueNotifier<AsyncList?> asyncListNotifier,
  required String cnpj,
  required ValueNotifier<bool> isActiveNotifier,
  required VoidCallback? whileIsActive,
  required VoidCallback? finalWhileIsActive,
  required VoidCallback? catchError,
}) async {
  try {
    asyncListNotifier.value = FetchTjEjacData()
        .call(cpfCnpj: removeMask(cnpj), baseUrl: 'https://esaj.tjsp.jus.br');

    // await storage.write(key: 'isDesative', value: 'true');

    while (isActiveNotifier.value) {
      if (asyncListNotifier.value?.isFinished == true) {
        whileIsActive?.call();
        break;
      }

      finalWhileIsActive?.call();

      await Future.delayed(const Duration(seconds: 1));

      if (!isActiveNotifier.value) {
        break;
      }
    }
  } catch (e) {
    catchError?.call();
  }
}

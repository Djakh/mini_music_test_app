import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

abstract class DownloadDataSource {
  Stream<double> download(String url, String savePath);
  Future<void> delete(String path);
  Future<bool> exists(String path);
}

class DioDownloadDataSource implements DownloadDataSource {
  DioDownloadDataSource(this._dio);

  final Dio _dio;

  @override
  Stream<double> download(String url, String savePath) {
    final controller = StreamController<double>();
    _dio
        .download(
      url,
      savePath,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (total == -1) {
          controller.add(0);
        } else {
          controller.add(received / total);
        }
      },
    )
        .then((_) {
      controller.add(1.0);
      controller.close();
    }).catchError((error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
        controller.close();
      }
    });
    return controller.stream;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists(String path) async {
    final file = File(path);
    return file.exists();
  }
}

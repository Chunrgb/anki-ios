import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/anki_service.dart';

final collectionProvider = FutureProvider<bool>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final collectionPath = '${dir.path}/anki/collection.anki2';

  await Directory('${dir.path}/anki').create(recursive: true);

  await AnkiService.instance.openCollection(collectionPath);
  return true;
});

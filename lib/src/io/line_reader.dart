import 'dart:convert';
import 'dart:io';

/// Читає текстовий файл рядками через `openRead` без завантаження цілком.
Stream<String> readLines(String path) {
  return File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
}

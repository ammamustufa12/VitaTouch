import 'dart:convert';

String formatNfcUid(String hex) {
  final clean = hex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
  final parts = <String>[];
  for (var index = 0; index < clean.length; index += 2) {
    final end = index + 2 > clean.length ? clean.length : index + 2;
    parts.add(clean.substring(index, end));
  }
  return parts.join(' ');
}

String? ndefTextFromPages(List<String> pageHex) {
  final bytes = <int>[];
  for (final page in pageHex) {
    final clean = page.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (clean.length < 8 || clean.length.isOdd) {
      return null;
    }
    for (var index = 0; index < clean.length; index += 2) {
      bytes.add(int.parse(clean.substring(index, index + 2), radix: 16));
    }
  }
  if (bytes.length < 18) {
    return null;
  }

  var index = 16;
  while (index < bytes.length) {
    final type = bytes[index];
    if (type == 0x00) {
      index += 1;
      continue;
    }
    if (type == 0xFE || type != 0x03) {
      return null;
    }
    index += 1;
    if (index >= bytes.length) {
      return null;
    }
    final int length;
    if (bytes[index] == 0xFF) {
      if (index + 2 >= bytes.length) {
        return null;
      }
      length = (bytes[index + 1] << 8) | bytes[index + 2];
      index += 3;
    } else {
      length = bytes[index];
      index += 1;
    }
    if (length == 0 || index + length > bytes.length) {
      return null;
    }
    return _textFromNdef(bytes.sublist(index, index + length));
  }
  return null;
}

String? _textFromNdef(List<int> message) {
  if (message.length < 3) {
    return null;
  }
  var index = 0;
  final header = message[index++];
  final typeLength = message[index++];
  final shortRecord = (header & 0x10) != 0;
  final hasId = (header & 0x08) != 0;
  if (index >= message.length) {
    return null;
  }
  final int payloadLength;
  if (shortRecord) {
    payloadLength = message[index++];
  } else {
    if (index + 4 > message.length) {
      return null;
    }
    payloadLength = (message[index] << 24) |
        (message[index + 1] << 16) |
        (message[index + 2] << 8) |
        message[index + 3];
    index += 4;
  }
  final idLength = hasId ? message[index++] : 0;
  if (index + typeLength + idLength + payloadLength > message.length) {
    return null;
  }
  final type = message.sublist(index, index + typeLength);
  index += typeLength + idLength;
  final payload = message.sublist(index, index + payloadLength);
  final isText = type.length == 1 && type.first == 0x54;
  if (!isText || payload.isEmpty) {
    return null;
  }
  final status = payload.first;
  final languageLength = status & 0x3F;
  if (1 + languageLength > payload.length) {
    return null;
  }
  final textBytes = payload.sublist(1 + languageLength);
  if ((status & 0x80) != 0) {
    final units = <int>[];
    for (var unit = 0; unit + 1 < textBytes.length; unit += 2) {
      units.add((textBytes[unit] << 8) | textBytes[unit + 1]);
    }
    final text = String.fromCharCodes(units).trim();
    return text.isEmpty ? null : text;
  }
  final text = utf8.decode(textBytes, allowMalformed: true).trim();
  return text.isEmpty ? null : text;
}

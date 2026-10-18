// lib/utils/business_logo.dart — the shop's logo: pick, shrink, read back.
//
// A phone photo is 3–12 MB and 4000px wide. Embedded as-is it would
// make every invoice PDF that size, and every WhatsApp share slow on
// metered data. So the picked image is decoded once, scaled so its long
// side is at most 512px — sharp at the 48pt it prints at — and stored
// as PNG, which keeps a transparent background transparent.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

const int _maxSide = 512;

/// Ask for an image and return it as a base64 PNG ready to store, or
/// null if the person cancelled. Throws if the file is not an image the
/// phone can decode.
Future<String?> pickBusinessLogo() async {
  final picked = await FilePicker.pickFile(type: FileType.image);
  final path = picked?.path;
  if (path == null) return null;
  final bytes = await File(path).readAsBytes();
  final png = await shrinkToPng(bytes);
  return base64Encode(png);
}

/// Decode, scale down to [_maxSide] on the long side (never up), and
/// re-encode as PNG.
Future<Uint8List> shrinkToPng(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final w = descriptor.width, h = descriptor.height;
  int? tw, th;
  if (w >= h && w > _maxSide) tw = _maxSide;
  if (h > w && h > _maxSide) th = _maxSide;
  final codec = await descriptor.instantiateCodec(
      targetWidth: tw, targetHeight: th);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  if (data == null) throw const FormatException('Could not encode the logo');
  return data.buffer.asUint8List();
}

String? _cachedKey;
Uint8List? _cachedBytes;

/// The stored logo's bytes, or null for none / unreadable. Decoded once
/// per distinct value — the invoice screen asks on every rebuild.
Uint8List? logoBytes(String base64Logo) {
  if (base64Logo.isEmpty) return null;
  if (identical(base64Logo, _cachedKey) || base64Logo == _cachedKey) {
    return _cachedBytes;
  }
  try {
    _cachedBytes = base64Decode(base64Logo);
  } catch (_) {
    _cachedBytes = null;
  }
  _cachedKey = base64Logo;
  return _cachedBytes;
}

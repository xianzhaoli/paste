import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/clipboard_item.dart';
import '../services/database_service.dart';

class ClipboardService {
  static Future<void> startListening() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;

    String? lastHash;

    while (true) {
      try {
        final reader = await clipboard.read();
        // 处理富文本
        for (final clipItem in reader.items) {
          ClipboardItem? item;
          if (clipItem.canProvide(Formats.uri) &&
              (await clipItem.readValue(Formats.plainText))!
                  .startsWith('http')) {
            final text = await clipItem.readValue(Formats.plainText);
            if (text != null) {
              final hash = _generateHash(text);
              if (hash != lastHash) {
                item = ClipboardItem(
                    type: 'uri',
                    content: text,
                    timestamp: DateTime.now(),
                    hash: hash,
                    size: text.length.toString());
              }
            }
          } else if (clipItem.canProvide(Formats.fileUri)) {
            final fileUri = await clipItem.readValue(Formats.fileUri);
            if (fileUri != null) {
              final hash = _generateHash(fileUri.path);
              if (hash != lastHash) {
                item = ClipboardItem(
                    type: 'file',
                    content: fileUri.path,
                    timestamp: DateTime.now(),
                    hash: hash,
                    size: Uri.decodeComponent(fileUri.path));
              }
            }
          }

          //处理富文本
          else if (clipItem.canProvide(Formats.plainText) && clipItem.canProvide(Formats.htmlText)) {
            final text = await clipItem.readValue(Formats.plainText);
            final htmlText = await clipItem.readValue(Formats.htmlText);
            if (text != null && text.trim().isNotEmpty) {
              final hash = _generateHash(text);
              if (hash != lastHash) {
                item = ClipboardItem(
                    type: 'text',
                    content: text,
                    timestamp: DateTime.now(),
                    hash: hash,
                    htmlContent: htmlText,
                    size: text.length.toString());
              }
            }
          }
          // 处理普通文本
          else if (clipItem.canProvide(Formats.plainText)) {
            final text = await clipItem.readValue(Formats.plainText);
            if (text != null && text.trim().isNotEmpty) {
              final hash = _generateHash(text);
              if (hash != lastHash) {
                item = ClipboardItem(
                    type: 'text',
                    content: text,
                    timestamp: DateTime.now(),
                    hash: hash,
                    size: text.length.toString());
              }
            }
          }

          // 处理图片
          else if (clipItem.canProvide(Formats.png)) {
            await clipItem.getFile(Formats.png, (file) async {
              final bytes = await file.readAll();
              final hash = _generateHash(bytes.toString());
              if (hash != lastHash) {
                lastHash = hash;
                final path = await _saveImage(
                    bytes,
                    file.fileName ??
                        '${DateTime.now().millisecondsSinceEpoch}.png');

                final completer = Completer<ui.Image>();
                ui.decodeImageFromList(bytes, (ui.Image img) {
                  return completer.complete(img);
                });
                final ui.Image image = await completer.future;

                item = ClipboardItem(
                    type: 'image',
                    content: path,
                    timestamp: DateTime.now(),
                    hash: hash,
                    size: '${image.width} x ${image.height}');
                lastHash = hash;
                await DatabaseService.insertOrUpdate(item!);
              }
            });
            continue;
          }
          if (item != null) {
            lastHash = item.hash;
            await DatabaseService.insertOrUpdate(item);
          }
        }
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        print('Clipboard monitoring error: $e');
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  static String _generateHash(String content) {
    return md5.convert(utf8.encode(content)).toString();
  }

  static Future<String> _saveImage(List<int> bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagePath = path.join(dir.path, 'clipboard_images', fileName);
    await Directory(path.dirname(imagePath)).create(recursive: true);
    await File(imagePath).writeAsBytes(bytes);
    return imagePath;
  }
}

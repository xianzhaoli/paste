import 'dart:async';

import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import '../models/clipboard_item.dart';
import '../services/database_service.dart';
import 'package:path/path.dart' as path;

class ClipboardHistoryView extends StatefulWidget {
  const ClipboardHistoryView({super.key});

  @override
  State<ClipboardHistoryView> createState() => _ClipboardHistoryViewState();
}

class _ClipboardHistoryViewState extends State<ClipboardHistoryView> {
  String? _selectedHash;
  String _searchQuery = ""; // 搜索关键词
  String selectedType = "";

  final TextEditingController _searchController =
      TextEditingController(); // 搜索框控制器

  final StreamController<List<ClipboardItem>> _controller =
      StreamController<List<ClipboardItem>>();

  Future<void> getClipboardStream() async {
    final List<ClipboardItem> historyItems =
        await DatabaseService.getHistory(_searchQuery, selectedType);
    // 手动向流中添加新数据
    _controller.sink.add(historyItems);
  }

  // 颜色选项
  final List<String> _groupList = ['text', 'image', 'file', 'uri'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 30,
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                      getClipboardStream();
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 18),
                    // 图标大小调整
                    hintText: '搜索记录...',
                    contentPadding: EdgeInsets.fromLTRB(0, 5, 20, 5),
                    // 垂直内边距
                    fillColor: Colors.grey[200],
                    // 背景颜色
                    // isDense: true,
                    // 更紧凑
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), // 圆形边框
                      borderSide: BorderSide.none, // 去掉边框线
                    ),
                  ),
                ),
              ),
              ..._groupList.map((item) {
                return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedType == item) {
                          selectedType = "";
                        } else {
                          selectedType = item;
                        }
                        getClipboardStream();
                      });
                    },
                    child: Row(children: [
                      SizedBox(
                        width: 20,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color.fromRGBO(222, 222, 222, 1), // 边框颜色
                            width: 1.0, // 边框宽度
                          ),
                          color: item == selectedType
                              ? Color.fromRGBO(222, 222, 222, 1)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(30), // 圆角半径，根据需要调整
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 8.0),
                        // 可选：内部填充
                        child: Row(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 5.0),
                              width: 15.0,
                              height: 18.0,
                              decoration: BoxDecoration(
                                color: _getCardMenuStr(item),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getCardMenuStr(item),
                                  width: 2.0,
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              _getContentTypeText(item),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                        ),
                      )
                    ]));
              })
            ],
          ),
        ),
        Expanded(
            child: StreamBuilder<List<ClipboardItem>>(
          stream: _controller.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return _buildClipboardCard(item, index);
              },
            );
          },
        ))
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    getClipboardStream();
    // 注册回调
    DatabaseService.onInsertOrUpdate = getClipboardStream;
    timeago.setLocaleMessages('zh', timeago.ZhCnMessages());
    hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.keyC,
        modifiers: [HotKeyModifier.meta],
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) {
        _copySelectedItem();
      },
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Widget _buildClipboardCard(ClipboardItem item, int index) {
    final bool isSelected = _selectedHash == item.hash;
    return GestureDetector(
      onTap: () => setState(() => _selectedHash = item.hash),
      onDoubleTap: () => _copyItem(item),
      child: Container(
        margin: EdgeInsets.all(8),
        width: 280,
        child: Card(
          elevation: isSelected ? 10 : 1,
          // shadowColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部蓝色标题栏
              Container(
                color: _getCardMenu(item),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  textDirection: TextDirection.ltr,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getContentTypeText(item.type),
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          timeago.format(item.timestamp, locale: 'zh'),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              // 内容区域
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: ContextMenuRegion(
                    contextMenu: GenericContextMenu(
                      buttonItems: [
                        ContextMenuButtonItem(
                          label: '复制',
                          onPressed: () => _copyItem(item),
                        ),
                        ContextMenuButtonItem(
                          label: '删除',
                          onPressed: () => _delete(item),
                        ),
                      ],
                    ),
                    child: _buildContentPreview(item),
                  ),
                ),
              ),
              // 底部字数统计
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                // color: Colors.grey[50],
                child: ExtendedText(
                    item.type == 'image' || item.type == 'file'
                        ? item.size.toString()
                        : '${item.size} 个字符',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflowWidget: TextOverflowWidget(
                        position: TextOverflowPosition.start,
                        child: Text(
                          "...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        )),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContentTypeText(String type) {
    switch (type) {
      case 'text':
        return '文本';
      case 'html':
        return 'HTML';
      case 'image':
        return '图片';
      case 'uri':
        return '链接';
      case 'file':
        return '文件';
      default:
        return '文本';
    }
  }

  Widget _buildContentPreview(ClipboardItem item) {
    switch (item.type) {
      case 'image':
        return Center(
          child: Image.file(
            File(item.content),
            height: 200,
            fit: BoxFit.cover,
          ),
        );
      case 'file':
        {
          return Center(
            child: Image.asset('assets/file.png'),
          );
        }
      case 'html':
      default:
        return Text(
          item.content,
          maxLines: 8,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
          ),
        );
    }
  }

  void _copySelectedItem() async {
    if (_selectedHash != null) {
      final items = await DatabaseService.getItemByHash(_selectedHash!);
      await _copyItem(items);
    }
  }

  Future<void> _copyItem(ClipboardItem item) async {
    _selectedHash = item.hash;
    final clipboard = SystemClipboard.instance;
    switch (item.type) {
      case 'image':
        final imagePath = item.content;
        final image = DataWriterItem(suggestedName: path.basename(imagePath));
        image.add(Formats.png(await File(imagePath).readAsBytes()));
        await clipboard?.write([image]);
        break;
      case 'html':
        // 复制 HTML
        Clipboard.setData(ClipboardData(text: item.content));
        break;
      case 'file':
        final file = DataWriterItem();
        file.add(Formats.fileUri(Uri.parse('file://${item.content}')));
        await clipboard?.write([file]);
        break;
      default:
        // 复制文本
        final text = DataWriterItem();
        final htmlText = item.htmlContent;
        if (htmlText != null) {
          text.add(Formats.htmlText(htmlText));
          text.add(Formats.plainText(item.content));
          await clipboard?.write([text]);
        } else {
          Clipboard.setData(ClipboardData(text: item.content));
        }
    }
    showToast('复制成功',
        context: context,
        animation: StyledToastAnimation.none,
        reverseAnimation: StyledToastAnimation.none,
        position: StyledToastPosition.center,
        duration: Duration(seconds: 3));
    // await DatabaseService.updateTimestamp(item.hash);
    // getClipboardStream();
  }

  void _delete(ClipboardItem item) async {
    await DatabaseService.delete(item.hash);
    getClipboardStream();
  }

  Color _getCardMenu(ClipboardItem item) {
    return _getCardMenuStr(item.type);
  }

  Color _getCardMenuStr(String type) {
    if (type == 'image') {
      return Color.fromARGB(255, 209, 103, 0);
    } else if (type == 'file') {
      return Color.fromARGB(255, 138, 64, 189);
    } else if (type == 'uri') {
      return Color.fromARGB(255, 210, 161, 189);
    } else {
      return Colors.blue;
    }
  }
}

// 右键菜单组件
class ContextMenuRegion extends StatelessWidget {
  final Widget child;
  final ContextMenu contextMenu;

  const ContextMenuRegion({
    Key? key,
    required this.child,
    required this.contextMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        showContextMenu(
          context: context,
          contextMenu: contextMenu,
          position: details.globalPosition,
        );
      },
      child: child,
    );
  }
}

class ContextMenu {
  final List<ContextMenuButtonItem> items;

  ContextMenu({required this.items});
}

class ContextMenuButtonItem {
  final String label;
  final VoidCallback onPressed;

  ContextMenuButtonItem({required this.label, required this.onPressed});
}

class GenericContextMenu extends ContextMenu {
  GenericContextMenu({required List<ContextMenuButtonItem> buttonItems})
      : super(items: buttonItems);
}

// Helper function to show the context menu
void showContextMenu({
  required BuildContext context,
  required ContextMenu contextMenu,
  required Offset position,
}) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    ),
    items: contextMenu.items
        .map((item) => PopupMenuItem(
              child: Text(item.label),
              onTap: item.onPressed,
            ))
        .toList(),
  );
}

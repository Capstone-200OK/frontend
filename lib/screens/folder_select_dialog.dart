import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

class FolderSelectableItem {
  final int id;
  final String name;
  final int? parentId;
  final String folderType;
  List<FolderSelectableItem> children = [];
  bool isExpanded = false;

  FolderSelectableItem({
    required this.id,
    required this.name,
    required this.parentId,
    required this.folderType,
  });
}

class FolderSelectDialog extends StatefulWidget {
  const FolderSelectDialog({Key? key}) : super(key: key);

  @override
  State<FolderSelectDialog> createState() => _FolderSelectDialogState();
}

class _FolderSelectDialogState extends State<FolderSelectDialog> {
  List<FolderSelectableItem> folderTree = [];
  FolderSelectableItem? selected;
  late int? userId;
  late String url;

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      fetchSelectableFolders();
    });
  }

  Future<void> fetchSelectableFolders() async {
    final response = await http.get(
      Uri.parse('$url/folder/selectable/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      List<FolderSelectableItem> flatList = data.map((item) => FolderSelectableItem(
        id: item['id'],
        name: item['name'],
        parentId: item['parentId'],
        folderType: item['folderType'],
      )).toList();

      setState(() {
        folderTree = buildFolderTree(flatList);
      });
    } else {
      throw Exception('폴더 불러오기 실패');
    }
  }

  List<FolderSelectableItem> buildFolderTree(List<FolderSelectableItem> flatList) {
    Map<int, FolderSelectableItem> map = { for (var item in flatList) item.id : item };
    List<FolderSelectableItem> roots = [];

    for (var item in flatList) {
      if (item.parentId == null) {
        roots.add(item);
      } else {
        map[item.parentId!]?.children.add(item);
      }
    }
    return roots;
  }

  Widget buildFolderNode(FolderSelectableItem folder) {
    return ExpansionTile(
      title: Row(
        children: [
          Checkbox(
            value: selected?.id == folder.id,
            onChanged: (_) => setState(() => selected = folder),
          ),
          Expanded(
            child: Text(
              folder.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      initiallyExpanded: folder.isExpanded,
      children: folder.children.map(buildFolderNode).toList(),
      onExpansionChanged: (expanded) {
        setState(() => folder.isExpanded = expanded);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("폴더 선택"),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView(
          children: folderTree.map(buildFolderNode).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("취소"),
        ),
        ElevatedButton(
          onPressed: selected != null
              ? () => Navigator.pop(context, selected)
              : null,
          child: const Text("확인"),
        ),
      ],
    );
  }
}

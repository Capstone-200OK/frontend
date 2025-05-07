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
      List<FolderSelectableItem> flatList =
          data
              .map(
                (item) => FolderSelectableItem(
                  id: item['id'],
                  name: item['name'],
                  parentId: item['parentId'],
                  folderType: item['folderType'],
                ),
              )
              .toList();

      setState(() {
        folderTree = buildFolderTree(flatList);
      });
    } else {
      throw Exception('폴더 불러오기 실패');
    }
  }

  List<FolderSelectableItem> buildFolderTree(
    List<FolderSelectableItem> flatList,
  ) {
    Map<int, FolderSelectableItem> map = {
      for (var item in flatList) item.id: item,
    };
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
    final isRoot = folder.parentId == null;

    final titleRow = Row(
      children: [
        if (!isRoot)
          Transform.scale(
            scale: 0.7,
            child: Checkbox(
              value: selected?.id == folder.id,
              onChanged: (_) {
                setState(() {
                  if (selected?.id == folder.id) {
                    selected = null;
                  } else {
                    selected = folder;
                  }
                });
              },
            ),
          ),
        Expanded(
          child: Text(
            folder.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'APPLESDGOTHICNEOR',
              color:
                  isRoot
                      ? const Color(0xFFECEFF1)
                      : Colors.black, // ✅ 텍스트 색상 분기
             
            ),
          ),
        ),
      ],
    );

    return ExpansionTile(
      initiallyExpanded: folder.isExpanded,
      onExpansionChanged: (expanded) {
        setState(() => folder.isExpanded = expanded);
      },
      title:
          isRoot
              ? Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF455A64),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: titleRow,
              )
              : titleRow,
      children: folder.children.map(buildFolderNode).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), //  모서리
      ),
      title: const Text(
        "폴더 선택",
        style: TextStyle(fontSize: 18, fontFamily: 'APPLESDGOTHICNEOEB'),
      ),
      content: SizedBox(
        width: 400,
        height: 300,

        child: ListView(children: folderTree.map(buildFolderNode).toList()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            "취소",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'APPLESDGOTHICNEOR',
              color: Colors.black,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selected != null
                    ? const Color(0xFF2E24E0)
                    : const Color(0xFFCFD8DC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: selected != null ? 2 : 0,
          ),
          onPressed:
              selected != null
                  ? () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pop(
                        context,
                        FolderItem(id: selected!.id, name: selected!.name),
                      );
                    });
                  }
                  : null,
          child: Text(
            "확인",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'APPLESDGOTHICNEOR',
              color: selected != null ? Colors.white : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

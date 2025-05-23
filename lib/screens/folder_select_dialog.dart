import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

/// 폴더 항목 모델 (트리 구조 구성용)
class FolderSelectableItem {
  final int id;
  final String name;
  final int? parentId;
  final String folderType;
  List<FolderSelectableItem> children = []; // 하위 폴더
  bool isExpanded = false; // 확장 여부

  FolderSelectableItem({
    required this.id,
    required this.name,
    required this.parentId,
    required this.folderType,
  });
}

/// 폴더 선택 다이얼로그
class FolderSelectDialog extends StatefulWidget {
  const FolderSelectDialog({Key? key}) : super(key: key);

  @override
  State<FolderSelectDialog> createState() => _FolderSelectDialogState();
}

class _FolderSelectDialogState extends State<FolderSelectDialog> {
  List<FolderSelectableItem> folderTree = []; // 전체 트리 구조
  FolderSelectableItem? selected; // 선택된 폴더
  late int? userId;
  late String url;

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    // context 접근 가능한 시점에 사용자 ID 초기화 및 폴더 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      fetchSelectableFolders();
    });
  }

  /// 서버로부터 선택 가능한 폴더 목록 조회
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

  /// flat 리스트를 트리 구조로 변환
  List<FolderSelectableItem> buildFolderTree(
    List<FolderSelectableItem> flatList,
  ) {
    Map<int, FolderSelectableItem> map = {
      for (var item in flatList) item.id: item,
    };
    List<FolderSelectableItem> roots = [];

    for (var item in flatList) {
      if (item.parentId == null) {
        roots.add(item); // 루트 노드
      } else {
        map[item.parentId!]?.children.add(item); // 자식 노드로 연결
      }
    }
    return roots;
  }

  /// 폴더 트리 UI 구성 (재귀적으로 구성)
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
                      : Colors.black,
             
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
        // 취소 버튼
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
        // 확인 버튼 (선택된 폴더 반환)
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

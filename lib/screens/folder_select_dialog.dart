import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FolderSelectDialog extends StatefulWidget {
  const FolderSelectDialog({Key? key}) : super(key: key);

  @override
  State<FolderSelectDialog> createState() => _FolderSelectDialogState();
}

class _FolderSelectDialogState extends State<FolderSelectDialog> {
  List<FolderItem> currentFolders = [];
  List<int> folderStack = [];
  FolderItem? selected;

  late String url;

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    loadFolders(1); // 루트 폴더 ID
  }

  Future<void> loadFolders(int folderId) async {
    final response = await http.get(
      Uri.parse('$url/folder/hierarchy/$folderId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final subFolders = List<Map<String, dynamic>>.from(data['subFolders']);
      setState(() {
        currentFolders = subFolders
            .map((f) => FolderItem(id: f['id'], name: f['name']))
            .toList();

        if (folderStack.isEmpty || folderStack.last != folderId) {
          folderStack.add(folderId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (folderStack.length > 1)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (folderStack.length > 1) {
                  folderStack.removeLast();
                  loadFolders(folderStack.last);
                }
              },
            ),
          const Text("폴더 선택"),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: currentFolders.length,
          itemBuilder: (context, index) {
            final folder = currentFolders[index];
            final isSelected = selected?.id == folder.id;

            return GestureDetector(
              onTap: () => setState(() => selected = folder),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => setState(() => selected = folder),
                    ),
                    const Icon(Icons.folder, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folder.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => loadFolders(folder.id),
                    ),
                  ],
                ),
              ),
            );
          },
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

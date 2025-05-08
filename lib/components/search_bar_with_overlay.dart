import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

class SearchBarWithOverlay extends StatefulWidget {
  final String baseUrl;
  final String username;

  const SearchBarWithOverlay({
    Key? key,
    required this.baseUrl,
    required this.username,
  }) : super(key: key);

  @override
  State<SearchBarWithOverlay> createState() => _SearchBarWithOverlayState();
}

class _SearchBarWithOverlayState extends State<SearchBarWithOverlay> {
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _searchOverlay;

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  TextSpan highlightOccurrences(String source, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: source,
        style: const TextStyle(color: Colors.black, fontSize: 14),
      );
    }

    final matches = <TextSpan>[];
    final lcSource = source.toLowerCase();
    final lcQuery = query.toLowerCase();

    int start = 0;
    int index = lcSource.indexOf(lcQuery, start);

    while (index != -1) {
      if (index > start) {
        matches.add(TextSpan(
          text: source.substring(start, index),
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ));
      }

      matches.add(TextSpan(
        text: source.substring(index, index + query.length),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
      ));

      start = index + query.length;
      index = lcSource.indexOf(lcQuery, start);
    }

    if (start < source.length) {
      matches.add(TextSpan(
        text: source.substring(start),
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ));
    }

    return TextSpan(children: matches);
  }

  Future<void> searchFoldersAndFiles(String input) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final url = widget.baseUrl;

    if (input.trim().isEmpty || userId == null) return;

    final folderRes = await http.get(Uri.parse('$url/folder/search/$userId/$input'));
    final fileRes = await http.get(Uri.parse('$url/file/search/$userId/$input'));

    if (folderRes.statusCode == 200 && fileRes.statusCode == 200) {
      final folderJson = List<Map<String, dynamic>>.from(
        jsonDecode(folderRes.body).map((e) => Map<String, dynamic>.from(e)),
      );

      final fileJson = List<Map<String, dynamic>>.from(
        jsonDecode(fileRes.body).map((e) => Map<String, dynamic>.from(e)),
      );

      final combinedResults = [
        ...folderJson.map((e) => {...e, 'type': 'folder'}),
        ...fileJson.map((e) => {...e, 'type': 'file'}),
      ];

      showSearchOverlay(combinedResults, userId);
    }
  }

  void showSearchOverlay(List<Map<String, dynamic>> results, int userId) {
    _removeSearchOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _searchOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy - 300,
        width: 800,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.white,
            child: ListView(
              shrinkWrap: true,
              children: results.map((item) {
                final isFolder = item['type'] == 'folder';
                return ListTile(
                  leading: Icon(
                    isFolder ? Icons.folder : Icons.insert_drive_file,
                    color: isFolder ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                  title: RichText(
                    text: highlightOccurrences(
                      item[isFolder ? 'folderName' : 'fileName'],
                      _searchController.text,
                    ),
                  ),
                  subtitle: Text(
                    item['parentFolderName'] != null
                        ? (item['folderType'] != null
                            ? "${item['folderType']}: ${item['parentFolderName']}"
                            : item['parentFolderName'])
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () async {
                    final id = isFolder ? item['folderId'] : item['parentFolderId'];
                    final response = await http.get(Uri.parse('${widget.baseUrl}/folder/path/$id'));

                    if (response.statusCode == 200) {
                      final List<dynamic> jsonList = jsonDecode(response.body);
                      final List<int> pathIds = jsonList.map((e) => e['folderId'] as int).toList();

                      _removeSearchOverlay();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonalScreen(
                            username: widget.username,
                            targetPathIds: pathIds,
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_searchOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 800,
        child: TextField(
          controller: _searchController,
          onSubmitted: (value) => searchFoldersAndFiles(value),
          style: const TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
          decoration: InputDecoration(
            hintText: 'search',
            hintStyle: const TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
            filled: true,
            fillColor: const Color(0xFFCFD8DC),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF607D8B), width: 2),
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xff263238)),
            suffixIcon: const Icon(Icons.tune, color: Color(0xff263238)),
          ),
        ),
      ),
    );
  }
}

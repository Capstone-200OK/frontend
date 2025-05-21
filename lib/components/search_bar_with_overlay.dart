import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:flutter_application_1/screens/cloud_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';

class SearchBarWithOverlay extends StatefulWidget {
  final String baseUrl;
  final String username;
  final String? preScreen;
  final List<int>? prePathIds;

  const SearchBarWithOverlay({
    Key? key,
    required this.baseUrl,
    required this.username,
    this.preScreen,
    this.prePathIds,
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
        matches.add(
          TextSpan(
            text: source.substring(start, index),
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        );
      }

      matches.add(
        TextSpan(
          text: source.substring(index, index + query.length),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 14,
          ),
        ),
      );

      start = index + query.length;
      index = lcSource.indexOf(lcQuery, start);
    }

    if (start < source.length) {
      matches.add(
        TextSpan(
          text: source.substring(start),
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      );
    }

    return TextSpan(children: matches);
  }

  Future<void> searchFoldersAndFiles(String input) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final url = widget.baseUrl;

    if (input.trim().isEmpty || userId == null) return;

    final folderRes = await http.get(
      Uri.parse('$url/folder/search/$userId/$input'),
    );
    final fileRes = await http.get(
      Uri.parse('$url/file/search/$userId/$input'),
    );

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
      builder:
          (context) => Stack(
            children: [
              // 🔹 배경을 터치하면 오버레이 제거
              GestureDetector(
                onTap: _removeSearchOverlay,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.transparent, // 투명 배경
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),

              // 🔹 검색 결과 박스
              Positioned(
                left: position.dx + 97,
                top: position.dy - 275,
                width: 800,
                child: Material(
                  elevation: 4,
                  //borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 250, // ✅ 최대 높이 지정
                     
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        ListView(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children:
                              results.map((item) {
                                final isFolder = item['type'] == 'folder';
                                return ListTile(
                                  leading: Icon(
                                    isFolder
                                        ? Icons.folder
                                        : Icons.insert_drive_file,
                                    color:
                                        isFolder ? Colors.amber : Colors.grey,
                                    size: 20,
                                  ),
                                  title: RichText(
                                    text: highlightOccurrences(
                                      item[isFolder
                                          ? 'folderName'
                                          : 'fileName'],
                                      _searchController.text,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item['parentFolderName'] != null
                                        ? (item['folderType'] != null
                                            ? "${item['folderType']}: ${item['parentFolderName']}"
                                            : item['parentFolderName'])
                                        : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () async {
                                    final id =
                                        isFolder
                                            ? item['folderId']
                                            : item['parentFolderId'];
                                    if (isFolder && item['folderType'] == 'CLOUD') {
                                      final userId = Provider.of<UserProvider>(context, listen: false).userId;
                                      final response = await http.get(
                                        Uri.parse(
                                          '${widget.baseUrl}/folder/cloudPath/$userId/$id',
                                        ),
                                      );
                                      if (response.statusCode == 200) {
                                        final List<dynamic> jsonList = jsonDecode(
                                          response.body,
                                        );
                                        final List<int> pathIds =
                                            jsonList
                                                .map((e) => e['folderId'] as int)
                                                .toList();
                                        _removeSearchOverlay();
                                        if (widget.prePathIds != null) {
                                          NavigationStack.pop();
                                          if (widget.preScreen == 'CLOUD') {
                                            NavigationStack.push('CloudScreen2', arguments: {
                                            'username': widget.username,
                                            'targetPathIds': widget.prePathIds,
                                            });
                                          }
                                          else if (widget.preScreen == 'PERSONAL') {
                                            NavigationStack.push('PersonalScreen2', arguments: {
                                            'username': widget.username,
                                            'targetPathIds': widget.prePathIds,
                                            });
                                          }
                                          NavigationStack.printStack();
                                        }
                                        NavigationStack.push('SearchCloudScreen', arguments: {
                                          'username': widget.username,
                                          'targetPathIds': pathIds,
                                        });
                                        NavigationStack.printStack();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CloudScreen(
                                                  username: widget.username,
                                                  targetPathIds: pathIds,
                                                ),
                                          ),
                                        );
                                      }
                                    } else {
                                      final response = await http.get(
                                        Uri.parse(
                                          '${widget.baseUrl}/folder/path/$id',
                                        ),
                                      );
                                      if (response.statusCode == 200) {
                                        final List<dynamic> jsonList = jsonDecode(
                                          response.body,
                                        );
                                        final List<int> pathIds =
                                            jsonList
                                                .map((e) => e['folderId'] as int)
                                                .toList();
                                        _removeSearchOverlay();
                                        if (widget.prePathIds != null) {
                                          NavigationStack.pop();
                                          if (widget.preScreen == 'CLOUD') {
                                            NavigationStack.push('CloudScreen2', arguments: {
                                            'username': widget.username,
                                            'targetPathIds': widget.prePathIds,
                                            });
                                          }
                                          else if (widget.preScreen == 'PERSONAL') {
                                            NavigationStack.push('PersonalScreen2', arguments: {
                                            'username': widget.username,
                                            'targetPathIds': widget.prePathIds,
                                            });
                                          }
                                          NavigationStack.printStack();
                                        }
                                        NavigationStack.push('SearchPersonalScreen', arguments: {
                                          'username': widget.username,
                                          'targetPathIds': pathIds,
                                        });
                                        NavigationStack.printStack();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => PersonalScreen(
                                                  username: widget.username,
                                                  targetPathIds: pathIds,
                                                ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              }).toList(),
                        ),

                        // 🔽 위쪽 그라데이션
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: IgnorePointer(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white54,
                                    //Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'APPLESDGOTHICNEOEB',
          ),
          decoration: InputDecoration(
            hintText: 'search',
            hintStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'APPLESDGOTHICNEOEB',
            ),
            filled: true,
            fillColor: const Color(0xFFCFD8DC),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF607D8B), width: 2),
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xff263238)),
            //suffixIcon: const Icon(Icons.tune, color: Color(0xff263238)),
          ),
        ),
      ),
    );
  }
}

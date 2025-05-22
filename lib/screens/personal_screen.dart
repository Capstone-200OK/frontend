import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_application_1/api/file_uploader.dart';
import 'package:flutter_application_1/api/important.dart';
import 'package:flutter_application_1/screens/file_sorty.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:flutter_application_1/api/trash.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/models/file_item.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_application_1/models/important_folder_item.dart';
import 'package:flutter_application_1/models/important_file_item.dart';
import 'package:flutter_application_1/components/navigation_drawer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/screens/file_view_dialog.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_application_1/components/search_bar_with_overlay.dart';
import 'package:flutter_application_1/api/websocket_service.dart';
import 'package:flutter_application_1/components/notification_button.dart'; // NotificationButton 위젯
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';
import 'package:flutter_application_1/components/navigation_helper.dart';

class PersonalScreen extends StatefulWidget {
  final String username;
  final List<int>? targetPathIds;

  const PersonalScreen({Key? key, required this.username, this.targetPathIds})
    : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  // 파일 선택 상태 저장용 리스트
  List<FileItem> selectedFiles = [];
  List<String> selectedFolderNames = [];
  String? selectedFolderName;
  bool isStartSelected = false;
  bool isDestSelected = false;
  // 폴더 목록 상태 관리
  List<String> folders = [];
  // 클래스 맨 위에 추가
  final GlobalKey _previewKey = GlobalKey();
  OverlayEntry? _previewOverlay;
  Timer? _hoverTimer;
  bool _isUploading = false;
  Set<String> fileNames = {}; // 중복 방지를 위한 파일 이름 저장용 집합
  late String url;
  late FileUploader uploader;
  int currentFolderId = 1; // 시작 폴더 ID (예: 2번 루트)
  String currentFolderName = 'ROOT'; // 현재 폴더명 ( ROOT로 시작 )
  List<String> breadcrumbPath = ['ROOT']; // 폴더명을 저장하는 List
  List<int> folderStack = []; // 상위 폴더 경로 추적
  Map<String, int> folderNameToId = {};
  Map<int, String> folderIdToName = {};
  late String s3BaseUrl;
  late int? userId;
  bool _dragHandled = false;
  List<ImportantFolderItem> importantFolders = [];
  List<ImportantFileItem> importantFiles = [];
  bool isAlreadyImportantFolder(int folderId) {
    return importantFolders.any((f) => f.folderId == folderId);
  }

  bool isAlreadyImportantFile(int fileId) {
    return importantFiles.any((f) => f.fileId == fileId);
  }

  List<Map<String, dynamic>> searchResults = [];
  OverlayEntry? _searchOverlay;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    s3BaseUrl = dotenv.get("S3BaseUrl");
    uploader = FileUploader(baseUrl: url, s3BaseUrl: s3BaseUrl);
    folderIdToName[1] = 'Root';
    // context 사용 가능한 시점에 userId 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = Provider.of<UserProvider>(context, listen: false).userId;

      if (widget.targetPathIds != null && widget.targetPathIds!.isNotEmpty) {
        for (final folderId in widget.targetPathIds!) {
          await fetchFolderHierarchy(folderId, userId!, pushToStack: true);
        }
      } else {
        await fetchFolderHierarchy(1, userId!, pushToStack: false);
      }

      await fetchImportantStatus(); // 별표 상태 초기화
    });
  }

  String getCurrentFolderPath() {
    List<int> pathIds = [...folderStack, currentFolderId];
    List<String> pathNames =
        pathIds.map((id) => folderIdToName[id] ?? 'Unknown').toList();
    return pathNames.join('/');
  }

  String getTruncatedPath({int showLast = 2}) {
    //상위는 ...으로 표시하기기
    if (breadcrumbPath.length <= showLast + 1) {
      return breadcrumbPath.join("  >  ");
    }

    final start = '...';
    final end = breadcrumbPath
        .sublist(breadcrumbPath.length - showLast)
        .join("  >  ");
    return '$start  >  $end';
  }

  Future<void> fetchImportantStatus() async {
    if (userId == null) return;
    final folders = await fetchImportantFolders(userId!);
    final files = await fetchImportantFiles(userId!);
    setState(() {
      importantFolders = folders;
      importantFiles = files;
    });
  }

  Future<void> fetchFolderHierarchy(
    int folderId,
    int userId, {
    bool pushToStack = true,
  }) async {
    final response = await http.get(
      Uri.parse('$url/folder/hierarchy/$folderId/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(
        data['subFolders'],
      );

      folderNameToId = {for (var f in folderList) f['name']: f['id']};

      // ✅ 덮어쓰기 제거하고 addAll만 사용
      folderIdToName.addAll({for (var f in folderList) f['id']: f['name']});

      setState(() {
        currentFolderName = data['name'] ?? 'ROOT';

        if (pushToStack && currentFolderId != folderId) {
          folderStack.add(currentFolderId);
          breadcrumbPath.add(currentFolderName);
        } else if (!pushToStack) {
          if (breadcrumbPath.length > 1) {
            breadcrumbPath.removeLast();
          }
        }

        currentFolderId = folderId;

        // 🔸 folder 이름 리스트만 추출하여 UI용으로 저장
        folders = folderList.map((f) => f['name'] as String).toList();

        selectedFiles = List<FileItem>.from(
          data['files'].map(
            (f) => FileItem(
              id: f['id'],
              name: f['name'],
              type: f['fileType'],
              sizeInBytes: f['size'],
              fileUrl: f['fileUrl'],
              fileThumbnail: f['fileThumbUrl'],
            ),
          ),
        );

        fileNames = selectedFiles.map((f) => f.name).toSet();
      });
    } else {
      print('폴더 계층 불러오기 실패: ${response.statusCode}');
    }
  }

  Future<void> refreshCurrentFolderFiles() async {
    final response = await http.get(
      Uri.parse('$url/folder/hierarchy/$currentFolderId/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(
        data['subFolders'],
      );

      folderNameToId = {for (var f in folderList) f['name']: f['id']};
      folderIdToName.addAll({for (var f in folderList) f['id']: f['name']});

      setState(() {
        folders = folderList.map((f) => f['name'] as String).toList();

        selectedFiles = List<FileItem>.from(
          data['files'].map(
            (f) => FileItem(
              name: f['name'],
              type: f['fileType'],
              sizeInBytes: f['size'],
              fileUrl: f['fileUrl'],
              fileThumbnail: f['fileThumbUrl'],
            ),
          ),
        );

        fileNames = selectedFiles.map((f) => f.name).toSet();
      });
    } else {
      print('파일 새로고침 실패: ${response.statusCode}');
    }
  }

  void _showPreviewOverlay(
    BuildContext context,
    String? url,
    String type,
    GlobalKey key,
  ) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || url == null) return;

    final overlay = Overlay.of(context);
    final offset = renderBox.localToGlobal(Offset.zero);

    _previewOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx + renderBox.size.width + 10,
            top: offset.dy,
            child: Material(
              elevation: 4,
              child: Container(
                width: 240,
                height: 240,
                color: Colors.white,
                child: _buildPreviewContent(url, type),
              ),
            ),
          ),
    );

    overlay.insert(_previewOverlay!);
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

  Future<void> showContextMenuAtPosition({
    required BuildContext context,
    required Offset position,
    required Function(String?) onSelected,
  }) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect positionRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: positionRect,
      color: Color(0xFFECEFF1),
      items: [
        PopupMenuItem(
          value: 'create',
          child: Row(
            children: const [
              Icon(Icons.create_new_folder, size: 16, color: Colors.black54),
              SizedBox(width: 8),
              Text('새 폴더', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete, size: 16, color: Colors.black54),
              SizedBox(width: 8),
              Text('삭제', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_to_important',
          child: Row(
            children: const [
              Icon(Icons.star, size: 15, color: Colors.black54),
              SizedBox(width: 8),
              Text('중요 문서로 추가', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );

    onSelected(selected);
  }

  Widget _buildPreviewContent(String url, String type, {String? thumbnailUrl}) {
    final lower = type.toLowerCase();

    // 이미지 확장자면 원본 URL 사용
    if (["png", "jpg", "jpeg", "gif", "bmp"].contains(lower)) {
      return Image.network(url, fit: BoxFit.contain);
    }

    // 썸네일 URL이 있으면 우선 사용
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Image.network(thumbnailUrl, fit: BoxFit.contain);
    }

    // fallback: 직접 렌더링 시도
    if (lower == "pdf") {
      return SfPdfViewer.network(url); // PDF 지원
    } else if (["doc", "docx", "xls", "xlsx", "ppt", "pptx"].contains(lower)) {
      return OfficeViewerWindows(fileUrl: url); // 오피스
    }

    return const Center(child: Text("미리보기를 지원하지 않는 형식입니다."));
  }

  void _removePreviewOverlay() {
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  void _showPreviewOverlayAtPosition(
    BuildContext context,
    String? url,
    String type,
    Offset position, {
    String? thumbnailUrl,
  }) {
    if (url == null) return;

    _removePreviewOverlay();

    _previewOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: position.dx,
            top: position.dy - 250,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 240,
                height: 240,
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: _buildPreviewContent(
                  url,
                  type,
                  thumbnailUrl: thumbnailUrl,
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_previewOverlay!);
  }

  void addFolder(String name) {
    setState(() {
      folders.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false, // 기본 뒤로가기/햄버거 제거
          backgroundColor: Colors.white,
          elevation: 0,

          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
          ),
          title: Row(
            children: [
              const SizedBox(width: 22), //햄버거 버튼과의 간격
              IconButton(
                icon: const Icon(
                  Icons.home,
                  color: Color(0xff263238),
                  size: 24,
                ),
                onPressed: () {
                  NavigationStack.clear();
                  NavigationStack.push(
                    'HomeScreen',
                    arguments: {'username': widget.username},
                  );
                  NavigationStack.printStack();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(username: widget.username),
                    ),
                  );
                },
              ),
              const SizedBox(width: 22),
              // 뒤로가기 버튼
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Color(0xff263238),
                  size: 15,
                ),
                onPressed: () {
                  final currentRoute = NavigationStack.peek()?['route'];

                  if (folderStack.isEmpty ||
                      currentRoute == 'SearchPersonalScreen') {
                    // ✅ stack이 비어있거나 현재 route가 SearchPersonalSceen이면 NavigationHelper 사용
                    NavigationHelper.navigateToPrevious(context);
                  } else {
                    // ✅ 일반 폴더 뒤로가기
                    int previousFolderId = folderStack.removeLast();
                    fetchFolderHierarchy(
                      previousFolderId,
                      userId!,
                      pushToStack: false,
                    );
                  }
                },
              ),
              const SizedBox(width: 8),

              // 타이틀
              Expanded(
                child: Text(
                  '${widget.username}님의 파일함',
                  style: const TextStyle(
                    fontSize: 18,
                    //fontWeight: FontWeight.bold,
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
                ),
              ),
              //아이콘 버튼
              Padding(
                padding: const EdgeInsets.only(right: 95), // 오른쪽에서 10px 떨어짐
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history, color: Color(0xff263238)),
                      onPressed: () {
                        NavigationStack.pop();
                        NavigationStack.push(
                          'PersonalScreen2',
                          arguments: {
                            'username': widget.username,
                            'targetPathIds': [...folderStack, currentFolderId],
                          },
                        );
                        NavigationStack.printStack();
                        NavigationStack.push(
                          'RecentFileScreen',
                          arguments: {
                            'username': widget.username,
                            'userId': userId,
                          },
                        );
                        NavigationStack.printStack();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RecentFileScreen(
                                  username: widget.username,
                                  userId: userId,
                                ),
                          ),
                        );
                      },
                    ),
                    const NotificationButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      drawer: NavigationDrawerWidget(
        username: widget.username,

        onFolderCreated: (folderName) {
          setState(() {
            folders.add(folderName);
          });
        },
        folders: folders,
        scaffoldContext: context,
        preScreen: 'PERSONAL',
        prePathIds: [...folderStack, currentFolderId],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 폴더 & 파일 레이블
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100.0),
                    child: Tooltip(
                      message: breadcrumbPath.join(" / "),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(breadcrumbPath.length, (
                            index,
                          ) {
                            int showLast = 2;
                            bool isEllipsis =
                                (breadcrumbPath.length > showLast + 1 &&
                                    index == 0);
                            bool isHidden =
                                (breadcrumbPath.length > showLast + 1 &&
                                    index < breadcrumbPath.length - showLast);
                            bool isLast = index == breadcrumbPath.length - 1;
                            bool clickable = !isLast && !isEllipsis;

                            if (!isEllipsis && isHidden)
                              return SizedBox.shrink();

                            return Row(
                              children: [
                                GestureDetector(
                                  onTapDown:
                                      isEllipsis
                                          ? (details) async {
                                            final hiddenItems = breadcrumbPath
                                                .sublist(
                                                  0,
                                                  breadcrumbPath.length -
                                                      showLast,
                                                );
                                            final selected = await showMenu<
                                              String
                                            >(
                                              context: context,
                                              position: RelativeRect.fromLTRB(
                                                details.globalPosition.dx,
                                                details.globalPosition.dy,
                                                details.globalPosition.dx,
                                                details.globalPosition.dy,
                                              ),
                                              items:
                                                  hiddenItems.map((name) {
                                                    return PopupMenuItem<
                                                      String
                                                    >(
                                                      value: name,
                                                      
                                                      child: Row(
                                                        children: [
                                                          SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              name,
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontFamily:
                                                                    'APPLESDGOTHICNEOR',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                            );
                                            if (selected != null) {
                                              int targetIndex = breadcrumbPath
                                                  .indexOf(selected);
                                              int diff =
                                                  (breadcrumbPath.length - 1) -
                                                  targetIndex;

                                              for (int i = 0; i < diff; i++) {
                                                if (folderStack.isNotEmpty) {
                                                  int previousFolderId =
                                                      folderStack.removeLast();
                                                  await fetchFolderHierarchy(
                                                    previousFolderId,
                                                    userId!,
                                                    pushToStack: false,
                                                  );
                                                }
                                              }
                                            }
                                          }
                                          : null,
                                  onTap:
                                      (isEllipsis || !clickable)
                                          ? null
                                          : () async {
                                            int diff =
                                                (breadcrumbPath.length - 1) -
                                                index;

                                            for (int i = 0; i < diff; i++) {
                                              if (folderStack.isNotEmpty) {
                                                int previousFolderId =
                                                    folderStack.removeLast();
                                                await fetchFolderHierarchy(
                                                  previousFolderId,
                                                  userId!,
                                                  pushToStack: false,
                                                );
                                              }
                                            }
                                          },
                                  child: Text(
                                    isEllipsis ? "..." : breadcrumbPath[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'APPLESDGOTHICNEOR',
                                      color:
                                          (isEllipsis || clickable)
                                              ? Colors.black
                                              : Colors.black,
                                      decoration:
                                          (isEllipsis || clickable)
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  const Text(
                                    "  >  ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'APPLESDGOTHICNEOR',
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 110.0),
                    child: Text(
                      '파일',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 101),
                  child: Row(
                    children: [
                      // 🔹 새 폴더 아이콘 버튼
                      IconButton(
                        icon: const Icon(
                          Icons.create_new_folder,
                          color: Color(0xFF596D79),
                        ),
                        tooltip: '새 폴더 생성',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => FolderCreateScreen(
                                  parentFolderId: currentFolderId,
                                  onCreateFolder: (newName) async {
                                    await refreshCurrentFolderFiles();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '"$newName" 폴더가 생성되었습니다.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          );
                        },
                      ),

                      const SizedBox(width: 10), // 버튼 사이 간격
                      // 🔹 Sorty 버튼
                      ElevatedButton(
                        onPressed:
                            selectedFolderNames.isNotEmpty
                                ? () {
                                  final selectedFolderItems =
                                      selectedFolderNames.map((name) {
                                        return FolderItem(
                                          name: name,
                                          id: folderNameToId[name]!,
                                        );
                                      }).toList();

                                  final selectedFolderIds =
                                      selectedFolderItems
                                          .map((f) => f.id)
                                          .toList();

                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => FileSortyScreen(
                                          folders: selectedFolderItems,
                                          username: widget.username,
                                          sourceFolderIds: selectedFolderIds,
                                          destinationFolderId: -1,
                                        ),
                                  );
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E24E0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          "SORTY",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 폴더 & 파일 영역
            Container(
              height: 450,
              width: 800,
              child: Row(
                children: [
                  // 폴더 리스트
                  Expanded(
                    child: Container(
                      height: 425,
                      decoration: BoxDecoration(
                        color: Color(0xFFCFD8DC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),

                      // 🔽 GestureDetector로 감싸서 우클릭 이벤트 추가
                      child: GestureDetector(
                        child: GridView.builder(
                          itemCount: folders.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.0,
                              ),
                          itemBuilder: (context, index) {
                            final folderName = folders[index];
                            final folderId = folderNameToId[folderName];
                            final folderKey = GlobalKey();
                            final isSelected = selectedFolderNames.contains(
                              folderName,
                            );

                            return GestureDetector(
                              key: folderKey,
                              onTap: () {
                                setState(() {
                                  if (selectedFolderNames.contains(
                                    folderName,
                                  )) {
                                    selectedFolderNames.remove(folderName);
                                  } else {
                                    selectedFolderNames.add(folderName);
                                  }
                                });
                              },
                              onDoubleTap: () {
                                if (folderId != null) {
                                  fetchFolderHierarchy(folderId, userId!);
                                }
                              },
                              onSecondaryTapDown: (TapDownDetails details) {
                                showContextMenuAtPosition(
                                  context: context,
                                  position: details.globalPosition,
                                  onSelected: (selected) async {
                                    if (selected == 'delete') {
                                      if (folderId != null) {
                                        await moveToTrash(userId!, [
                                          folderId,
                                        ], []);
                                        setState(() {
                                          folders.removeAt(index);
                                        });
                                      }
                                    } else if (selected == 'add_to_important') {
                                      if (folderId != null &&
                                          !isAlreadyImportantFolder(folderId)) {
                                        await addToImportant(
                                          userId: userId!,
                                          folderId: folderId,
                                        );
                                        await fetchImportantStatus();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '$folderName 폴더가 중요 문서함에 추가되었습니다.',
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (selected == 'create') {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => FolderCreateScreen(
                                              parentFolderId: currentFolderId,
                                              onCreateFolder: (newName) async {
                                                await refreshCurrentFolderFiles(); // 새로고침
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '"$newName" 폴더가 생성되었습니다.',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                      );
                                    }
                                  },
                                );
                              },

                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        selectedFolderNames.contains(folderName)
                                            ? Colors.blueGrey
                                            : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 3,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.6,
                                      child: Checkbox(
                                        value: selectedFolderNames.contains(
                                          folderName,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedFolderNames.add(
                                                folderName,
                                              );
                                            } else {
                                              selectedFolderNames.remove(
                                                folderName,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const Icon(
                                      Icons.folder,
                                      color: Color(0xFF263238),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        folderName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'APPLESDGOTHICNEOR',
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isAlreadyImportantFolder(folderId!)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color:
                                            isAlreadyImportantFolder(folderId!)
                                                ? Colors.amber
                                                : Colors.grey,
                                        size: 13,
                                      ),
                                      onPressed: () async {
                                        if (isAlreadyImportantFolder(
                                          folderId!,
                                        )) {
                                          final target = importantFolders
                                              .firstWhere(
                                                (f) => f.folderId == folderId,
                                              );
                                          await removeFromImportant(
                                            target.importantId,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$folderName 폴더가 중요 문서함에서 삭제되었습니다.',
                                              ),
                                            ),
                                          );
                                        } else {
                                          await addToImportant(
                                            userId: userId!,
                                            folderId: folderId,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$folderName 폴더가 중요 문서함에 추가되었습니다.',
                                              ),
                                            ),
                                          );
                                        }
                                        await fetchImportantStatus();
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 파일 리스트
                  Expanded(
                    // DropTarget (파일 드래그 앤 드랍)
                    child: DropTarget(
                      onDragDone: (detail) async {
                        if (_isUploading || _dragHandled) return;
                        _isUploading = true;
                        _dragHandled = true;

                        try {
                          List<File> droppedFiles =
                              detail.files.map((f) => File(f.path)).toList();

                          List<FileItem> newFileItems = [];

                          // 드래그 앤 드롭한 파일이 비어있는지 확인
                          if (droppedFiles.isEmpty) {
                            print('드래그된 파일이 없습니다.');
                            return;
                          }

                          // 중복 체크 및 파일 정보 업데이트
                          for (final file in detail.files) {
                            final fileName = file.name;

                            if (!fileNames.contains(fileName)) {
                              final fileType = fileName.split('.').last;
                              final fileSize = File(file.path).lengthSync();
                              final fileItem = FileItem(
                                name: fileName,
                                type: fileType,
                                sizeInBytes: fileSize,
                              );
                              newFileItems.add(fileItem);
                              fileNames.add(fileName);
                            }
                          }

                          setState(() {
                            selectedFiles.addAll(newFileItems);
                          });
                          final int fixedFolderId =
                              currentFolderId; // 💥 여기서 고정
                          final currentFolderPath = getCurrentFolderPath();
                          // 업로드 호출
                          print('📦 folderIdToName: $folderIdToName');
                          print('📁 folderStack: $folderStack');
                          print('📁 currentFolderId: $currentFolderId');
                          print('📁 경로: $currentFolderPath');
                          await uploader.uploadFiles(
                            file: droppedFiles[0],
                            userId: userId!, // login 할때때 받아올 값으로 수정
                            folderId: fixedFolderId,
                            currentFolderPath: currentFolderPath,
                          );
                          await refreshCurrentFolderFiles();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${droppedFiles.length}개의 파일 업로드 완료!',
                              ),
                            ),
                          );
                        } catch (e) {
                          // 예외 발생 시 처리
                          print('파일 업로드 중 오류 발생: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('파일 업로드 실패: $e')),
                          );
                        } finally {
                          _isUploading = false;
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _dragHandled = false;
                          });
                        }
                      },
                      onDragEntered: (details) {
                        print('드래그 시작');
                      },
                      onDragExited: (details) {
                        print('드래그 종료');
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 7,
                        ),

                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFECEFF1),
                          border: Border.all(color: Color(0xff90A4AE)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: selectedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = selectedFiles[index];
                                  final fileKey = GlobalKey();
                                  return GestureDetector(
                                    onSecondaryTapDown: (
                                      TapDownDetails details,
                                    ) {
                                      showContextMenuAtPosition(
                                        context: context,
                                        position: details.globalPosition,
                                        onSelected: (selected) async {
                                          final file = selectedFiles[index];
                                          if (selected == 'delete') {
                                            try {
                                              await moveToTrash(userId!, [], [
                                                file.id,
                                              ]);
                                              setState(() {
                                                selectedFiles.removeAt(index);
                                                fileNames.remove(file.name);
                                              });
                                            } catch (e) {
                                              print('파일 휴지통 이동 실패: $e');
                                            }
                                          } else if (selected ==
                                              'add_to_important') {
                                            if (isAlreadyImportantFile(
                                              file.id!,
                                            )) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '이미 중요 문서함에 추가된 파일입니다.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            try {
                                              await addToImportant(
                                                userId: userId!,
                                                fileId: file.id,
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${file.name} 파일이 중요 문서함에 추가되었습니다.',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              print('중요 문서 추가 실패: $e');
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '중요 문서 추가 실패: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      );
                                    },
                                    child: MouseRegion(
                                      key: fileKey,
                                      onEnter: (event) {
                                        _hoverTimer = Timer(
                                          const Duration(milliseconds: 500),
                                          () {
                                            final position =
                                                event.position; // 마우스 위치
                                            _showPreviewOverlayAtPosition(
                                              context,
                                              file.fileUrl,
                                              file.type,
                                              position,
                                              thumbnailUrl: file.fileThumbnail,
                                            );
                                          },
                                        );
                                      },
                                      onExit: (_) {
                                        _hoverTimer?.cancel();
                                        _removePreviewOverlay();
                                      },
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.insert_drive_file,
                                          size: 20,
                                        ),
                                        title: Text(
                                          file.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          '${file.type} • ${(file.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                                          style: const TextStyle(fontSize: 11),
                                        ),

                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isAlreadyImportantFile(file.id!)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color:
                                                    isAlreadyImportantFile(
                                                          file.id!,
                                                        )
                                                        ? Colors.amber
                                                        : Colors.grey,
                                                size: 13,
                                              ),
                                              onPressed: () async {
                                                if (isAlreadyImportantFile(
                                                  file.id!,
                                                )) {
                                                  final target = importantFiles
                                                      .firstWhere(
                                                        (f) =>
                                                            f.fileId == file.id,
                                                      );
                                                  await removeFromImportant(
                                                    target.importantId,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '${file.name} 파일이 중요 문서함에서 삭제되었습니다.',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  await addToImportant(
                                                    userId: userId!,
                                                    fileId: file.id,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '${file.name} 파일이 중요 문서함에 추가되었습니다.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                                await fetchImportantStatus();
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          print(
                                            '[파일 미리보기 요청] file.name=${file.name}, fileUrl=${file.fileUrl}, type=${file.type}',
                                          );
                                          showDialog(
                                            context: context,
                                            builder:
                                                (_) => FilePreviewDialog(
                                                  fileUrl: file.fileUrl!,
                                                  fileType: file.type,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // 검색창
            SearchBarWithOverlay(
              baseUrl: dotenv.get("BaseUrl"),
              username: widget.username,
              preScreen: 'PERSONAL',
              prePathIds: [...folderStack, currentFolderId],
            ),
          ],
        ),
      ),
    );
  }
}

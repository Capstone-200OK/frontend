import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_application_1/api/file_uploader.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_application_1/screens/file_sorty.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:flutter_application_1/screens/trash_screen.dart';
import 'package:flutter_application_1/screens/file_reservation_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/models/file_item.dart';
import 'package:flutter_application_1/models/folder_item.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/screens/file_view_dialog.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

class PersonalScreen extends StatefulWidget {
  final String username;

  const PersonalScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  // 파일 선택 상태 저장용 리스트
  List<FileItem> selectedFiles = [];
  List<String> selectedFolderNames = [];
  List<FileItem> importantFolders = []; // 중요 폴더 리스트
  String? selectedFolderName;
  int? startFolderId;
  int? destFolderId;
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

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    s3BaseUrl = dotenv.get("S3BaseUrl");
    uploader = FileUploader(baseUrl: url, s3BaseUrl: s3BaseUrl);
    folderIdToName[1] = 'Root';
    // context 사용 가능한 시점에 userId 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        userId = Provider.of<UserProvider>(context, listen: false).userId;
      });
      fetchFolderHierarchy(1, userId!, pushToStack: false); // userId 초기화된 이후 호출
    });
  }

  String getCurrentFolderPath() {
    List<int> pathIds = [...folderStack, currentFolderId];
    List<String> pathNames =
        pathIds.map((id) => folderIdToName[id] ?? 'Unknown').toList();
    return pathNames.join('/');
  }

  Future<void> fetchFolderHierarchy(
    int folderId,
    int userId, {
    bool pushToStack = true,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$url/folder/hierarchy/$folderId/$userId',
      ), // $url/folder/hierarchy/$folderId/$userId 로 수정 필요 (login 할때 받은 userId 전송)
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
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(data['subFolders']);

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

  Future<void> showContextMenu({
    required BuildContext context,
    required GlobalKey key,
    required Function(String?) onSelected,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final double dx = offset.dx + 80; // 오른쪽으로 10px
    final double dy = offset.dy + 60; // 아래로 5px

    final RelativeRect position = RelativeRect.fromLTRB(
      dx,
      dy,
      overlay.size.width - dx - renderBox.size.width,
      overlay.size.height - dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Text(
            '삭제',
            style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR'),
          ),
        ),
        PopupMenuItem(
          value: 'add_to_important',
          child: Text(
            '중요 폴더로 추가',
            style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR'),
          ),
        ),
      ],
      elevation: 8,
      color: Colors.white,
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
                  Icons.home, // 홈 모양 아이콘
                  color: Color(0xff263238), // 짙은 남색 계열
                  size: 24, // 아이콘 크기 (적당한 크기)
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => HomeScreen(username: widget.username),
                    ),
                  );
                },
              ),
              const SizedBox(width: 22),
              // 뒤로가기 버튼
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color:
                      folderStack.isEmpty
                          ? Colors.grey
                          : Color(0xff263238), // 스택 비었으면 회색
                  size: 15,
                ),
                onPressed:
                    folderStack.isEmpty
                        ? null // 스택 비었으면 비활성화
                        : () {
                          int previousFolderId =
                              folderStack.removeLast(); // 마지막 폴더ID 꺼내기
                          breadcrumbPath.removeLast(); // breadcrumb 경로도 하나 줄이기
                          fetchFolderHierarchy(
                            previousFolderId,
                            userId!,
                            pushToStack: false,
                          );
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
                      icon: const Icon(
                        Icons.history,
                        color: Color(0xff263238),
                      ), //최근항목아이콘
                      onPressed: () {
                        // 최근 항목 페이지 이동 로직
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RecentFileScreen(username: widget.username),
                          ),
                        );
                        print('최근 항목 눌림');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Color(0xff263238),
                      ), //알림 버튼튼
                      onPressed: () {
                        print('알림 눌림');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 모서리 각지게
        ),
        child: Container(
          color: Color(0xFF455A64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: Color(0xFF455A64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18, // 원 크기
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: Color(0xFF455A64),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'APPLESDGOTHICNEOEB',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.username}@example.com',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 70), //사이 간격
              ListTile(
                leading: Icon(
                  Icons.file_upload,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '업로드',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () async {
                  // 짧은 딜레이 후 팝업 표시 ( 드로어 닫힘 타이밍 맞추기 )
                  await Future.delayed(const Duration(milliseconds: 100));

                  final RenderBox overlay =
                      Overlay.of(context).context.findRenderObject()
                          as RenderBox;
                  final RelativeRect position = RelativeRect.fromLTRB(
                    100, // 좌측에서 거리
                    210, // 위에서 거리
                    overlay.size.width - 100,
                    0,
                  );
                  final selected = await showMenu<String>(
                    context: context,
                    position: position,
                    items: [
                      const PopupMenuItem(
                        value: 'new_folder',
                        child: SizedBox(
                          width: 150, // ← 여기 크기로 팝업창이 맞춰짐
                          child: Text(
                            '새 폴더',
                            style: TextStyle(
                              fontSize: 12, // 폰트 크기 조정
                              fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 패밀리로 변경
                              color: Colors.black, // 글씨 색상
                            ),
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'upload_file',
                        child: Text(
                          '파일 업로드',
                          style: TextStyle(
                            fontSize: 12, // 폰트 크기 조정
                            fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 패밀리로 변경
                            color: Colors.black, // 글씨 색상
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'upload_folder',
                        child: Text(
                          '폴더 업로드',
                          style: TextStyle(
                            fontSize: 12, // 폰트 크기 조정
                            fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 패밀리로 변경
                            color: Colors.black, // 글씨 색상
                          ),
                        ),
                      ),
                    ],
                    elevation: 8, // 그림자 깊이 설정
                    color: Colors.white, // 위젯 배경 흰색
                  ).then((selected) async {
                    // folder_create를 불러와서 폴더 생성하는 팝업창
                    if (selected == 'new_folder') {
                      final result = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Container(
                              width: 350, // 너비 설정
                              height: 280, // 높이 설정
                              color: Colors.white,
                              child: FolderCreateScreen(
                                onCreateFolder: (folderName) {
                                  setState(() {
                                    folders.add(folderName);
                                  });
                                  Navigator.of(context).pop();
                                },
                              ), // 실제 내용
                            ),
                          );
                        },
                      );
                      if (result == true) {
                        print('새 폴더 생성 완료');
                      }
                    }
                    // 다른 항목은 여기에 맞게 처리
                  });
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.star_border,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '중요문서함',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '휴지통',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TrashScreen(username: widget.username),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.check, size: 24, color: Colors.white),
                title: Text(
                  '예약하기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: 'APPLESDGOTHICNEOR',
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => FileReservationScreen(), // ⬅️ 이동할 화면
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.sd_storage,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '저장용량',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 폴더 & 파일 레이블
            Row(
              children: [
                // ROOT 텍스트를 누르면 personal_screen.dart기본 화면으로 이동
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PersonalScreen(
                                  username: widget.username,
                                ), // PersonalScreen()으로 이동
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            '${breadcrumbPath.join("  >  ")}',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'APPLESDGOTHICNEOR',
                            ),
                          ),
                        ],
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
                                          sourceFolderIds:
                                              selectedFolderIds, // ✅ 이제 리스트로 전달
                                          destinationFolderId:
                                              -1, // 목적지는 내부에서 선택함
                                        ),
                                  );
                                }
                                : null, // selectedFolderNames가 비어 있으면 버튼 비활성화
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
                          final itemKey = GlobalKey();
                          final isSelected = selectedFolderNames.contains(
                            folderName,
                          );

                          return GestureDetector(
                            key: itemKey,
                            onTap: () {
                              setState(() {
                                if (selectedFolderNames.contains(folderName)) {
                                  selectedFolderNames.remove(folderName);
                                } else {
                                  selectedFolderNames.add(folderName);
                                }
                              });
                            },
                            onSecondaryTap: () {
                              showContextMenu(
                                context: context,
                                key: itemKey, // 폴더별 GlobalKey
                                onSelected: (selected) async {
                                  if (selected == 'delete') {
                                    if (folderId != null) {
                                      deletedFolders.add(
                                        FileItem(
                                          name: folderName,
                                          type: "폴더",
                                          sizeInBytes: 0,
                                        ),
                                      );
                                      setState(() {
                                        folders.removeAt(index);
                                      });
                                    }
                                  } else if (selected == 'add_to_important') {
                                    if (folderId != null) {
                                      setState(() {
                                        importantFolders.add(
                                          FileItem(
                                            name: folderName,
                                            type: "폴더",
                                            sizeInBytes: 0,
                                          ),
                                        );
                                      });
                                    }
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
                                    //폴더 선택
                                    child: Checkbox(
                                      value: selectedFolderNames.contains(
                                        folderName,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedFolderNames.add(folderName);
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
                                        fontSize: 14,
                                        fontFamily: 'APPLESDGOTHICNEOR',
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      /*Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => TrashScreen(username: widget.username),
                                          ),
                                        );*/
                                      if (folderId != null)
                                        fetchFolderHierarchy(folderId, userId!);
                                    },
                                    icon: const Icon(
                                      Icons.navigate_next,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 파일 리스트
                  Expanded(
                    // DropTarget (파일 드래그 앤 드랍)
                    child: DropTarget(
                      onDragDone: (detail) async {
                        if (_isUploading) return;
                         _isUploading = true;
                         
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

                          final currentFolderPath = getCurrentFolderPath();
                          // 업로드 호출
                          print('📦 folderIdToName: $folderIdToName');
                          print('📁 folderStack: $folderStack');
                          print('📁 currentFolderId: $currentFolderId');
                          print('📁 경로: $currentFolderPath');
                          await uploader.uploadFiles(
                            file: droppedFiles[0],
                            userId: userId!, // login 할때때 받아올 값으로 수정
                            folderId: currentFolderId,
                            currentFolderPath: currentFolderPath,
                          );
                          await refreshCurrentFolderFiles();
                          // setState(() {
                          //   //파일 추가 후 selectedFiles 초기화화
                          //   selectedFiles.clear();
                          //   fileNames.clear();
                          // });

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
                        }finally {
                          _isUploading = false;
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
                                  return MouseRegion(
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
                                          // IconButton(
                                          //   icon: Icon(
                                          //     file.isFavorite
                                          //         ? Icons.star
                                          //         : Icons
                                          //             .star_border, // 즐겨찾기 여부에 따라 아이콘 변경
                                          //     size: 14,
                                          //     color:
                                          //         file.isFavorite
                                          //             ? Colors.yellow
                                          //             : Colors.grey, // 색칠 여부
                                          //   ),
                                          //   onPressed: () {
                                          //     setState(() {
                                          //       file.isFavorite =
                                          //           !file.isFavorite; // 즐겨찾기 토글
                                          //     });
                                          //   },
                                          // ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 16,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                // 파일을 삭제 리스트로 옮기기
                                                final deletedFile =
                                                    selectedFiles[index];
                                                deletedFiles.add(deletedFile);

                                                // 원래 리스트에서 제거
                                                selectedFiles.removeAt(index);
                                                fileNames.remove(file.name);
                                              });
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
            Align(
              alignment: Alignment.center, // 센터 정렬
              child: SizedBox(
                width: 800, // 원하는 가로폭
                child: TextField(
                  style: TextStyle(
                    fontSize: 16, // 입력 텍스트 크기
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
                  decoration: InputDecoration(
                    hintText: 'search', // 검색창의 힌트 텍스트
                    hintStyle: TextStyle(
                      fontSize: 16, // 힌트 텍스트 크기
                      fontFamily: 'APPLESDGOTHICNEOEB',
                    ),
                    filled: true, // 🔹 배경색 적용할 때 필수
                    fillColor: Color(0xFFCFD8DC), //  TextField 배경색
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), // 둥근 정도 설정
                      borderSide: BorderSide.none, // 기본 테두리 제거 (filled일 때 깔끔)
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Color(0xFF607D8B),
                        width: 2,
                      ), // 포커스 시 진한 테두리
                    ),
                    //border: OutlineInputBorder(), // 검색창의 테두리 설정
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xff263238),
                      // 검색 아이콘을 왼쪽에 추가
                    ),
                    suffixIcon: Icon(
                      Icons.tune,
                      color: Color(0xff263238),
                    ), // 오른쪽 '조절' 아이콘
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

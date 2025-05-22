import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_application_1/api/file_uploader.dart';
import 'package:flutter_application_1/screens/file_sorty.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:flutter_application_1/screens/trash_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/models/file_item.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_application_1/components/navigation_drawer.dart';
import 'package:flutter_application_1/components/search_bar_with_overlay.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/screens/file_view_dialog.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/api/trash.dart';
import 'package:flutter_application_1/models/important_file_item.dart';
import 'package:flutter_application_1/models/important_folder_item.dart';
import 'package:flutter_application_1/api/important.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_application_1/screens/folder_grant_dialog.dart';
import 'package:flutter_application_1/api/websocket_service.dart';
import 'package:flutter_application_1/components/notification_button.dart'; // NotificationButton 위젯
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';
import 'package:flutter_application_1/components/navigation_helper.dart';

class CloudScreen extends StatefulWidget {
  final String username; // 사용자 이름
  final List<int>? targetPathIds; // 진입 시 지정된 폴더 경로 ID 목록 (선택적)

  const CloudScreen({Key? key, required this.username, this.targetPathIds})
    : super(key: key);

  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  // 선택된 파일 목록
  List<FileItem> selectedFiles = [];

  // 선택된 폴더 이름 목록
  List<String> selectedFolderNames = [];

  // 중요 폴더 목록
  List<ImportantFolderItem> importantFolders = [];

  // 선택된 폴더 이름 (정렬 기능 관련)
  String? selectedFolderName;

  // 정렬 출발/도착 폴더 선택 여부
  bool isStartSelected = false;
  bool isDestSelected = false;

  // 현재 폴더 내 폴더 이름 목록
  List<String> folders = [];

  // 미리보기 관련 변수
  final GlobalKey _previewKey = GlobalKey();
  OverlayEntry? _previewOverlay;
  Timer? _hoverTimer;

  // 업로드 중 상태 플래그
  bool _isUploading = false;

  // 중복 방지를 위한 현재 폴더 내 파일 이름 목록
  Set<String> fileNames = {};

  // API 요청용 URL 및 업로더
  late String url;
  late FileUploader uploader;

  // 현재 폴더 ID (기본: Cloud의 루트)
  int currentFolderId = 2; 
  String currentFolderName = 'Cloud'; 

  // 화면 상단에 표시될 폴더 경로
  List<String> breadcrumbPath = ['Cloud']; 

  // 뒤로가기용 폴더 ID 스택
  List<int> folderStack = []; 

  // 폴더명 ↔ 폴더ID 매핑
  Map<String, int> folderNameToId = {};
  Map<int, String> folderIdToName = {};

  // S3 URL
  late String s3BaseUrl;

  // 현재 사용자 ID
  late int? userId;

  // 중요 파일 목록
  List<ImportantFileItem> importantFiles = [];

  // 드래그 이벤트 중복 처리 방지 플래그
  bool _dragHandled = false;
  
  // 해당 폴더가 이미 중요 폴더인지 확인
  bool isAlreadyImportantFolder(int folderId) {
    return importantFolders.any((f) => f.folderId == folderId);
  }

  // 해당 파일이 이미 중요 파일인지 확인
  bool isAlreadyImportantFile(int fileId) {
    return importantFiles.any((f) => f.fileId == fileId);
  }

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    s3BaseUrl = dotenv.get("S3BaseUrl");
    uploader = FileUploader(baseUrl: url, s3BaseUrl: s3BaseUrl);
    
    // 위젯 빌드 후 userId를 가져와 초기 폴더 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (widget.targetPathIds != null && widget.targetPathIds!.isNotEmpty) {
        // 지정된 경로가 있다면 해당 경로로 진입
        for (final folderId in widget.targetPathIds!) {
          await fetchFolderHierarchy(folderId, userId!, pushToStack: true);
        }
      } else {
        // 아니면 Cloud 루트에서 시작
        await fetchAccessibleCloudRoots();
      }
      await fetchImportantStatus(); // 중요 표시 상태 불러오기
    });
  }

  // 우클릭 시 표시될 컨텍스트 메뉴 항목 구성
List<PopupMenuEntry<String>> buildContextMenuItems({
  required bool isFolder, // 폴더인지 여부
  required bool isCloud, // 클라우드 화면인지 여부
}) {
  List<PopupMenuEntry<String>> items = [];

  if (isFolder) {
    // 폴더일 경우 메뉴
    items.addAll([
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 16, color: Colors.black54),
            SizedBox(width: 8),
            Text('삭제', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'add_to_important',
        child: Row(
          children: [
            Icon(Icons.star, size: 15, color: Colors.black54),
            SizedBox(width: 8),
            Text('중요 폴더로 추가', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ]);

    // 클라우드 폴더에만 '초대하기' 메뉴 제공
    if (isCloud) {
      items.add(
        const PopupMenuItem(
          value: 'grant',
          child: Row(
            children: [
              Icon(Icons.person_add, size: 15, color: Colors.black54),
              SizedBox(width: 8),
              Text('초대하기', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  } 
  else {
    // 파일일 경우 메뉴
    items.addAll([
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 16, color: Colors.black54),
            SizedBox(width: 8),
            Text('삭제', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'add_to_important',
        child: Row(
          children: [
            Icon(Icons.star, size: 15, color: Colors.black54),
            SizedBox(width: 8),
            Text('중요 문서로 추가', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ]);
  }

  return items;
}

// 업로드 상태 표시용 오버레이
OverlayEntry? _uploadOverlayEntry;

// 현재 업로드 중인 파일 이름 목록
List<String> _uploadingFiles = [];

// 업로드 완료된 파일 이름 집합
Set<String> _completedFiles = {};

// 업로드 실패한 파일 이름 집합
Set<String> _failedFiles = {};

// 파일 업로드 진행 상태를 오버레이 UI로 표시하는 함수
void _showUploadStatusOverlayUI() {
  // 기존 오버레이 제거 (중복 방지)
  _uploadOverlayEntry?.remove();

  // 새로운 오버레이 생성
  _uploadOverlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 30, // 화면 아래에서 30px 위
      right: 30, // 화면 오른쪽에서 30px 왼쪽
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📦 파일 업로드 중...', // 상단 제목
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // 파일별 업로드 상태 표시 (성공 / 실패 / 진행 중)
              ..._uploadingFiles.map((fileName) {
                Widget statusIcon;
            
                // 업로드 완료
                if (_completedFiles.contains(fileName)) {
                  statusIcon = const Icon(Icons.check, color: Colors.green, size: 16);
                } 
                
                // 업로드 실패
                else if (_failedFiles.contains(fileName)) {
                  statusIcon = const Icon(Icons.error, color: Colors.red, size: 16);
                } 
                
                // 업로드 진행 중
                else {
                  statusIcon = const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 파일 이름 (너무 길면 ... 처리)
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 상태 아이콘 표시
                      statusIcon,
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),
  );
  // 오버레이 삽입
  Overlay.of(context).insert(_uploadOverlayEntry!);
}

  // 중요 문서/폴더 상태를 서버에서 불러와 갱신
  Future<void> fetchImportantStatus() async {
    if (userId == null) return;
    importantFolders = await fetchImportantFolders(userId!);
    importantFiles = await fetchImportantFiles(userId!);
    setState(() {}); // UI 갱신
  }
  
  // 현재 폴더 경로를 문자열로 반환 (예: Root/Projects/Flutter)
  String getCurrentFolderPath() {
    List<int> pathIds = [...folderStack, currentFolderId];
    List<String> pathNames =
        pathIds.map((id) => folderIdToName[id] ?? 'Unknown').toList();
    return pathNames.join('/');
  }

  // 간단한 텍스트 오버레이 표시 (예: 업로드 완료 메시지)
  void _showUploadStatusOverlay(String message, {bool autoRemove = false}) {
  _uploadOverlayEntry?.remove(); // 기존 오버레이 제거
  _uploadOverlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 30,
      right: 30,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(_uploadOverlayEntry!);

  // 자동 제거 옵션이 설정된 경우 일정 시간 후 제거
  if (autoRemove) {
    Future.delayed(const Duration(seconds: 3), () {
      _uploadOverlayEntry?.remove();
      _uploadOverlayEntry = null;
      });
    }
  } 

  // 긴 경로의 일부만 보여주는 함수 (예: ... > Flutter > components)
  String getTruncatedPath({int showLast = 2}) {
    if (breadcrumbPath.length <= showLast + 1) {
      return breadcrumbPath.join("  >  ");
    }

    final start = '...';
    final end = breadcrumbPath
        .sublist(breadcrumbPath.length - showLast)
        .join("  >  ");
    return '$start  >  $end';
  }

  // 현재 사용자가 접근 가능한 클라우드 루트 폴더 목록 요청
  Future<void> fetchAccessibleCloudRoots() async {
    final response = await http.get(
      Uri.parse('$url/folder/cloud-visible/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;

      // 상태 초기화 및 업데이트
      folderNameToId.clear();
      folderIdToName.clear();
      folders.clear();
      selectedFiles.clear();
      folderStack.clear();
      folderIdToName[2] = "Cloud";  // 기본 루트 이름 설정

      for (final folder in data) {
        final id = folder['id'];
        final name = folder['name'];
        folderNameToId[name] = id;
        folderIdToName[id] = name;
        folders.add(name);
      }

      breadcrumbPath = ['Cloud'];
      currentFolderId = 2; // Cloud는 논리적 루트
      setState(() {});
    } else {
      print("🚫 클라우드 진입 가능 폴더 불러오기 실패: ${response.statusCode}");
    }
  }

  // 특정 폴더의 전체 구조(하위 폴더/파일) 불러오기
  Future<void> fetchFolderHierarchy(
    int folderId,
    int userId, {
    bool pushToStack = true,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$url/folder/hierarchy/$folderId/$userId',
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(
        data['subFolders'],
      );

      // 폴더 ID/이름 매핑 업데이트
      folderNameToId = {for (var f in folderList) f['name']: f['id']};
      folderIdToName.addAll({for (var f in folderList) f['id']: f['name']});

      setState(() {
        currentFolderName = data['name'] ?? 'Cloud';

        // 브레드크럼 경로 갱신
        if (pushToStack && currentFolderId != folderId) {
          folderStack.add(currentFolderId);
          breadcrumbPath.add(currentFolderName);
        } else if (!pushToStack) {
          if (breadcrumbPath.length > 1) {
            breadcrumbPath.removeLast();
          }
        }

        currentFolderId = folderId;

        // 폴더/파일 목록 추출
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

  // 현재 폴더의 파일 및 하위 폴더 목록을 새로 불러오는 함수
  Future<void> refreshCurrentFolderFiles() async {
    final response = await http.get(
      Uri.parse('$url/folder/hierarchy/$currentFolderId/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // 하위 폴더 정보 리스트 추출
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(
        data['subFolders'],
      );

      // 폴더 이름과 ID 매핑
      folderNameToId = {for (var f in folderList) f['name']: f['id']};
      folderIdToName.addAll({for (var f in folderList) f['id']: f['name']});

      setState(() {
        // UI에서 사용할 폴더 이름 리스트 갱신
        folders = folderList.map((f) => f['name'] as String).toList();

        // 파일 정보 추출 및 리스트로 변환
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

        // 파일 이름 집합 갱신 (중복 방지용)
        fileNames = selectedFiles.map((f) => f.name).toSet();
      });
    } else {
      print('파일 새로고침 실패: ${response.statusCode}');
    }
  }

  // 파일 썸네일 또는 미리보기 오버레이를 화면에 표시
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
            left: offset.dx + renderBox.size.width + 10, // 아이템 우측에 표시
            top: offset.dy,
            child: Material(
              elevation: 4,
              child: Container(
                width: 240,
                height: 240,
                color: Colors.white,
                child: _buildPreviewContent(url, type), // 미리보기 위젯 렌더링
              ),
            ),
          ),
    );

    overlay.insert(_previewOverlay!);
  }

  // 특정 위젯(GlobalKey 기준)에 대해 컨텍스트 메뉴를 표시
  Future<void> showContextMenu({
    required BuildContext context,
    required GlobalKey key,
    required Function(String?) onSelected,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50)); // 딜레이

    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final double dx = offset.dx + 80; // 오른쪽으로 약간 이동
    final double dy = offset.dy + 60; // 아래로 약간 이동

    final RelativeRect position = RelativeRect.fromLTRB(
      dx,
      dy,
      overlay.size.width - dx - renderBox.size.width,
      overlay.size.height - dy,
    );

    // 팝업 메뉴 표시
    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                '삭제',
                style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR'),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_to_important',
          child: Row(
            children: [
              Icon(Icons.star, size: 16, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                '중요 폴더로 추가',
                style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR'),
              ),
            ],
          ),
        ),
        PopupMenuItem(
              value: 'grant',
              child: Row(
            children: [
              Icon(Icons.star, size: 16, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                '초대하기',
                style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR'),
              ),
            ],
          ),
        )
      ],
      // 사용자가 메뉴 선택 시 콜백 실행
      elevation: 8,
    );
    onSelected(selected);
  }

  // 마우스 우클릭한 특정 위치에 컨텍스트 메뉴를 표시하는 함수
  Future<void> showContextMenuAtPosition({
    required BuildContext context,
    required Offset position,
    required Function(String?) onSelected,
    required bool isFolder,
    required bool isCloud,
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
      color: const Color(0xFFECEFF1),
      items: buildContextMenuItems(
        isFolder: isFolder,
        isCloud: isCloud,
      ),
    );
    onSelected(selected); // 선택된 메뉴 항목 전달
  }
 
  // 파일 타입에 따라 미리보기 컨텐츠를 생성하는 위젯
  Widget _buildPreviewContent(String url, String type, {String? thumbnailUrl}) {
    final lower = type.toLowerCase();

    // 이미지 파일이면 원본 이미지 표시
    if (["png", "jpg", "jpeg", "gif", "bmp"].contains(lower)) {
      return Image.network(url, fit: BoxFit.contain);
    }

    // 썸네일이 있다면 우선적으로 썸네일 이미지 사용
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Image.network(thumbnailUrl, fit: BoxFit.contain);
    }

    // PDF 파일이면 PDF 뷰어로 렌더링
    if (lower == "pdf") {
      return SfPdfViewer.network(url); // PDF 미리보기
    } 
    else if (["doc", "docx", "xls", "xlsx", "ppt", "pptx"].contains(lower)) {
      return OfficeViewerWindows(fileUrl: url); // 오피스 문서 미리보기
    }

    // 그 외 형식은 미리보기 불가 메시지 표시
    return const Center(child: Text("미리보기를 지원하지 않는 형식입니다."));
  }

  // 기존 미리보기 오버레이 제거 함수
  void _removePreviewOverlay() {
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  // 지정된 위치에 파일 미리보기 오버레이를 띄우는 함수
  void _showPreviewOverlayAtPosition(
    BuildContext context,
    String? url,
    String type,
    Offset position, {
    String? thumbnailUrl,
  }) {
    if (url == null) return; // URL이 없으면 종료

    _removePreviewOverlay(); // 기존 오버레이 제거

    _previewOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: position.dx, // 마우스 좌표 기준 위치
            top: position.dy - 250, // 마우스 기준 위쪽으로 250px 띄움
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
                  thumbnailUrl: thumbnailUrl, // 썸네일 있으면 전달
                ),
              ),
            ),
          ),
    );
    Overlay.of(context).insert(_previewOverlay!); // 오버레이 삽입
  }

  // 폴더를 리스트에 추가하고 상태를 갱신
  void addFolder(String name) {
    setState(() {
      folders.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 상단 앱바 정의
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false, // 자동 햄버거/뒤로가기 버튼 비활성화
          backgroundColor: Colors.white,
          elevation: 0, // 그림자 제거

          // 왼쪽 상단 햄버거 메뉴 버튼
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer(); // 드로어 열기
                  },
                ),
          ),

          // 중앙 타이틀과 네비게이션 버튼들
          title: Row(
            children: [
              const SizedBox(width: 22), //햄버거 버튼과의 간격

              // 홈 버튼
              IconButton(
                icon: const Icon(
                  Icons.home, // 홈 아이콘
                  color: Color(0xff263238), // 짙은 회색
                  size: 24, 
                ),
                onPressed: () {
                  NavigationStack.clear(); // 네비게이션 스택 초기화
                  NavigationStack.push('HomeScreen', arguments: {'username': widget.username});
                  NavigationStack.printStack();

                  // 홈 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => HomeScreen(username: widget.username),
                    ),
                  );
                },
              ),
              const SizedBox(width: 22), // 홈 버튼과 뒤로가기 버튼 사이 간격

              // 뒤로가기 버튼
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Color(0xff263238),
                  size: 15,
                ),
                onPressed: () {
                  final currentRoute = NavigationStack.peek()?['route'];

                  if (folderStack.isNotEmpty) {
                    if (currentRoute == 'SearchCloudScreen') {
                      // 검색화면에서 왔다면 NavigationHelper 사용
                      NavigationHelper.navigateToPrevious(context);
                    } else if (folderStack.length == 1) {
                      // 루트 바로 아래면 클라우드 루트 다시 로딩
                      int previousFolderId = folderStack.removeLast();
                      fetchAccessibleCloudRoots();
                    } else {
                      // 폴더 계층 뒤로가기
                      int previousFolderId = folderStack.removeLast();
                      fetchFolderHierarchy(previousFolderId, userId!, pushToStack: false);
                    }
                  } else {
                    // 폴더 스택이 없으면 전역 스택에서 이전으로
                    NavigationHelper.navigateToPrevious(context);
                  }
                },
              ),
              const SizedBox(width: 8), // 뒤로가기 버튼과 타이틀 사이 간격

              // 화면 타이틀 영역 (클라우드 아이콘 + 유저명)
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud, // 클라우드 아이콘
                      color: Color(0xFFCFD8DC), // 연한 회색
                      size: 30,
                    ),
                    const SizedBox(width: 13),
                    Text(
                      '${widget.username}님의 클라우드',
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'APPLESDGOTHICNEOEB',
                      ),
                    ),
                  ],
                ),
              ),
              // 오른쪽 상단 아이콘들 (최근 문서 + 알림)
              Padding(
                padding: const EdgeInsets.only(right: 95),
                child: Row(
                  children: [
                    // 최근 항목 아이콘
                    IconButton(
                      icon: const Icon(
                        Icons.history,
                        color: Color(0xff263238),
                      ), 
                      onPressed: () {
                        // 최근 항목 화면으로 이동
                        NavigationStack.pop(); // 현재 위치 제거
                        NavigationStack.push('CloudScreen2', arguments: {
                          'username': widget.username,
                          'targetPathIds': [...folderStack, currentFolderId],
                        });
                        NavigationStack.printStack();
                        NavigationStack.push('RecentFileScreen', arguments: {
                          'username': widget.username, 
                          'userId': userId
                        });
                        NavigationStack.printStack();

                        // 화면 이동
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RecentFileScreen(
                                  username: widget.username,
                                  userId: 1,
                                ),
                          ),
                        );
                      },
                    ),
                    // 알림 버튼 (사용자 정의 NotificationButton 위젯)
                    const NotificationButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 왼쪽 사이드 네비게이션 드로어
      drawer: NavigationDrawerWidget(
        username: widget.username, // 사용자 이름 전달
        onFolderCreated: (folderName) {
          // 새 폴더 생성 시 폴더 목록에 추가
          setState(() {
            folders.add(folderName);
          });
        },
        folders: folders, // 현재 폴더 목록 전달
        scaffoldContext: context, // 현재 Scaffold의 context 전달
        preScreen: 'CLOUD', // 현재 화면이 클라우드임을 명시 (다른 화면들과 구분용)
        prePathIds: [...folderStack, currentFolderId], // 현재 경로의 폴더 ID 경로 전달
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 바깥 여백 설정
        child: Column(
          children: [
            // 폴더 및 파일 헤더 영역
            Row(
              children: [
                // 좌측 : 폴더 경로(빵조각 경로) 표시 영역
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100.0),
                    child: Tooltip(
                      message: breadcrumbPath.join(" / "), // 전체 경로 툴팁
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(breadcrumbPath.length, (index) {
                            int showLast = 2;
                            bool isEllipsis = (breadcrumbPath.length > showLast + 1 && index == 0);
                            bool isHidden = (breadcrumbPath.length > showLast + 1 && index < breadcrumbPath.length - showLast);
                            bool isLast = index == breadcrumbPath.length - 1;
                            bool clickable = !isLast && !isEllipsis;

                            // 생략된 경로는 렌더링하지 않음
                            if (!isEllipsis && isHidden) return SizedBox.shrink();

                            return Row(
                              children: [
                                // 각 경로 아이템 클릭 처리
                                GestureDetector(
                                  onTapDown: isEllipsis
                                      ? (details) async {
                                          // 생략(...) 클릭 시 숨겨진 경로 리스트 보여줌
                                          final hiddenItems = breadcrumbPath.sublist(
                                              0, breadcrumbPath.length - showLast);
                                          final selected = await showMenu<String>(
                                            context: context,
                                            position: RelativeRect.fromLTRB(
                                              details.globalPosition.dx,
                                              details.globalPosition.dy,
                                              details.globalPosition.dx,
                                              details.globalPosition.dy,
                                            ),
                                            color: Color(0xFFECEFF1),
                                            items: hiddenItems.map((name) {
                                              return PopupMenuItem<String>(
                                                value: name,
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontFamily: 'APPLESDGOTHICNEOR',
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                          if (selected != null) {
                                            // 선택된 경로로 이동
                                            int targetIndex = breadcrumbPath.indexOf(selected);
                                            int diff = (breadcrumbPath.length - 1) - targetIndex;

                                            for (int i = 0; i < diff; i++) {
                                              if (folderStack.isNotEmpty) {
                                                int previousFolderId = folderStack.removeLast();
                                                await fetchFolderHierarchy(
                                                    previousFolderId, userId!,
                                                    pushToStack: false);
                                              }
                                            }
                                          }
                                        }
                                      : null,
                                  onTap: (isEllipsis || !clickable)
                                      ? null
                                      : () async {
                                          int diff = (breadcrumbPath.length - 1) - index;

                                          for (int i = 0; i < diff; i++) {
                                            if (folderStack.isNotEmpty) {
                                              int previousFolderId = folderStack.removeLast();
                                              await fetchFolderHierarchy(
                                                  previousFolderId, userId!,
                                                  pushToStack: false);
                                            }
                                          }
                                        },
                                  child: Text(
                                    isEllipsis ? "..." : breadcrumbPath[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'APPLESDGOTHICNEOR',
                                      color: (isEllipsis || clickable)
                                          ? Colors.black
                                          : Colors.black,
                                      decoration: (isEllipsis || clickable)
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
                // 중앙: '파일' 텍스트 표시
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 135.0),
                    child: Text(
                      '파일',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ),
                ),
                // 우측: 새 폴더 생성 + Sorty 버튼
                Padding(
                  padding: const EdgeInsets.only(right: 101),
                  child: Row(
                    children: [
                      // 새 폴더 생성 아이콘 버튼
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

                      const SizedBox(width: 10), // 버튼 사이 여백
                      // SORTY 버튼 (선택된 폴더가 있어야 활성화)
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
            const SizedBox(height: 8), // 헤더와 본문 사이 간격

            // 폴더 & 파일 표시 영역
            Container(
              height: 450, // 전체 높이 설정
              width: 800, // 전체 너비 설정
              child: Row(
                children: [
                  // 폴더 리스트
                  Expanded(
                    child: Container(
                      height: 425,
                      decoration: BoxDecoration(
                        color: Color(0xFFCFD8DC), // 배경색
                        borderRadius: BorderRadius.circular(16), // 모서리 둥글게
                      ),
                      padding: const EdgeInsets.all(12), // 안쪽 여백

                      // GestureDetector로 감싸 우클릭 등 제스처 인식 가능하게
                      child: GestureDetector(
                        child: GridView.builder(
                          itemCount: folders.length, // 폴더 개수만큼 아이템 생성
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 한 줄에 2개
                                mainAxisSpacing: 12, // 세로 간격
                                crossAxisSpacing: 12, // 가로 간격
                                childAspectRatio: 2.0, // 가로세로 비율
                              ),
                          itemBuilder: (context, index) {
                            final folderName = folders[index];
                            final folderId = folderNameToId[folderName]; // 이름으로 ID 조회
                            final folderKey = GlobalKey(); // 우클릭 위치 참조용 키
                            final isSelected = selectedFolderNames.contains(folderName,); // 선태 여부

                            return GestureDetector(
                              key: folderKey,
                              onTap: () {
                                // 클릭 시 선택/선택 해제 토글
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
                                // 더블 클릭 시 해당 폴더로 이동
                                if (folderId != null) {
                                  fetchFolderHierarchy(folderId, userId!);
                                }
                              },
                              onSecondaryTapDown: (TapDownDetails details) {
                                // 마우스 우클릭 시 컨텍스트 메뉴 표시
                                showContextMenuAtPosition(
                                  context: context,
                                  position: details.globalPosition,
                                  onSelected: (selected) async {
                                    if (selected == 'delete') {
                                      // 삭제 선택 시
                                      if (folderId != null) {
                                        await moveToTrash(userId!, [
                                          folderId,
                                        ], []);
                                        setState(() {
                                          folders.removeAt(index); // UI에서 제거
                                        });
                                      }
                                    } else if (selected == 'add_to_important') {
                                      // 중요 폴더로 추가
                                      if (folderId != null &&
                                          !isAlreadyImportantFolder(folderId)) {
                                        await addToImportant(
                                          userId: userId!,
                                          folderId: folderId,
                                        );
                                        await fetchImportantStatus(); // 상태 갱신
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
                                      // 폴더 생성
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => FolderCreateScreen(
                                              parentFolderId: currentFolderId,
                                              onCreateFolder: (newName) async {
                                                await refreshCurrentFolderFiles(); // 폴더 새로고침
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
                                    } else if (selected == 'grant') {
                                      // 초대하기
                                      showDialog(
                                        context: context,
                                        builder: (_) => FolderGrantDialog(folderId: folderId),
                                      );
                                    }
                                  },    
                                  isFolder: true,
                                  isCloud: true, // 클라우드 폴더 여부 지정
                                );
                              },

                              child: Container(
                                // 폴더 항목 박스 스타일 설정
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, // 좌우 여백
                                  vertical: 8, // 상하 여백
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white, // 배경색 흰색
                                  borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                                  // 선택된 폴더는 파란 테두리, 아니면 회색 테두리
                                  border: Border.all(
                                    color:
                                        selectedFolderNames.contains(folderName)
                                            ? Colors.blueGrey
                                            : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12, // 그림자 색상
                                      blurRadius: 3, // 그림자 흐림 정도
                                      offset: Offset(0, 2), // 그림자 위치 (아래쪽)
                                    ),
                                  ],
                                ),

                                // 폴더 항목 내부 구성
                                child: Row(
                                  children: [
                                    // 체크박스 (선택용)
                                    Transform.scale(
                                      scale: 0.6, // 체크박스 크기 축소
                                      child: Checkbox(
                                        value: selectedFolderNames.contains(folderName,), // 선택 여부 
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedFolderNames.add(folderName,); // 선택 추가
                                            } else {
                                              selectedFolderNames.remove(folderName,); // 선택 해제
                                            }
                                          });
                                        },
                                      ),
                                    ),

                                    // 폴더 아이콘
                                    const Icon(
                                      Icons.folder,
                                      color: Color(0xFF263238), // 진한 회색
                                    ),
                                    const SizedBox(width: 8), // 아이콘과 텍스트 사이 간격

                                    // 폴더 이름 텍스트
                                    Expanded(
                                      child: Text(
                                        folderName, // 폴더 이름 표시
                                        overflow: TextOverflow.ellipsis, // 텍스트 길면 ... 처리
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'APPLESDGOTHICNEOR',
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      // 중요 폴더 여부에 따라 별 아이콘 표시
                                      icon: Icon(
                                        isAlreadyImportantFolder(folderId!) // 이미 중요 폴더인지
                                            ? Icons.star // 중요 폴더이면 채워진 별 아이콘
                                            : Icons.star_border, // 아니면 빈 별 아이콘
                                        color:
                                            isAlreadyImportantFolder(folderId!) // 별 색상도 상태에 따라 변경
                                                ? Colors.amber // 중요 폴더 -> 노란색
                                                : Colors.grey, // 일반 폴더 -> 회색
                                        size: 13, // 아이콘 크기
                                      ),
                                      onPressed: () async {
                                        if (isAlreadyImportantFolder(
                                          folderId!,
                                        )) {
                                          // 이미 중요 폴더이면 → 중요 목록에서 제거
                                          final target = importantFolders
                                              .firstWhere(
                                                (f) => f.folderId == folderId,
                                              );
                                          await removeFromImportant(target.importantId,); // 서버에 삭제 요청

                                          // 사용자에게 제거 메시지 표시
                                          ScaffoldMessenger.of(context,).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$folderName 폴더가 중요 문서함에서 삭제되었습니다.',
                                              ),
                                            ),
                                          );
                                        } else {
                                          // 중요 폴더가 아니라면 -> 중요 폴더로 등록
                                          await addToImportant(
                                            userId: userId!,
                                            folderId: folderId,
                                          );

                                          // 사용자에게 추가 메시지 표시
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
                                        await fetchImportantStatus(); // 중요 폴더/파일 상태 갱신
                                        setState(() {}); // UI 다시 그리기
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
                      // 사용자가 파일을 드래그하여 놓았을 때 호출
                      onDragDone: (detail) async {
                        if (_isUploading || _dragHandled) return; // 중복 업로드 방지
                        _isUploading = true;
                        _dragHandled = true;

                        try {
                          // 드래그된 파일 목록 가져오기
                          List<File> droppedFiles = detail.files.map((f) => File(f.path)).toList();

                          // 드래그된 파일이 없으면 리턴
                          if (droppedFiles.isEmpty) {
                            print('드래그된 파일이 없습니다.');
                            return;
                          }

                          // 업로드 상태 초기화 및 UI 표시
                          _uploadingFiles = droppedFiles.map((f) => f.path.split(Platform.pathSeparator).last).toList();
                          _completedFiles.clear();
                          _failedFiles.clear();
                          _showUploadStatusOverlayUI();

                          // 새 파일 리스트에 추가 (UI 표시용)
                          List<FileItem> newFileItems = [];
                          for (final f in droppedFiles) {
                            final fileName = f.path.split(Platform.pathSeparator).last;
                            if (!fileNames.contains(fileName)) {
                              final fileType = fileName.split('.').last;
                              final fileSize = f.lengthSync();
                              newFileItems.add(FileItem(name: fileName, type: fileType, sizeInBytes: fileSize));
                              fileNames.add(fileName);
                            }
                          }
                          setState(() {
                            selectedFiles.addAll(newFileItems);
                          });

                          final int fixedFolderId = currentFolderId;
                          final currentFolderPath = getCurrentFolderPath();

                          // 실제 파일 업로드 처리
                          for (final file in droppedFiles) {
                            final fileName = file.path.split(Platform.pathSeparator).last;
                            try {
                              await uploader.uploadFiles(
                                file: file,
                                userId: userId!,
                                folderId: fixedFolderId,
                                currentFolderPath: currentFolderPath,
                              );
                              _completedFiles.add(fileName);
                            } catch (e) {
                              print("❌ 업로드 실패: $fileName → $e");
                              _failedFiles.add(fileName);
                            }
                            _showUploadStatusOverlayUI(); // 업로드 상태 UI 갱신
                          }

                          await refreshCurrentFolderFiles(); // 업로드 후 폴더 새로고침

                          // 업로드 완료 메시지 일정 시간 후 제거
                          Future.delayed(const Duration(seconds: 3), () {
                            _uploadOverlayEntry?.remove();
                            _uploadOverlayEntry = null;
                          });
                        } catch (e) {
                          print('파일 업로드 전체 실패: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('파일 업로드 중 오류 발생: $e')),
                          );
                        } finally {
                          _isUploading = false;
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _dragHandled = false;
                          });
                        }
                      },
                      onDragEntered: (details) {
                        print('드래그 시작'); // 드래그 진입
                      },
                      onDragExited: (details) {
                        print('드래그 종료'); // 드래그 영역 이탈
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
                            // 파일 리스트 뷰
                            Expanded(
                              child: ListView.builder(
                                itemCount: selectedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = selectedFiles[index];
                                  final fileKey = GlobalKey();

                                  return GestureDetector(
                                    // 파일 우클릭 컨텍스트 메뉴
                                    onSecondaryTapDown: (
                                      TapDownDetails details,
                                    ) {
                                      showContextMenuAtPosition(
                                        context: context,
                                        position: details.globalPosition,
                                        onSelected: (selected) async {
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
                                              print('파일 삭제 실패: $e');
                                            }
                                          } else if (selected ==
                                              'add_to_important') {
                                            print("file.id: ${file.id}");
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
                                                    '${file.name} 파일이 중요 문서함에 추가됨',
                                                  ),
                                                ),
                                              );
                                              await fetchImportantStatus();
                                              setState(() {});
                                            } catch (e) {
                                              print('중요 문서 추가 실패: $e');
                                            }
                                          }
                                        },    
                                        isFolder: false,
                                        isCloud: true, // Personal은 false
                                      );
                                    },

                                    // 마우스 오버 시 미리보기 오버레이 표시
                                    child: MouseRegion(
                                      key: fileKey,
                                      onEnter: (event) {
                                        _hoverTimer = Timer(
                                          const Duration(milliseconds: 500),
                                          () {
                                            final position = event.position;
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

                                      // 파일 항목 UI
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
                                        trailing: IconButton(
                                          icon: Icon(
                                            isAlreadyImportantFile(file.id!)
                                                ? Icons.star
                                                : Icons.star_border,
                                            color:
                                                isAlreadyImportantFile(file.id!)
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
                                                    (f) => f.fileId == file.id,
                                                  );
                                              await removeFromImportant(
                                                target.importantId,
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${file.name} 파일이 중요 문서함에서 삭제됨',
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
                                                    '${file.name} 파일이 중요 문서함에 추가됨',
                                                  ),
                                                ),
                                              );
                                            }
                                            await fetchImportantStatus();
                                            setState(() {});
                                          },
                                        ),
                                        onTap: () {
                                          // 파일 상세보기 다이얼로그
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
              preScreen: 'CLOUD',
              prePathIds: [...folderStack, currentFolderId],
            ),
          ],
        ),
      ),
    );
  }
}

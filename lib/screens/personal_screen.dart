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
  final String username; // 사용자 이름
  final List<int>? targetPathIds; // 탐색하려는 폴더 경로 ID 리스트 (선택적)

  const PersonalScreen({Key? key, required this.username, this.targetPathIds})
    : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  List<FileItem> selectedFiles = []; // 선택된 파일 리스트
  List<String> selectedFolderNames = []; // 선택된 폴더 이름 리스트 (다중 선택 지원)
  String? selectedFolderName; // 현재 선택된 단일 폴더 이름
  bool isStartSelected = false; // 시작 지점 폴더 선택 여부
  bool isDestSelected = false; // 목적지 폴더 선택 여부
  List<String> folders = []; // 현재 폴더에 존재하는 폴더 이름 리스트
  final GlobalKey _previewKey = GlobalKey(); // 미리보기용 글로벌 키
  OverlayEntry? _previewOverlay; // 파일 미리보기 오버레이
  Timer? _hoverTimer; // 마우스 hover 시 미리보기 딜레이를 위한 타이머
  bool _isUploading = false; // 파일 업로드 중인지 여부
  Set<String> fileNames = {}; // 중복 업로드 방지를 위한 파일 이름 집합
  late String url; // 서버 기본 URL
  late FileUploader uploader; // 파일 업로더 인스턴스
  int currentFolderId = 1; // 현재 폴더 ID (기본값: 루트 폴더 ID = 1)
  String currentFolderName = 'Personal'; // 현재 폴더 이름 (기본: Personal)
  List<String> breadcrumbPath = ['Personal']; // 현재까지 이동한 폴더 경로 이름 리스트 (Breadcrumb)
  List<int> folderStack = []; // 상위 폴더 경로 추적용 스택 (ID 기준)
  Map<String, int> folderNameToId = {}; // 폴더 이름 → ID 매핑
  Map<int, String> folderIdToName = {}; // 폴더 ID → 이름 매핑
  late String s3BaseUrl; // S3 스토리지 기본 URL
  late int? userId; // 현재 사용자 ID
  bool _dragHandled = false; // 드래그 중복 처리를 막기 위한 플래그
  List<ImportantFolderItem> importantFolders = []; // 중요 폴더 리스트
  List<ImportantFileItem> importantFiles = []; // 중요 파일 리스트
  // 폴더가 중요 폴더인지 여부 판단
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
    folderIdToName[1] = 'Personal';
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

  // 우클릭 컨텍스트 메뉴 항목을 구성하는 함수
  List<PopupMenuEntry<String>> buildContextMenuItems({
    required bool isFolder, // 폴더인지 여부
    required bool isCloud, // 클라우드 문서함인지 여부
  }) {
    List<PopupMenuEntry<String>> items = []; // 팝업 메뉴 항목

    // 폴더일 경우
    if (isFolder) {
      items.addAll([
        // 삭제 항목 추가
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
        // 중요 폴더로 추가 항목
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

     // 클라우드 문서함일 경우 → 초대하기 항목 추가
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
    // 파일일 경우
    } else {
      items.addAll([
        // 삭제 항목
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
        // 중요 문서로 추가 항목
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
  
  // 현재 폴더의 전체 경로를 문자열로 반환
  String getCurrentFolderPath() {
    // 현재까지의 폴더 ID 경로 구성 (스택 + 현재 폴더 ID)
    List<int> pathIds = [...folderStack, currentFolderId];

    // 각 ID에 대응하는 폴더 이름을 매핑 (없으면 'Unknown')
    List<String> pathNames =
        pathIds.map((id) => folderIdToName[id] ?? 'Unknown').toList();

    // 경로를 "/" 구분자로 연결해서 반환
    return pathNames.join('/');
  }

  // 경로가 길 경우 생략(...) 표시로 줄여서 반환
  String getTruncatedPath({int showLast = 2}) {
    // 표시할 경로 길이가 충분히 짧으면 전체 경로 그대로 표시
    if (breadcrumbPath.length <= showLast + 1) {
      return breadcrumbPath.join("  >  ");
    }

    // 그렇지 않으면 앞은 생략(...)으로, 마지막 몇 개만 표시
    final start = '...';
    final end = breadcrumbPath
        .sublist(breadcrumbPath.length - showLast)
        .join("  >  ");
    return '$start  >  $end';
  }

  // 중요 폴더 및 중요 파일 정보를 서버에서 가져와 상태 업데이트
  Future<void> fetchImportantStatus() async {
    if (userId == null) return;

    // 사용자 ID 기반으로 중요 폴더와 중요 파일 정보 요청
    final folders = await fetchImportantFolders(userId!);
    final files = await fetchImportantFiles(userId!);

    // 상태 업데이트
    setState(() {
      importantFolders = folders;
      importantFiles = files;
    });
  }

  // 특정 폴더 ID에 대한 폴더 계층 구조와 파일 목록을 서버에서 가져오기
  Future<void> fetchFolderHierarchy(
    int folderId,
    int userId, {
    bool pushToStack = true, // true면 현재 경로를 스택에 추가 (뒤로가기용)
  }) async {
    final response = await http.get(
      Uri.parse(
        '$url/folder/hierarchy/$folderId/$userId',
      ),
      headers: {"Content-Type": "application/json"},
    );

    // 요청 성공 시
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 하위 폴더 목록을 Map으로 파싱
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(
        data['subFolders'],
      );

      // 폴더 이름과 ID 매핑 저장 (이름으로 ID 찾기용)
      folderNameToId = {for (var f in folderList) f['name']: f['id']};

      // 기존 맵에 덮어쓰기 없이 추가
      folderIdToName.addAll({for (var f in folderList) f['id']: f['name']});

      setState(() {
        // 현재 폴더 이름 업데이트 (없으면 기본값 'Personal')
        currentFolderName = data['name'] ?? 'Personal';

        // 경로 이동 기록 스택 업데이트
        if (pushToStack && currentFolderId != folderId) {
          folderStack.add(currentFolderId);
          breadcrumbPath.add(currentFolderName);
        } else if (!pushToStack) {
          if (breadcrumbPath.length > 1) {
            breadcrumbPath.removeLast(); // 한 단계 뒤로 가기
          }
        }

        // 현재 폴더 ID 갱신
        currentFolderId = folderId;

        // 폴더 이름 리스트 UI용으로 저장
        folders = folderList.map((f) => f['name'] as String).toList();

        // 파일 정보 리스트로 변환 후 상태 저장
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


        // 파일 이름 중복 방지를 위한 Set 저장
        fileNames = selectedFiles.map((f) => f.name).toSet();
      });
    } else {
      print('폴더 계층 불러오기 실패: ${response.statusCode}');
    }
  }

  Widget _buildFileLeadingThumb(FileItem file) {
    final thumb = file.fileThumbnail;
    final fileUrl = file.fileUrl;

    final ext = file.type.toLowerCase();
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'].contains(ext);

    // 우선순위: 썸네일 URL > 이미지면 원본 URL > 기본 아이콘
    final String? displayUrl =
        (thumb != null && thumb.isNotEmpty) ? thumb : (isImage ? fileUrl : null);

    if (displayUrl == null || displayUrl.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffB0BEC5)),
        ),
        child: const Icon(Icons.insert_drive_file, size: 20),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        displayUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffB0BEC5)),
            ),
            child: const Icon(Icons.broken_image, size: 18),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffB0BEC5)),
            ),
            child: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  // 현재 폴더에 있는 파일 및 하위 폴더 목록을 새로고침하는 함수
  Future<void> refreshCurrentFolderFiles() async {
    // 현재 폴더 ID와 사용자 ID를 이용해 폴더 계층 정보 요청
    final response = await http.get(
      Uri.parse('$url/folder/hierarchy/$currentFolderId/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    // 요청이 성공한 경우
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 하위 폴더 목록 추출 및 변환
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(
        data['subFolders'],
      );

      folderNameToId = {for (var f in folderList) f['name']: f['id']}; // 폴더 이름 → ID 매핑 저장
      folderIdToName.addAll({for (var f in folderList) f['id']: f['name']}); // 폴더 ID → 이름 매핑 추가 (덮어쓰기 아님)

      // UI 상태 업데이트
      setState(() {
        folders = folderList.map((f) => f['name'] as String).toList(); // 폴더 이름 리스트 추출

        // 파일 목록을 FileItem 리스트로 변환
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

        // 파일 이름 중복 방지를 위한 Set으로 저장
        fileNames = selectedFiles.map((f) => f.name).toSet();
      });
    } else {
      // 요청 실패 시 로그 출력
      print('파일 새로고침 실패: ${response.statusCode}');
    }
  }

  // 미리보기 오버레이를 화면에 표시하는 함수
  void _showPreviewOverlay(
    BuildContext context,
    String? url, // 미리볼 파일의 URL
    String type, // 파일 타입
    GlobalKey key, // 미리보기 위치 기준이 되는 위젯의 키
  ) {
    // 기준 위젯의 위치를 가져오기 위한 RenderBox
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || url == null) return;

    final overlay = Overlay.of(context); // 오버레이 레이어 가져오기
    final offset = renderBox.localToGlobal(Offset.zero); // 위젯의 화면 위치 계산

    // 오버레이 생성
    _previewOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx + renderBox.size.width + 10, // 오른쪽 옆에 위치
            top: offset.dy, // 동일한 Y 위치
            child: Material(
              elevation: 4,
              child: Container(
                width: 240,
                height: 240,
                color: Colors.white,
                child: _buildPreviewContent(url, type), // 파일 형식에 맞는 미리보기 표시
              ),
            ),
          ),
    );

    overlay.insert(_previewOverlay!); // 오버레이 삽입
  }

  // 검색어 하이라이트 기능 구현 함수
  TextSpan highlightOccurrences(String source, String query) {
    if (query.isEmpty) {
      // 검색어가 없으면 전체 텍스트 그대로 반환
      return TextSpan(
        text: source,
        style: const TextStyle(color: Colors.black, fontSize: 14),
      );
    }

    final matches = <TextSpan>[]; // 결과로 반환될 TextSpan 리스트
    final lcSource = source.toLowerCase(); // 소문자 변환 (대소문자 무시 비교)
    final lcQuery = query.toLowerCase();

    int start = 0;
    int index = lcSource.indexOf(lcQuery, start); // 첫 매칭 인덱스 찾기

    while (index != -1) {
      // 매칭 이전 부분 텍스트 추가
      if (index > start) {
        matches.add(
          TextSpan(
            text: source.substring(start, index),
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        );
      }

      // 매칭된 부분 강조 (굵은 파란색)
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
      index = lcSource.indexOf(lcQuery, start); // 다음 매칭 찾기
    }

    // 마지막 매칭 이후 텍스트 추가
    if (start < source.length) {
      matches.add(
        TextSpan(
          text: source.substring(start),
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      );
    }
    return TextSpan(children: matches); // 모든 부분 합쳐서 반환
  }

  // 업로드 상태 오버레이를 위한 변수들
  OverlayEntry? _uploadOverlayEntry;
  List<String> _uploadingFiles = []; // 업로드 중인 파일 이름 목록
  Set<String> _completedFiles = {}; // 업로드 완료된 파일
  Set<String> _failedFiles = {}; // 업로드 실패한 파일
  
  // 업로드 상태 오버레이 UI 표시 함수
  void _showUploadStatusOverlayUI() {
    _uploadOverlayEntry?.remove(); // 기존 오버레이 제거

    _uploadOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 30,
        right: 30,
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
                  '📦 파일 업로드 중...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 업로드 중인 각 파일 상태 표시
                ..._uploadingFiles.map((fileName) {
                  Widget statusIcon;
                  if (_completedFiles.contains(fileName)) {
                    statusIcon = const Icon(Icons.check, color: Colors.green, size: 16);
                  } else if (_failedFiles.contains(fileName)) {
                    statusIcon = const Icon(Icons.error, color: Colors.red, size: 16);
                  } else {
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
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis, // 길면 말줄임표 처리
                          ),
                        ),
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

  Overlay.of(context).insert(_uploadOverlayEntry!);
}

// 우클릭 메뉴를 특정 위치에 띄우는 함수
Future<void> showContextMenuAtPosition({
  required BuildContext context,
  required Offset position,
  required Function(String?) onSelected, // 선택 후 실행될 콜백
  required bool isFolder,
  required bool isCloud,
}) async {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  // 마우스 위치 기준 상대 위치 계산
  final RelativeRect positionRect = RelativeRect.fromLTRB(
    position.dx,
    position.dy,
    overlay.size.width - position.dx,
    overlay.size.height - position.dy,
  );

  // 메뉴 표시
  final selected = await showMenu<String>(
    context: context,
    position: positionRect,
    color: const Color(0xFFECEFF1),
    items: buildContextMenuItems(
      isFolder: isFolder,
      isCloud: isCloud,
    ),
  );
  onSelected(selected); // 선택 결과 콜백 실행
}
  // 파일 형식에 따른 미리보기 위젯 생성 함수
  Widget _buildPreviewContent(String url, String type, {String? thumbnailUrl}) {
    final lower = type.toLowerCase();

    // 이미지 형식인 경우
    if (["png", "jpg", "jpeg", "gif", "bmp"].contains(lower)) {
      return Image.network(url, fit: BoxFit.contain);
    }

    // 썸네일이 있다면 우선 사용
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Image.network(thumbnailUrl, fit: BoxFit.contain);
    }

    // PDF 문서
    if (lower == "pdf") {
      return SfPdfViewer.network(url); // PDF 지원
    } 
    // 오피스 문서 (doc, ppt 등)
    else if (["doc", "docx", "xls", "xlsx", "ppt", "pptx"].contains(lower)) {
      return OfficeViewerWindows(fileUrl: url); // 오피스
    }
    // 지원하지 않는 형식
    return const Center(child: Text("미리보기를 지원하지 않는 형식입니다."));
  }

  // 기존 미리보기 오버레이 제거
  void _removePreviewOverlay() {
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  // 특정 위치에 파일 미리보기 오버레이 표시
  void _showPreviewOverlayAtPosition(
    BuildContext context,
    String? url,
    String type,
    Offset position, {
    String? thumbnailUrl,
  }) {
    if (url == null) return;

    _removePreviewOverlay(); // 기존 오버레이 제거

    _previewOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: position.dx,
            top: position.dy - 250, // 커서보다 위쪽에 표시
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

    Overlay.of(context).insert(_previewOverlay!); // 오버레이 삽입
  }

  // 새로운 폴더를 추가하는 함수
  void addFolder(String name) {
    setState(() {
      folders.add(name); // 폴더 리스트에 이름 추가 후 UI 갱신
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색 흰색

      // 상단 앱바
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false, // 기본 뒤로가기/햄버거 제거
          backgroundColor: Colors.white,
          elevation: 0, // 그림자 제거

          // 햄버거 메뉴 버튼 (Navigation Drawer 열기)
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer(); // Drawer 열기
                  },
                ),
          ),
          // 앱바 내부 요소 정렬
          title: Row(
            children: [
              const SizedBox(width: 22), //햄버거 버튼과의 간격

              // 홈 버튼
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xff263238), size: 24),
                onPressed: () {
                  // 홈으로 이동
                  NavigationStack.clear(); // 내비게이션 스택 초기화
                  NavigationStack.push('HomeScreen', arguments: {'username': widget.username});
                  NavigationStack.printStack(); // 스택 상태 출력 (디버깅용)

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(username: widget.username),
                    ),
                  );
                },
              ),
              const SizedBox(width: 22), // 홈 버튼과의 간격

              // 뒤로가기 버튼
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Color(0xff263238),
                  size: 15,
                ),
                onPressed: () {
                  final currentRoute = NavigationStack.peek()?['route'];
                  
                  // 검색에서 들어온 경우: 이전 화면으로
                  if (folderStack.isEmpty || currentRoute == 'SearchPersonalScreen') {
                    // stack이 비어있거나 현재 route가 SearchPersonalSceen이면 NavigationHelper 사용
                    NavigationHelper.navigateToPrevious(context);
                  } else {
                    // 일반 폴더 탐색 뒤로가기
                    int previousFolderId = folderStack.removeLast();
                    fetchFolderHierarchy(previousFolderId, userId!, pushToStack: false);
                  }
                },
              ),
              const SizedBox(width: 8),

              // 타이틀 텍스트 (유저명 표시)
              Expanded(
                child: Text(
                  '${widget.username}님의 파일함',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
                ),
              ),

              // 오른쪽 아이콘 버튼 (히스토리, 알림)
              Padding(
                padding: const EdgeInsets.only(right: 95), // 오른쪽에서 10px 떨어짐
                child: Row(
                  children: [
                    // 히스토리 아이콘
                    IconButton(
                      icon: const Icon(Icons.history, color: Color(0xff263238)),
                      onPressed: () {
                        // 히스토리 화면으로 이동
                        NavigationStack.pop();
                        NavigationStack.push('PersonalScreen2', arguments: {
                          'username': widget.username,
                          'targetPathIds': [...folderStack, currentFolderId],
                        });
                        NavigationStack.printStack();
                        NavigationStack.push('RecentFileScreen', arguments: {'username': widget.username, 'userId': userId});
                        NavigationStack.printStack();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecentFileScreen(
                              username: widget.username,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                    ),
                    // 알림 버튼 (커스텀 위젯)
                    const NotificationButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 사이드 메뉴 (Navigation Drawer)
      drawer: NavigationDrawerWidget(
        username: widget.username, // 사용자 이름 전달

        // 폴더 생성 시 호출될 콜백
        onFolderCreated: (folderName) {
          setState(() {
            folders.add(folderName); // 폴더 리스트에 추가
          });
        },
        folders: folders, // 현재 폴더 목록 전달
        scaffoldContext: context, // 스캐폴드 컨텍스트 전달
        preScreen: 'PERSONAL', // 현재 화면 타입 지정
        prePathIds: [...folderStack, currentFolderId], // 현재 경로 ID 전달
      ),

      // 본문 시작
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 상단 레이블 영역 (경로 + 파일 텍스트 + 버튼들)
            Row(
              children: [
                // 왼쪽 경로 표시
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100.0),
                    child: Tooltip(
                      message: breadcrumbPath.join(" / "), // 전체 경로 툴팁으로 표시
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(breadcrumbPath.length, (index) {
                            int showLast = 2;
                            bool isEllipsis = (breadcrumbPath.length > showLast + 1 && index == 0); // "..." 여부
                            bool isHidden = (breadcrumbPath.length > showLast + 1 && index < breadcrumbPath.length - showLast); // 숨김 처리 여부
                            bool isLast = index == breadcrumbPath.length - 1; // 마지막 항목 여부
                            bool clickable = !isLast && !isEllipsis; // 클릭 가능 여부

                            if (!isEllipsis && isHidden) return SizedBox.shrink(); // 중간 경로 숨기기

                            return Row(
                              children: [
                                GestureDetector(
                                  // "..." 클릭 시 숨겨진 경로 메뉴 표시
                                  onTapDown: isEllipsis
                                      ? (details) async {
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
                                    // 경로 항목 클릭 시 해당 폴더로 이동
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
                                    isEllipsis ? "..." : breadcrumbPath[index], // 표시할 텍스트
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

                // 가운데 "파일" 텍스트
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

                // 오른쪽 버튼 영역 (새 폴더 + SORTY)
                Padding(
                  padding: const EdgeInsets.only(right: 101),
                  child: Row(
                    children: [
                      // 새 폴더 아이콘 버튼
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
                      // Sorty 버튼 (정렬 기능)
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

                      // GestureDetector로 감싸서 우클릭 이벤트 추가
                      child: GestureDetector(
                        child: GridView.builder(
                          itemCount: folders.length, // 폴더 개수
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 한 줄에 폴더 2개씩 배치
                                mainAxisSpacing: 12, // 위아래 간격
                                crossAxisSpacing: 12, // 좌우 간격
                                childAspectRatio: 2.0, // 가로:세로 비율
                              ),
                          itemBuilder: (context, index) {
                            final folderName = folders[index]; // 폴더 이름
                            final folderId = folderNameToId[folderName]; // 폴더 ID
                            final folderKey = GlobalKey(); // 폴더 구분용 key
                            final isSelected = selectedFolderNames.contains( // 선택 여부 확인
                              folderName,
                            );

                            return GestureDetector(
                              key: folderKey,

                              // 폴더 클릭 시 선택/해제
                              onTap: () {
                                setState(() {
                                  if (selectedFolderNames.contains(
                                    folderName,
                                  )) {
                                    selectedFolderNames.remove(folderName); // 선택 해제
                                  } else {
                                    selectedFolderNames.add(folderName); // 선택 추가
                                  }
                                });
                              },

                              // 폴더 더블 클릭 시 내부로 진입
                              onDoubleTap: () {
                                if (folderId != null) {
                                  fetchFolderHierarchy(folderId, userId!); // 폴더 내부 조회
                                }
                              },

                              // 마우스 우클릭 시 컨텍스트 메뉴 표시
                              onSecondaryTapDown: (TapDownDetails details) {
                                showContextMenuAtPosition(
                                  context: context,
                                  position: details.globalPosition,
                                  onSelected: (selected) async {
                                    if (selected == 'delete') {
                                      // 삭제 선택 시 폴더 휴지통 이동
                                      if (folderId != null) {
                                        await moveToTrash(userId!, [
                                          folderId,
                                        ], []);
                                        setState(() {
                                          folders.removeAt(index); // UI에서 제거
                                        });
                                      }
                                    } else if (selected == 'add_to_important') {
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
                                      // 하위 폴더 생성
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
                                  isFolder: true,
                                  isCloud: false, // Personal은 false
                                );
                              },

                              // 폴더 UI 박스
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
                                            ? Colors.blueGrey // 선택됨 표시
                                            : Colors.grey.shade400, // 기본 회색
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

                                // 폴더 내부 내용
                                child: Row(
                                  children: [
                                    // 체크박스 (선택 상태 조절용)
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

                                    // 폴더 아이콘
                                    const Icon(
                                      Icons.folder,
                                      color: Color(0xFF263238),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // 폴더 이름 텍스트
                                    Expanded(
                                      child: Text(
                                        folderName,
                                        overflow: TextOverflow.ellipsis, // 길면 ... 처리
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
                        // 이미 업로드 중이거나 드래그 처리 중이면 무시
                        if (_isUploading || _dragHandled) return;
                        _isUploading = true;
                        _dragHandled = true;

                        try {
                          // 드롭된 파일들을 File 객체 리스트로 변환
                          List<File> droppedFiles = detail.files.map((f) => File(f.path)).toList();

                          // 드래그된 파일이 없으면 리턴
                          if (droppedFiles.isEmpty) {
                            print('드래그된 파일이 없습니다.');
                            return;
                          }

                          // 업로드 상태 초기화
                          _uploadingFiles = droppedFiles.map((f) => f.path.split(Platform.pathSeparator).last).toList();
                          _completedFiles.clear();
                          _failedFiles.clear();
                          _showUploadStatusOverlayUI(); // 상태 표시 오버레이 띄우기

                          // 새 파일 추가 (UI용)
                          List<FileItem> newFileItems = [];
                          for (final f in droppedFiles) {
                            final fileName = f.path.split(Platform.pathSeparator).last;
                            if (!fileNames.contains(fileName)) {
                              final fileType = fileName.split('.').last; // 확장자
                              final fileSize = f.lengthSync(); // 파일 크기
                              newFileItems.add(FileItem(name: fileName, type: fileType, sizeInBytes: fileSize));
                              fileNames.add(fileName); // 중복 방지를 위해 저장
                            }
                          }
                          // 상태 업데이트 : UI에 파일 추가
                          setState(() {
                            selectedFiles.addAll(newFileItems); 
                          });

                          // 업로드 대상 폴더 정보 저장
                          final int fixedFolderId = currentFolderId;
                          final currentFolderPath = getCurrentFolderPath();

                          // 실제 파일 업로드 수행
                          for (final file in droppedFiles) {
                            final fileName = file.path.split(Platform.pathSeparator).last;
                            try {
                              await uploader.uploadFiles(
                                file: file,
                                userId: userId!,
                                folderId: fixedFolderId,
                                currentFolderPath: currentFolderPath,
                              );
                              _completedFiles.add(fileName); // 성공한 파일 목록에 추가
                            } catch (e) {
                              print("❌ 업로드 실패: $fileName → $e");
                              _failedFiles.add(fileName); // 실패한 파일 목록에 추가
                            }
                            _showUploadStatusOverlayUI(); // 진행 상태 갱신
                          }
                          // 업로드 후 현재 폴더의 파일 목록 새로고침
                          await refreshCurrentFolderFiles();
                          Future.delayed(const Duration(seconds: 2), () => refreshCurrentFolderFiles());
                          // 업로드 오버레이 일정 시간 후 자동 제거
                          Future.delayed(const Duration(seconds: 3), () {
                            _uploadOverlayEntry?.remove(); // 오버레이 제거
                            _uploadOverlayEntry = null; // 참조 제거
                          });
                        } catch (e) {
                          // 전체 업로드 중 오류 발생 시 에러 로그 및 스낵바 표시
                          print('파일 업로드 전체 실패: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('파일 업로드 중 오류 발생: $e')),
                          );
                        } finally {
                          // 업로드 상태 초기화
                          _isUploading = false;

                          // 드래그 처리 플래그도 딜레이 후 초기화
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
                                itemCount: selectedFiles.length, // 파일 개수만큼 생성
                                itemBuilder: (context, index) {
                                  final file = selectedFiles[index];
                                  final fileKey = GlobalKey(); // 마우스 Hover 시 미리보기
                                  return GestureDetector(
                                    // 마우스 우클리 시 메뉴 표시
                                    onSecondaryTapDown: (
                                      TapDownDetails details,
                                    ) {
                                      showContextMenuAtPosition(
                                        context: context,
                                        position: details.globalPosition,
                                        onSelected: (selected) async {
                                          final file = selectedFiles[index]; // 선택된 파일
                                          if (selected == 'delete') {
                                            // 삭제 선택 시 -> 휴지통으로 이동
                                            try {
                                              await moveToTrash(userId!, [], [
                                                file.id,
                                              ]);
                                              setState(() {
                                                selectedFiles.removeAt(index); // 리스트에서 제거
                                                fileNames.remove(file.name); // 중복 방지 리스트에서도 제거
                                              });
                                            } catch (e) {
                                              print('파일 휴지통 이동 실패: $e');
                                            }
                                          } else if (selected ==
                                              'add_to_important') { // 중복 문서함에 추가
                                            if (isAlreadyImportantFile( // 이미 등록된 경우 알림
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
                                        isFolder: false, 
                                        isCloud: false, 
                                      );
                                    },
                                    child: MouseRegion(
                                      key: fileKey,
                                      // 마우스를 파일 항목 이에 올렸을 때
                                      onEnter: (event) {
                                        _hoverTimer = Timer(
                                          const Duration(milliseconds: 500), // 0.5초 후 미리보기 오버레이 표시
                                          () {
                                            final position =
                                                event.position; // 마우스 위치
                                            _showPreviewOverlayAtPosition(
                                              context,
                                              file.fileUrl, // 미리볼 파일 URL
                                              file.type, // 파일 형식
                                              position, // 마우스 위치 오버레이 표시
                                              thumbnailUrl: file.fileThumbnail, // 썸네일 이미지가 있을 경우 사용
                                            );
                                          },
                                        );
                                      },
                                      // 마우스가 벗어났을 때 미리보기 제거
                                      onExit: (_) {
                                        _hoverTimer?.cancel();
                                        _removePreviewOverlay();
                                      },
                                      // 파일 항목 구성
                                      child: ListTile(
                                        leading: _buildFileLeadingThumb(file),
                                        title: Text(
                                          file.name, // 파일 이름
                                          overflow: TextOverflow.ellipsis, // 길 경우 말줄임표 처리
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
                                                // 중요 표시 여부에 따라 아이콘 변경
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
                                                )) {  // 중요 문서함에서 제거
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
                                                  // 중요 문서함에 추가
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
                                                // 상태 갱신
                                                await fetchImportantStatus();
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                        // 파일 클릭 시 미리보기 다이얼로그
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

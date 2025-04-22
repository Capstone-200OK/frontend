import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'package:flutter_application_1/api/file_uploader.dart';
import 'package:flutter_application_1/screens/file_sorty.dart';
import 'package:flutter_application_1/models/file_item.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  String? selectedFolderName;
  int? startFolderId;
  int? destFolderId;
  bool isStartSelected = false;
  bool isDestSelected = false;
  // 폴더 목록 상태 관리
  List<String> folders = [];

  Set<String> fileNames = {}; // 중복 방지를 위한 파일 이름 저장용 집합
  late String url;
  late FileUploader uploader;
  int currentFolderId = 101; // 시작 폴더 ID (예: 2번 루트)
  List<int> folderStack = []; // 상위 폴더 경로 추적
  Map<String, int> folderNameToId = {};

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    uploader = FileUploader(baseUrl: url);
    fetchFolderHierarchy(1); // 루트 폴더 ID
  }

  Future<void> fetchFolderHierarchy(
    int folderId, {
    bool pushToStack = true,
  }) async {
    final response = await http.get(
      Uri.parse('$url/folder/hierarchy/$folderId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 🔹 여기! folderList와 folderNameToId를 먼저 만든 뒤
      List<Map<String, dynamic>> folderList = List<Map<String, dynamic>>.from(
        data['subFolders'],
      );
      folderNameToId = {for (var f in folderList) f['name']: f['id']};

      setState(() {
        if (pushToStack && currentFolderId != folderId) {
          folderStack.add(currentFolderId);
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
            ),
          ),
        );

        fileNames = selectedFiles.map((f) => f.name).toSet();
        folderNameToId = {for (var f in folderList) f['name']: f['id']};

        // 🔸 folderNameToId도 저장하고 싶다면 상태 변수로 따로 관리 가능
      });
    } else {
      print('폴더 계층 불러오기 실패: ${response.statusCode}');
    }
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
              const SizedBox(width: 10), //햄버거 버튼과의 간격
              // 뒤로가기 버튼
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xff263238),
                  size: 15,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),

              // 타이틀
              Expanded(
                child: Text(
                  '${widget.username}님의 파일함',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              //아이콘 버튼
              Padding(
                padding: const EdgeInsets.only(right: 34), // 오른쪽에서 10px 떨어짐
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xff263238),
                      ), // 환경설정 아이콘
                      onPressed: () {
                        // 환경설정 페이지 이동 로직
                        print('환경설정 눌림');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.history,
                        color: Color(0xff263238),
                      ), //최근항목아이콘
                      onPressed: () {
                        // 최근 항목 페이지 이동 로직
                        print('최근 항목 눌림');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Color(0xff263238),
                      ), //d알림 버튼튼
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
                        child: Text('새 폴더'),
                      ),
                      const PopupMenuItem(
                        value: 'upload_file',
                        child: Text('파일 업로드'),
                      ),
                      const PopupMenuItem(
                        value: 'upload_folder',
                        child: Text('폴더 업로드'),
                      ),
                    ],
                  ).then((selected) async {
                    // folder_create를 불러와서 폴더 생성하는 팝업창
                    if (selected == 'new_folder') {
                      final result = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Container(
                              width: 300, // 너비 설정
                              height: 280, // 높이 설정
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
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
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
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.check,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '예약하기',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100.0),
                    child: Text(
                      '폴더',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
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
                      // // 🔹 Start 버튼
                      // ElevatedButton(
                      //   onPressed:
                      //       selectedFolderName != null && !isStartSelected
                      //           ? () {
                      //             setState(() {
                      //               startFolderId =
                      //                   folderNameToId[selectedFolderName!];
                      //               isStartSelected = true;
                      //             });
                      //           }
                      //           : null,
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.teal,
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 12,
                      //       vertical: 6,
                      //     ),
                      //   ),
                      //   child: const Text(
                      //     "Start",
                      //     style: TextStyle(color: Colors.white, fontSize: 12),
                      //   ),
                      // ),
                      // const SizedBox(width: 8),

                      // // 🔹 Dest 버튼
                      // ElevatedButton(
                      //   onPressed:
                      //       selectedFolderName != null && !isDestSelected
                      //           ? () {
                      //             setState(() {
                      //               destFolderId =
                      //                   folderNameToId[selectedFolderName!];
                      //               isDestSelected = true;
                      //             });
                      //           }
                      //           : null,
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.indigo,
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 12,
                      //       vertical: 6,
                      //     ),
                      //   ),
                      //   child: const Text(
                      //     "Dest",
                      //     style: TextStyle(color: Colors.white, fontSize: 12),
                      //   ),
                      // ),
                      // const SizedBox(width: 8),

                      // 🔹 Sorty 버튼
                      ElevatedButton(
                        onPressed:
                            selectedFolderName != null
                                ? () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => FileSortyScreen(
                                          files: selectedFiles,
                                          username: widget.username,
                                          sourceFolderId:
                                              folderNameToId[selectedFolderName!]!,
                                          destinationFolderId:
                                              folderNameToId[selectedFolderName!]!, // 동일 폴더로도 가능하게
                                        ),
                                  );
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff2E24E0),
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

                          final isSelected = selectedFolderName == folderName;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFolderName =
                                    isSelected ? null : folderName;
                              });
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
                                      isSelected
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
                                    scale: 0.6, // 숫자가 크면 커지고, 1.0 이 기본
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedFolderName =
                                              value == true ? folderName : null;
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
                                      if (folderId != null)
                                        fetchFolderHierarchy(folderId);
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

                        try {
                          // 업로드 호출
                          await uploader.uploadFiles(
                            file: droppedFiles[0],
                            userId: 1,
                            folderId: 2,
                          );
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
                            // 파일 리스트뷰
                            Expanded(
                              child: ListView.builder(
                                itemCount: folders.length,
                                itemBuilder: (context, index) {
                                  final folderName = folders[index];
                                  final isSelected = selectedFolderNames
                                      .contains(folderName);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0.1,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // ✅ 폴더 선택용 체크박스
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                if (!selectedFolderNames
                                                    .contains(folderName)) {
                                                  selectedFolderNames.add(
                                                    folderName,
                                                  );
                                                }
                                              } else {
                                                selectedFolderNames.remove(
                                                  folderName,
                                                );
                                              }
                                            });
                                          },
                                          activeColor: const Color(0xff263238),
                                          side: const BorderSide(
                                            color: Colors.white,
                                            width: 0.1,
                                          ),
                                          fillColor:
                                              MaterialStateProperty.resolveWith<
                                                Color
                                              >((states) {
                                                if (states.contains(
                                                  MaterialState.disabled,
                                                )) {
                                                  return Colors.white;
                                                }
                                                return Colors.white;
                                              }),
                                          checkColor: const Color(0xff263238),
                                        ),

                                        // ✅ 폴더 이름 및 UI 꾸밈
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.folder,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  folderName.length > 30
                                                      ? '${folderName.substring(0, 30)}...'
                                                      : folderName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontFamily:
                                                        'APPLESDGOTHICNEOR',
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      folders.removeAt(index);
                                                      selectedFolderNames
                                                          .remove(folderName);
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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

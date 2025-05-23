import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/folder_select_dialog.dart';
import 'package:flutter_application_1/api/file_reservation_service.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_application_1/models/reservation_item.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

class FileReservationScreen extends StatefulWidget {
  final String mode; // create 또는 modify 모드
  final Reservation? reservation; // 수정 모드일 때 기존 예약 정보

  const FileReservationScreen({super.key, this.mode = 'create', this.reservation});

  @override
  State<FileReservationScreen> createState() => _FileReservationScreenState();
}

class _FileReservationScreenState extends State<FileReservationScreen> {
  FolderItem? selectedPreviousFolder; // 정리할 기존 폴더
  FolderItem? selectedNewFolder; // 정리 후 보낼 목적지 폴더
  List<String> intervals = ['DAILY', 'WEEKLY', 'MONTHLY']; // 반복 주기 옵션
  int selectedInterval = 0; // 선택된 주기의 인덱스
  int selectedHour = 12; // 정리 예약 실행 시간 (시 기준)
  String? selectedMode; // 정리 기준 (content, title, date, type 등)
  late int? userId; // 사용자 ID
  late PageController _intervalPageController; // 주기 선택 슬라이더용 컨트롤러
  bool keepFolder = false; // 기존 폴더 유지 여부
  bool keepFileName = false; // 기존 파일 이름 유지 여부 (정리 기준이 내용일 때만 표시)
  @override
  void initState() {
    super.initState();
    // 사용자 ID 불러오기 (Provider 이용)
    userId = Provider.of<UserProvider>(context, listen: false).userId;
    
    // 주기 선택을 위한 페이지 컨트롤러 초기화
    _intervalPageController = PageController(
      initialPage: 1000 * intervals.length + 0, // 무한 스크롤처럼 보이게 설정
      viewportFraction: 0.58,
    );

    // 수정 모드일 경우 기존 예약 정보로 초기화
    if (widget.mode == 'modify' && widget.reservation != null) {
      final r = widget.reservation!;
      selectedPreviousFolder = FolderItem(id: r.previousFolderId, name: r.previousFoldername);
      selectedNewFolder = FolderItem(id: r.newFolderId, name: r.newFoldername);
      selectedMode = r.criteria.toLowerCase();
      selectedInterval = r.interval == 'DAILY' ? 0 : r.interval == 'WEEKLY' ? 1 : 2;
      selectedHour = r.nextExecuted.hour;
    }
  }
  @override
  void dispose() {
    _intervalPageController.dispose(); // 페이지 컨트롤러 해제
    super.dispose();
  }

  // 좌/우 화살표 버튼 클릭 시 주기 변경
  void _changeInterval(int direction) {
    setState(() {
      selectedInterval = (selectedInterval + direction) % intervals.length;
      if (selectedInterval < 0) {
        selectedInterval += intervals.length;
      }
    });
  }
  // 주기 선택 UI 위젯 (좌우 넘김 가능한 PageView)
  Widget buildIntervalSelector() {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 왼쪽 화살표 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              _intervalPageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          // 주기 표시 뷰
          SizedBox(
            width: 150,
            height: 40,
            child: PageView.builder(
             controller: _intervalPageController,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final actualIndex = index % intervals.length;
                final isSelected =
                  _intervalPageController.hasClients &&
                  ((_intervalPageController.page?.round() ?? 0) % intervals.length == actualIndex);
                return Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: isSelected ? 1.0 : 0.8,
                      end: isSelected ? 1.0 : 0.8,
                    ),
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    builder: (context, scale, child) {
                      return Opacity(
                        opacity: isSelected ? 1.0 : 0.4,
                        child: Transform.scale(
                          scale: scale,
                          child: Text(
                            intervals[actualIndex],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              onPageChanged: (index) {
                setState(() {
                  selectedInterval = index % intervals.length;
                });
              },
            ),
          ),
          // 오른쪽 화살표 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _intervalPageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );  
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFE0E0E0), // 다이얼로그 배경색
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 테두리 둥글게
      child: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 타이틀 바
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF37474F),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 다이얼로그 제목
                  Text(
                    widget.mode == 'modify' ? '파일 예약을 수정합니다 !' : '파일 예약을 시작합니다 !',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'APPLESDGOTHICNEOR',
                    ),
                  ),
                  // 닫기 버튼 (우측 X 아이콘)
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 본문 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽 설정 영역
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('주기를 설정하세요', style: TextStyle(fontSize: 14,fontFamily: 'APPLESDGOTHICNEOEB',)),
                          buildIntervalSelector(), // 주기 선택 뷰
                          const SizedBox(height: 4),

                          // 시간 선택
                          SizedBox(
                            height: 100,
                            child: Container(
                              color: Colors.white,
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(initialItem: selectedHour),
                                itemExtent: 30,
                                onSelectedItemChanged: (index) => setState(() => selectedHour = index),
                                children: List.generate(24, (index) {
                                  final isSelected = index == selectedHour;
                                  return Center(
                                    child: Text(
                                      '${index.toString().padLeft(2, '0')}:00',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isSelected ? Colors.black : Colors.grey.shade600, // 🔹 흐림 효과
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('관리 폴더 선택', style: TextStyle(fontFamily: 'APPLESDGOTHICNEOEB',)),
                          const SizedBox(height: 10),
                          // 이전 폴더 선택 버튼
                          GestureDetector(
                            onTap: () async {
                              final result = await showDialog<FolderItem>(
                                context: context,
                                builder: (_) => const FolderSelectDialog(),
                              );
                              if (result != null) setState(() => selectedPreviousFolder = result);
                            },
                            child: folderBox(selectedPreviousFolder?.name ?? '', Icons.add_circle),
                          ),
                          const SizedBox(height: 10),
                          const Text('목적지 폴더 선택', style: TextStyle(fontFamily: 'APPLESDGOTHICNEOEB',)),
                          const SizedBox(height: 10),
                          // 새 폴더 선택 버튼
                          GestureDetector(
                            onTap: () async {
                              final result = await showDialog<FolderItem>(
                                context: context,
                                builder: (_) => const FolderSelectDialog(),
                              );
                              if (result != null) setState(() => selectedNewFolder = result);
                            },
                            child: folderBox(selectedNewFolder?.name ?? '', Icons.drive_folder_upload),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // 오른쪽 정리 기준 및 옵션 영역
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text('정리 기준 선택', style: TextStyle(fontFamily: 'APPLESDGOTHICNEOEB',)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildTag(context, '내용', 'content'),
                              _buildTag(context, '제목', 'title'),
                              _buildTag(context, '날짜', 'date'),
                              _buildTag(context, '유형', 'type'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 기존 폴더 유지 여부
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('기존 폴더 유지', style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR',)),
                            value: keepFolder,
                            onChanged: (val) => setState(() => keepFolder = val!),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          // 내용 기준일 경우에만 파일이름 유지 체크 표시
                          if (selectedMode == 'content')
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('기존 파일이름 유지', style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR',)),
                              value: keepFileName,
                              onChanged: (val) => setState(() => keepFileName = val!),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          const SizedBox(height: 10),

                          // 예약 or 수정 버튼
                          ElevatedButton(
                            onPressed: () async {
                              // 폴더 선택 안됐을 경우 예외 처리
                              if (selectedPreviousFolder == null || selectedNewFolder == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('폴더를 모두 선택해주세요')));
                                return;
                              }

                              // 선택된 주기 변환
                              String convertedInterval = intervals[selectedInterval];

                              // 시간 선택에 맞춰 예약 시간 설정
                              DateTime selectedDateTime = DateTime.now().copyWith(
                                hour: selectedHour,
                                minute: 0,
                              );

                              bool success = false;

                              // 수정 모드일 경우
                              if (widget.mode == 'modify') {
                                success = await FileReservationService.modifyReservation(
                                  taskId: widget.reservation!.taskId,
                                  userId: userId!,
                                  previousFolderId: selectedPreviousFolder!.id,
                                  newFolderId: selectedNewFolder!.id,
                                  criteria: selectedMode?.toUpperCase() ?? 'TYPE',
                                  interval: convertedInterval,
                                  nextExecuted: selectedDateTime,
                                  keepFolder: keepFolder,
                                  keepFileName: keepFileName,
                                );
                              } else {
                                // 생성 모드일 경우
                                success = await FileReservationService.addReservation(
                                  userId: userId!,
                                  previousFolderId: selectedPreviousFolder!.id,
                                  newFolderId: selectedNewFolder!.id,
                                  criteria: selectedMode?.toUpperCase() ?? 'TYPE',
                                  interval: convertedInterval,
                                  nextExecuted: selectedDateTime,
                                  keepFolder: keepFolder,
                                  keepFileName: keepFileName,
                                );
                              }
                              // 성공 여부에 따른 메시지 처리
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.mode == 'modify' ? '파일 예약 수정 완료!' : '파일 예약 등록 완료!')));
                                Navigator.of(context, rootNavigator: true).pop();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('작업 실패 😢')));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E24E0)),
                            child: Text(
                              widget.mode == 'modify' ? '수정하기' : '예약하기',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontFamily: 'APPLESDGOTHICNEOR',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 폴더 이름 또는 아이콘을 표시하는 상자 위젯
  Widget folderBox(String text, IconData icon) {
    return Container(
      height: 40, // 높이 고정
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(
        // 폴더명이 비어 있으면 아이콘, 그렇지 않으면 텍스트 표시
        child: text.isEmpty
            ? Icon(icon, color: const Color(0xFF37474F))
            : Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  // 정리 기준 선택 버튼을 생성하는 위젯
  Widget _buildTag(BuildContext context, String label, String mode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedMode == mode ? const Color(0xFF37474F) : Colors.white, // 선택된 경우 배경색
        foregroundColor: selectedMode == mode ? Colors.white : const Color(0xFF37474F), // 텍스트 색상 반전
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 버튼 모서리 둥글게
      ), 
      onPressed: () => setState(() => selectedMode = mode), // 클릭 시 선택 상태 변경
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/folder_select_dialog.dart';
import 'package:flutter_application_1/api/file_reservation_service.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_application_1/models/reservation_item.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

class FileReservationScreen extends StatefulWidget {
  final String mode; // 'create' or 'modify'
  final Reservation? reservation;

  const FileReservationScreen({super.key, this.mode = 'create', this.reservation});

  @override
  State<FileReservationScreen> createState() => _FileReservationScreenState();
}

class _FileReservationScreenState extends State<FileReservationScreen> {
  FolderItem? selectedPreviousFolder;
  FolderItem? selectedNewFolder;
  List<String> intervals = ['DAILY', 'WEEKLY', 'MONTHLY'];
  int selectedInterval = 0;
  int selectedHour = 12;
  String? selectedMode;
  late int? userId;
  late PageController _intervalPageController;
  bool keepFolder = false;
  bool keepFileName = false;
  @override
  void initState() {
    super.initState();
    userId = Provider.of<UserProvider>(context, listen: false).userId;
    _intervalPageController = PageController(
      initialPage: 1000 * intervals.length + 0, // 무한스크롤 느낌
      viewportFraction: 0.58,
    );

    // ⭐ modify 모드면 기존 값으로 초기화
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
    _intervalPageController.dispose();
    super.dispose();
  }
  void _changeInterval(int direction) {
    setState(() {
      selectedInterval = (selectedInterval + direction) % intervals.length;
      if (selectedInterval < 0) {
        selectedInterval += intervals.length;
      }
    });
  }
Widget buildIntervalSelector() {
  return SizedBox(
    height: 50,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            _intervalPageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
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
      backgroundColor: const Color(0xFFE0E0E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  Text(
                    widget.mode == 'modify' ? '파일 예약을 수정합니다 !' : '파일 예약을 시작합니다 !',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'APPLESDGOTHICNEOR',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('주기를 설정하세요', style: TextStyle(fontSize: 14,fontFamily: 'APPLESDGOTHICNEOEB',)),
                          buildIntervalSelector(),
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

                    // 오른쪽
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
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('기존 폴더 유지', style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR',)),
                            value: keepFolder,
                            onChanged: (val) => setState(() => keepFolder = val!),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (selectedMode == 'content')
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('기존 파일이름 유지', style: TextStyle(fontSize: 12, fontFamily: 'APPLESDGOTHICNEOR',)),
                              value: keepFileName,
                              onChanged: (val) => setState(() => keepFileName = val!),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedPreviousFolder == null || selectedNewFolder == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('폴더를 모두 선택해주세요')));
                                return;
                              }

                              String convertedInterval = intervals[selectedInterval];

                              DateTime selectedDateTime = DateTime.now().copyWith(
                                hour: selectedHour,
                                minute: 0,
                              );

                              bool success = false;
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

  Widget folderBox(String text, IconData icon) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: text.isEmpty
            ? Icon(icon, color: const Color(0xFF37474F))
            : Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label, String mode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedMode == mode ? const Color(0xFF37474F) : Colors.white,
        foregroundColor: selectedMode == mode ? Colors.white : const Color(0xFF37474F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => setState(() => selectedMode = mode),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

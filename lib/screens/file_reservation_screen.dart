import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/folder_select_dialog.dart';
import 'package:flutter_application_1/api/file_reservation_service.dart';
import 'package:flutter_application_1/models/folder_item.dart';

class FileReservationScreen extends StatefulWidget {
  const FileReservationScreen({super.key});

  @override
  State<FileReservationScreen> createState() => _FileReservationScreenState();
}

class _FileReservationScreenState extends State<FileReservationScreen> {
  FolderItem? selectedPreviousFolder;
  FolderItem? selectedNewFolder;
  List<String> intervals = ['하루', '일주일', '한 달'];
  int selectedInterval = 0;
  int selectedHour = 12;
  String? selectedMode;

  void _changeInterval(int direction) {
    setState(() {
      selectedInterval = (selectedInterval + direction) % intervals.length;
      if (selectedInterval < 0) selectedInterval += intervals.length;
    });
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
            // 상단 바 (패딩 없이 가득)
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
                  const Text(
                    '파일 예약을 시작합니다 !',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'APPLESDGOTHICNEOR',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 본문은 Padding으로 감싸기
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽 부분
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '주기를 설정하세요',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'APPLESDGOTHICNEOR',
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => _changeInterval(-1),
                                icon: const Icon(Icons.arrow_left),
                              ),
                              Text(
                                intervals[selectedInterval],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'APPLESDGOTHICNEOR',
                                ),
                              ),
                              IconButton(
                                onPressed: () => _changeInterval(1),
                                icon: const Icon(Icons.arrow_right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 시간 선택
                          SizedBox(
                            height: 100,
                            child: Container(
                              color: Colors.white,
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: selectedHour,
                                ),
                                itemExtent: 30,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedHour = index;
                                  });
                                },
                                children: List.generate(24, (index) {
                                  return Center(
                                    child: Text(
                                      '${index.toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '주기적으로 관리할 폴더를 선택해 주세요',
                            style: TextStyle(
                              fontFamily: 'APPLESDGOTHICNEOR',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              selectedPreviousFolder =
                                  await showDialog<FolderItem>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const FolderSelectDialog();
                                    },
                                  );

                              if (selectedPreviousFolder != null) {
                                print(
                                  '출발 폴더 선택됨: ${selectedPreviousFolder!.name}',
                                );
                                setState(() {}); // ✅ UI 갱신
                              }
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child:
                                    selectedPreviousFolder == null
                                        ? const Icon(
                                          Icons.add_circle,
                                          color: Color(0xFF37474F),
                                        )
                                        : Text(
                                          selectedPreviousFolder!.name,
                                          style: const TextStyle(
                                            fontFamily: 'APPLESDGOTHICNEOR',
                                            fontSize: 13,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '목적지 폴더를 선택하세요',
                            style: TextStyle(
                              fontFamily: 'APPLESDGOTHICNEOR',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              // 목적지 폴더 선택
                              selectedNewFolder = await showDialog<FolderItem>(
                                context: context,
                                builder: (BuildContext context) {
                                  return const FolderSelectDialog();
                                },
                              );

                              if (selectedNewFolder != null) {
                                print('목적지 폴더 선택됨: ${selectedNewFolder!.name}');
                                setState(() {}); // ✅ UI 갱신
                              }
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child:
                                    selectedNewFolder == null
                                        ? const Icon(
                                          Icons.drive_folder_upload,
                                          color: Color(0xFF37474F),
                                        )
                                        : Text(
                                          selectedNewFolder!.name,
                                          style: const TextStyle(
                                            fontFamily: 'APPLESDGOTHICNEOR',
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // 오른쪽 부분
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '정리 기준을 선택해 주세요!',
                              style: TextStyle(
                                fontFamily: 'APPLESDGOTHICNEOR',
                                fontSize: 14,
                              ),
                            ),
                          ),
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
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () async {
                              if (selectedPreviousFolder == null ||
                                  selectedNewFolder == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('폴더를 모두 선택해주세요'),
                                  ),
                                );
                                return;
                              }

                              bool success =
                                  await FileReservationService.addReservation(
                                    userId: 1,
                                    previousFolderId:
                                        selectedPreviousFolder!.id, // 여기 ✅
                                    newFolderId: selectedNewFolder!.id, // 여기 ✅
                                    criteria:
                                        selectedMode?.toUpperCase() ?? 'TYPE',
                                    interval:
                                        intervals[selectedInterval] == '하루'
                                            ? 'DAILY'
                                            : intervals[selectedInterval] ==
                                                '일주일'
                                            ? 'WEEKLY'
                                            : 'MONTHLY',
                                    nextExecuted: DateTime.now()
                                        .add(
                                          Duration(
                                            days:
                                                selectedInterval == 0
                                                    ? 1
                                                    : selectedInterval == 1
                                                    ? 7
                                                    : 30,
                                          ),
                                        )
                                        .copyWith(
                                          hour: selectedHour,
                                          minute: 0,
                                        ),
                                  );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('파일 예약이 완료되었습니다!'),
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('파일 예약에 실패했습니다 😢'),
                                  ),
                                );
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E24E0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 53,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              '예약하기',
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

  // Widget _buildTag(String label) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(13),
  //     ),
  //     child: Text(
  //       label,
  //       style: const TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOR'),
  //     ),
  //   );
  // }

  Widget _buildTag(BuildContext context, String label, String mode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedMode == mode ? Color(0xFF37474F) : Colors.white,
        foregroundColor:
            selectedMode == mode ? Colors.white : Color(0xFF37474F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          selectedMode = mode;
        });
      },
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOR'),
      ),
    );
  }
}

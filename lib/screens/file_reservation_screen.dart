import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/folder_select_dialog.dart';


class FileReservationScreen extends StatefulWidget {
  const FileReservationScreen({super.key});

  @override
  State<FileReservationScreen> createState() => _FileReservationScreenState();
}

class _FileReservationScreenState extends State<FileReservationScreen> {
  List<String> intervals = ['하루', '일주일', '한 달'];
  int selectedInterval = 0;
  int selectedHour = 12;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 바
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF37474F),
                borderRadius: BorderRadius.circular(15),
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

            // 주기 설정, 파일 추가, 목적지 폴더 위치 추가 (왼쪽 레이아웃)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽 부분 (주기 설정, 파일 추가, 목적지 폴더 위치 추가)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 주기 설정
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
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('주기적으로 관리할 파일을 선택해 주세요'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          // 폴더 선택 다이얼로그 띄우기
                          String? selectedFolder = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return const FolderSelectDialog();
                            },
                          );
                          if (selectedFolder != null) {
                            // 선택된 폴더에 대한 처리
                            print('선택된 폴더: $selectedFolder');
                          }
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('목적지 폴더를 선택하세요'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          // 폴더 선택 다이얼로그 띄우기
                          String? selectedFolder = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return const FolderSelectDialog();
                            },
                          );

                          if (selectedFolder != null) {
                            // 선택된 폴더에 대한 처리
                            print('선택된 폴더: $selectedFolder');
                          }
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 오른쪽 부분 (정리 기준, 예약하기 버튼)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('정리 기준을 선택해 주세요!'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildTag('내용'),
                          _buildTag('제목'),
                          _buildTag('날짜'),
                          _buildTag('유형'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 예약하기 버튼
                      ElevatedButton(
                        onPressed: () {
                          print(
                            '예약 설정됨: ${intervals[selectedInterval]}, ${selectedHour}시',
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF37474F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '예약하기',
                          style: TextStyle(
                            fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOR'),
      ),
    );
  }
}

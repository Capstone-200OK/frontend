import 'package:flutter/material.dart';

class PersonalScreen extends StatefulWidget {
  final String username;

  const PersonalScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  // 파일 선택 상태 저장용 리스트
  List<bool> selectedFiles = List.generate(6, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('${widget.username}님의 파일함', style: const TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Icon(Icons.history, color: Colors.black),
          SizedBox(width: 10),
          Icon(Icons.settings, color: Colors.black),
          SizedBox(width: 10),
        ],
      ),
      drawer: const Drawer(), // 필요 시 구현
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 폴더 & 파일 레이블
            Row(
              children: const [
                Expanded(child: Text('폴더', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Expanded(child: Text('파일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),

            // 폴더 & 파일 영역
            Expanded(
              child: Row(
                children: [
                  // 폴더 리스트
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        itemCount: 8,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.folder, color: Colors.black),
                              label: const Text('학생회', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 파일 리스트
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // 정렬 버튼
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('SORTY', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),

                          // 파일 리스트뷰
                          Expanded(
                            child: ListView.builder(
                              itemCount: selectedFiles.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Checkbox(
                                    value: selectedFiles[index],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedFiles[index] = value ?? false;
                                      });
                                    },
                                  ),
                                  title: index == 0
                                      ? Row(
                                          children: const [
                                            Icon(Icons.description, size: 24),
                                            SizedBox(width: 8),
                                            Text('회사 보고서_2025'),
                                          ],
                                        )
                                      : Container(
                                          height: 20,
                                          color: Colors.white,
                                        ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text('word / 2KB'),
                                      SizedBox(width: 12),
                                      Icon(Icons.star_border),
                                      SizedBox(width: 8),
                                      Icon(Icons.more_vert),
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
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 검색창
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Color(0xff263238)),
                  SizedBox(width: 8),
                  Expanded(child: TextField(decoration: InputDecoration(border: InputBorder.none, hintText: '검색'))),
                  Icon(Icons.tune, color: Color(0xff263238)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

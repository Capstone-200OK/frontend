//팝업이 아니라 창으로 만들기 
//리스트 스크롤 할 수 있게끔 

import 'package:flutter/material.dart';

void showFileMoveDialog(
  BuildContext context,
  String fromPath,
  String toPath,
  String fileName,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 500,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '파일 이동 경로',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                fileName,
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.folder, size: 50),
                        onPressed: () {
                          print('출발 폴더 클릭');
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(fromPath),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, size: 30),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.folder, size: 50),
                        onPressed: () {
                          print('도착 폴더 클릭');
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(toPath),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      );
    },
  );
}


// 유저 ID나 숫자 값을 계속 넘기기 위한 Provider 모델
import 'package:flutter/material.dart';

// ChangeNotifier를 사용한 상태 관리 모델
class CounterModel with ChangeNotifier {
  int _count = 0; // 내부 상태 값 (초기값 0)

  // 외부에서 count 값을 읽을 수 있도록 getter 제공
  int get count => _count;

  // count 값을 1 증가시키고, 리스너들에게 알림
  void increase() {
    _count++;
    notifyListeners(); // 이 모델을 구독하는 위젯들에게 상태 변경 알림
  }

  // count 값을 1 감소시키고, 리스너들에게 알림
  void decrease() {
    _count--;
    notifyListeners(); // UI 갱신을 위한 알림
  }
}
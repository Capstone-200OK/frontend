/// 화면 이동 기록을 관리하는 스택 클래스 (페이지 이동 추적용)
class NavigationStack {
  // 내부에서 사용하는 스택(List) 구조: 각 항목은 route 이름과 arguments를 담은 Map
  static final List<Map<String, dynamic>> _stack = [];

  // 새로운 화면 정보를 스택에 추가
  static void push(String route, {Map<String, dynamic>? arguments}) {
    _stack.add({
      'route': route, // 화면 경로 이름
      'arguments': arguments ?? {}, // 화면에 전달된 인자 (없으면 빈 Map)
    });
  }

  // 스택의 최상단(최근) 항목을 반환 (제거하지 않음)
  static Map<String, dynamic>? peek() {
    if (_stack.isNotEmpty) {
      return _stack.last;
    }
    return null;
  }

  // 스택의 최상단 항목을 제거 (pop)
  static void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast(); // 마지막 항목 제거
    }
  }

  // 스택에서 이전 화면 정보 반환
  static Map<String, dynamic>? getPrevious() {
    if (_stack.length >= 2) {
      // 이전 화면이 존재하는 경우 (현재 화면 제외한 마지막 바로 전 항목)
      return _stack[_stack.length - 2];
    }
    else if (_stack.length == 1) {
      // 스택에 하나만 있는 경우, 그 하나를 반환
      return _stack[0];
    }
    return null; // 아무것도 없을 경우
  }

  // 현재 스택 내용을 출력 (디버깅용)
  static void printStack() {
    print("📋 Navigation Stack: $_stack");
  }

  // 스택 초기화 (모든 기록 삭제)
  static void clear() {
    _stack.clear();
  }
}
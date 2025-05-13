class NavigationStack {
  static final List<Map<String, dynamic>> _stack = [];

  static void push(String route, {Map<String, dynamic>? arguments}) {
    _stack.add({
      'route': route,
      'arguments': arguments ?? {},
    });
  }

  static Map<String, dynamic>? peek() {
    if (_stack.isNotEmpty) {
      return _stack.last;
    }
    return null;
  }

  static void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();    // 마지막 화면 pop
    }
  }

  static Map<String, dynamic>? getPrevious() {
    if (_stack.length >= 2) {
      return _stack[_stack.length - 2];
    }
    else if (_stack.length == 1) {
      return _stack[0];
    }
    return null;
  }

  static void printStack() {
    print("📋 Navigation Stack: $_stack");
  }

  static void clear() {
    _stack.clear();
  }
}
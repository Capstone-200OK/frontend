import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
  
    let flutterViewController = FlutterViewController()
    let windowFrame = NSRect(x: 0, y: 0, width: 1040, height: 720)  // 창 크기 설정
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)  // 설정한 크기로 창을 띄움
    
    self.isMovableByWindowBackground = true  // 창 이동 가능
    self.styleMask.insert(.resizable)  // 창 크기 조절 가능 (원하면 제거 가능)

   RegisterGeneratedPlugins(registry: flutterViewController)
   super.awakeFromNib()
  }
}

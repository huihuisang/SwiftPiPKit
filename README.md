# SwiftPiPKit

[English](#english) | [中文](#中文)

---

## English

A modern Swift package that brings Picture-in-Picture (PiP) functionality to SwiftUI applications. Display any custom SwiftUI View in a floating PiP window with full state synchronization.

### Features

✨ **Generic Support** - Use any SwiftUI View as PiP content  
🔄 **State Synchronization** - Seamlessly sync state between main app and PiP window  
🎯 **Navigation Restoration** - Smooth transitions when returning from PiP  
🎨 **Modern API** - Clean, type-safe SwiftUI integration  
📱 **iOS 15+** - Built on latest AVFoundation ContentSource API

### Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

### Installation

#### Swift Package Manager

Add SwiftPiPKit to your project using Xcode:

1. File → Add Packages...
2. Enter the package repository URL
3. Select version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "path/to/SwiftPiPKit", from: "1.0.0")
]
```

### Configuration

Add the following to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Quick Start

#### 1. Import the framework

```swift
import SwiftPiPKit
```

#### 2. Create a PiPManager with your custom content

```swift
@StateObject private var pipManager = PiPManager {
    MyCustomPiPView()
}
```

#### 3. Attach an anchor view (must be visible on screen)

**Recommended: Simplified API**

```swift
Button("Start PiP") {
    pipManager.startPictureInPicture()
}
.attachToPiP(pipManager)
```

**Advanced: Manual setup (for custom requirements)**

```swift
Button("Start PiP") {
    pipManager.startPictureInPicture()
}
.background {
    PiPAnchorView { view in
        pipManager.attachActiveSourceView(view)
    }
    .frame(width: 1, height: 1)
}
```

**Customization options:**

```swift
// Use minimal footprint (1x1 size)
.attachToPiP(pipManager, size: CGSize(width: 1, height: 1))

// Custom configuration
.attachToPiP(pipManager) { view in
    view.backgroundColor = .clear
}
```

#### 4. Control PiP lifecycle

```swift
// Start Picture-in-Picture
pipManager.startPictureInPicture()

// Stop Picture-in-Picture
pipManager.stopPictureInPicture()

// Check PiP status
if pipManager.isPictureInPictureActive {
    // PiP is active
}
```

### Advanced Usage

#### State Synchronization

Pass observable objects to your PiP content to keep state in sync:

```swift
@StateObject private var counter = Counter()

let pipManager = PiPManager {
    CounterView(counter: counter)
}
```

Both the main app and PiP window will observe and react to state changes.

#### Navigation Restoration

Handle the restore callback to navigate to a specific screen:

```swift
pipManager.onRestoreRequested = {
    navigateToDetailView = true
}
```

On the destination screen, update the anchor point:

**Recommended: Simplified API**

```swift
DetailView()
    .updatePiPAnchor(pipManager)
```

**Advanced: Manual setup**

```swift
PiPAnchorView { view in
    pipManager.updateAnchorForRestore(view)
}
.frame(width: 2, height: 2)
```

#### Background/Foreground Handling

Automatically manage PiP when app moves to background:

```swift
.onChange(of: scenePhase) { phase in
    switch phase {
    case .background:
        pipManager.startPictureInPicture()
    case .active:
        if !pipManager.isRestoringFromPiP {
            pipManager.stopPictureInPicture()
        }
    default:
        break
    }
}
```

### Example

```swift
import SwiftUI
import SwiftPiPKit

struct ContentView: View {
    @StateObject private var pipManager = PiPManager {
        PiPContentView()
    }
    
    var body: some View {
        VStack {
            Text("SwiftUI PiP Demo")
                .font(.title)
            
            Button("Start PiP") {
                pipManager.startPictureInPicture()
            }
            .attachToPiP(pipManager)
            
            Button("Stop PiP") {
                pipManager.stopPictureInPicture()
            }
        }
    }
}

struct PiPContentView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.6)
            Text("PiP View")
                .foregroundColor(.white)
        }
    }
}
```

### Troubleshooting

**PiP not working on device?**
- Ensure iOS 15+ on iPhone, iOS 9+ on iPad
- Verify Info.plist configuration
- Check that anchor view is visible on screen
- Test on a real device (simulator has limitations)

**PiP window not displaying content?**
- Ensure view is properly passed to PiPManager
- Check console for error messages
- Verify your content view renders correctly

### License

MIT License - See LICENSE file for details

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 中文

一个现代化的 Swift 包，为 SwiftUI 应用带来画中画（PiP）功能。在浮动的 PiP 窗口中显示任何自定义的 SwiftUI 视图，并支持完整的状态同步。

### 特性

✨ **泛型支持** - 使用任何 SwiftUI View 作为 PiP 内容  
🔄 **状态同步** - 主应用和 PiP 窗口之间无缝同步状态  
🎯 **导航恢复** - 从 PiP 返回时平滑过渡  
🎨 **现代 API** - 简洁、类型安全的 SwiftUI 集成  
📱 **iOS 15+** - 基于最新的 AVFoundation ContentSource API

### 系统要求

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

### 安装

#### Swift Package Manager

使用 Xcode 将 SwiftPiPKit 添加到你的项目：

1. 文件 → 添加包...
2. 输入包仓库 URL
3. 选择版本并添加到目标

或添加到你的 `Package.swift`：

```swift
dependencies: [
    .package(url: "path/to/SwiftPiPKit", from: "1.0.0")
]
```

### 配置

在 `Info.plist` 中添加以下内容：

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### 快速开始

#### 1. 导入框架

```swift
import SwiftPiPKit
```

#### 2. 创建带有自定义内容的 PiPManager

```swift
@StateObject private var pipManager = PiPManager {
    MyCustomPiPView()
}
```

#### 3. 附加锚点视图（必须在屏幕上可见）

**推荐：简化 API**

```swift
Button("开始画中画") {
    pipManager.startPictureInPicture()
}
.attachToPiP(pipManager)
```

**高级：手动设置（用于自定义需求）**

```swift
Button("开始画中画") {
    pipManager.startPictureInPicture()
}
.background {
    PiPAnchorView { view in
        pipManager.attachActiveSourceView(view)
    }
    .frame(width: 1, height: 1)
}
```

**自定义选项：**

```swift
// 使用最小占用空间（1x1 尺寸）
.attachToPiP(pipManager, size: CGSize(width: 1, height: 1))

// 自定义配置
.attachToPiP(pipManager) { view in
    view.backgroundColor = .clear
}
```

#### 4. 控制 PiP 生命周期

```swift
// 开始画中画
pipManager.startPictureInPicture()

// 停止画中画
pipManager.stopPictureInPicture()

// 检查 PiP 状态
if pipManager.isPictureInPictureActive {
    // PiP 处于活跃状态
}
```

### 高级用法

#### 状态同步

将可观察对象传递给 PiP 内容以保持状态同步：

```swift
@StateObject private var counter = Counter()

let pipManager = PiPManager {
    CounterView(counter: counter)
}
```

主应用和 PiP 窗口都会观察并响应状态变化。

#### 导航恢复

处理恢复回调以导航到特定屏幕：

```swift
pipManager.onRestoreRequested = {
    navigateToDetailView = true
}
```

在目标屏幕上，更新锚点：

**推荐：简化 API**

```swift
DetailView()
    .updatePiPAnchor(pipManager)
```

**高级：手动设置**

```swift
PiPAnchorView { view in
    pipManager.updateAnchorForRestore(view)
}
.frame(width: 2, height: 2)
```

#### 后台/前台处理

当应用进入后台时自动管理 PiP：

```swift
.onChange(of: scenePhase) { phase in
    switch phase {
    case .background:
        pipManager.startPictureInPicture()
    case .active:
        if !pipManager.isRestoringFromPiP {
            pipManager.stopPictureInPicture()
        }
    default:
        break
    }
}
```

### 示例

```swift
import SwiftUI
import SwiftPiPKit

struct ContentView: View {
    @StateObject private var pipManager = PiPManager {
        PiPContentView()
    }
    
    var body: some View {
        VStack {
            Text("SwiftUI 画中画演示")
                .font(.title)
            
            Button("开始画中画") {
                pipManager.startPictureInPicture()
            }
            .attachToPiP(pipManager)
            
            Button("停止画中画") {
                pipManager.stopPictureInPicture()
            }
        }
    }
}

struct PiPContentView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.6)
            Text("PiP 视图")
                .foregroundColor(.white)
        }
    }
}
```

### 故障排除

**设备上 PiP 无法工作？**
- 确保 iPhone 使用 iOS 15+，iPad 使用 iOS 9+
- 验证 Info.plist 配置
- 检查锚点视图在屏幕上可见
- 在真机上测试（模拟器有限制）

**PiP 窗口不显示内容？**
- 确保视图正确传递给 PiPManager
- 检查控制台错误消息
- 验证内容视图能正确渲染

### 许可证

MIT 许可证 - 详见 LICENSE 文件

### 贡献

欢迎贡献！请随时提交 Pull Request。


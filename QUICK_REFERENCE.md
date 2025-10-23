# SwiftPiPKit Quick Reference / 快速参考

## Basic Setup / 基础设置

### Simplified API (Recommended) / 简化 API（推荐）

```swift
import SwiftPiPKit

// 1. Create PiPManager with your content
@StateObject private var pipManager = PiPManager {
    YourCustomPiPView()
}

// 2. Attach anchor (must be visible)
Button("Start PiP") {
    pipManager.startPictureInPicture()
}
.attachToPiP(pipManager)
```

### Manual Setup (Advanced) / 手动设置（高级）

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

## API Reference / API 参考

### PiPManager

```swift
class PiPManager<Content: View>: ObservableObject
```

#### Properties / 属性

| Property | Type | Description |
|----------|------|-------------|
| `isPictureInPictureActive` | `Bool` | PiP 是否活跃 / Is PiP active |
| `isRestoringFromPiP` | `Bool` | 是否正在从 PiP 恢复 / Is restoring from PiP |
| `onRestoreRequested` | `(() -> Void)?` | 恢复回调 / Restore callback |

#### Methods / 方法

```swift
// Initialize with content
init(@ViewBuilder content: @escaping () -> Content)

// Attach anchor view (must be visible on screen)
func attachActiveSourceView(_ view: UIView)

// Start Picture-in-Picture
func startPictureInPicture()

// Stop Picture-in-Picture
func stopPictureInPicture()

// Update anchor for restore animation
func updateAnchorForRestore(_ newAnchor: UIView)
```

### View Extension

```swift
extension View {
    func attachToPiP<Content: View>(
        _ manager: PiPManager<Content>,
        size: CGSize? = nil,
        configure: ((UIView) -> Void)? = nil
    ) -> some View
}
```

#### Usage / 用法

```swift
// Attach PiP to a view (default: use container size)
.attachToPiP(pipManager)

// Minimal footprint (1x1)
.attachToPiP(pipManager, size: CGSize(width: 1, height: 1))

// Custom configuration
.attachToPiP(pipManager) { view in
    view.backgroundColor = .clear
}

// Update anchor for restore animation
.updatePiPAnchor(pipManager)

// Update with custom size
.updatePiPAnchor(pipManager, size: CGSize(width: 2, height: 2))
```

### PiPAnchorView

```swift
struct PiPAnchorView: UIViewRepresentable
```

#### Usage / 用法

```swift
PiPAnchorView { view in
    pipManager.attachActiveSourceView(view)
}
.frame(width: 1, height: 1)
```

## Common Patterns / 常用模式

### With State Synchronization / 带状态同步

```swift
@StateObject private var sharedData = SharedData()

let pipManager = PiPManager {
    ContentView(data: sharedData)
}
```

### Navigation Restoration / 导航恢复

```swift
// In main view / 在主视图中
pipManager.onRestoreRequested = {
    navigateToDetail = true
}

// In detail view / 在详情视图中
DetailView()
    .updatePiPAnchor(pipManager)

// Or manual setup / 或者手动设置
PiPAnchorView { view in
    pipManager.updateAnchorForRestore(view)
}
.frame(width: 2, height: 2)
```

### Background/Foreground / 后台/前台

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

## Requirements / 要求

- iOS 15.0+
- Info.plist configuration:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Tips / 提示

✅ Anchor view must be visible on screen  
✅ Use @ObservedObject for state sync  
✅ Check `isRestoringFromPiP` before stopping PiP  
✅ Test on real devices (simulator has limitations)

❌ Don't hide anchor view  
❌ Don't stop PiP during restore animation  
❌ Don't forget Info.plist configuration


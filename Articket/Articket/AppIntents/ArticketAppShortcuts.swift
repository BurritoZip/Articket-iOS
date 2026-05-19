import AppIntents

// Shortcuts 앱에 Articket 액션을 자동으로 노출시키는 프로바이더
// SceneDelegate.scene(_:willConnectTo:) 에서 updateAppShortcutParameters() 호출 필수
@available(iOS 16.0, *)
struct ArticketAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTimetableWallpaperIntent(),
            phrases: [
                "\(.applicationName) 배경화면 가져오기",
                "\(.applicationName) 타임테이블 배경화면",
                "\(.applicationName) 잠금화면 설정"
            ],
            shortTitle: "배경화면 가져오기",
            systemImageName: "photo.on.rectangle"
        )
    }
}

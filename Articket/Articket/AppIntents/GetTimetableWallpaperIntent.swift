import AppIntents
import UIKit
import UniformTypeIdentifiers

// Shortcuts: Articket "배경화면 가져오기" → 시스템 "배경화면 사진 설정"(잠금 화면)
@available(iOS 16.0, *)
struct GetTimetableWallpaperIntent: AppIntent {

    static var title: LocalizedStringResource = "타임테이블 배경화면 가져오기"
    static var description = IntentDescription(
        "앱에서 저장한 배경+타임테이블 합성 이미지를 반환합니다. 단축어에서 '배경화면 사진 설정'과 연결하세요."
    )

    func perform() async throws -> some ReturnsValue<IntentFile> & ProvidesDialog {
        guard let data = try? Data(contentsOf: TimetableWallpaperStorage.fileURL),
              !data.isEmpty else {
            throw TimetableIntentError.noSavedImage
        }
        let file = IntentFile(data: data, filename: "timetable_wallpaper.png", type: .png)
        return .result(value: file, dialog: "잠금화면 이미지를 가져왔습니다. 단축어에서 '배경화면 사진 설정'을 이어주세요.")
    }
}

enum TimetableIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case noSavedImage

    var localizedStringResource: LocalizedStringResource {
        "Articket 앱에서 '타임테이블 이미지 저장하기'를 먼저 실행해주세요."
    }
}

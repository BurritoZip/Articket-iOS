import Foundation
import UIKit
import Supabase

/// app_error_logs 테이블에 앱 런타임 에러/크래시를 insert. 실패해도 앱 흐름을 막지 않도록 조용히 무시.
struct SupabaseErrorReporter: ErrorReporting {

    private struct ErrorInsert: Encodable {
        let platform: String
        let errorType: String
        let message: String
        let domain: String?
        let stackTrace: String?
        let context: [String: String]?
        let appVersion: String?
        let osVersion: String?
        let deviceModel: String?
        let appUserId: UUID?
        enum CodingKeys: String, CodingKey {
            case platform
            case errorType = "error_type"
            case message
            case domain
            case stackTrace = "stack_trace"
            case context
            case appVersion = "app_version"
            case osVersion = "os_version"
            case deviceModel = "device_model"
            case appUserId = "app_user_id"
        }
    }

    func report(_ report: AppErrorReport) async {
        let insert = ErrorInsert(
            platform: "ios",
            errorType: report.type.rawValue,
            message: String(report.message.prefix(2000)),
            domain: report.domain,
            stackTrace: report.stackTrace,
            context: report.context,
            appVersion: DeviceInfo.appVersion,
            osVersion: DeviceInfo.osVersion,
            deviceModel: DeviceInfo.deviceModel,
            appUserId: AuthService.shared.currentUserId
        )
        // 텔레메트리 성격 — 실패는 무시(앱 UX 영향 없음)
        try? await SupabaseService.shared.client
            .from("app_error_logs")
            .insert(insert)
            .execute()
    }
}

/// 에러 리포트에 붙일 실행 환경 정보
enum DeviceInfo {
    static var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short)(\(build))"
    }

    static var osVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}

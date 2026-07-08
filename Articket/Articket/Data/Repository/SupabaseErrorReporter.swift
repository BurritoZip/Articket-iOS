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
        let id = modelIdentifier
        // "iPhone 15 Pro (iPhone16,1)" 처럼 마케팅명 + 식별자. 미매핑이면 식별자만.
        if let name = marketingName(for: id) {
            return "\(name) (\(id))"
        }
        return id
    }

    /// 하드웨어 식별자. 시뮬레이터는 utsname 이 호스트 arch("arm64")를 주므로 env 로 대체.
    private static var modelIdentifier: String {
        if let sim = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return sim
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }

    /// 최근 기종 식별자 → 마케팅명. 미등록 기종은 nil(식별자만 표기).
    private static func marketingName(for id: String) -> String? {
        let map: [String: String] = [
            // iPhone 16
            "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
            "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,5": "iPhone 16e",
            // iPhone 15
            "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
            // iPhone 14
            "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
            // iPhone 13
            "iPhone14,5": "iPhone 13", "iPhone14,4": "iPhone 13 mini",
            "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
            // iPhone SE / 12
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone13,2": "iPhone 12", "iPhone13,1": "iPhone 12 mini",
            "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
        ]
        return map[id]
    }
}

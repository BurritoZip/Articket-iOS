import Foundation

/// 진단용 흔적 1건 — 화면 진입/UI 액션/API 결과.
struct Breadcrumb: Sendable, Equatable {
    enum Kind: String, Sendable { case screen, action, api }
    let time: Date
    let kind: Kind
    let screen: String?
    let message: String
    let meta: [String: String]?
}

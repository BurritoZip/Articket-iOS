import Foundation

@MainActor final class SearchViewModel {

    struct State {
        var recentKeywords: [String] = []
        var recommendedKeywords: [String] = ["단독콘서트", "페스티벌", "내한공연", "뮤지컬", "재즈"]
    }

    private static let recentKey = "search.recentKeywords"
    private static let maxRecent = 10

    var state = State()
    var onStateChanged: (() -> Void)?

    init() {
        state.recentKeywords = UserDefaults.standard.stringArray(forKey: Self.recentKey) ?? []
    }

    func addKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        state.recentKeywords.removeAll { $0 == trimmed }
        state.recentKeywords.insert(trimmed, at: 0)
        if state.recentKeywords.count > Self.maxRecent {
            state.recentKeywords = Array(state.recentKeywords.prefix(Self.maxRecent))
        }
        UserDefaults.standard.set(state.recentKeywords, forKey: Self.recentKey)
        onStateChanged?()
    }

    func removeKeyword(_ keyword: String) {
        state.recentKeywords.removeAll { $0 == keyword }
        UserDefaults.standard.set(state.recentKeywords, forKey: Self.recentKey)
        onStateChanged?()
    }

    func clearAll() {
        state.recentKeywords.removeAll()
        UserDefaults.standard.set(state.recentKeywords, forKey: Self.recentKey)
        onStateChanged?()
    }
}

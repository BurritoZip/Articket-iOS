import Foundation

@MainActor final class SearchViewModel {

    struct State {
        var recentKeywords: [String] = ["백예린", "IU", "검정치마", "인스파이어아레나"]
        var recommendedKeywords: [String] = ["단독콘서트", "페스티벌", "내한공연"]
    }

    var state = State()
    var onStateChanged: (() -> Void)?

    func removeKeyword(_ keyword: String) {
        state.recentKeywords.removeAll { $0 == keyword }
        onStateChanged?()
    }

    func clearAll() {
        state.recentKeywords.removeAll()
        onStateChanged?()
    }
}

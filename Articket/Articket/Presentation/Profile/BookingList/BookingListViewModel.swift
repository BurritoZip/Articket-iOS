import Foundation

@MainActor
final class BookingListViewModel {

    enum Tab: Int, CaseIterable {
        case active = 0
        case cancelled = 1

        var title: String {
            switch self {
            case .active: return "예매내역"
            case .cancelled: return "취소내역"
            }
        }
    }

    struct State {
        var activeBookings: [Booking] = []
        var cancelledBookings: [Booking] = []
        var selectedTab: Tab = .active
        var isLoading: Bool = true
    }

    private(set) var state: State = .init()
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    private let repository: any BookingRepositoryProtocol

    init(initialTab: Tab = .active, repository: some BookingRepositoryProtocol) {
        self.repository = repository
        self.state.selectedTab = initialTab
    }

    func viewDidLoad() {
        state.isLoading = true
        onStateChanged?()
        Task {
            async let activeTask = repository.fetchMyBookings()
            async let cancelledTask = repository.fetchCancelledBookings()
            do {
                state.activeBookings = try await activeTask
                state.cancelledBookings = (try? await cancelledTask) ?? []
            } catch {
                onError?("예매 내역을 불러오지 못했어요")
            }
            state.isLoading = false
            onStateChanged?()
        }
    }

    func selectTab(_ tab: Tab) {
        state.selectedTab = tab
        onStateChanged?()
    }

    var currentBookings: [Booking] {
        state.selectedTab == .active ? state.activeBookings : state.cancelledBookings
    }
}

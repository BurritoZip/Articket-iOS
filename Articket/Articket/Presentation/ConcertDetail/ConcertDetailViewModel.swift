import Foundation

@MainActor
final class ConcertDetailViewModel {

    struct State {
        var detail: ConcertDetail
        var selectedTab: Int = 0
        var heroImageAssetName: String?
        var isLoading: Bool = true
        var isInterested: Bool = false
        var isBooked: Bool = false
    }

    private(set) var state: State
    var onStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoginRequired: ((@escaping () -> Void) -> Void)?
    var onInterestToggled: ((Bool) -> Void)?

    private let concertId: UUID
    private let repository: any ConcertDetailRepositoryProtocol
    private let bookingRepository: any BookingRepositoryProtocol

    init(concertId: UUID,
         imageAssetName: String? = nil,
         repository: some ConcertDetailRepositoryProtocol,
         bookingRepository: any BookingRepositoryProtocol = SupabaseBookingRepository()) {
        self.concertId = concertId
        self.repository = repository
        self.bookingRepository = bookingRepository
        self.state = State(
            detail: .placeholder,
            heroImageAssetName: imageAssetName,
            isLoading: true
        )
    }

    func viewDidLoad() {
        onStateChanged?()
        Task {
            async let detailTask = repository.fetchConcertDetail(concertId: concertId)
            async let isInterestedTask = repository.fetchIsInterested(concertId: concertId)
            async let isBookedTask = try? bookingRepository.isBooked(eventId: concertId)
            do {
                let detail = try await detailTask
                state = State(
                    detail: detail,
                    heroImageAssetName: state.heroImageAssetName ?? detail.imageAssetName,
                    isLoading: false,
                    isInterested: await isInterestedTask,
                    isBooked: (await isBookedTask) ?? false
                )
            } catch {
                state.isLoading = false
                onError?("공연 정보를 불러오지 못했습니다.")
            }
            onStateChanged?()
        }
    }

    func toggleInterested() {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.toggleInterested() }
            return
        }
        let wasInterested = state.isInterested
        state.isInterested = !wasInterested
        onStateChanged?()
        Task {
            do {
                try await repository.toggleInterested(concertId: concertId, currentlyInterested: wasInterested)
                NotificationCenter.default.post(name: .eventInterestedDidChange, object: concertId)
                onInterestToggled?(state.isInterested)
            } catch {
                state.isInterested = wasInterested
                onStateChanged?()
                onError?("관심 공연 처리에 실패했습니다.")
            }
        }
    }

    func markBooked() {
        guard AuthService.shared.isLoggedIn else {
            onLoginRequired? { [weak self] in self?.markBooked() }
            return
        }
        guard !state.isBooked else { return }
        let previous = state.isBooked
        state.isBooked = true            // 낙관적 반영
        onStateChanged?()
        Task {
            do {
                try await bookingRepository.markBooked(eventId: concertId)
            } catch {
                state.isBooked = previous
                onStateChanged?()
                onError?("예매 완료 처리에 실패했습니다.")
            }
        }
    }

    func selectTab(_ index: Int) {
        state.selectedTab = index
        onStateChanged?()
    }
}

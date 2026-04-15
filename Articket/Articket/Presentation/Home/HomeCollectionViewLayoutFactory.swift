import UIKit

// MARK: - Layout Design Rules
// - ALL section title headers: leading 20pt.
// - Hero banner: full-width paging carousel. Poster has 45pt side margins (blurred bg shows through).
//   Poster ratio 1:1.43. topInset = safeAreaTop + headerBarHeight + 17 pushes poster below header.
//   Progress bar is inside each cell (20pt below poster, 2.5pt tall, 10pt bottom padding).
//   60pt white gap after the hero section before the next section header.
// - Interested events image ratio: 1:1.41 (portrait), ~160pt card width, ~2 cards visible.
// - Newly started / soon ending: VERTICAL list, full-width rows, image LEFT (1:1), text RIGHT.
// - Section-to-section spacing: 36pt (contentInsets.bottom) except hero banner which uses 60pt.

enum HomeCollectionViewLayoutFactory {

    static func makeLayout(
        topInset: CGFloat = 0,
        onHeroBannerPageChanged: ((Int) -> Void)? = nil
    ) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = HomeSection(rawValue: sectionIndex) else { return nil }
            switch section {
            case .heroBanner:
                return Self.heroBannerSection(environment: environment, topInset: topInset, onPageChanged: onHeroBannerPageChanged)
            case .interestedEvents:
                return Self.interestedEventsSection()
            case .upcomingEvents:
                return Self.upcomingEventsSection()
            case .newlyStarted, .soonEnding:
                return Self.verticalEventSection()
            }
        }
    }

    // MARK: - Hero Banner
    // - Group = full container width → each swipe shows exactly one poster (no peeking).
    // - Poster inside cell has 45pt side margins; blurred bg shows on each side.
    // - Cell height = topInset + posterHeight + progressAreaHeight.
    //   Progress area = 20pt gap + 2.5pt bar + 10pt padding = 32.5pt.
    // - contentInsets.bottom = 60: white gap before "관심 있는 이벤트" header.
    static let heroBannerPosterSideMargin: CGFloat = 45
    /// Height consumed below the poster within the cell: 20pt gap + 2.5pt bar + 58pt below bar.
    static let heroBannerProgressAreaHeight: CGFloat = 80.5

    private static func heroBannerSection(
        environment: NSCollectionLayoutEnvironment,
        topInset: CGFloat,
        onPageChanged: ((Int) -> Void)?
    ) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.effectiveContentSize.width

        let posterWidth = containerWidth - heroBannerPosterSideMargin * 2
        let posterHeight = posterWidth * 1.43
        let groupHeight = topInset + posterHeight + heroBannerProgressAreaHeight

        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .absolute(containerWidth), heightDimension: .absolute(groupHeight)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        // 60pt white gap between blurred background bottom and next section header.
        section.contentInsets = .init(top: 0, leading: 0, bottom: 60, trailing: 0)

        if let onPageChanged = onPageChanged {
            section.visibleItemsInvalidationHandler = { _, contentOffset, _ in
                guard containerWidth > 0 else { return }
                let page = Int(round(contentOffset.x / containerWidth))
                onPageChanged(max(0, page))
            }
        }

        return section
    }

    // MARK: - Interested Events
    // Horizontal scroll, ~200pt wide portrait cards (1:1.41 ratio), ~2 cards visible at once.
    private static func interestedEventsSection() -> NSCollectionLayoutSection {
        let cardWidth: CGFloat = 200
        let cardHeight: CGFloat = cardWidth * 1.41 + 67

        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .absolute(cardWidth), heightDimension: .absolute(cardHeight)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 16
        section.contentInsets = .init(top: 12, leading: 24, bottom: 36, trailing: 24)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - Upcoming Events
    private static func upcomingEventsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 12, leading: 24, bottom: 36, trailing: 24)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - Newly Started / Soon Ending
    private static func verticalEventSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(96))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(96)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = .init(top: 12, leading: 24, bottom: 36, trailing: 24)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - Shared header
    private static func sectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}

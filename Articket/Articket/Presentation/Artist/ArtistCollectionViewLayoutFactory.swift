import UIKit

enum ArtistCollectionViewLayoutFactory {

    static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = ArtistSection(rawValue: sectionIndex) else { return nil }
            switch section {
            case .myArtists:        return Self.myArtistsSection()
            case .popularArtists:   return Self.popularArtistsSection()
            case .calendar:         return Self.calendarSection()
            case .recommendedArtists: return Self.recommendedArtistsSection()
            }
        }
    }

    // MARK: - 내 아티스트: 가로 스크롤, 80pt 아이템
    private static func myArtistsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .absolute(80), heightDimension: .absolute(108))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .absolute(80), heightDimension: .absolute(108)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 16
        section.contentInsets = .init(top: 12, leading: 20, bottom: 24, trailing: 20)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - 인기 아티스트: 가로 스크롤, 128pt 카드
    private static func popularArtistsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .absolute(128), heightDimension: .absolute(157))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .absolute(128), heightDimension: .absolute(157)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 16
        section.contentInsets = .init(top: 12, leading: 24, bottom: 24, trailing: 24)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - 공연 캘린더: 단일 full-width 셀
    private static func calendarSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(380))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(380)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 12, leading: 24, bottom: 24, trailing: 24)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - 추천 아티스트: 세로 목록, 90pt 고정 높이
    private static func recommendedArtistsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(90))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(90)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 12, leading: 24, bottom: 24, trailing: 24)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    private static func sectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}

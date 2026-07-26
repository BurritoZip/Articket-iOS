import UIKit

enum MyCollectionViewLayoutFactory {

    static func makeLayout(sections: [MySection]) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard sectionIndex < sections.count else { return nil }
            switch sections[sectionIndex] {
            case .myBookings:    return Self.myBookingsSection()
            case .shortcuts:     return Self.shortcutsSection()
            case .yearlyStats:   return Self.yearlyStatsSection()
            case .statDetail:    return Self.statDetailSection()
            }
        }
    }

    // MARK: - 내 예매 현황: 세로 나열, full-width 카드, estimated 높이로 자동 계산
    private static func myBookingsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(200)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 12, leading: 20, bottom: 36, trailing: 20)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - 바로가기: 3-column 그리드
    private static func shortcutsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1/3), heightDimension: .absolute(92))
        )
        item.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(92)),
            subitems: [item, item, item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 12, leading: 16, bottom: 36, trailing: 16)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - 올해 본 공연: 3개 아이템 (subtitle / chart / stat row)
    // estimated 높이로 각 셀이 Auto Layout 기반 자체 크기 결정
    private static func yearlyStatsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = .init(top: 12, leading: 20, bottom: 36, trailing: 20)
        section.boundarySupplementaryItems = [sectionHeader()]
        return section
    }

    // MARK: - 통계 상세: 선택 카드에 따라 스왑되는 세로 목록 (아티스트/관람작/더보기)
    // "올해 본 공연" 섹션 바로 아래 — 별도 섹션 헤더 없음. estimated로 가변 높이 수용.
    private static func statDetailSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(84))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(84)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 20, bottom: 36, trailing: 20)
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

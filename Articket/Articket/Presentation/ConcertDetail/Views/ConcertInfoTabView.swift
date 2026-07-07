import UIKit
import SnapKit

// MARK: - ConcertInfoTabView
// Figma 1:1728 — 아티스트 정보 + NOTICE + PLACE

final class ConcertInfoTabView: UIView {

    /// 탭한 아티스트의 id 를 전달 — 다중 라인업에서 개별 아티스트로 라우팅하기 위함
    var onArtistTapped: ((UUID) -> Void)?
    var onMapTapped: (() -> Void)?

    /// 탭 제스처에 아티스트 id 를 실어 보내기 위한 전용 인식기 (target/action은 payload를 못 싣음)
    private final class ArtistTapGesture: UITapGestureRecognizer {
        var artistId: UUID?
    }

    private let mainStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    @objc private func artistTapped(_ sender: UITapGestureRecognizer) {
        guard let id = (sender as? ArtistTapGesture)?.artistId else { return }
        onArtistTapped?(id)
    }
    @objc private func mapTapped() { onMapTapped?() }

    /// 로그인 유저가 팔로우한 아티스트 id — 하트 배지를 팔로우한 아티스트에만 표시하기 위함
    private var followedArtistIds: Set<UUID> = []

    func configure(with detail: ConcertDetail, followedArtistIds: Set<UUID> = []) {
        self.followedArtistIds = followedArtistIds
        mainStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // 페스티벌 등 아티스트가 제대로 연결되지 않은 경우 빈/placeholder 아티스트가 뜨면 오해를 준다.
        // 실제 이름이 있는 아티스트만 남기고, 하나도 없으면 '아티스트 정보' 섹션 자체를 숨긴다.
        let lineup = (detail.lineupArtists.isEmpty ? [detail.artist] : detail.lineupArtists)
            .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !lineup.isEmpty {
            mainStack.addArrangedSubview(makeArtistSection(artists: lineup))
        }
        if !detail.noticeText.isEmpty {
            mainStack.addArrangedSubview(makeNoticeSection(text: detail.noticeText))
        }
        if !detail.venueName.isEmpty {
            mainStack.addArrangedSubview(makePlaceSection(detail: detail))
        }
    }

    // MARK: - Section Builders

    private func makeArtistSection(artists: [Artist]) -> UIView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 12

        let heading = makeSectionHeading("아티스트 정보")
        section.addArrangedSubview(heading)

        // 단일 출연: 기존 디자인(아바타 + 팔로우 배지 + 탭)
        // configure에서 이름 있는 아티스트만 넘어오므로 항상 유효 (빈 배열은 섹션 자체가 미생성)
        if artists.count <= 1, let artist = artists.first {
            let avatarContainer = UIView()
            let avatarView = makeAvatarView(size: 80, name: artist.name, urlString: artist.avatarUrl)
            avatarContainer.addSubview(avatarView)
            avatarView.snp.makeConstraints { $0.leading.top.equalToSuperview(); $0.size.equalTo(80) }
            avatarContainer.snp.makeConstraints { $0.height.equalTo(80) }
            avatarView.isUserInteractionEnabled = true
            let artistTap = ArtistTapGesture(target: self, action: #selector(artistTapped(_:)))
            artistTap.artistId = artist.id
            avatarView.addGestureRecognizer(artistTap)

            // 팔로우한 아티스트에만 하트 배지 표시
            if followedArtistIds.contains(artist.id) {
                let badge = makeFollowBadge()
                avatarContainer.addSubview(badge)
                badge.snp.makeConstraints {
                    $0.size.equalTo(24)
                    $0.leading.equalTo(avatarView).offset(56)
                    $0.top.equalTo(avatarView).offset(56)
                }
            }
            section.addArrangedSubview(avatarContainer)
            return section
        }

        // 다중 출연(페스티벌/합동공연): 아바타 + 이름 가로 스크롤
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .top
        for artist in artists {
            let item = UIStackView()
            item.axis = .vertical
            item.spacing = 6
            item.alignment = .center
            let avatarView = makeAvatarView(size: 64, name: artist.name, urlString: artist.avatarUrl)
            avatarView.snp.makeConstraints { $0.size.equalTo(64) }

            // 아바타 컨테이너 — 팔로우한 아티스트에만 하트 배지 오버레이
            let avatarContainer = UIView()
            avatarContainer.addSubview(avatarView)
            avatarView.snp.makeConstraints { $0.edges.equalToSuperview() }
            avatarContainer.snp.makeConstraints { $0.size.equalTo(64) }
            if followedArtistIds.contains(artist.id) {
                let badge = makeFollowBadge()
                avatarContainer.addSubview(badge)
                badge.snp.makeConstraints {
                    $0.size.equalTo(24)
                    $0.trailing.bottom.equalToSuperview()
                }
            }

            let nameLabel = UILabel()
            nameLabel.text = artist.name
            nameLabel.font = .systemFont(ofSize: 13)
            nameLabel.textAlignment = .center
            nameLabel.numberOfLines = 2
            item.addArrangedSubview(avatarContainer)
            item.addArrangedSubview(nameLabel)
            item.snp.makeConstraints { $0.width.equalTo(72) }

            // 각 라인업 아이템(아바타+이름)을 탭하면 해당 아티스트 상세로 이동
            item.isUserInteractionEnabled = true
            let tap = ArtistTapGesture(target: self, action: #selector(artistTapped(_:)))
            tap.artistId = artist.id
            item.addGestureRecognizer(tap)

            row.addArrangedSubview(item)
        }
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        scroll.snp.makeConstraints { $0.height.equalTo(108) }
        section.addArrangedSubview(scroll)

        return section
    }

    private func makeNoticeSection(text: String) -> UIView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 12

        section.addArrangedSubview(makeSectionHeading("NOTICE"))

        let box = UIView()
        box.backgroundColor = UIColor(red: 0.996, green: 0.949, blue: 0.949, alpha: 1)
        box.layer.borderColor = UIColor(red: 1.0, green: 0.788, blue: 0.788, alpha: 1).cgColor
        box.layer.borderWidth = 1
        box.layer.cornerRadius = 10

        let noticeLabel = UILabel()
        noticeLabel.text = text
        noticeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        noticeLabel.textColor = UIColor(red: 0.755, green: 0.0, blue: 0.027, alpha: 1)
        noticeLabel.numberOfLines = 0

        box.addSubview(noticeLabel)
        noticeLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        section.addArrangedSubview(box)

        return section
    }

    private func makePlaceSection(detail: ConcertDetail) -> UIView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 12

        section.addArrangedSubview(makeSectionHeading("PLACE"))

        let nameLabel = UILabel()
        nameLabel.text = detail.venueName
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

        let addressLabel = UILabel()
        addressLabel.text = detail.address
        addressLabel.font = .systemFont(ofSize: 13, weight: .regular)
        addressLabel.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)

        var infoViews: [UIView] = [nameLabel]
        if !detail.address.isEmpty { infoViews.append(addressLabel) }
        let infoStack = UIStackView(arrangedSubviews: infoViews)
        infoStack.axis = .vertical
        infoStack.spacing = 4

        // Phone row (전화번호 있을 때만)
        var placeViews: [UIView] = [infoStack]

        if !detail.phoneNumber.isEmpty {
            let phoneIcon = UIImageView(image: UIImage(systemName: "phone"))
            phoneIcon.tintColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)
            phoneIcon.contentMode = .scaleAspectFit
            phoneIcon.snp.makeConstraints { $0.size.equalTo(14) }

            let phoneLabel = UILabel()
            phoneLabel.text = detail.phoneNumber
            phoneLabel.font = .systemFont(ofSize: 13, weight: .regular)
            phoneLabel.textColor = UIColor(red: 0.463, green: 0.463, blue: 0.463, alpha: 1)

            let phoneRow = UIStackView(arrangedSubviews: [phoneIcon, phoneLabel])
            phoneRow.axis = .horizontal
            phoneRow.spacing = 8
            phoneRow.alignment = .center
            placeViews.append(phoneRow)
        }

        // Map button
        let mapIcon = UIImageView(image: UIImage(systemName: "map"))
        mapIcon.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        mapIcon.contentMode = .scaleAspectFit
        mapIcon.snp.makeConstraints { $0.size.equalTo(18) }

        let mapLabel = UILabel()
        mapLabel.text = "지도보기"
        mapLabel.font = .systemFont(ofSize: 14, weight: .medium)
        mapLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

        let mapButton = UIView()
        mapButton.layer.borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1).cgColor
        mapButton.layer.borderWidth = 1
        mapButton.layer.cornerRadius = 10
        mapButton.isUserInteractionEnabled = true
        let mapTap = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        mapButton.addGestureRecognizer(mapTap)

        let mapRow = UIStackView(arrangedSubviews: [mapIcon, mapLabel])
        mapRow.axis = .horizontal
        mapRow.spacing = 8
        mapRow.alignment = .center

        mapButton.addSubview(mapRow)
        mapRow.snp.makeConstraints { $0.center.equalToSuperview() }
        mapButton.snp.makeConstraints { $0.height.equalTo(47) }
        placeViews.append(mapButton)

        let placeContent = UIStackView(arrangedSubviews: placeViews)
        placeContent.axis = .vertical
        placeContent.spacing = 8

        section.addArrangedSubview(placeContent)
        return section
    }

    // MARK: - Helpers

    private func makeSectionHeading(_ title: String) -> UILabel {
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        return l
    }

    /// 팔로우 표시용 하트 배지 (검정 원 + 흰 하트, 흰 테두리)
    private func makeFollowBadge() -> UIView {
        let badge = UIView()
        badge.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1)
        badge.layer.cornerRadius = 12
        badge.layer.borderWidth = 2
        badge.layer.borderColor = UIColor.white.cgColor
        badge.clipsToBounds = true
        let badgeIcon = UIImageView(image: UIImage(systemName: "heart.fill"))
        badgeIcon.tintColor = .white
        badgeIcon.contentMode = .scaleAspectFit
        badge.addSubview(badgeIcon)
        badgeIcon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12) }
        return badge
    }

    private func makeAvatarView(size: CGFloat, name: String, urlString: String?) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = size / 2
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1).cgColor
        container.clipsToBounds = true
        container.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        container.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let hasImage = !(urlString ?? "").isEmpty
        if hasImage { imageView.loadImage(urlString: urlString) }

        // 이미지 URL 없으면(또는 빈 문자열) 이름 이니셜 아이콘 폴백
        if !hasImage {
            let label = UILabel()
            label.text = String(name.prefix(1))
            label.font = .systemFont(ofSize: size * 0.35, weight: .bold)
            label.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
            label.textAlignment = .center
            container.addSubview(label)
            label.snp.makeConstraints { $0.center.equalToSuperview() }
        }

        return container
    }
}

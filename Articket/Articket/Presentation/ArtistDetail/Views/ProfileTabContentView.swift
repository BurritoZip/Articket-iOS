import UIKit
import SnapKit

// MARK: - ProfileTabContentView
// Figma 1:2941 — 프로필 정보 + 뮤직비디오 + 앨범

final class ProfileTabContentView: UIView {

    private let mainStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 36
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(detail: ArtistDetail) {
        mainStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 프로필 정보
        let profileStack = UIStackView()
        profileStack.axis = .vertical
        profileStack.spacing = 0

        let info = detail.profileInfo
        let rows = [
            ("직업", info.occupation),
            ("출생", info.birthDate),
            ("출생지", info.birthPlace),
            ("관련사항", info.related),
        ]
        for (label, value) in rows {
            profileStack.addArrangedSubview(ProfileInfoRowView(label: label, value: value))
        }
        mainStack.addArrangedSubview(profileStack)

        // 뮤직비디오
        let mvSection = UIStackView()
        mvSection.axis = .vertical
        mvSection.spacing = 20

        mvSection.addArrangedSubview(ProfileSectionHeaderView(title: "뮤직비디오", iconName: "play.tv"))

        let mvStack = UIStackView()
        mvStack.axis = .vertical
        mvStack.spacing = 12
        for video in detail.musicVideos {
            let row = MusicVideoRowView()
            row.configure(with: video)
            mvStack.addArrangedSubview(row)
        }
        mvSection.addArrangedSubview(mvStack)
        mainStack.addArrangedSubview(mvSection)

        // 앨범
        let albumSection = UIStackView()
        albumSection.axis = .vertical
        albumSection.spacing = 20

        albumSection.addArrangedSubview(ProfileSectionHeaderView(title: "앨범", iconName: "music.note.list"))

        let albumScrollView = UIScrollView()
        albumScrollView.showsHorizontalScrollIndicator = false
        albumScrollView.alwaysBounceHorizontal = true

        let albumContentStack = UIStackView()
        albumContentStack.axis = .horizontal
        albumContentStack.spacing = 12
        albumContentStack.alignment = .top

        for album in detail.albums {
            let card = AlbumCardView()
            card.configure(with: album)
            albumContentStack.addArrangedSubview(card)
        }

        albumScrollView.addSubview(albumContentStack)
        albumContentStack.snp.makeConstraints {
            $0.edges.equalTo(albumScrollView.contentLayoutGuide)
            $0.height.equalTo(albumScrollView.frameLayoutGuide)
        }
        albumScrollView.snp.makeConstraints { $0.height.equalTo(211) }

        albumSection.addArrangedSubview(albumScrollView)
        mainStack.addArrangedSubview(albumSection)

        // 하단 여백
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(36) }
        mainStack.addArrangedSubview(spacer)
    }
}

// MARK: - ProfileSectionHeaderView

private final class ProfileSectionHeaderView: UIView {

    init(title: String, iconName: String?) {
        super.init(frame: .zero)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center

        if let iconName = iconName {
            let icon = UIImageView(image: UIImage(systemName: iconName))
            icon.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            icon.snp.makeConstraints { $0.size.equalTo(20) }
            stack.addArrangedSubview(icon)
        }

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        stack.addArrangedSubview(label)

        addSubview(stack)
        stack.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        snp.makeConstraints { $0.height.equalTo(27) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}

// MARK: - ProfileInfoRowView

private final class ProfileInfoRowView: UIView {

    init(label: String, value: String) {
        super.init(frame: .zero)

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 15, weight: .medium)
        labelView.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        labelView.setContentHuggingPriority(.required, for: .horizontal)

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 15, weight: .regular)
        valueView.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        valueView.numberOfLines = 0

        addSubview(labelView)
        addSubview(valueView)

        labelView.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.width.equalTo(84)
            $0.bottom.lessThanOrEqualToSuperview()
        }
        valueView.snp.makeConstraints {
            $0.leading.equalTo(labelView.snp.trailing).offset(4)
            $0.trailing.top.bottom.equalToSuperview()
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(24) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}

// MARK: - MusicVideoRowView
// Figma 1:2984 — 128×80 썸네일 + 제목/조회수/좋아요/날짜

private final class MusicVideoRowView: UIView {

    private let thumbnailContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    private let dimOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        return v
    }()

    private let playContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        v.layer.cornerRadius = 14
        return v
    }()

    private let playIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.fill"))
        iv.tintColor = .white
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        l.numberOfLines = 2
        return l
    }()

    private let statsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        thumbnailContainer.addSubview(dimOverlay)
        thumbnailContainer.addSubview(playContainer)
        playContainer.addSubview(playIcon)

        dimOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        playContainer.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(28) }
        playIcon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12.6) }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, statsLabel])
        textStack.axis = .vertical
        textStack.spacing = 8

        let row = UIStackView(arrangedSubviews: [thumbnailContainer, textStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        thumbnailContainer.snp.makeConstraints { $0.width.equalTo(128); $0.height.equalTo(80) }

        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with video: MusicVideo) {
        titleLabel.text = video.title
        statsLabel.text = "👁 \(video.viewCount)  🤍 \(video.likeCount)  ·  \(video.uploadDate)"
    }
}

// MARK: - AlbumCardView
// Figma 1:3065 — 160×160 이미지 + 제목 + 연도

private final class AlbumCardView: UIView {

    private let albumImageView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1)
        v.layer.cornerRadius = 10
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 6
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return l
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stack = UIStackView(arrangedSubviews: [albumImageView, titleLabel, yearLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading

        albumImageView.snp.makeConstraints { $0.size.equalTo(160) }

        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        snp.makeConstraints { $0.width.equalTo(160) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with album: AlbumItem) {
        titleLabel.text = album.title
        yearLabel.text = album.year
    }
}

# 코드 패턴 & 템플릿

새 기능을 추가할 때 아래 템플릿을 그대로 따르세요. 기존 구현을 읽지 않아도 됩니다.

---

## ViewModel 템플릿

```swift
@MainActor
final class [Feature]ViewModel {

    struct State {
        var items: [[Entity]] = []
        static let empty = State()
    }

    private(set) var state: State = .empty
    var onStateChanged: (() -> Void)?

    private let useCase: any [Feature]UseCaseProtocol

    init(useCase: some [Feature]UseCaseProtocol) {
        self.useCase = useCase
    }

    func viewDidLoad() {
        let result = useCase.execute()
        state = State(items: result.items)
        onStateChanged?()
    }
}
```

---

## Cell 템플릿

```swift
final class [Type]Cell: UICollectionViewCell {

    static let reuseIdentifier = "[Type]Cell"

    private let imageView: UIImageView = { ... }()
    private let titleLabel: UILabel = { ... }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.snp.makeConstraints { ... }
        titleLabel.snp.makeConstraints { ... }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(with event: Event) {
        titleLabel.text = event.title
        if let name = event.imageAssetName {
            imageView.image = UIImage(named: name)
        } else {
            imageView.image = UIImage(systemName: "photo")
        }
    }
}
```

---

## UseCase + Repository 템플릿

```swift
// Domain/Repository/[Entity]RepositoryProtocol.swift
protocol [Entity]RepositoryProtocol: Sendable {
    func fetch[Entity]s() -> [[Entity]]
}

// Domain/UseCase/Fetch[Feature]UseCase.swift
protocol Fetch[Feature]UseCaseProtocol: Sendable {
    func execute() -> [Result]
}
final class Fetch[Feature]UseCase: Fetch[Feature]UseCaseProtocol, Sendable {
    private let repository: any [Entity]RepositoryProtocol
    init(repository: some [Entity]RepositoryProtocol) { self.repository = repository }
    func execute() -> [Result] { repository.fetch[Entity]s() }
}

// Data/Repository/Mock[Entity]Repository.swift
final class Mock[Entity]Repository: [Entity]RepositoryProtocol {
    func fetch[Entity]s() -> [[Entity]] { [ /* 더미 데이터 */ ] }
}
```

---

## Supplementary View 템플릿

```swift
final class [Type]View: UICollectionReusableView {
    static let reuseIdentifier = "[Type]View"

    override init(frame: CGRect) {
        super.init(frame: frame)
        // setup subviews
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 콜백/상태 초기화
    }

    func configure(...) { ... }
}
```

---

## 새 Feature 추가 체크리스트

```
[ ] Domain/Entity/[Entity].swift
[ ] Domain/Repository/[Entity]RepositoryProtocol.swift
[ ] Domain/UseCase/Fetch[Feature]UseCase.swift
[ ] Data/Repository/Mock[Entity]Repository.swift
[ ] Presentation/[Feature]/[Feature]Section.swift
[ ] Presentation/[Feature]/[Feature]ViewController.swift
[ ] Presentation/[Feature]/[Feature]ViewModel.swift
[ ] Presentation/[Feature]/[Feature]CollectionViewLayoutFactory.swift  (필요 시)
[ ] Presentation/[Feature]/Cells/*.swift
[ ] MainTabBarController.setupTabs() — DI 연결
[ ] docs/CODEMAPS/[FEATURE].md 생성
```

---

## SectionHeader 액세서리 타입

`SectionHeaderView.configure(title:accessory:)`:
- `.seeMore` — 더보기 버튼 → `onSeeMoreTapped` 콜백
- `.arrows` — 좌/우 화살표 → `onLeftArrowTapped` / `onRightArrowTapped` 콜백
- `.none` — 액세서리 없음

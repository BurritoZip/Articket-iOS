import XCTest
@testable import Articket

// 유닛 테스트 구조:
//
// ArticketTests/
//   Mocks/            — Mock*Repository (테스트 타깃 전용)
//   FetchHomeEventsUseCaseTests.swift — UseCase 로직 검증
//
// Mock 사용 방법:
//   class MyTests: XCTestCase {
//       let repo = MockEventRepository()
//       func test_example() async throws { ... }
//   }

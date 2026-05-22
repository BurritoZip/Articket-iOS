@testable import Articket

import Foundation

final class MockInquiryRepository: InquiryRepositoryProtocol {

    func fetchMyInquiries() async throws -> [Inquiry] { [] }

    func submitInquiry(title: String, content: String) async throws {}
}

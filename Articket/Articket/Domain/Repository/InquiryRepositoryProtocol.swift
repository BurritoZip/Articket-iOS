import Foundation

protocol InquiryRepositoryProtocol: Sendable {
    func fetchMyInquiries() async throws -> [Inquiry]
    func submitInquiry(title: String, content: String) async throws
}

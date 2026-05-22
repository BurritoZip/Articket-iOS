import Foundation
import Supabase

struct SupabaseInquiryRepository: InquiryRepositoryProtocol {

    func fetchMyInquiries() async throws -> [Inquiry] {
        guard AuthService.shared.isLoggedIn else { return [] }
        let rows: [InquiryRow] = try await SupabaseService.shared.fetch(
            table: "inquiries",
            query: "select=id,title,content,status,created_at,answer&order=created_at.desc&limit=50"
        )
        return rows.map { $0.toInquiry() }
    }

    func submitInquiry(title: String, content: String) async throws {
        guard let userId = AuthService.shared.currentUserId else {
            throw InquiryError.notLoggedIn
        }
        try await SupabaseService.shared.client
            .from("inquiries")
            .insert(InquiryInsert(userId: userId, title: title, content: content))
            .execute()
    }
}

enum InquiryError: Error {
    case notLoggedIn
}

import Foundation
import Supabase

// MARK: - Client
// SupabaseConfig는 gitignore된 SupabaseConfig.swift에 정의됨
// 최초 설정 시: SupabaseConfig.example.swift → SupabaseConfig.swift 복사 후 값 채우기

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    // supabase-swift 공식 클라이언트 — 인증 세션 관리, 토큰 갱신 내장
    let client = SupabaseClient(
        supabaseURL: URL(string: SupabaseConfig.projectURL)!,
        supabaseKey: SupabaseConfig.anonKey,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
    )

    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        let fmt1 = ISO8601DateFormatter()
        fmt1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fmt2 = ISO8601DateFormatter()
        fmt2.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { dec in
            let str = try dec.singleValueContainer().decode(String.self)
            if let date = fmt1.date(from: str) ?? fmt2.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: try dec.singleValueContainer(),
                debugDescription: "Cannot parse date: \(str)"
            )
        }
        return d
    }()

    func fetch<T: Decodable>(table: String, query: String) async throws -> T {
        let urlString = "\(SupabaseConfig.projectURL)/rest/v1/\(table)?\(query)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        // 로그인 상태면 사용자 JWT 사용 → RLS user-specific 쿼리 동작
        let token = client.auth.currentSession?.accessToken ?? SupabaseConfig.anonKey
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[Supabase] HTTP \(statusCode) — \(urlString)\n\(body)")
            throw SupabaseError.httpError(statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[Supabase] Decode 실패 — \(urlString)\n\(error)\n원본: \(body.prefix(500))")
            throw error
        }
    }

    func uploadToStorage(data: Data, path: String, bucket: String) async throws -> String {
        try await client.storage
            .from(bucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
        let url = try client.storage.from(bucket).getPublicURL(path: path)
        return url.absoluteString
    }
}

enum SupabaseError: Error {
    case notConfigured
    case httpError(Int)
}

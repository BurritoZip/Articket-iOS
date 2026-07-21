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

        // 비동기 freshToken — 만료 시 supabase-swift가 자동 refresh 시도
        let (token, wasAuthenticated) = await freshToken()

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401, wasAuthenticated {
            // refresh된 토큰으로도 401 → 세션 완전 무효 → 강제 로그아웃
            Task { @MainActor in
                try? await self.client.auth.signOut()
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
            }
            throw SupabaseError.sessionExpired
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[Supabase] HTTP \(statusCode) — \(urlString)\n\(body)")
            ErrorReporter.shared.capture(
                .http,
                message: "HTTP \(statusCode) — \(table)",
                domain: "SupabaseService.fetch",
                context: ["table": table, "status": String(statusCode), "body": String(body.prefix(500))]
            )
            throw SupabaseError.httpError(statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[Supabase] Decode 실패 — \(urlString)\n\(error)\n원본: \(body.prefix(500))")
            ErrorReporter.shared.capture(
                .decoding,
                message: "Decode 실패 — \(table)",
                domain: "SupabaseService.fetch",
                error: error,
                context: ["table": table, "type": String(describing: T.self)]
            )
            throw error
        }
    }

    // 세션이 있으면 supabase-swift의 async session으로 토큰 자동 갱신 시도.
    // refresh 토큰도 만료됐으면 로그아웃 처리 후 anon key 반환.
    private func freshToken() async -> (token: String, wasAuthenticated: Bool) {
        guard client.auth.currentSession != nil else {
            return (SupabaseConfig.anonKey, false)
        }
        do {
            let session = try await client.auth.session
            return (session.accessToken, true)
        } catch {
            // 네트워크 오류면 세션을 만료로 단정하지 않는다 — 로그아웃하지 않고 세션을 보존한다.
            // (이 경우 이어지는 URLSession 요청도 어차피 네트워크 오류로 실패하므로 anon 반환의
            //  실질 영향은 "이번 요청 실패"로 동일하고, 세션만 안전하게 유지된다.)
            if !error.isNetworkConnectionError {
                Task { @MainActor in
                    try? await self.client.auth.signOut()
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                }
            }
            return (SupabaseConfig.anonKey, false)
        }
    }

    func uploadToStorage(data: Data, path: String, bucket: String) async throws -> String {
        try await client.storage
            .from(bucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
        let url = try client.storage.from(bucket).getPublicURL(path: path)
        return url.absoluteString
    }

    private var didStartAuthObserver = false

    /// supabase-swift의 인증 상태 변화를 구독해, 세션이 만료·정리되면 앱 전역에 알린다.
    ///
    /// 쓰기(`client.from().execute()`)는 공통 `fetch()`의 401→로그아웃 로직을 타지 않아,
    /// 세션이 만료된 채 계속 실패해도 앱이 로그인 상태로 착각했다(자가치유 불가). SDK는
    /// 토큰 갱신에 실패하면 내부적으로 signOut 처리하며 `.signedOut` 이벤트를 발행하므로,
    /// 이를 한 곳에서 구독하면 읽기·쓰기 어느 경로의 만료든 중앙에서 잡아 Guest 전환·재로그인
    /// 유도로 이어진다. 리포지토리 18곳의 쓰기 호출을 개별 수정할 필요가 없다.
    func startAuthObserver() {
        guard !didStartAuthObserver else { return }
        didStartAuthObserver = true
        Task {
            for await state in client.auth.authStateChanges {
                // .signedOut 만 관심 — 로그인/토큰갱신/초기세션 이벤트는 무시
                guard state.event == .signedOut else { continue }
                await MainActor.run {
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                }
            }
        }
    }
}

enum SupabaseError: Error {
    case notConfigured
    case httpError(Int)
    case sessionExpired
}

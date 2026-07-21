import Foundation

extension Error {
    /// 네트워크 연결 실패(오프라인·타임아웃·연결 끊김 등)인지 여부.
    ///
    /// 세션 만료와 구분하기 위한 판별자다. 인증 토큰 갱신(`client.auth.session`)이 실패하는
    /// 원인은 크게 둘 — (1) refresh 토큰 만료(진짜 로그아웃 대상), (2) 일시적 네트워크 오류.
    /// 이를 구분하지 않고 로그아웃하면, 잠깐 오프라인이던 로그인 유저가 복귀 시 쫓겨난다.
    /// 네트워크 오류일 때는 세션을 보존하고 다음 기회에 재시도해야 한다.
    var isNetworkConnectionError: Bool {
        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain { return true }
        // 일부 SDK는 URLError를 underlying error로 감싸 전달한다
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSURLErrorDomain {
            return true
        }
        return false
    }
}

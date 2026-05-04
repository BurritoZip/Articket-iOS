// SupabaseConfig.example.swift — 커밋용 템플릿
//
// 사용법:
//   1. 이 파일을 복사해 같은 폴더에 SupabaseConfig.swift 생성
//   2. Supabase 대시보드 > Settings > API 에서 값 복사
//   3. SupabaseConfig.swift를 Xcode 프로젝트(Data/Service 그룹)에 추가
//      → "Add to target: Articket" 체크
//   4. SupabaseConfig.swift는 .gitignore에 등록되어 커밋되지 않음

enum SupabaseConfigExample {
    static let projectURL = ""   // "https://xxxxxxxxxxxx.supabase.co"
    static let anonKey    = ""   // "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

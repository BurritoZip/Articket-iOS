-- admin 레포(supabase/migrations/)에 적용. iOS 로깅이 screen/breadcrumbs를 채운다.
ALTER TABLE app_error_logs ADD COLUMN IF NOT EXISTS screen text;
ALTER TABLE app_error_logs ADD COLUMN IF NOT EXISTS breadcrumbs jsonb;
COMMENT ON COLUMN app_error_logs.screen IS '에러 발생 화면(뷰컨트롤러명)';
COMMENT ON COLUMN app_error_logs.breadcrumbs IS '직전 흔적 trail [{time,kind,screen,message,meta}]';

-- QA 테스트 계정 정리 (실제 학생 아님, 개발 중 테스트용으로 등록됐던 계정)
-- 대상: C4-S9999999999("QA테스트"), C3-S0000000001("QA테스트임시")
-- Supabase 대시보드 > SQL Editor 에서 이 스크립트를 그대로 실행하세요.

delete from stage0_records  where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from stage0_progress where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from week23_records  where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from week23_progress where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from week45_records  where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from week45_progress where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from quiz_results      where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from research_consent  where participant_code in ('C4-S9999999999', 'C3-S0000000001');
delete from students          where participant_code in ('C4-S9999999999', 'C3-S0000000001');

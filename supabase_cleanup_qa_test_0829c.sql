-- 로그인 공유 수정 확인용 테스트 계정 정리 (C3-S7788112233 "QA로그인테스트", C4-S6677889900 "QA로그인2")
-- 그리고 앞서 만든 전체 흐름 QA 계정(C3-S8899001122 "QA점검0829")도 함께 정리
-- Supabase 대시보드 > SQL Editor 에서 이 스크립트를 그대로 실행하세요.

delete from stage0_records  where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from stage0_progress where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from week23_records  where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from week23_progress where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from week45_records  where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from week45_progress where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from quiz_results      where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from research_consent  where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from research_survey   where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');
delete from students          where participant_code in ('C3-S7788112233','C4-S6677889900','C3-S8899001122');

-- 연구 참여 동의 저장소 설정
-- Supabase 대시보드 > SQL Editor 에서 이 스크립트를 그대로 실행하세요.
-- 참여자 코드(participant_code)당 1행 — 3개 프로그램(1주차/2~3주차/4~5주차) 중
-- 어디서 먼저 물어보든 공유되며, 한 번 응답하면 다시 묻지 않음.
-- 동의 여부는 프로그램 사용 자체(참여 점수)와 무관 — 동의하지 않아도 프로그램은 동일하게 사용 가능,
-- 연구 분석에서만 해당 참여자 데이터를 제외하는 데 사용.

create table if not exists research_consent (
  participant_code text primary key,
  agreed boolean not null,
  responded_at timestamptz not null default now()
);

alter table research_consent enable row level security;

drop policy if exists "anon insert consent" on research_consent;
create policy "anon insert consent" on research_consent
  for insert to anon with check (true);

drop policy if exists "anon update consent" on research_consent;
create policy "anon update consent" on research_consent
  for update to anon using (true) with check (true);

drop policy if exists "anon select consent" on research_consent;
create policy "anon select consent" on research_consent
  for select to anon using (true);

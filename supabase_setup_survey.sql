-- 연구 설문(RQ2 사전-사후) 저장소 설정
-- Supabase 대시보드 > SQL Editor 에서 이 스크립트를 그대로 실행하세요.
-- 참여자 코드당 phase='pre' 1행 + phase='post' 1행(4~5주차 전체 완료 시) — 3개 프로그램
-- 중 어디서 먼저 로그인하든 사전 설문은 공유되며, 한 번 응답하면 다시 묻지 않음.
-- answers는 문항 id -> 응답(리커트 1~5 숫자 또는 서술형 텍스트)의 JSON.

create table if not exists research_survey (
  id bigint generated always as identity primary key,
  participant_code text not null,
  phase text not null check (phase in ('pre', 'post')),
  answers jsonb not null,
  submitted_at timestamptz not null default now(),
  unique (participant_code, phase)
);

create index if not exists research_survey_code_idx on research_survey (participant_code);

alter table research_survey enable row level security;

drop policy if exists "anon insert survey" on research_survey;
create policy "anon insert survey" on research_survey
  for insert to anon with check (true);

drop policy if exists "anon select survey" on research_survey;
create policy "anon select survey" on research_survey
  for select to anon using (true);

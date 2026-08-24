-- stage0_jari_practice.html 저장소 설정
-- Supabase 대시보드 > SQL Editor 에서 이 스크립트를 그대로 실행하세요.

-- 1) 참여자별 진행 상태 (단계 잠금 해제 여부)
create table if not exists stage0_progress (
  participant_code text primary key,
  completed_stages int[] not null default '{}',
  next_stage int not null default 1,
  updated_at timestamptz not null default now()
);

-- 2) 단계별 연습 기록 (진행 시간 / 정확도 / 오타 수 등, 연구 데이터)
--    idle_count/idle_total_sec: 무입력 5초 이상(자리 비움 등)이 감지되어 자동으로
--    멈췄던 횟수와 그 시간의 합. time_sec은 시작~완료까지의 총 시간(쉰 시간 포함)이고,
--    실제 입력에 걸린 시간은 time_sec - idle_total_sec 로 계산합니다.
create table if not exists stage0_records (
  id bigint generated always as identity primary key,
  participant_code text not null,
  stage_id int not null,
  stage_name text not null,
  item_count int not null,
  time_sec numeric not null,
  accuracy int not null,
  typo_count int not null,
  total_attempts int not null,
  correct_attempts int not null,
  idle_count int not null default 0,
  idle_total_sec numeric not null default 0,
  recorded_at timestamptz not null default now()
);

-- 이미 만들어진 테이블에는 위 두 컬럼이 없을 수 있으므로 안전하게 추가 (기존 행은 0으로 채워짐)
alter table stage0_records add column if not exists idle_count int not null default 0;
alter table stage0_records add column if not exists idle_total_sec numeric not null default 0;

create index if not exists stage0_records_code_idx on stage0_records (participant_code);

-- 3) 보안 설정: 참여자 코드만으로 접근하는 연구용 도구이므로
--    publishable(anon) 키로 읽기/쓰기는 허용하되, 삭제는 막습니다.
alter table stage0_progress enable row level security;
alter table stage0_records enable row level security;

drop policy if exists "anon insert progress" on stage0_progress;
create policy "anon insert progress" on stage0_progress
  for insert to anon with check (true);

drop policy if exists "anon update progress" on stage0_progress;
create policy "anon update progress" on stage0_progress
  for update to anon using (true) with check (true);

drop policy if exists "anon select progress" on stage0_progress;
create policy "anon select progress" on stage0_progress
  for select to anon using (true);

drop policy if exists "anon insert records" on stage0_records;
create policy "anon insert records" on stage0_records
  for insert to anon with check (true);

drop policy if exists "anon select records" on stage0_records;
create policy "anon select records" on stage0_records
  for select to anon using (true);

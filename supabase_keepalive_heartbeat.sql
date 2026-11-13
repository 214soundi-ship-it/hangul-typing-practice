-- Supabase 자동 정지 방지용 '하트비트' 테이블 (2026-11-13)
-- GitHub Actions(supabase-keepalive.yml)가 매일 이 테이블의 시각 한 칸을 갱신해서
-- 프로젝트에 '쓰기 활동'이 계속 있도록 합니다. 연구 데이터 테이블은 전혀 건드리지 않습니다.
-- Supabase 대시보드 > SQL Editor 에서 전체를 한 번에 실행하세요. (여러 번 실행해도 안전)

create table if not exists keepalive_heartbeat (
  id        int primary key,
  pinged_at timestamptz not null default now()
);

insert into keepalive_heartbeat (id) values (1) on conflict (id) do nothing;

alter table keepalive_heartbeat enable row level security;

drop policy if exists "heartbeat select" on keepalive_heartbeat;
drop policy if exists "heartbeat update" on keepalive_heartbeat;

create policy "heartbeat select" on keepalive_heartbeat
  for select to anon using (id = 1);
create policy "heartbeat update" on keepalive_heartbeat
  for update to anon using (id = 1) with check (id = 1);

grant select, update on keepalive_heartbeat to anon;

-- 확인용: 1행이 보이면 성공
-- select * from keepalive_heartbeat;

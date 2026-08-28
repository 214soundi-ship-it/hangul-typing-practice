-- week4_5_summary.html 저장소 설정
-- Supabase 대시보드 > SQL Editor 에서 이 스크립트를 그대로 실행하세요.
-- (이미 실행한 적이 있어도 그대로 다시 실행하면 됩니다 — 컬럼 추가는 안전하게
--  건너뛰고, 콘텐츠는 지우고 새로 채웁니다.)
--
-- 저작권 안내: week45_content 테이블에는 교재(외국인 유학생을 위한 학술적 글쓰기,
-- 고려대학교, 45~64쪽 "요약하기" 단원)에서 가져온 어휘·정의가 들어갑니다. 이 SQL
-- 파일 자체는 git에 커밋되지만, 실행 결과인 데이터는 DB 안에만 있고 앱은 실행
-- 시점에 fetch로 가져오므로 교재 원문이 공개 GitHub 소스코드에는 남지 않습니다.
-- (사람이 보는 참고용 정리본은 week45_vocabulary.md — 이 파일도 gitignore됨)
--
-- 구조: 요약하기 단원은 파트 1(요약을 활용한 글쓰기의 절차와 방법, 6단원, 45~54쪽)/
-- 파트 2(요약을 활용한 글 작성하기, 7단원, 55~64쪽)로 나뉨(실제 수업 진행 순서와 동일).
-- 파트 1은 어휘 2그룹(핵심 개념어/지문 어휘), 파트 2는 어휘 1그룹(핵심 개념어)으로 구성.
-- "활동 지시문 어휘"(1~8단계를 어떻게 수행하라는 절차 지시, 표현 바꿔쓰기 5가지 방법 등)는
-- 성찰적 글에서와 같은 이유(수업 시간에 교수자가 직접 설명)로 처음부터 포함하지 않음.
-- 선별 기준은 성찰적 글과 동일: 어휘 난이도는 고려하지 않고, 그 파트 내용을 이해하는 데
-- 필요한가만으로 판단. 지문 어휘(38개)는 46~47쪽 "자료"(기후 위기로 인한 사회적 불평등)와
-- 그 요약 예시("요약을 활용한 글" ①②)를 문장 단위로 재대조해 확정 — "이 어휘를 모르면 이
-- 글이 이해되나?"를 기준으로 삼음. 뜻풀이는 사전적 의미를 기본으로 하되, 뜻풀이 안에 또
-- 다른 어려운 단어가 들어가는 "순환 정의"가 없는지 재검사해 9개 항목을 다듬음
-- (research-notes.md §5 항목 58 참고).

-- 1) 콘텐츠 (교재에서 가져온 학습 내용 — 읽기 전용, 관리자가 이 파일로만 채움)
create table if not exists week45_content (
  id bigint generated always as identity primary key,
  unit text not null default 'week45',
  part int not null default 1,  -- 1=요약하기, 2=요약을 활용한 글 작성하기
  stage_key text not null,      -- 파트 1: 'concept'|'reading'(지문어휘)|'passage'(지문원문/요약예시), 파트 2: 'concept'
  order_num int not null,
  target_text text not null,    -- 실제 타이핑 대상 텍스트 (passage는 읽기 전용, 타이핑 안 함)
  gloss text,                   -- 쉬운 한국어 뜻풀이 (passage 행은 섹션 구분용 '원문'|'요약1'|'요약2')
  gloss_en text,                -- 영어 번역
  gloss_zh text,                -- 중국어(간체) 번역
  created_at timestamptz not null default now()
);

create index if not exists week45_content_unit_part_stage_idx
  on week45_content (unit, part, stage_key, order_num);

-- 2) 참여자별 진행 상태
create table if not exists week45_progress (
  participant_code text primary key,
  completed_stages int[] not null default '{}',
  next_stage int not null default 1,
  updated_at timestamptz not null default now()
);

-- 3) 단계별 연습 기록 (연구 데이터)
create table if not exists week45_records (
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

create index if not exists week45_records_code_idx on week45_records (participant_code);

-- 3-1) 이해도 확인 퀴즈 결과는 2~3주차와 같은 공유 테이블(quiz_results)을 그대로 씀
-- (unit='week45'로 구분). 이미 supabase_setup_week23.sql에서 생성했다면 아래는 안전하게
-- 건너뜀 — 혹시 이 파일만 먼저 실행하는 경우를 대비해 동일하게 포함해 둠
create table if not exists quiz_results (
  id bigint generated always as identity primary key,
  unit text not null,
  part int not null,
  participant_code text not null,
  score int not null,
  total int not null,
  details jsonb not null,  -- [{type, word, lang, question, correctAnswer, chosenAnswer, isCorrect}, ...]
  recorded_at timestamptz not null default now()
);

create index if not exists quiz_results_code_idx on quiz_results (participant_code);

-- 3-2) 내용 이해 문항 — 어휘 재인이 아니라 지문을 실제로 읽고 이해해야 풀 수 있는 문항.
-- 무작위 샘플링 없이 파트별로 준비된 문항을 전부 사용.
create table if not exists week45_comprehension_questions (
  id bigint generated always as identity primary key,
  unit text not null default 'week45',
  part int not null,
  order_num int not null,
  question_text text not null,
  correct_answer text not null,
  distractor_1 text not null,
  distractor_2 text not null,
  distractor_3 text not null,
  created_at timestamptz not null default now()
);

create index if not exists week45_comp_q_unit_part_idx
  on week45_comprehension_questions (unit, part, order_num);

-- 4) 보안 설정
alter table week45_content enable row level security;
alter table week45_progress enable row level security;
alter table week45_records enable row level security;
alter table quiz_results enable row level security;
alter table week45_comprehension_questions enable row level security;

drop policy if exists "anon select content" on week45_content;
create policy "anon select content" on week45_content
  for select to anon using (true);

drop policy if exists "anon insert progress" on week45_progress;
create policy "anon insert progress" on week45_progress
  for insert to anon with check (true);

drop policy if exists "anon update progress" on week45_progress;
create policy "anon update progress" on week45_progress
  for update to anon using (true) with check (true);

drop policy if exists "anon select progress" on week45_progress;
create policy "anon select progress" on week45_progress
  for select to anon using (true);

drop policy if exists "anon insert records" on week45_records;
create policy "anon insert records" on week45_records
  for insert to anon with check (true);

drop policy if exists "anon select records" on week45_records;
create policy "anon select records" on week45_records
  for select to anon using (true);

drop policy if exists "anon insert quiz results" on quiz_results;
create policy "anon insert quiz results" on quiz_results
  for insert to anon with check (true);

drop policy if exists "anon select quiz results" on quiz_results;
create policy "anon select quiz results" on quiz_results
  for select to anon using (true);

drop policy if exists "anon select comp questions" on week45_comprehension_questions;
create policy "anon select comp questions" on week45_comprehension_questions
  for select to anon using (true);

-- 5) 콘텐츠 채우기 — 파트 1(요약하기, 6단원, 45~54쪽)만 우선 반영 (파트 2는 추후)
delete from week45_content where unit = 'week45';

insert into week45_content (unit, part, stage_key, order_num, target_text, gloss, gloss_en, gloss_zh) values
-- 핵심 개념어 (8)
('week45', 1, 'concept', 1, '요약', '자료의 핵심을 중심으로 간단하게 정리하여 자신의 언어로 바꿔 쓰는 것', 'summary', '概括；摘要'),
('week45', 1, 'concept', 2, '원문', '요약하기 전의 원래 글', 'original text', '原文'),
('week45', 1, 'concept', 3, '전체 주제', '글 전체에서 가장 중심이 되는 생각', 'overall topic', '整体主题'),
('week45', 1, 'concept', 4, '뒷받침하는 내용', '전체 주제를 구체적으로 설명해 주는 세부 내용', 'supporting content', '支撑内容'),
('week45', 1, 'concept', 5, '핵심 내용', '글이나 자료에서 가장 중요하고 중심이 되는 내용', 'key content', '核心内容'),
('week45', 1, 'concept', 6, '표현 바꿔 쓰기', '내용은 자료와 같게, 표현만 자신의 말로 다르게 바꿔 쓰는 것', 'paraphrasing', '改写表达'),
('week45', 1, 'concept', 7, '인용 표현', '다른 사람의 말이나 글을 인용할 때 사용하는 표현(예: "-다고 하다")', 'citation expression', '引用表达'),
('week45', 1, 'concept', 8, '자신의 의견 덧붙이기', '자료 내용에 찬성 또는 반대하는 생각과 그 이유를 더하는 것', 'adding one''s own opinion', '添加自己的意见'),

-- 지문 어휘 (38) — 46~47쪽 "기후 위기로 인한 사회적 불평등" 자료 + 요약글①② 기준
('week45', 1, 'reading', 1, '소득 수준', '돈을 버는 정도', 'income level', '收入水平'),
('week45', 1, 'reading', 2, '노약자', '나이 많은 사람과 약한 사람', 'the elderly and the weak', '老弱者'),
('week45', 1, 'reading', 3, '부유하다', '돈이 많다', 'to be wealthy', '富裕'),
('week45', 1, 'reading', 4, '지속적으로', '끊이지 않고 계속해서', 'continuously', '持续地'),
('week45', 1, 'reading', 5, '불평등', '사람들이 서로 다르게 대우받아 똑같지 않은 것', 'inequality', '不平等'),
('week45', 1, 'reading', 6, '약자', '힘이 약한 사람들', 'the vulnerable', '弱者'),
('week45', 1, 'reading', 7, '야기되다', '어떤 일이나 사건이 일어나게 되다', 'to be caused', '被引发'),
('week45', 1, 'reading', 8, '이산화탄소', '지구 온난화를 일으키는 대표적인 기체(CO2)', 'carbon dioxide', '二氧化碳'),
('week45', 1, 'reading', 9, '아산화질소', '지구 온난화를 일으키는 기체 중 하나(N2O)', 'nitrous oxide', '氧化亚氮'),
('week45', 1, 'reading', 10, '온난화', '지구의 기온이 점점 올라가는 현상', '(global) warming', '变暖'),
('week45', 1, 'reading', 11, '자연재해', '태풍·홍수처럼 자연에서 일어나 사람들에게 피해를 주는 일', 'natural disaster', '自然灾害'),
('week45', 1, 'reading', 12, '추구하다', '원하는 것을 이루려고 계속 노력하다', 'to pursue', '追求'),
('week45', 1, 'reading', 13, '악화되다', '상태가 더 나빠지다', 'to worsen', '恶化'),
('week45', 1, 'reading', 14, '저지대', '다른 곳보다 낮은 지역', 'low-lying area', '低洼地区'),
('week45', 1, 'reading', 15, '해수면 상승', '바닷물의 높이가 올라가는 것', 'sea level rise', '海平面上升'),
('week45', 1, 'reading', 16, '위협하다', '위험한 상황에 놓이게 하다', 'to threaten', '威胁'),
('week45', 1, 'reading', 17, '경제력', '돈을 벌거나 쓸 수 있는 능력', 'economic means', '经济能力'),
('week45', 1, 'reading', 18, '악영향', '나쁜 영향', 'adverse effect', '不良影响'),
('week45', 1, 'reading', 19, '극복하다', '어려운 상황을 이겨 내다', 'to overcome', '克服'),
('week45', 1, 'reading', 20, '홍수', '비가 많이 와서 물이 넘치는 것', 'flood', '洪水'),
('week45', 1, 'reading', 21, '열악하다', '환경이나 조건이 매우 나쁘다', 'to be poor (conditions)', '恶劣'),
('week45', 1, 'reading', 22, '거주지', '사람이 실제로 살고 있는 장소', 'residence', '居住地'),
('week45', 1, 'reading', 23, '상실', '잃어버림', 'loss', '丧失'),
('week45', 1, 'reading', 24, '직간접적으로', '직접 겪기도 하고, 다른 것을 통해 겪기도 하며', 'directly and indirectly', '直接或间接地'),
('week45', 1, 'reading', 25, '불안감', '마음이 편하지 않고 두려운 느낌', 'anxiety', '不安感'),
('week45', 1, 'reading', 26, '또래', '나이가 서로 비슷한 사람', 'peer', '同龄人'),
('week45', 1, 'reading', 27, '인식하다', '어떤 사실을 분명히 알다', 'to recognize', '认识到'),
('week45', 1, 'reading', 28, '여유', '시간이나 돈이 충분해서 걱정 없이 지낼 수 있는 것', 'room to spare', '余地'),
('week45', 1, 'reading', 29, '확대되다', '크게 넓어지다', 'to expand', '扩大'),
('week45', 1, 'reading', 30, '제도', '사회에서 정해 놓은 규칙이나 방법', 'system, institution', '制度'),
('week45', 1, 'reading', 31, '마련하다', '필요한 것을 미리 준비하다', 'to arrange, set up', '准备；制定'),
('week45', 1, 'reading', 32, '지적하다', '문제점이나 특징을 꼭 집어서 말하다', 'to point out', '指出'),
('week45', 1, 'reading', 33, '뒷받침되다', '다른 내용이 도와주어서 더 확실해지다', 'to be supported', '得到支撑'),
('week45', 1, 'reading', 34, '배려하다', '다른 사람을 도와주거나 보살펴 주려고 마음을 쓰다', 'to consider others', '关怀；体谅'),
('week45', 1, 'reading', 35, '완화', '심각하거나 긴장된 상태를 덜 심하게 함', 'mitigation', '缓解'),
('week45', 1, 'reading', 36, '실천', '생각한 것을 실제 행동으로 옮김', 'putting into practice', '实践'),
('week45', 1, 'reading', 37, '의지', '무엇을 이루고자 하는 마음', 'will, determination', '意志'),
('week45', 1, 'reading', 38, '겪다', '어떤 일을 직접 만나거나 실제로 당하다', 'to go through, experience', '经历'),

-- 지문 읽기 화면용 원문(6단락) — 타이핑 대상 아님. 요약 예시①②는 앱의 지문 읽기 화면
-- 목적을 "원문 내용 이해"로만 좁히기로 하면서 제외함(연구자 결정, research-notes.md
-- §74 참고) — 요약①②는 어차피 교재 46~47쪽에 그대로 있어 수업 시간에 다룸
('week45', 1, 'passage', 1, '소득 수준이나 교육 수준, 나이나 건강 상태 등에 따라 사회적 불평등은 다양하게 나타난다. 특히 장애인과 노약자, 경제적으로 어려움을 겪는 사람 등은 약자의 위치에 있는 이들이다. 점점 심각해지고 있는 기후 위기는 사회적으로 좋은 위치에 있거나 부유한 사람들보다 이러한 사회적 약자의 위치에 있는 사람들에게 더 큰 영향을 미친다. 그리고 이와 같은 상황은 사회적 불평등이 더욱 심해지는 결과로 이어진다. 이것이 기후 위기의 시대에 국가가 사회적으로 불평등한 위치에 있는 사람들에게 지속적으로 관심을 가져야 하는 이유이다.', '원문', null, null),
('week45', 1, 'passage', 2, '기후 위기란 지구의 기후가 변화하면서 발생하는 환경적 문제와 사회·경제적 문제를 의미한다. 기후 위기는 사회와 과학이 발전하는 과정에서 야기된다. 에너지 사용으로 발생되는 이산화탄소(CO2), 농업이나 축산업의 과정에서 나타나는 아산화질소(N2O) 등이 지구의 평균 온도를 상승시키면서 기후에도 영향을 미친다. 이와 같은 온난화나 이상 기온 현상은 자연재해 등과 같은 다양한 문제로 이어지며, 더불어 사회적 문제도 함께 증가하게 된다.', '원문', null, null),
('week45', 1, 'passage', 3, '이러한 기후 위기는 인간이 편리한 생활을 추구할수록 악화된다. 기온이 높아졌을 때 사람들이 일상적으로 사용하는 에어컨은 지구의 평균 온도를 더욱 높여 해수면 상승으로 이어지고, 이러한 현상은 저지대에 살고 있는 이들의 생존을 위협한다. 즉, 사람들이 원하는 편한 생활은 다른 누군가의 생존에 영향을 줄 수도 있는 것이다. 그뿐만 아니라 에어컨을 사용하지 못하는 가난한 사람들은 경제력이 있는 사람들이 사용하는 에어컨의 뜨거운 공기까지 견뎌야 하므로, 참아야 하는 더위의 수준이 점점 더 높아져 건강에도 악영향을 미친다.', '원문', null, null),
('week45', 1, 'passage', 4, '기후 위기로 인한 문제는 가난한 사람들에게 더욱 위험하다. 기후 변화로 자연재해가 발생하면 가난한 사람들에게는 이를 해결하고 극복할 수 있는 힘이 없다. 홍수가 발생했다고 가정해 보자. 돈이 있는 사람들은 홍수로 인한 피해를 자신의 경제력으로 해결할 수 있다. 하지만 가난한 사람들은 주거 환경이 열악하기 때문에 홍수로 인한 피해를 더 크게 입는다. 더구나 피해를 해결할 수 있는 경제력도 부족하여 거주지를 잃게 되는 상황이 발생할 수도 있다.', '원문', null, null),
('week45', 1, 'passage', 5, '기후 위기로 인한 사회적 불평등은 생존 문제와 거주지 상실이라는 상황에만 해당되는 것이 아니라 심리적인 부분에까지 영향을 미친다. 기후 변화로 인해 자연재해를 직간접적으로 경험한 미래 세대들은 어른들보다 불안감을 더 크게 느껴 앞으로 맞이할 세상을 두려운 시선으로 바라보게 된다. 무엇보다 가난한 환경에 놓여 있는 어린이와 청소년들은 경제력이 있는 부모를 둔 또래에 비해 생활 환경의 변화를 더 크게 겪게 되고, 기후 위기로 인한 불평등이 더욱 커진다는 것을 인식하게 된다.', '원문', null, null),
('week45', 1, 'passage', 6, '그렇다면 과연 기후 위기로 인한 사회적 불평등은 각 개인의 노력으로 해결될 수 있는 문제인가? 앞에서 살펴본 바와 같이 기후 위기 시대에는 편리한 생활을 추구하는 이들이 늘어날수록 특정 지역에 살고 있는 사람들이나 편리함을 누릴 여유가 없는 사람들이 지속적인 불평등을 경험해야 한다. 무엇보다 어른들이 편한 삶을 살수록 미래 세대가 느끼는 불안감과 두려움은 더욱 증가하여 사회적 불안과 불만으로 확대된다. 따라서 국가가 불평등한 위치에 있는 사람들에게 관심을 가지고 기후 위기로 인한 사회적 문제를 해결하는 제도를 적극적으로 마련해야 한다.', '원문', null, null);

-- 5-2) 파트 2(7단원 "1.요약하기", 55~61쪽) 콘텐츠 — "혐오 표현" 자료(김영희, 시민일보)
-- 기준. 핵심 개념어는 파트 1과 8단계 절차가 완전히 동일해 새로 만들지 않음(연구자 결정,
-- research-notes.md §5 항목 76) — 지문 어휘만 새로 큐레이션
delete from week45_content where unit = 'week45' and part = 2;

insert into week45_content (unit, part, stage_key, order_num, target_text, gloss, gloss_en, gloss_zh) values
-- 지문 어휘 (46) — "혐오 표현, 왜 규제가 필요한가"(김영희, 2025.7.5., 시민일보) 5단락 기준
('week45', 2, 'reading', 1, '혐오', '어떤 대상을 아주 심하게 싫어하는 마음', 'hatred, disgust', '厌恶'),
('week45', 2, 'reading', 2, '반감', '무언가가 마음에 안 들어서 반대하고 싶은 느낌', 'antipathy', '反感'),
('week45', 2, 'reading', 3, '거부감', '받아들이고 싶지 않은 느낌', 'aversion', '抵触感'),
('week45', 2, 'reading', 4, '맥락', '①말이나 글의 흐름(문맥) ②어떤 일이 일어나는 사회적 상황·배경', 'context', '①语境 ②背景'),
('week45', 2, 'reading', 5, '정체성', '자신이 어떤 사람인지에 대한 인식(성별·인종·종교 등)', 'identity', '身份认同'),
('week45', 2, 'reading', 6, '편견', '사실을 제대로 보지 않고 미리 정해 놓은 잘못된 생각', 'prejudice', '偏见'),
('week45', 2, 'reading', 7, '차별', '이유 없이 다르게, 나쁘게 대하는 것', 'discrimination', '歧视'),
('week45', 2, 'reading', 8, '성적 지향', '어떤 성별에게 감정적·성적으로 끌리는지에 대한 방향', 'sexual orientation', '性取向'),
('week45', 2, 'reading', 9, '정당화하다', '옳지 않은 일을 옳은 것처럼 만들다', 'to justify', '使正当化'),
('week45', 2, 'reading', 10, '일상화되다', '흔히 있는 일이 되다', 'to become routine', '日常化'),
('week45', 2, 'reading', 11, '사회적 약자', '사회에서 차별받기 쉬운 힘없는 사람들', 'socially vulnerable group', '社会弱势群体'),
('week45', 2, 'reading', 12, '우려하다', '걱정하다', 'to be concerned', '担忧'),
('week45', 2, 'reading', 13, '대응하다', '어떤 문제나 상황에 맞서 알맞게 행동하다', 'to respond', '应对'),
('week45', 2, 'reading', 14, '규제하다', '규칙으로 정해서 제한하다', 'to regulate', '规制'),
('week45', 2, 'reading', 15, '침해하다', '다른 사람의 권리나 영역 등을 함부로 넘어와 해를 끼치다', 'to infringe', '侵犯'),
('week45', 2, 'reading', 16, '보장되다', '문제없이 이루어지도록 확실히 지켜지다', 'to be guaranteed', '得到保障'),
('week45', 2, 'reading', 17, '표현의 자유', '자기 생각을 자유롭게 말하거나 표현할 수 있는 권리', 'freedom of expression', '表达自由'),
('week45', 2, 'reading', 18, '원칙', '어떤 일을 할 때 지켜야 하는 기본적인 기준', 'principle', '原则'),
('week45', 2, 'reading', 19, '인종차별적', '인종을 이유로 차별하는 (특성의)', 'racially discriminatory', '种族歧视性的'),
('week45', 2, 'reading', 20, '형사 처벌', '범죄에 대해 법으로 벌을 주는 것', 'criminal punishment', '刑事处罚'),
('week45', 2, 'reading', 21, '장치', '어떤 목적을 이루기 위한 수단이나 제도', 'mechanism', '机制'),
('week45', 2, 'reading', 22, '인권', '사람이면 누구나 가지는 기본적인 권리', 'human rights', '人权'),
('week45', 2, 'reading', 23, '성소수자', '성별·성적 지향이 다수와 다른 사람들', 'sexual minority', '性少数群体'),
('week45', 2, 'reading', 24, '이주민', '다른 지역·나라로 옮겨와 사는 사람', 'migrant', '移民'),
('week45', 2, 'reading', 25, '고립되다', '다른 사람들과 멀어져서 혼자가 되다', 'to be isolated', '被孤立'),
('week45', 2, 'reading', 26, '부정당하다', '그렇지 않다고 단정되거나 옳지 않다고 반대받다', 'to be denied', '被否定'),
('week45', 2, 'reading', 27, '평등하다', '차별 없이 똑같다', 'to be equal', '平等'),
('week45', 2, 'reading', 28, '위협하다', '①힘으로 협박하다 ②위험한 상태에 빠뜨리다', 'to threaten', '①威胁（用武力）②使…处于危险'),
('week45', 2, 'reading', 29, '단호하다', '마음이나 태도가 흔들리지 않고 분명하다', 'firm, resolute', '坚决'),
('week45', 2, 'reading', 30, '적대감', '상대를 적으로 여기고 미워하는 마음', 'hostility', '敌意'),
('week45', 2, 'reading', 31, '굳어지다', '쉽게 바뀌지 않는 상태가 되다', 'to become entrenched', '固化'),
('week45', 2, 'reading', 32, '혐오 범죄', '혐오를 이유로 저지르는 범죄', 'hate crime', '仇恨犯罪'),
('week45', 2, 'reading', 33, '확산되다', '널리 퍼지다', 'to spread', '扩散'),
('week45', 2, 'reading', 34, '집단 괴롭힘', '여러 사람이 한 사람에게 반복적으로 나쁘게 대하며 힘들게 만드는 것', 'group bullying', '集体霸凌'),
('week45', 2, 'reading', 35, '트라우마', '마음에 깊이 남는 충격적인 상처', 'trauma', '心理创伤'),
('week45', 2, 'reading', 36, '유발하다', '어떤 일을 일어나게 하다', 'to induce, trigger', '引发'),
('week45', 2, 'reading', 37, '통합', '여러 사람이나 집단이 서로 잘 어울려 하나가 되는 것', 'integration, unity', '团结'),
('week45', 2, 'reading', 38, '무너뜨리다', '안전하거나 튼튼한 것을 깨뜨리거나 부서지게 만들다', 'to undermine', '破坏'),
('week45', 2, 'reading', 39, '도덕적', '사람으로서 지켜야 할 옳고 그름의 기준에 관한', 'moral', '道德上的'),
('week45', 2, 'reading', 40, '자율', '스스로 판단해서 행동함', 'autonomy', '自主'),
('week45', 2, 'reading', 41, '근본적', '가장 중요하고 기본이 되는', 'fundamental', '根本性的'),
('week45', 2, 'reading', 42, '용인되다', '문제없다고 인정되어 받아들여지다', 'to be tolerated', '被容忍'),
('week45', 2, 'reading', 43, '기준', '무언가를 판단할 때 사용하는 정해진 규칙이나 정도', 'standard, criterion', '标准'),
('week45', 2, 'reading', 44, '뒤따르다', '다음에 이어서 함께 오다', 'to follow, accompany', '随之而来'),
('week45', 2, 'reading', 45, '존엄', '인간으로서 존중받아야 할 가치', 'dignity', '尊严'),
('week45', 2, 'reading', 46, '실질적', '겉으로만이 아니라 실제로 이루어지는', 'substantial, practical', '实质性的'),
-- 지문 읽기 화면용 원문(5단락 + 출처)
('week45', 2, 'passage', 1, '''혐오''란 어떤 대상에 대해 강한 반감과 거부감을 느끼는 감정을 뜻한다. 하지만 사회적 맥락에서의 혐오는 단순한 감정을 넘어선다. 성별, 인종, 종교, 국적, 성적 지향 등 정체성과 관련된 혐오는 편견과 차별, 나아가 폭력을 정당화하는 태도로 나타나기 때문이다. 특히 온라인 공간을 중심으로 혐오 표현이 일상화되면서 사회적 약자들이 심각한 피해를 입고 있어 이를 우려하는 목소리가 커지고 있다. 그렇기에 혐오 표현을 단순히 ''불쾌한 말''로 여길 것이 아니라 법적 규제와 처벌을 통해 혐오 표현에 적극적으로 대응해야 한다.', '원문', null, null),
('week45', 2, 'passage', 2, '일부에서는 혐오 표현을 법적으로 규제하는 것이 표현의 자유를 침해하는 것이라고 주장한다. 물론 표현의 자유는 민주주의의 핵심 가치이다. 하지만 그 자유는 타인의 권리를 해치지 않는 범위에서만 보장되어야 한다. 국제사회도 이러한 원칙을 받아들이고 있다. 예를 들어 독일은 나치 상징 사용과 인종차별적 표현을 금지하고 있으며, 캐나다도 혐오 발언에 대해 형사 처벌을 하고 있다. 이러한 사례들은 혐오 표현 규제가 민주주의를 지키기 위한 장치임을 보여준다.', '원문', null, null),
('week45', 2, 'passage', 3, '혐오 표현의 문제점은 타인의 인권을 직접적으로 침해한다는 것이다. 성소수자, 이주민, 장애인 등 사회적 약자들은 혐오 발언으로 인해 고립되고, 자신의 존재를 부정당하는 경험을 반복적으로 겪는다. 혐오 표현은 그 대상이 스스로 바꿀 수 없는 부분에 대한 공격이라는 점에서 특히 심각하다. 단지 감정적 상처를 주는 수준이 아니라 평등하게 살아갈 권리 자체를 위협하는 것이다. 이러한 인권 침해는 단호한 법적 대응 없이는 해결되기 어렵다.', '원문', null, null),
('week45', 2, 'passage', 4, '또한 특정 집단에 대한 적대감이 언어로 반복되면 그 편견은 쉽게 사회적 인식으로 굳어진다. 이것은 차별을 정당화할 뿐만 아니라 혐오 범죄로 이어질 위험도 높인다. 특히 온라인 공간에서 빠르게 확산되는 혐오 표현은 집단 괴롭힘, 정신적 트라우마, 심지어 자살에 이르기까지 많은 사회적 문제를 유발한다. 이렇게 혐오 표현은 사회 전체에도 심각한 영향을 미친다. 더 이상 개인 간 갈등이 아니라 사회의 안전과 통합을 위협하는 문제인 것이다.', '원문', null, null),
('week45', 2, 'passage', 5, '혐오 표현은 사회적 약자의 권리를 침해할 뿐 아니라 사회의 안전까지 무너뜨리는 심각한 문제다. 이를 도덕적 판단이나 개인의 자율에 맡겨두는 것만으로는 근본적인 해결이 어렵다. 혐오 표현이 용인되지 않는다는 분명한 기준을 사회에 제시하기 위해서는 강력한 법적 규제와 처벌이 반드시 뒤따라야 한다. 누구나 차별 없이 존중받으며 살아갈 수 있는 사회, 혐오보다 존엄이 우선되는 사회를 만들기 위해 이제는 실질적인 대응이 필요하다.', '원문', null, null),
('week45', 2, 'passage', 6, '김영희(2025.7.5.). 혐오 표현, 왜 규제가 필요한가. 시민일보.', '출처', null, null);

-- 5-3) 파트 3(7단원 "2.요약을 활용한 글 작성하기", 62~64쪽) 콘텐츠 — "앞서가는 AI" 자료
-- (박민수, 미래사회 5월호) 기준. 파트 2와 같은 이유로 핵심 개념어는 새로 만들지 않음.
-- 64쪽 "문어체" 코너(구어체·문어체 표현 변환 규칙)는 어휘 타이핑 대상이 아니라 프로그램에서
-- 제외하기로 함(연구자 결정, research-notes.md §5 항목 76·78 참고)
delete from week45_content where unit = 'week45' and part = 3;

insert into week45_content (unit, part, stage_key, order_num, target_text, gloss, gloss_en, gloss_zh) values
-- 지문 어휘 (47) — "앞서가는 AI, 우리에게는 시간이 필요하다"(박민수, 2025, 미래사회 5월호) 5단락 기준.
-- 확산되다·위협하다·대응하다·차별적(파트2)·불평등(파트1)은 이미 배운 단어라 재수록하지 않음
('week45', 3, 'reading', 1, '전반', '어떤 것의 전체 여러 부분', 'overall, across the board', '全面，各个方面'),
('week45', 3, 'reading', 2, '효율성', '적은 노력으로 좋은 결과를 내는 정도', 'efficiency', '效率'),
('week45', 3, 'reading', 3, '혁신적', '완전히 새롭고 뛰어난 (것)', 'innovative', '革新性的'),
('week45', 3, 'reading', 4, '자율주행', '사람이 운전하지 않아도 스스로 움직이는 자동차 기술', 'self-driving, autonomous driving', '自动驾驶'),
('week45', 3, 'reading', 5, '실정', '실제로 그러한 상황', 'actual situation', '实际情况'),
('week45', 3, 'reading', 6, '사회 구조', '사회가 이루어져 있는 방식', 'social structure', '社会结构'),
('week45', 3, 'reading', 7, '제도적', '사회의 규칙이나 방법과 관련된', 'institutional', '制度上的'),
('week45', 3, 'reading', 8, '미비하다', '충분히 준비되지 않아 부족하다', 'to be insufficient, inadequate', '不完备'),
('week45', 3, 'reading', 9, '맹목적으로', '이유나 판단 없이 무조건', 'blindly', '盲目地'),
('week45', 3, 'reading', 10, '추진하다', '어떤 일을 계획해서 계속 진행하다', 'to promote, push forward', '推进'),
('week45', 3, 'reading', 11, '조절하다', '적당하게 맞추어 바꾸다', 'to adjust, regulate', '调节'),
('week45', 3, 'reading', 12, '대체하다', '다른 것으로 바꾸어 대신하다', 'to replace', '替代'),
('week45', 3, 'reading', 13, '실직', '직업을 잃음', 'job loss, unemployment', '失业'),
('week45', 3, 'reading', 14, '불안정하다', '안정되지 않고 계속 바뀌거나 흔들리다', 'to be unstable', '不稳定'),
('week45', 3, 'reading', 15, '중장년층', '중년과 장년에 속하는 사람들(보통 40~60대)', 'middle-aged and older adults', '中老年群体'),
('week45', 3, 'reading', 16, '저소득층', '소득이 적은 사람들', 'low-income group', '低收入群体'),
('week45', 3, 'reading', 17, '재교육', '새로운 지식이나 기술을 다시 배우는 것', 'retraining, re-education', '再教育'),
('week45', 3, 'reading', 18, '계층', '사회적·경제적 위치가 비슷한 사람들의 집단', '(social) class, stratum', '阶层'),
('week45', 3, 'reading', 19, '적응하다', '새로운 환경이나 조건에 익숙해지다', 'to adapt', '适应'),
('week45', 3, 'reading', 20, '제약', '어떤 일을 자유롭게 하지 못하게 막는 것', 'constraint, restriction', '制约'),
('week45', 3, 'reading', 21, '도입', '새로운 것을 들여와 쓰기 시작함', 'introduction, adoption', '引进'),
('week45', 3, 'reading', 22, '확보하다', '필요한 것을 미리 준비해서 가지다', 'to secure, ensure', '确保'),
('week45', 3, 'reading', 23, '자동화', '기계가 사람 대신 자동으로 작업하게 만드는 것', 'automation', '自动化'),
('week45', 3, 'reading', 24, '생산성', '일한 만큼 결과를 만들어 내는 능력', 'productivity', '生产力'),
('week45', 3, 'reading', 25, '자본', '사업을 하는 데 필요한 돈이나 재산', 'capital', '资本'),
('week45', 3, 'reading', 26, '대기업', '규모가 아주 큰 기업', 'large corporation', '大企业'),
('week45', 3, 'reading', 27, '인건비', '사람을 고용하는 데 드는 비용', 'labor cost', '人工成本'),
('week45', 3, 'reading', 28, '수익', '일이나 사업을 해서 얻는 이익', 'profit, revenue', '收益'),
('week45', 3, 'reading', 29, '극대화하다', '가장 크게 만들다', 'to maximize', '最大化'),
('week45', 3, 'reading', 30, '중소기업', '규모가 작거나 중간 정도인 기업', 'small and medium-sized enterprise', '中小企业'),
('week45', 3, 'reading', 31, '뒤처지다', '다른 것보다 늦어지거나 못하게 되다', 'to fall behind', '落后'),
('week45', 3, 'reading', 32, '고용', '돈을 주고 사람을 일하게 함', 'employment', '雇佣'),
('week45', 3, 'reading', 33, '처하다', '어떤 상황이나 상태에 놓이다', 'to be in (a situation/state)', '处于'),
('week45', 3, 'reading', 34, '혜택', '특별히 주어지는 이익이나 도움', 'benefit', '好处'),
('week45', 3, 'reading', 35, '집중되다', '한곳으로 모이다', 'to be concentrated', '集中'),
('week45', 3, 'reading', 36, '분배되다', '여러 사람에게 나누어지다', 'to be distributed', '分配'),
('week45', 3, 'reading', 37, '조세 정책', '세금과 관련해 정부가 정한 방침', 'tax policy', '税收政策'),
('week45', 3, 'reading', 38, '복지 제도', '국민의 생활을 돕기 위한 국가의 제도', 'welfare system', '福利制度'),
('week45', 3, 'reading', 39, '심화되다', '정도가 더 심해지다', 'to intensify, deepen', '加深'),
('week45', 3, 'reading', 40, '윤리적', '옳고 그름에 대한 도덕적 기준과 관련된', 'ethical', '伦理上的'),
('week45', 3, 'reading', 41, '법적 책임', '법에 따라 져야 하는 책임', 'legal responsibility', '法律责任'),
('week45', 3, 'reading', 42, '편향되다', '여러 쪽이 아니라 한쪽 정보만 많다', 'biased', '有偏向的'),
('week45', 3, 'reading', 43, '학습하다', '많은 자료를 보고 스스로 규칙이나 방법을 찾아 익히다', 'to learn (by training on data)', '通过大量数据自主掌握规律或方法'),
('week45', 3, 'reading', 44, '사전 동의', '미리 허락을 받는 것', 'prior consent', '事先同意'),
('week45', 3, 'reading', 45, '합의', '여러 사람이 서로 의견을 맞추어 하나로 정함', 'agreement, consensus', '共识'),
('week45', 3, 'reading', 46, '선행되다', '다른 일보다 먼저 이루어지다', 'to precede, come first', '先行'),
('week45', 3, 'reading', 47, '신중하다', '가볍게 하지 않고 조심스럽게 잘 생각하다', 'to be careful, prudent', '慎重'),
-- 지문 읽기 화면용 원문(5단락 + 출처)
('week45', 3, 'passage', 1, '일상 곳곳에서 확산되고 있는 인공지능(AI)은 사회 전반에 새로운 가능성과 효율성을 가져다주는 혁신적 기술이다. 검색, 번역, 자율주행 등 다양한 분야에서 AI는 이미 우리의 삶에 들어와 있다. 그러나 기술이 너무 빠르게 발전하면서 우리 사회는 그 변화의 속도에 적절히 대응하지 못하고 있는 실정이다. 특히 AI가 인간의 삶과 노동, 사회 구조 전반에 어떤 변화를 일으킬지에 대한 논의가 충분히 이루어지지 못하고 있으며 제도적 준비도 미비하다. 따라서 맹목적으로 AI 개발을 추진할 것이 아니라 발전 속도를 조절할 필요가 있다.', '원문', null, null),
('week45', 3, 'passage', 2, 'AI는 이미 인간의 일자리를 위협하고 있다. 단순한 반복 노동뿐 아니라 의료, 교육, 상담, 디자인 등 전문 분야까지 AI가 대체하고 있으며, 이에 따라 실직과 직업 불안정이 현실로 나타나고 있다. 특히 중장년층, 저소득층처럼 재교육 기회가 적은 계층은 기술 변화에 적응하기 어렵고, 새로운 일자리가 생긴다고 해도 접근하는 데에 제약이 없다. 그렇기 때문에 기술 도입의 속도를 조절하면서 사회가 준비할 시간을 확보해야 한다.', '원문', null, null),
('week45', 3, 'passage', 3, '물론 AI를 활용한 자동화는 기업의 생산성과 효율성을 크게 높이고 있다. 그러나 이것은 일부 기업에만 해당되는 사항이다. 자본과 기술을 갖춘 대기업은 인건비를 줄이고 수익을 극대화하고 있지만 중소기업은 기술 도입에 어려움을 겪으며 경쟁에서 뒤처지고 있다. 노동자들 또한 불안정한 고용 상태에 처해 있다. 이처럼 AI의 혜택이 소수에게만 집중되는 것도 문제이다. 기술이 모두를 위한 도구가 되기 위해서는 그 이익이 공정하게 분배되어야 한다. 이를 위한 조세 정책, 복지 제도, 재교육 시스템 등이 마련되지 않은 상황에서 기술만 앞서가면 사회 불평등은 더욱 심화될 것이다.', '원문', null, null),
('week45', 3, 'passage', 4, '그뿐만 아니라 AI는 여전히 윤리적 기준과 법적 책임이 부족한 상태에서 도입되고 있다. 예를 들어 편향된 데이터를 학습한 AI가 특정 집단에 차별적 결정을 내리는 문제가 발생하고 있다. 또 종종 사용자의 사전 동의 없이 정보 수집이 이루어지기도 한다. 기술이 사회 전반에 영향을 미치기 전에 최소한의 윤리 기준과 법적 책임에 대한 사회적 합의가 선행되어야 한다. 그렇지 않으면 기술은 오히려 사람들에게 피해를 주는 도구가 될 수 있다.', '원문', null, null),
('week45', 3, 'passage', 5, '기술의 미래를 결정하는 것은 속도가 아니라 방향이며, 그 방향은 사회적 합의를 통해 신중하게 정해져야 한다. AI 기술을 무조건 빠르게 발전시키기보다는 사회 전체가 그 의미와 결과를 충분히 이해하고 대응할 수 있도록 속도를 조절할 필요가 있다. AI가 진정으로 사람을 위한 기술이 되기 위해서 잠시 멈추는 용기가 요구된다.', '원문', null, null),
('week45', 3, 'passage', 6, '박민수(2025). 앞서가는 AI, 우리에게는 시간이 필요하다. 미래사회 5월호.', '출처', null, null);

-- 6) 내용 이해 문항 채우기 — 파트 1(기후 위기 지문) + 파트 2(혐오 표현 지문) + 파트 3(AI 지문)
delete from week45_comprehension_questions where unit = 'week45';

insert into week45_comprehension_questions (unit, part, order_num, question_text, correct_answer, distractor_1, distractor_2, distractor_3) values
('week45', 1, 1, '이 글에 따르면, 기후 위기로 인한 피해를 더 크게 입는 사람들은 누구인가?', '가난한 사람들', '부유한 사람들', '젊은 사람들', '도시에 사는 사람들'),
('week45', 1, 2, '이 글에서 에어컨 사용이 문제가 되는 이유는 무엇인가?', '지구의 평균 온도를 높여 해수면 상승 등으로 다른 사람의 생존을 위협하기 때문', '전기 요금이 많이 들기 때문', '고장이 잘 나기 때문', '사용법이 어렵기 때문'),
('week45', 1, 3, '이 글에서 홍수가 발생했을 때, 가난한 사람들이 부유한 사람들보다 피해를 더 크게 입는 이유로 든 것은 무엇인가?', '주거 환경이 열악하고 피해를 해결할 경제력이 부족하기 때문', '홍수 보험에 가입하지 않았기 때문', '정부의 지원 대상이 아니기 때문', '저지대에 살지 않기 때문'),
('week45', 1, 4, '이 글쓴이는 기후 위기로 인한 사회적 불평등을 해결하기 위해 무엇이 필요하다고 주장하는가?', '국가의 적극적인 제도 마련', '개인의 노력만으로 충분하다', '기술 발전을 멈춰야 한다', '가난한 사람들의 노력이 필요하다'),
('week45', 2, 1, '이 글에서 독일과 캐나다는 혐오 표현에 대해 어떻게 대응하고 있는가?', '법으로 금지하거나 형사 처벌을 한다', '규제하지 않고 개인의 자유에 맡긴다', '벌금만 부과한다', '온라인에서만 규제한다'),
('week45', 2, 2, '이 글에 따르면, 혐오 표현이 특히 심각한 이유는 무엇인가?', '그 대상이 스스로 바꿀 수 없는 부분을 공격하기 때문', '가해자가 익명이기 때문', '처벌이 약하기 때문', '온라인에서 일어나기 때문'),
('week45', 2, 3, '이 글에서 온라인에서 빠르게 확산되는 혐오 표현이 유발할 수 있다고 언급한 문제는 무엇인가?', '집단 괴롭힘, 정신적 트라우마, 자살', '경제적 손실', '인터넷 속도 저하', '법적 소송 증가'),
('week45', 2, 4, '이 글쓴이가 혐오 표현 문제를 해결하기 위해 결론적으로 주장하는 것은 무엇인가?', '강력한 법적 규제와 처벌이 반드시 뒤따라야 한다', '개인의 도덕적 판단에 맡겨야 한다', '온라인 이용을 금지해야 한다', '교육을 통해서만 해결해야 한다'),
('week45', 3, 1, '이 글에 따르면, 재교육 기회가 적은 계층(중장년층, 저소득층)이 겪는 어려움은 무엇인가?', '기술 변화에 적응하기 어렵다', '임금이 줄어든다', '일자리가 아예 없어진다', '해외로 이주해야 한다'),
('week45', 3, 2, '이 글에서 AI 자동화의 혜택은 주로 누구에게 집중된다고 설명하는가?', '자본과 기술을 갖춘 대기업', '모든 기업이 골고루', '중소기업', '노동자들'),
('week45', 3, 3, '이 글에서 AI 기술 도입의 문제점으로 든 것은 무엇인가?', '윤리적 기준과 법적 책임이 부족한 상태에서 도입되고 있다', '속도가 너무 느리다', '비용이 너무 많이 든다', '사용법이 복잡하다'),
('week45', 3, 4, '이 글쓴이가 결론적으로 주장하는 것은 무엇인가?', '기술의 발전 속도보다 방향이 중요하며, 사회적 합의를 통해 신중하게 결정해야 한다', 'AI 개발을 완전히 멈춰야 한다', '속도를 최대한 빠르게 높여야 한다', '개인의 판단에 맡겨야 한다');

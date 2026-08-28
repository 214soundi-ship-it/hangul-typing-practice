-- week2_3_reflective_writing.html 저장소 설정
-- Supabase 대시보드 > SQL Editor 에서 이 스크립트를 그대로 실행하세요.
-- (이미 실행한 적이 있어도 그대로 다시 실행하면 됩니다 — 컬럼 추가는 안전하게
--  건너뛰고, 콘텐츠는 지우고 새로 채웁니다.)
--
-- 저작권 안내: week23_content 테이블에는 교재(외국인 유학생을 위한 학술적 글쓰기,
-- 고려대학교, 23~44쪽 "성찰적 글" 단원)에서 가져온 어휘·정의가 들어갑니다. 이 SQL
-- 파일 자체는 git에 커밋되지만, 실행 결과인 데이터는 DB 안에만 있고 앱은 실행
-- 시점에 fetch로 가져오므로 교재 원문이 공개 GitHub 소스코드에는 남지 않습니다.
-- (사람이 보는 참고용 정리본은 week23_vocabulary.md — 이 파일도 gitignore됨)
--
-- 구조: 성찰적 글 단원은 파트 1(계획하기,3단원)/파트 2(작성하기,4단원)/파트 3(수정하기,
-- 5단원)로 나뉨(실제 수업 진행 순서와 동일). 파트 1·2·3 모두 확정·적용.
-- 파트 1·2는 각각 어휘 2그룹(핵심 개념어/예시 이해 or 읽어보기 어휘)으로 구성.
-- (수정 이력) 한때 두 파트 모두에 "활동 지시문 어휘" 그룹(교재 지시문 이해용 어휘)이 있었음 —
-- 파트 1엔 바탕/관점/태도/확장하다/구체적/선정하다 6개, 파트 2엔 나열하다/어울리다/유의하다/
-- 살펴보다 4개(원문 29~36쪽에 실제로 쓰이는 걸 재확인 후 반영했었음). 그런데 연구자가 "실제
-- 활동은 어차피 수업 시간에 교수자가 직접 설명해준다"는 점을 지적 — 핵심 개념어·읽어보기
-- 어휘는 학생이 "혼자 텍스트만으로" 이해해야 하는 반면, 활동 지시문은 교수자의 실시간 설명이라는
-- 안전망이 이미 있어 사전학습 도구로 다룰 실익이 적고, "수업 지문 내용 이해도"(RQ1)라는 이
-- 도구의 측정 목적과도 결이 다르다는 데 동의해 파트 1·2 두 곳 모두에서 그룹째 제외하기로 최종
-- 결정함. research-notes.md 로그 참고.
-- 파트 3은 어휘 2그룹(핵심 개념어/부사 연습(42쪽) 어휘)으로 구성 — 5단원의 "조사 바르게 사용하기" 연습은
-- 4단원(파트 2) 본문 문장을 그대로 재사용(오류만 삽입)해서 새 어휘가 필요 없었고, "부사
-- 적절하게 사용하기" 연습 단어 5개(펑펑/홀로/유독/한없이/다름없이)는 전부 파트 2 읽어보기
-- 어휘와 동일 — 다만 여기서는 "정확히 골라 쓰기"라는 능동적 사용 목적이 달라 다시 수록함.
-- "핵심 문장" 타이핑 단계는 세 파트 모두 넣지 않기로 함(파트 1·2는 읽어보기 어휘와 내용이
-- 겹쳐 피로도만 늘어난다고 판단, 파트 3은 애초에 읽기 지문이 파트 2와 같은 본문의 재탕이라
-- 불필요). 선별 기준: 어휘 난이도는 고려하지 않고, 외국인 유학생이 그 파트의 교재 내용을
-- 이해하는 데 필요한가만으로 판단(사용자 확정 기준) — 같은 단어가 여러 파트에 다시 나오면
-- 각 파트 본문/활동 이해에 필요하면 중복 삽입 허용(예: 다짐/무시하다는 파트 1·2, 부사 5개는
-- 파트 2·3). 단, 이미 배운 개념이 새 뜻 없이 평가 기준으로만 재언급되는 경우(예: 통일성이
-- 파트 2·3 유의사항에 반복 등장, 제목·구체적이 파트 3 체크리스트에 재언급)는 중복 제외함.

-- 1) 콘텐츠 (교재에서 가져온 학습 내용 — 읽기 전용, 관리자가 이 파일로만 채움)
create table if not exists week23_content (
  id bigint generated always as identity primary key,
  unit text not null default 'week23',
  part int not null default 1,  -- 1=계획하기, 2=작성하기, 3=수정하기
  stage_key text not null,      -- 파트 1: 'concept'|'activity'|'narrative', 파트 2: 'concept'|'reading', 파트 3: 'concept'|'adverb'
  order_num int not null,
  target_text text not null,    -- 실제 타이핑 대상 텍스트
  gloss text,                   -- 쉬운 한국어 뜻풀이
  gloss_en text,                -- 영어 번역
  gloss_zh text,                -- 중국어(간체) 번역
  created_at timestamptz not null default now()
);

-- 이미 만들어진 테이블이면 새 컬럼만 안전하게 추가 (기존 행은 delete+insert로 다시 채워짐)
alter table week23_content add column if not exists part int not null default 1;
alter table week23_content add column if not exists gloss_en text;
alter table week23_content add column if not exists gloss_zh text;

create index if not exists week23_content_unit_part_stage_idx
  on week23_content (unit, part, stage_key, order_num);

-- 2) 참여자별 진행 상태 (stage0_progress와 동일한 구조)
create table if not exists week23_progress (
  participant_code text primary key,
  completed_stages int[] not null default '{}',
  next_stage int not null default 1,
  updated_at timestamptz not null default now()
);

-- 3) 단계별 연습 기록 (연구 데이터, stage0_records와 동일한 구조)
create table if not exists week23_records (
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

create index if not exists week23_records_code_idx on week23_records (participant_code);

-- 3-1) 이해도 확인 퀴즈 결과 (연구 데이터, RQ1 측정 도구 — 파트를 마칠 때마다 그 파트
--      어휘에서 무작위로 뽑은 4지선다 문항의 결과. unit 필드를 둔 건 4~5주차 등 다른
--      프로그램에도 같은 구조로 재사용하기 위함)
create table if not exists quiz_results (
  id bigint generated always as identity primary key,
  unit text not null,
  part int not null,
  participant_code text not null,
  score int not null,
  total int not null,
  details jsonb not null,  -- [{word, correctAnswer, chosenAnswer, isCorrect}, ...]
  recorded_at timestamptz not null default now()
);

create index if not exists quiz_results_code_idx on quiz_results (participant_code);

-- 3-2) 내용 이해 문항 (연구 데이터 아님, 콘텐츠 테이블 — 어휘 재인이 아니라 지문을 실제로
--      읽고 이해해야 풀 수 있는 문항. 무작위 샘플링 없이 파트별로 준비된 문항을 전부 사용.
--      해당 파트에 문항이 없으면(예: 파트 1·3) 그냥 어휘 퀴즈만 나온다)
create table if not exists week23_comprehension_questions (
  id bigint generated always as identity primary key,
  unit text not null default 'week23',
  part int not null,
  order_num int not null,
  question_text text not null,
  correct_answer text not null,
  distractor_1 text not null,
  distractor_2 text not null,
  distractor_3 text not null,
  created_at timestamptz not null default now()
);

create index if not exists week23_comp_q_unit_part_idx
  on week23_comprehension_questions (unit, part, order_num);

-- 4) 보안 설정
alter table week23_content enable row level security;
alter table week23_progress enable row level security;
alter table week23_records enable row level security;
alter table quiz_results enable row level security;
alter table week23_comprehension_questions enable row level security;

drop policy if exists "anon select comp questions" on week23_comprehension_questions;
create policy "anon select comp questions" on week23_comprehension_questions
  for select to anon using (true);

drop policy if exists "anon insert quiz results" on quiz_results;
create policy "anon insert quiz results" on quiz_results
  for insert to anon with check (true);

drop policy if exists "anon select quiz results" on quiz_results;
create policy "anon select quiz results" on quiz_results
  for select to anon using (true);

drop policy if exists "anon select content" on week23_content;
create policy "anon select content" on week23_content
  for select to anon using (true);

drop policy if exists "anon insert progress" on week23_progress;
create policy "anon insert progress" on week23_progress
  for insert to anon with check (true);

drop policy if exists "anon update progress" on week23_progress;
create policy "anon update progress" on week23_progress
  for update to anon using (true) with check (true);

drop policy if exists "anon select progress" on week23_progress;
create policy "anon select progress" on week23_progress
  for select to anon using (true);

drop policy if exists "anon insert records" on week23_records;
create policy "anon insert records" on week23_records
  for insert to anon with check (true);

drop policy if exists "anon select records" on week23_records;
create policy "anon select records" on week23_records
  for select to anon using (true);

-- 5) 콘텐츠 채우기 — 파트 1(계획하기, 3단원, 23~28쪽), 파트 2(작성하기, 4단원, 29~36쪽),
--    파트 3(수정하기, 5단원, 37~44쪽) 모두 확정 반영
delete from week23_content where unit = 'week23';

insert into week23_content (unit, part, stage_key, order_num, target_text, gloss, gloss_en, gloss_zh) values
-- 핵심 개념어 (9)
('week23', 1, 'concept', 1, '성찰', '자기 자신을 대상으로 하여 경험과 생각, 감정 등을 되돌아보는 것', 'reflection (looking back at one''s own experiences, thoughts, feelings)', '反思（回顾自己的经历、想法和感情）'),
('week23', 1, 'concept', 2, '되돌아보다', '과거의 경험이나 지난 일을 다시 생각하다', 'to look back (on a past experience)', '回顾，回想'),
('week23', 1, 'concept', 3, '객관적', '개인적인 감정이나 생각에 치우치지 않고 있는 그대로 바라보는 것', 'objective (seeing something as it is without being influenced by personal feelings)', '客观的（不受个人感情或想法影响，如实看待事物）'),
('week23', 1, 'concept', 4, '화제', '이야기가 되는 바탕 소재', 'topic', '话题'),
('week23', 1, 'concept', 5, '글감', '글을 쓰는 데 재료가 되는 경험이나 일상', 'writing material', '写作素材'),
('week23', 1, 'concept', 6, '중심 사건', '경험 중에서 의미를 발견한 가장 중요한 사건', 'central event', '核心事件'),
('week23', 1, 'concept', 7, '의미', '사건이나 경험이 나에게 주는 특별한 가치나 깨달음', 'meaning', '意义'),
('week23', 1, 'concept', 8, '주제문', '중심 사건과 그것이 주는 의미를 정리한 하나의 문장', 'thesis statement', '主题句'),
('week23', 1, 'concept', 9, '통일성', '글의 내용이 여러 이야기로 나뉘지 않고 하나의 주제로 잘 뭉쳐 있는 것', 'unity', '统一性'),

-- 예시 이해 어휘 (8)
('week23', 1, 'narrative', 1, '일상', '특별한 일이 없는 평범한 하루하루의 생활', 'daily life', '日常'),
('week23', 1, 'narrative', 2, '일교차', '하루 동안의 최고 기온과 최저 기온의 차이', 'daily temperature range', '日温差'),
('week23', 1, 'narrative', 3, '쾌적하다', '기분이 상쾌할 정도로 날씨나 환경이 좋음', 'pleasant, comfortable', '舒适宜人'),
('week23', 1, 'narrative', 4, '겪다', '어렵거나 중요한 일, 경험 등을 직접 하다', 'to go through, experience', '经历'),
('week23', 1, 'narrative', 5, '무시하다', '어떤 것을 알고 있으면서도 신경 쓰지 않고 그냥 지나치다', 'to ignore (something one is aware of)', '忽视'),
('week23', 1, 'narrative', 6, '들여다보다', '겉만 보지 않고 속이나 자세한 내용을 깊이 살펴보다', 'to look closely into (something), not just at the surface', '细看，深入察看'),
('week23', 1, 'narrative', 7, '보람', '어떤 일을 한 뒤에 얻는 좋은 결과나 만족한 느낌', 'a sense of fulfillment', '成就感'),
('week23', 1, 'narrative', 8, '다짐', '마음을 굳게 먹고 스스로 약속함', 'resolve, vow', '决心'),

-- 파트 2. 성찰적 글 작성하기 (4단원, 29~36쪽)
-- 핵심 개념어 (글의 구성 이론 — 처음-중간-끝 틀과 그 구성 요소)
('week23', 2, 'concept', 1, '처음-중간-끝', '글을 배경 설명(처음)-중심 사건과 의미(중간)-삶으로의 적용(끝)의 세 부분으로 구성하는 방식', 'beginning-middle-end (a three-part writing structure)', '开头-中间-结尾（三部分结构）'),
('week23', 2, 'concept', 2, '배경', '어떤 일이 일어나게 된 주변 상황', 'background', '背景'),
('week23', 2, 'concept', 3, '방향', '어떤 목적을 이루기 위해 나아가는 쪽', 'direction (how the writing will unfold)', '方向'),
('week23', 2, 'concept', 4, '암시하다', '직접 말하지 않고 간접적으로 알려 주다', 'to hint, to imply', '暗示'),
('week23', 2, 'concept', 5, '독자', '글을 읽는 사람', 'reader', '读者'),
('week23', 2, 'concept', 6, '전달하다', '생각이나 감정을 다른 사람에게 알게 하다', 'to convey, to communicate', '传达'),
('week23', 2, 'concept', 7, '비유', '내 마음이나 상황을 비슷한 다른 것에 빗대어 표현하는 것', 'figurative expression', '比喻'),
('week23', 2, 'concept', 8, '빗대다', '어떤 것을 비슷한 다른 대상에 견주어 표현하다', 'to liken (something) to', '比作，比拟'),
('week23', 2, 'concept', 9, '단락 나누기', '하나의 중심 생각마다 문단을 나누어 쓰는 것', 'paragraphing', '分段'),
('week23', 2, 'concept', 10, '중심 문장', '한 단락에서 가장 중요한 생각을 담은 문장', 'topic sentence', '中心句'),
('week23', 2, 'concept', 11, '뒷받침 문장', '중심 문장의 내용을 자세히 설명해 주는 문장', 'supporting sentence', '支撑句'),
('week23', 2, 'concept', 12, '삶으로의 적용', '사건이 주는 의미를 자신의 앞으로의 삶에 연결하는 것', 'application to life', '应用到生活'),
('week23', 2, 'concept', 13, '제목', '글의 핵심 내용을 보여주는 짧은 이름', 'title', '标题'),

-- 읽어보기(30쪽) 어휘 (학생 글 "나의 한국 유학 생활" 전체 본문 이해용 — 문장 순서와 무관하게 등장 순)
('week23', 2, 'reading', 1, '하루도 빠짐없이', '하루도 빼지 않고 매일', 'without a single day missing', '每天都不落下'),
('week23', 2, 'reading', 2, '속상하다', '일이 마음대로 되지 않거나 좋지 않은 일이 있어 마음이 불편하고 괴롭다', 'to feel upset', '难过；心里不舒服'),
('week23', 2, 'reading', 3, '심리적', '마음과 관련된', 'psychological', '心理上的'),
('week23', 2, 'reading', 4, '성숙하다', '(정신적으로) 어른스럽게 자라다', 'to mature', '成熟'),
('week23', 2, 'reading', 5, '견디다', '힘든 상황을 참고 버티다', 'to endure, to bear', '忍受，坚持'),
('week23', 2, 'reading', 6, '상상조차 못 하다', '짐작도 하지 못하다', 'to not even be able to imagine', '连想都没想到'),
('week23', 2, 'reading', 7, '유독', '여럿 중에서 특히 (뒤에 부정적 내용이 오는 경우가 많음)', 'especially, unusually', '格外，尤其'),
('week23', 2, 'reading', 8, '매섭다', '(바람 등이) 몹시 세차고 날카롭다', 'to be fierce, biting (wind)', '（风）猛烈刺骨'),
('week23', 2, 'reading', 9, '낯설다', '익숙하지 않고 처음 보는 것 같다', 'to be unfamiliar, strange', '陌生'),
('week23', 2, 'reading', 10, '존재하다', '실제로 있다', 'to exist', '存在'),
('week23', 2, 'reading', 11, '몹시', '아주 심하게', 'extremely', '非常'),
('week23', 2, 'reading', 12, '쓸쓸하다', '외롭고 허전하다', 'to feel lonely and empty', '孤单寂寞'),
('week23', 2, 'reading', 13, '다름없이', '평소와 전혀 다르지 않게', 'just as usual', '和平常一样'),
('week23', 2, 'reading', 14, '안부를 묻다', '잘 지내는지 묻다', 'to ask how someone is doing', '问候'),
('week23', 2, 'reading', 15, '눈물을 머금다', '눈에 눈물이 살짝 고이다, 또는 눈물이 나려는 것을 참다', 'to hold back tears', '含着泪水'),
('week23', 2, 'reading', 16, '귀 기울이다', '관심을 가지고 주의 깊게 듣다/살피다', 'to pay close attention', '倾听，留意'),
('week23', 2, 'reading', 17, '바람', '바람에는 두 가지 뜻이 있음 — ① 공기의 움직임(날씨) ② 이루어지기를 바라는 마음(소망)', 'two meanings: ① wind ② a wish/hope for something to happen', '有两个意思：①风 ②希望实现的心愿'),
('week23', 2, 'reading', 18, '마음을 속이다', '진짜 감정을 숨기고 다른 척하다', 'to deceive one''s own heart', '欺骗自己的内心'),
('week23', 2, 'reading', 19, '쬐다', '볕이나 불기운 등을 몸에 받다', 'to bask in (sunlight)', '晒（太阳）'),
('week23', 2, 'reading', 20, '홀로', '혼자서', 'alone', '独自'),
('week23', 2, 'reading', 21, '주저앉다', '서 있거나 움직이다가 그 자리에 힘없이 앉다', 'to sink down; to collapse into a sitting position', '瘫坐下来；一下子坐倒在地'),
('week23', 2, 'reading', 22, '펑펑', '눈물을 많이 흘리며 세게 우는 모양', 'heavily, profusely (펑펑 울다: to cry hard / to cry one''s eyes out)', '（펑펑 울다）放声大哭；哭得很厉害'),
('week23', 2, 'reading', 23, '가득하다', '빈 곳 없이 꽉 차 있다', 'to be full', '充满'),
('week23', 2, 'reading', 24, '한참', '시간이 꽤 지나는 동안', 'for quite a while', '好一会儿'),
('week23', 2, 'reading', 25, '진정되다', '(마음이) 흥분이 가라앉아 조용해지다', 'to calm down', '（心情）平静下来'),
('week23', 2, 'reading', 26, '차분히', '마음이 가라앉아 조용하고 평온하게', 'calmly', '平静地'),
('week23', 2, 'reading', 27, '가라앉히다', '(마음을) 차분하게 만들다', 'to calm (one''s mind)', '使（心情）平静'),
('week23', 2, 'reading', 28, '도전', '어렵지만 부딪혀 보는 일', 'challenge', '挑战'),
('week23', 2, 'reading', 29, '깨닫다', '몰랐던 것을 알게 되다', 'to realize', '领悟，意识到'),
('week23', 2, 'reading', 30, '대하다', '상대방이나 일을 어떤 태도로 다루다', 'to treat, to deal with', '对待'),
('week23', 2, 'reading', 31, '누르다', '(감정을) 억지로 참다', 'to suppress (emotion)', '压抑（感情）'),
('week23', 2, 'reading', 32, '품다', '마음속에 어떤 생각이나 감정을 가지다', 'to hold, to harbor (a dream)', '怀着，心怀'),
('week23', 2, 'reading', 33, '아깝다', '손해나 낭비 같아서 안타깝다', 'to feel it''s a waste/pity', '可惜'),
('week23', 2, 'reading', 34, '단단하다', '(사람의 마음이) 쉽게 흔들리지 않고 강하다', 'to be firm, strong-willed', '（内心）坚强'),
('week23', 2, 'reading', 35, '원동력', '어떤 일을 하게 만드는 힘의 근원', 'driving force', '原动力'),
('week23', 2, 'reading', 36, '여전히', '전과 다름없이 지금도', 'still, as before', '依然，仍然'),
('week23', 2, 'reading', 37, '헛되다', '아무 보람이나 결과가 없다', 'to be in vain', '徒劳'),
('week23', 2, 'reading', 38, '살갗을 에다', '바람이 살을 벨 것처럼 아주 차갑다', 'to cut like a knife (cold wind)', '（风）刺骨'),
('week23', 2, 'reading', 39, '무너지다', '쌓이거나 서 있던 것이 허물어져 내려앉듯이, 마음이 힘을 잃고 크게 흔들리다', 'to break down (emotionally)', '（心理）崩溃'),
('week23', 2, 'reading', 40, '다짐', '마음을 굳게 먹고 스스로 약속함', 'resolve, vow', '决心'),
('week23', 2, 'reading', 41, '무시하다', '어떤 것을 알고 있으면서도 신경 쓰지 않고 그냥 지나치다', 'to ignore (something one is aware of)', '忽视'),
('week23', 2, 'reading', 42, '한없이', '끝이 없이, 아주 많이', 'endlessly', '无限地，非常'),

-- 읽어보기 지문 전문 (30~31쪽 "나의 유학 생활", 6단락) — 타이핑 대상 아님, 어휘를 다 마친 뒤
-- 읽기 전용으로 보여주는 화면(screen-passage)에서만 사용. 어휘 지식만으로는 문장 연결·문법·
-- 흐름까지 이해했다고 보기 어렵다는 점을 고려해, 지문 전체를 한 번 이어서 읽게 하는 단계를
-- 이해도 퀴즈 앞에 추가함(연구자 결정) — gloss/영어/중국어는 필요 없어 비워둠
('week23', 2, 'passage', 1, '365일이 여름인 나라에서 태어나고 성장한 나는 날마다 따뜻한 햇볕 아래에서 행복하게 자랐다. 하루도 빠짐없이 날씨가 맑고 좋았는데, 속상한 일이 있을 때에 한없이 푸르고 따뜻한 날씨를 느끼면 다시 행복해졌다. 계절이나 날씨에 따라 사람들의 심리적인 상태가 달라진다는 것을 책에서 본 적이 있었지만, 항상 여름인 나라에 살던 나는 날씨의 변화가 사람들에게 큰 영향을 준다는 사실이 믿어지지 않았다. 그렇게 자란 나는 스무 살이 되어 혼자 한국으로 유학을 오게 되었다. 처음에는 우리 고향과 한국이 많이 달라서 적응하는 데 시간이 걸렸지만, 나 스스로를 한국에 와서 유학 생활을 할 만큼 성숙한 어른이라고 생각하니 견뎌 낼 수 있었다. 어느 추운 겨울날, 한국의 겨울바람 때문에 내 마음이 무너지게 될 것이라고는 상상조차 하지 못했다.', null, null, null),
('week23', 2, 'passage', 2, '그날, 날씨가 유독 더 추웠다. 미리 준비해 둔 두꺼운 패딩을 꺼내 입고 학교로 갔다. 매섭게 부는 바람은 살갗을 에는 듯했다. 수업이 다 끝난 후에 집으로 혼자 걸어오는 길은 평소보다 더 어두웠다. 아무도 없는 길을 혼자 걷고 있으니 마치 세상에 나 혼자만 존재하는 것 같았다. 찬바람이 더 강하게 불어왔다. 두꺼운 패딩 안의 내 어깨가 몹시 무겁게 느껴졌는데 갑자기 내가 그동안 너무 외롭고 쓸쓸했다는 생각이 들었다. 내가 가는 그 골목길이 내가 알지 못하는 낯선 곳처럼 느껴졌다. 그때 고향에 계신 어머니의 메시지가 도착했다. 그날도 평소와 다름없이 나의 안부를 물어보셨다. "잘 지내니? 괜찮아?" 어머니의 메시지는 항상 같았고 내 답장도 늘 똑같았지만, 그날은 평소와 다르게 눈물을 가득 머금고 답장을 보내드렸다. "괜찮아. 오늘도 잘 지냈어."', null, null, null),
('week23', 2, 'passage', 3, '늘 하던 거짓말이었다. 몸이 좋지 않아도, 학업 때문에 스트레스를 받아도, 무슨 문제가 생겨도 나는 항상 어머니에게 똑같은 답장을 보내드렸다. 서울에 온 후, 바쁜 일상으로 내 감정에 귀 기울이지 못했다. 그리고 ''괜찮아지겠지'' 하며 감정을 무시하는 법을 배웠다. 진심으로 나를 걱정해주는 사람들이 내 걱정을 하지 않았으면 하는 바람으로 내 마음을 속였다. 햇볕을 쬐며 행복해했던 예전의 그 아이가 지금은 낯선 곳에서 홀로 어른이 되어가는 중이라고 생각했다.', null, null, null),
('week23', 2, 'passage', 4, '결국 나는 그 골목길에서 주저앉아 소리 내어 펑펑 울었다. 아무도 없는 조용한 골목길에는 바람 소리와 나의 울음소리만이 가득했다. 한참을 울고 난 후에야 마음이 진정되기 시작했다. 차분히 마음을 가라앉히고 나니 내가 한국에 유학 오는 것이 사실 큰 도전이었다는 것을 깨달았다. 아직은 따뜻한 곳에서 가족과 함께 있고 싶어 하는 내가, 갑자기 한국에 와서 스스로를 어른처럼 대했기 때문에 외롭고 슬픈 마음을 누를 수밖에 없었던 것이다.', null, null, null),
('week23', 2, 'passage', 5, '내 마음을 알게 된 후, 꿈을 이루어 가는 과정이 힘들고 외롭겠지만 유학 생활을 잘 마쳐야겠다고 다짐을 했다. 꿈을 품고 한국에 유학을 온 것이기 때문에 그 도전이 아깝지 않게 지내는 것이 유학 생활의 목표가 되었다. 나는 단단한 사람이기 때문에 차가운 바람에 무너져도 다시 일어설 수 있는 힘을 가지고 있다고 믿는다.', null, null, null),
('week23', 2, 'passage', 6, '몹시 슬프고 외로웠던 그 날이 내가 다시 일어설 수 있는 원동력이 되었다. 지금도 가끔 슬픈 하루들이 여전히 나를 찾아오지만, 골목길에서의 다짐을 기억하며 견뎌 내고 있다. 앞으로도 외롭고 쓸쓸한 마음은 매서운 바람과 함께 나를 찾아올 것이다. 그럴 때마다 나는 주저앉아 펑펑 울다 다시 일어났던 그 골목길의 내 모습을 기억하며 다시 일어설 것이다. 다시 일어서서 내 도전이 헛되지 않도록 걸어 나갈 것이다.', null, null, null),

-- 파트 3. 성찰적 글 수정하기 (5단원, 37~44쪽)
-- 핵심 개념어 (수정 절차·방법과 그 이해에 필요한 최소 개념)
('week23', 3, 'concept', 1, '수정의 절차와 방법', '글을 주제→내용→단락→표현→제목 순서로 점검하고 고치는 방법', 'revision process (topic → content → paragraphs → expression → title order)', '修改的顺序和方法'),
('week23', 3, 'concept', 2, '수정하다', '글의 부족한 부분을 다시 점검하고 고치다', 'to revise, to correct', '修改'),
('week23', 3, 'concept', 3, '초고', '아직 수정하지 않은, 처음 쓴 글', 'first draft', '初稿'),
('week23', 3, 'concept', 4, '동료', '함께 공부하는 같은 반 친구', 'peer, classmate', '同学，同伴'),
('week23', 3, 'concept', 5, '교정 부호', '수정할 부분을 표시하기 위해 약속된 기호', 'proofreading marks (agreed-upon symbols for marking corrections)', '校对符号'),
('week23', 3, 'concept', 6, '조사', '명사 뒤에 붙어 문법적 관계를 나타내는 말 (예: 이/가, 을/를)', 'particle (attaches after a noun to show its grammatical role)', '助词'),
('week23', 3, 'concept', 7, '부사', '동사·형용사·문장의 뜻을 더 자세하게 꾸며 주는 말 (예: 매우, 유독)', 'adverb (modifies a verb, adjective, or sentence)', '副词'),
('week23', 3, 'concept', 8, '주제', '글에서 가장 중심이 되는 생각', 'topic, theme', '主题'),
('week23', 3, 'concept', 9, '내용', '글에 담긴 실제 이야기·정보', 'content', '内容'),
('week23', 3, 'concept', 10, '문법', '문장을 바르게 만드는 규칙', 'grammar', '语法'),
('week23', 3, 'concept', 11, '어휘', '어떤 범위 안에서 쓰이는 단어들, 또는 낱말', 'vocabulary', '词汇'),
('week23', 3, 'concept', 12, '띄어쓰기', '단어와 단어 사이를 띄어서 쓰는 것', 'word spacing', '空格'),
('week23', 3, 'concept', 13, '문장 부호', '마침표·쉼표·물음표처럼 문장의 뜻을 도와주는 부호', 'punctuation mark', '标点符号'),
('week23', 3, 'concept', 14, '범위', '어떤 것이 미치는 한계나 영역', 'scope, range', '范围'),
('week23', 3, 'concept', 15, '순서', '정해진 차례', 'order, sequence', '顺序'),
('week23', 3, 'concept', 16, '분위기', '그 상황에서 느껴지는 전체적인 느낌', 'atmosphere, mood', '氛围'),

-- 부사 연습(42쪽) 어휘 (파트 2 읽어보기 어휘와 동일 5개 — "본문에서 만나기"가 아니라
-- "정확히 골라 쓰기"라는 능동적 사용 목적으로 재수록)
('week23', 3, 'adverb', 1, '펑펑', '눈물을 많이 흘리며 세게 우는 모양', 'heavily, profusely (펑펑 울다: to cry hard / to cry one''s eyes out)', '（펑펑 울다）放声大哭；哭得很厉害'),
('week23', 3, 'adverb', 2, '홀로', '혼자서', 'alone', '独自'),
('week23', 3, 'adverb', 3, '유독', '여럿 중에서 특히 (뒤에 부정적 내용이 오는 경우가 많음)', 'especially, unusually', '格外，尤其'),
('week23', 3, 'adverb', 4, '한없이', '끝이 없이, 아주 많이', 'endlessly', '无限地，非常'),
('week23', 3, 'adverb', 5, '다름없이', '평소와 전혀 다르지 않게', 'just as usual', '和平常一样');

-- 참고: 파트 1·2의 "활동 지시문 어휘" 그룹을 최종적으로 제외하면서 단계 번호가 기존
-- 7단계에서 6단계로 바뀌었습니다 (기존 1=파트1 개념어 그대로, 2=파트1 활동어휘 삭제,
-- 3=파트1 예시어휘→2, 4=파트2 개념어→3, 5=파트2 읽어보기→4, 6=파트3 개념어→5,
-- 7=파트3 부사연습→6). 이미 저장된 진행 기록(week23_progress/week23_records)의 단계
-- 번호를 옮기는 마이그레이션은 **이 파일에 넣지 않고 별도의 1회용 SQL로 분리**했습니다 —
-- 이 위 INSERT 블록은 실행할 때마다 콘텐츠를 delete+재삽입하므로 몇 번을 다시 실행해도
-- 안전해야 하는데, 단계 번호 이동 로직은 반복 실행하면 값이 계속 밀려버려 안전하지 않기
-- 때문입니다. 마이그레이션 SQL은 대화 중 별도로 전달됨 — 그건 딱 한 번만 실행하세요.

-- 5) 내용 이해 문항 채우기 — 파트 2(읽어보기 지문)만 우선 반영. 어휘를 다 알아도 지문
--    전체(문장 연결·문법·담화 흐름)를 이해했다고 보긴 어렵다는 한계를 보완하기 위해 추가함
--    (research-notes.md §5 항목 55, 논문자료/어휘_선정_기록.md §10 참고). 어휘 퀴즈처럼
--    무작위 샘플링하지 않고, 파트당 준비된 문항을 전부 사용한다.
delete from week23_comprehension_questions where unit = 'week23';

insert into week23_comprehension_questions (unit, part, order_num, question_text, correct_answer, distractor_1, distractor_2, distractor_3) values
('week23', 2, 1, '글쓴이가 유학 오기 전에 살던 곳의 날씨는 어땠나?', '1년 내내 여름이었다', '겨울이 아주 길었다', '사계절이 뚜렷했다', '비가 많이 왔다'),
('week23', 2, 2, '글쓴이는 왜 항상 어머니에게 "괜찮다"고 답장했나?', '어머니가 자신을 걱정하지 않기를 바라서', '정말로 아무 문제가 없어서', '한국어로 길게 쓰는 게 힘들어서', '어머니와 사이가 안 좋아서'),
('week23', 2, 3, '글쓴이는 골목길에서 운 후 무엇을 깨달았나?', '한국 유학이 사실 큰 도전이었다는 것', '한국이 자신과 안 맞는다는 것', '고향으로 돌아가야겠다는 것', '더 이상 힘들어하지 않기로 했다는 것'),
('week23', 2, 4, '글쓴이에게 "겨울바람"은 결국 어떤 의미가 되었나?', '다시 일어설 수 있게 하는 원동력', '피하고 싶은 나쁜 기억', '고향을 그립게 하는 계기', '유학을 포기하게 만든 이유');

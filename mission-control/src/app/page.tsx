'use client';

import { FormEvent, useEffect, useMemo, useState } from "react";

type MissionStatus = "진행중" | "완료" | "지연" | "대기";

type MissionPriority = "H" | "M" | "L";
type Task = { id: string; title: string; done: boolean };

type Mission = {
  id: string;
  title: string;
  detail: string;
  due: string;
  owner: string;
  status: MissionStatus;
  priority: MissionPriority;
  tasks: Task[];
  progress: number;
};

const STORAGE_KEY = "mission-control:data:v1";

const DEFAULT_MISSIONS: Mission[] = [
  {
    id: "m-1",
    title: "테크 레벨업",
    detail: "Next.js와 CI 자동화를 활용해 앱 개발 파이프라인을 고도화한다.",
    due: "2026-02-28",
    owner: "준영",
    status: "진행중",
    priority: "H",
    tasks: [
      { id: "t-1", title: "미션 컨트롤 운영형 UI 구현", done: true },
      { id: "t-2", title: "CI 재시도/알림 자동화", done: true },
      { id: "t-3", title: "로컬 호스팅/운영 가이드 정리", done: true },
    ],
    progress: 75,
  },
  {
    id: "m-2",
    title: "재무 자유 준비",
    detail: "주간 예산·투자 포지션·리스크 체크를 한 화면에서 관리한다.",
    due: "2026-03-31",
    owner: "준영",
    status: "진행중",
    priority: "H",
    tasks: [
      { id: "t-4", title: "고정비/변동비 입력 항목 정리", done: true },
      { id: "t-5", title: "월말 투자 검토 체크리스트 작성", done: false },
      { id: "t-6", title: "환율·금리 알림 슬롯 추가", done: false },
    ],
    progress: 52,
  },
  {
    id: "m-3",
    title: "부동산 전환",
    detail: "Hebbal ELT 주변 단지 비교표와 점검 스케줄을 한 화면에서 관리한다.",
    due: "2026-03-15",
    owner: "준영",
    status: "대기",
    priority: "M",
    tasks: [
      { id: "t-7", title: "세대별 임대료/관리비 비교표 갱신", done: false },
      { id: "t-8", title: "현장 방문 일정 배정", done: false },
      { id: "t-9", title: "합리적 입주 조건 체크", done: false },
    ],
    progress: 38,
  },
];

const priorityLabel: Record<MissionPriority, string> = {
  H: "높음",
  M: "보통",
  L: "낮음",
};

function uid(prefix: string) {
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;
}

function clamp(num: number, min = 0, max = 100) {
  return Math.min(max, Math.max(min, num));
}

function progressFromTasks(tasks: Task[]) {
  if (tasks.length === 0) return 0;
  return Math.round((tasks.filter((x) => x.done).length / tasks.length) * 100);
}

export default function Home() {
  const [missions, setMissions] = useState<Mission[]>(DEFAULT_MISSIONS);
  const [todayFocus, setTodayFocus] = useState("");
  const [focusLog, setFocusLog] = useState("");
  const [form, setForm] = useState({
    title: "",
    detail: "",
    due: new Date().toISOString().slice(0, 10),
    owner: "준영",
    priority: "M" as MissionPriority,
  });

  useEffect(() => {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    try {
      const parsed = JSON.parse(raw) as {
        missions: Mission[];
        todayFocus: string;
        focusLog: string;
      };
      if (Array.isArray(parsed.missions)) {
        setMissions(parsed.missions);
      }
      setTodayFocus(parsed.todayFocus || "");
      setFocusLog(parsed.focusLog || "");
    } catch {
      // ignore parse errors and keep defaults
    }
  }, []);

  useEffect(() => {
    const payload = { missions, todayFocus, focusLog };
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  }, [missions, todayFocus, focusLog]);

  const summary = useMemo(() => {
    const total = missions.length;
    const completed = missions.filter((m) => m.status === "완료").length;
    const inProgress = missions.filter((m) => m.status === "진행중").length;
    const avg = total === 0 ? 0 : Math.round(missions.reduce((acc, m) => acc + m.progress, 0) / total);
    const overdue = missions.filter((m) => new Date(m.due) < new Date()).length;
    return { total, completed, inProgress, avg, overdue };
  }, [missions]);

  function saveMissionProgress(id: string, progress: number) {
    const clamped = clamp(progress);
    setMissions((prev) => prev.map((m) => (m.id === id ? { ...m, progress: clamped } : m)));
  }

  function toggleTask(mid: string, tid: string) {
    setMissions((prev) =>
      prev.map((m) => {
        if (m.id !== mid) return m;
        const tasks = m.tasks.map((t) => (t.id === tid ? { ...t, done: !t.done } : t));
        return { ...m, tasks, progress: progressFromTasks(tasks) };
      }),
    );
  }

  function updateStatus(id: string, status: MissionStatus) {
    setMissions((prev) => prev.map((m) => (m.id === id ? { ...m, status } : m)));
  }

  function addMission(e: FormEvent) {
    e.preventDefault();
    if (!form.title.trim() || !form.detail.trim() || !form.due) return;

    const mission: Mission = {
      id: uid("m"),
      title: form.title.trim(),
      detail: form.detail.trim(),
      due: form.due,
      owner: form.owner.trim() || "준영",
      priority: form.priority,
      status: "진행중",
      tasks: [],
      progress: 0,
    };
    setMissions((prev) => [...prev, mission]);
    setForm((f) => ({ ...f, title: "", detail: "" }));
  }

  function addTask(mid: string) {
    const title = window.prompt("새 체크리스트 항목");
    if (!title?.trim()) return;

    setMissions((prev) =>
      prev.map((m) => {
        if (m.id !== mid) return m;
        const tasks = [...m.tasks, { id: uid("t"), title: title.trim(), done: false }];
        return { ...m, tasks, progress: progressFromTasks(tasks) };
      }),
    );
  }

  function removeMission(id: string) {
    setMissions((prev) => prev.filter((m) => m.id !== id));
  }

  function resetStorage() {
    if (!window.confirm("로컬 저장 데이터를 초기화할까요?")) return;
    window.localStorage.removeItem(STORAGE_KEY);
    setMissions(DEFAULT_MISSIONS);
    setTodayFocus("");
    setFocusLog("");
  }

  return (
    <main className="container">
      <section className="header">
        <p className="kicker">Mission Control</p>
        <h1>준영님 개인 미션 컨트롤 (운영판)</h1>
        <p className="sub">Next.js + localStorage 기반으로 바로 쓸 수 있는 운영형 미션 보드</p>
      </section>

      <section className="summary">
        <article>
          <h2>미션 현황</h2>
          <p>
            총 {summary.total}개 · 완료 {summary.completed}개 · 진행 {summary.inProgress}개
          </p>
          <p>평균 진행률: {summary.avg}%</p>
        </article>
        <article>
          <h2>알림</h2>
          <p>마감 임박/초과: {summary.overdue}개</p>
          <p>데이터 보관: 브라우저 로컬스토리지</p>
        </article>
        <article>
          <h2>오늘 한 줄</h2>
          <textarea
            value={todayFocus}
            onChange={(e) => setTodayFocus(e.target.value)}
            placeholder="예: 오늘은 Hebbal 부동산 비교표 정리"
          />
          <button className="ghost" onClick={() => setFocusLog(todayFocus)}>
            메모 저장
          </button>
          {focusLog && <p className="muted">최근 메모: {focusLog}</p>}
        </article>
      </section>

      <section className="panel">
        <h2>미션 등록</h2>
        <form onSubmit={addMission} className="formRow">
          <input
            required
            placeholder="미션 제목"
            value={form.title}
            onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
          />
          <input
            required
            placeholder="목표/상세"
            value={form.detail}
            onChange={(e) => setForm((f) => ({ ...f, detail: e.target.value }))}
          />
          <input
            required
            type="date"
            value={form.due}
            onChange={(e) => setForm((f) => ({ ...f, due: e.target.value }))}
          />
          <select
            value={form.priority}
            onChange={(e) => setForm((f) => ({ ...f, priority: e.target.value as MissionPriority }))}
          >
            <option value="H">높음</option>
            <option value="M">보통</option>
            <option value="L">낮음</option>
          </select>
          <button type="submit">등록</button>
        </form>
      </section>

      <section className="grid">
        {missions.map((mission) => (
          <article key={mission.id} className="card">
            <div className="card-head">
              <h3>
                {mission.title}
                <span className="muted"> • {mission.owner}</span>
              </h3>
              <span className={`status ${mission.status}`}>{mission.status}</span>
            </div>
            <p className="muted">
              우선순위: {priorityLabel[mission.priority]} · 마감: {mission.due}
            </p>
            <p>{mission.detail}</p>

            <div className="barWrap">
              <div className="bar" style={{ width: `${mission.progress}%` }} />
            </div>
            <div className="row">
              <span>진행률 {mission.progress}%</span>
              <span>{new Date(mission.due) < new Date() ? "지연" : "정상"}</span>
            </div>

            <div className="taskWrap">
              <h4>체크리스트</h4>
              {mission.tasks.length === 0 ? (
                <p className="muted">항목 없음</p>
              ) : (
                mission.tasks.map((t) => (
                  <label key={t.id} className="taskItem">
                    <input
                      type="checkbox"
                      checked={t.done}
                      onChange={() => toggleTask(mission.id, t.id)}
                    />
                    <span className={t.done ? "done" : ""}>{t.title}</span>
                  </label>
                ))
              )}
              <button type="button" onClick={() => addTask(mission.id)}>
                + 체크리스트 추가
              </button>
            </div>

            <div className="row">
              <select
                value={mission.status}
                onChange={(e) => updateStatus(mission.id, e.target.value as MissionStatus)}
              >
                <option value="진행중">진행중</option>
                <option value="완료">완료</option>
                <option value="지연">지연</option>
                <option value="대기">대기</option>
              </select>
              <div className="inline">
                <input
                  type="range"
                  min={0}
                  max={100}
                  value={mission.progress}
                  onChange={(e) => saveMissionProgress(mission.id, Number(e.target.value))}
                />
                <button type="button" onClick={() => removeMission(mission.id)} className="danger">
                  삭제
                </button>
              </div>
            </div>
          </article>
        ))}
      </section>

      <div className="footerActions">
        <button className="danger" onClick={resetStorage}>
          로컬 데이터 초기화
        </button>
      </div>
    </main>
  );
}

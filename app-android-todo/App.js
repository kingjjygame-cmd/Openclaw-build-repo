import React, { useMemo, useState } from 'react';
import {
  SafeAreaView,
  View,
  Text,
  TextInput,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from 'react-native';

const PRIORITY = {
  high: '높음',
  mid: '보통',
  low: '낮음',
};

const priorityOrder = { high: 0, mid: 1, low: 2 };

export default function App() {
  const [title, setTitle] = useState('');
  const [priority, setPriority] = useState('mid');
  const [due, setDue] = useState('');
  const [search, setSearch] = useState('');
  const [onlyOpen, setOnlyOpen] = useState(false);
  const [todos, setTodos] = useState([]);

  const nextId = useMemo(() => `${Date.now()}_${Math.random().toString(36).slice(2, 7)}`, [todos]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return todos
      .filter((t) => !q || t.title.toLowerCase().includes(q) || t.note.toLowerCase().includes(q))
      .filter((t) => !onlyOpen || !t.done)
      .sort((a, b) => {
        if (priorityOrder[a.priority] !== priorityOrder[b.priority]) {
          return priorityOrder[a.priority] - priorityOrder[b.priority];
        }
        return new Date(a.dueDate) - new Date(b.dueDate);
      });
  }, [todos, search, onlyOpen]);

  const isDueOver = (d) => {
    const n = new Date(d).setHours(0, 0, 0, 0);
    const t = new Date().setHours(0, 0, 0, 0);
    return n < t;
  };

  const addTodo = () => {
    const t = title.trim();
    if (!t) {
      Alert.alert('입력 오류', '할일 제목을 입력해 주세요.');
      return;
    }

    const newTodo = {
      id: nextId,
      title: t,
      note: '',
      priority,
      dueDate: due || new Date().toISOString().slice(0, 10),
      done: false,
      createdAt: new Date().toISOString(),
    };

    setTodos((prev) => [newTodo, ...prev]);
    setTitle('');
    setDue('');
    setPriority('mid');
  };

  const toggleDone = (id) => {
    setTodos((prev) => prev.map((t) => (t.id === id ? { ...t, done: !t.done } : t)));
  };

  const removeTodo = (id) => {
    Alert.alert('삭제', '정말 삭제하시겠어요?', [
      { text: '취소', style: 'cancel' },
      {
        text: '삭제',
        style: 'destructive',
        onPress: () => {
          setTodos((prev) => prev.filter((t) => t.id !== id));
        },
      },
    ]);
  };

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>간단 할일 앱 (Android)</Text>

      <View style={styles.card}>
        <TextInput
          style={styles.input}
          placeholder="할일 제목"
          value={title}
          onChangeText={setTitle}
          placeholderTextColor="#8f9bb3"
        />

        <View style={styles.row}>
          <TextInput
            style={[styles.input, { flex: 1 }]}
            placeholder="마감일(예: 2026-02-28)"
            value={due}
            onChangeText={setDue}
            placeholderTextColor="#8f9bb3"
          />
          <View style={styles.pills}>
            {Object.entries(PRIORITY).map(([k, label]) => {
              const active = k === priority;
              return (
                <TouchableOpacity
                  key={k}
                  style={[styles.pill, active && styles.pillActive]}
                  onPress={() => setPriority(k)}
                >
                  <Text style={[styles.pillText, active && styles.pillTextActive]}>{label}</Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        <TouchableOpacity onPress={addTodo} style={styles.primaryBtn}>
          <Text style={styles.primaryBtnText}>추가하기</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.filterRow}>
        <TextInput
          style={styles.input}
          placeholder="검색"
          value={search}
          onChangeText={setSearch}
          placeholderTextColor="#8f9bb3"
        />
        <TouchableOpacity
          style={[styles.toggleBtn, onlyOpen && styles.toggleBtnActive]}
          onPress={() => setOnlyOpen((s) => !s)}
        >
          <Text style={styles.toggleText}>{onlyOpen ? '미완료만 보기' : '전체 보기'}</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ paddingBottom: 30 }}
        renderItem={({ item }) => (
          <View style={styles.todoItem}>
            <TouchableOpacity onPress={() => toggleDone(item.id)} style={styles.checkWrap}>
              <Text style={styles.check}>{item.done ? '✅' : '⬜'}</Text>
            </TouchableOpacity>
            <View style={{ flex: 1 }}>
              <Text style={[styles.todoTitle, item.done && styles.todoDone]}>{item.title}</Text>
              <Text style={styles.todoSub}>
                우선순위: {PRIORITY[item.priority]} / 마감: {item.dueDate}{' '}
                {isDueOver(item.dueDate) && !item.done ? '⚠ 마감 초과' : ''}
              </Text>
            </View>
            <TouchableOpacity onPress={() => removeTodo(item.id)}>
              <Text style={styles.delete}>삭제</Text>
            </TouchableOpacity>
          </View>
        )}
        ListEmptyComponent={<Text style={styles.empty}>할일이 없어요. 추가해보세요.</Text>}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0f172a',
    padding: 16,
  },
  title: { color: '#f8fafc', fontSize: 22, fontWeight: '700', marginBottom: 10 },
  card: {
    backgroundColor: '#111827',
    borderRadius: 14,
    padding: 12,
    gap: 10,
    marginBottom: 12,
  },
  input: {
    backgroundColor: '#1f2937',
    color: '#f1f5f9',
    borderRadius: 10,
    padding: 10,
  },
  row: { gap: 8 },
  pills: { flexDirection: 'row', gap: 8, marginTop: 4 },
  pill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: '#334155',
  },
  pillActive: { backgroundColor: '#2563eb', borderColor: '#2563eb' },
  pillText: { color: '#94a3b8', fontWeight: '600' },
  pillTextActive: { color: '#e2e8f0' },
  primaryBtn: {
    backgroundColor: '#0284c7',
    borderRadius: 10,
    alignItems: 'center',
    padding: 12,
  },
  primaryBtnText: { color: '#fff', fontWeight: '700' },
  filterRow: { gap: 8, marginBottom: 8 },
  toggleBtn: {
    backgroundColor: '#334155',
    padding: 8,
    borderRadius: 10,
    alignItems: 'center',
  },
  toggleBtnActive: { backgroundColor: '#0369a1' },
  toggleText: { color: '#e2e8f0', fontWeight: '700' },
  todoItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: '#111827',
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
  },
  checkWrap: { padding: 6 },
  check: { fontSize: 18 },
  todoTitle: { color: '#e2e8f0', fontSize: 16, fontWeight: '700' },
  todoDone: { textDecorationLine: 'line-through', color: '#64748b' },
  todoSub: { color: '#94a3b8', marginTop: 3, fontSize: 12 },
  delete: { color: '#f87171', fontWeight: '700' },
  empty: { color: '#94a3b8', textAlign: 'center', marginTop: 24 },
});

import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useState } from 'react';

export default function App() {
  const [count, setCount] = useState(0);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Hello World!</Text>
      <Text style={styles.subtitle}>OpenClaw Android Starter</Text>

      <View style={styles.counterWrap}>
        <Pressable
          onPress={() => setCount((prev) => prev - 1)}
          style={({ pressed }) => [styles.btn, pressed && styles.btnPressed]}
        >
          <Text style={styles.btnText}>－</Text>
        </Pressable>

        <Text style={styles.counterText}>{count}</Text>

        <Pressable
          onPress={() => setCount((prev) => prev + 1)}
          style={({ pressed }) => [styles.btn, pressed && styles.btnPressed]}
        >
          <Text style={styles.btnText}>＋</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 34,
    fontWeight: '700',
    color: '#0f172a',
    marginBottom: 6,
  },
  subtitle: {
    fontSize: 16,
    color: '#475569',
  },
  counterWrap: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 140,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
  },
  counterText: {
    fontSize: 42,
    color: '#0f172a',
    fontWeight: '700',
    minWidth: 72,
    textAlign: 'center',
  },
  btn: {
    width: 54,
    height: 54,
    borderRadius: 27,
    backgroundColor: '#2563eb',
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 5,
  },
  btnPressed: {
    backgroundColor: '#1d4ed8',
    transform: [{ scale: 0.96 }],
  },
  btnText: {
    fontSize: 34,
    color: '#fff',
    fontWeight: '700',
    lineHeight: 36,
  },
});
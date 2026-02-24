import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useState } from 'react';

export default function App() {
  const [count, setCount] = useState(0);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Hello World!</Text>
      <Text style={styles.subtitle}>OpenClaw Android Starter</Text>

      <View style={styles.fabWrap}>
        <Pressable
          onPress={() => setCount((prev) => prev + 1)}
          style={({ pressed }) => [
            styles.fab,
            pressed && styles.fabPressed,
          ]}
        >
          <Text style={styles.fabText}>{count}</Text>
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
  fabWrap: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 30,
    alignItems: 'center',
  },
  fab: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#2563eb',
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 6,
  },
  fabPressed: {
    backgroundColor: '#1d4ed8',
    transform: [{ scale: 0.96 }],
  },
  fabText: {
    fontSize: 26,
    color: '#fff',
    fontWeight: '700',
  },
});
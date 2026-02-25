import { Pressable, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { useCallback, useEffect, useRef, useState } from 'react';

const BUTTON_SIZE = 96;
const EDGE_PADDING = 24;

export default function App() {
  const { width, height } = useWindowDimensions();
  const [count, setCount] = useState(0);
  const [reaction, setReaction] = useState('');
  const [position, setPosition] = useState({ x: 0, y: 0 });

  const timerRef = useRef(null);
  const reactionRef = useRef(null);

  const clearTimers = () => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    if (reactionRef.current) {
      clearTimeout(reactionRef.current);
      reactionRef.current = null;
    }
  };

  const spawnButton = useCallback(() => {
    if (width <= 0 || height <= 0) {
      return;
    }

    const maxX = Math.max(EDGE_PADDING, width - BUTTON_SIZE - EDGE_PADDING);
    const maxY = Math.max(EDGE_PADDING + 90, height - BUTTON_SIZE - EDGE_PADDING);

    setPosition({
      x: Math.floor(EDGE_PADDING + Math.random() * Math.max(1, maxX - EDGE_PADDING)),
      y: Math.floor(EDGE_PADDING + Math.random() * Math.max(1, maxY - (EDGE_PADDING + 90))),
    });

    clearTimers();
    timerRef.current = setTimeout(() => {
      setReaction('놓침!');
      reactionRef.current = setTimeout(spawnButton, 120);
    }, 1000);
  }, [clearTimers, height, width]);

  const flashReaction = useCallback((text) => {
    setReaction(text);
    if (reactionRef.current) {
      clearTimeout(reactionRef.current);
    }
    reactionRef.current = setTimeout(() => setReaction(''), 280);
  }, []);

  const onPressButton = () => {
    clearTimers();
    setCount((prev) => prev + 1);
    flashReaction('좋아요!');
    spawnButton();
  };

  useEffect(() => {
    spawnButton();
    return () => {
      clearTimers();
    };
  }, [spawnButton, clearTimers]);

  return (
    <View style={styles.container}>
      <Text style={styles.counter}>🧸 {count}</Text>

      {reaction ? <Text style={styles.reaction}>{reaction}</Text> : null}

      <Pressable
        onPress={onPressButton}
        style={({ pressed }) => [
          styles.button,
          { left: position.x, top: position.y },
          pressed && styles.buttonPressed,
        ]}
      >
        <Text style={styles.buttonText}>START</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fbff',
  },
  counter: {
    position: 'absolute',
    top: 38,
    left: 0,
    right: 0,
    textAlign: 'center',
    fontSize: 62,
    fontWeight: '900',
    color: '#0f172a',
  },
  reaction: {
    position: 'absolute',
    top: 108,
    left: 0,
    right: 0,
    textAlign: 'center',
    fontSize: 26,
    color: '#0f6cff',
    fontWeight: '700',
  },
  button: {
    width: BUTTON_SIZE,
    height: BUTTON_SIZE,
    borderRadius: BUTTON_SIZE / 2,
    backgroundColor: '#ff7a59',
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 8,
    borderWidth: 4,
    borderColor: 'rgba(255,255,255,0.85)',
  },
  buttonPressed: {
    transform: [{ scale: 0.92 }],
    backgroundColor: '#ff996c',
  },
  buttonText: {
    color: '#fff',
    fontWeight: '800',
    fontSize: 24,
  },
});
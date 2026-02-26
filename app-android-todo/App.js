import { Pressable, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { useEffect, useRef, useState } from 'react';

const BUTTON_SIZE = 96;
const EDGE_PADDING = 24;
const MOVE_DELAY_MS = 1_000; // fixed at 1 second
const APP_REV = 'tap-dwell-v3';

export default function App() {
  const { width, height } = useWindowDimensions();
  const [count, setCount] = useState(0);
  const [reaction, setReaction] = useState('');
  const [position, setPosition] = useState({ x: 0, y: 0 });

  const moveTimerRef = useRef(null);
  const reactionTimerRef = useRef(null);
  const sizeRef = useRef({ width, height });

  useEffect(() => {
    sizeRef.current = { width, height };
  }, [width, height]);

  const clearMoveTimer = () => {
    if (moveTimerRef.current) {
      clearTimeout(moveTimerRef.current);
      moveTimerRef.current = null;
    }
  };

  const clearReactionTimer = () => {
    if (reactionTimerRef.current) {
      clearTimeout(reactionTimerRef.current);
      reactionTimerRef.current = null;
    }
  };

  const showReaction = (text) => {
    clearReactionTimer();
    setReaction(text);
    reactionTimerRef.current = setTimeout(() => {
      setReaction('');
    }, 300);
  };

  const moveButton = () => {
    const { width: w, height: h } = sizeRef.current;
    if (w <= 0 || h <= 0) {
      return;
    }

    const maxX = Math.max(EDGE_PADDING, w - BUTTON_SIZE - EDGE_PADDING);
    const maxY = Math.max(EDGE_PADDING + 100, h - BUTTON_SIZE - EDGE_PADDING);

    setPosition({
      x: Math.floor(EDGE_PADDING + Math.random() * Math.max(0, maxX - EDGE_PADDING)),
      y: Math.floor(EDGE_PADDING + 100 + Math.random() * Math.max(0, maxY - (EDGE_PADDING + 100))),
    });
  };

  const scheduleMove = () => {
    clearMoveTimer();
    moveTimerRef.current = setTimeout(() => {
      showReaction('놓침!');
      moveButton();
      scheduleMove();
    }, MOVE_DELAY_MS);
  };

  const handlePress = () => {
    setCount((prev) => prev + 1);
    showReaction('좋아요!');
  };

  useEffect(() => {
    moveButton();
    scheduleMove();

    return () => {
      clearMoveTimer();
      clearReactionTimer();
    };
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.revision}>rev: {APP_REV}</Text>
      <Text style={styles.counter}>🧸 {count}</Text>
      <Text style={styles.hint}>이동 간격: {MOVE_DELAY_MS}ms</Text>

      {reaction ? <Text style={styles.reaction}>{reaction}</Text> : null}

      <Pressable
        onPress={handlePress}
        style={({ pressed }) => [
          styles.button,
          { left: position.x, top: position.y },
          pressed && styles.buttonPressed,
        ]}
      >
        <Text style={styles.buttonText}>TAP</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fbff',
  },
  revision: {
    position: 'absolute',
    top: 12,
    left: 0,
    right: 0,
    textAlign: 'center',
    fontSize: 12,
    color: '#64748b',
    fontWeight: '700',
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
  hint: {
    position: 'absolute',
    top: 112,
    left: 0,
    right: 0,
    textAlign: 'center',
    fontSize: 16,
    color: '#334155',
    fontWeight: '600',
  },
  reaction: {
    position: 'absolute',
    top: 140,
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
    fontSize: 22,
  },
});

import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useState } from 'react';

export default function App() {
  const [count, setCount] = useState(0);
  const [moved, setMoved] = useState(false);

  const handlePress = () => {
    setCount((prev) => prev + 1);
    setMoved((prev) => !prev);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.counter}>{count}</Text>

      <Pressable
        onPress={handlePress}
        style={({ pressed }) => [
          styles.button,
          moved ? styles.buttonPosBottom : styles.buttonPosTop,
          pressed && styles.buttonPressed,
        ]}
      >
        <Text style={styles.buttonText}>터치</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  counter: {
    position: 'absolute',
    top: 40,
    left: 0,
    right: 0,
    textAlign: 'center',
    fontSize: 46,
    fontWeight: '700',
    color: '#0f172a',
  },
  button: {
    width: 130,
    height: 54,
    borderRadius: 27,
    backgroundColor: '#2563eb',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'absolute',
    left: '50%',
    transform: [{ translateX: -65 }],
    elevation: 6,
  },
  buttonPosTop: {
    top: 220,
  },
  buttonPosBottom: {
    bottom: 220,
  },
  buttonPressed: {
    backgroundColor: '#1d4ed8',
    transform: [{ translateX: -65 }, { scale: 0.96 }],
  },
  buttonText: {
    fontSize: 22,
    color: '#fff',
    fontWeight: '700',
  },
});
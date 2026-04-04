import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  Keyboard,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TouchableWithoutFeedback,
  View,
  useColorScheme,
} from "react-native";
import * as Haptics from "expo-haptics";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { sendFeedback } from "./FeedbackService";

// FeedbackSheet
// A modal with a feedback text field,
// send button with cooldown, and character counter.

const MAX_CHARACTERS = 2000;
const COOLDOWN_DURATION = 60;
const COOLDOWN_KEY = "feedpush_last_send_timestamp";

interface FeedbackSheetProps {
  visible: boolean;
  onDismiss: () => void;
  feedbackPlaceholder?: string;
  sendButtonText?: string;
  successMessage?: string;
  errorMessage?: string;
}

export function FeedbackSheet({
  visible,
  onDismiss,
  feedbackPlaceholder = "What's on your mind?",
  sendButtonText = "Send",
  successMessage = "Thank you for your feedback!",
  errorMessage = "Could not send feedback. Please check your connection and try again.",
}: FeedbackSheetProps) {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  const [feedbackText, setFeedbackText] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [showError, setShowError] = useState(false);
  const [cooldownRemaining, setCooldownRemaining] = useState(0);
  const cooldownRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const isSendDisabled =
    feedbackText.trim().length === 0 ||
    feedbackText.length > MAX_CHARACTERS ||
    isSending ||
    cooldownRemaining > 0;

  // Check existing cooldown on mount
  useEffect(() => {
    if (!visible) return;

    AsyncStorage.getItem(COOLDOWN_KEY).then((value) => {
      if (!value) return;
      const lastSend = parseInt(value, 10);
      const elapsed = Math.floor(Date.now() / 1000) - lastSend;
      const remaining = COOLDOWN_DURATION - elapsed;
      if (remaining > 0) {
        setCooldownRemaining(remaining);
        startCooldownTimer(remaining);
      }
    });

    return () => {
      if (cooldownRef.current) clearInterval(cooldownRef.current);
    };
  }, [visible]);

  const startCooldownTimer = useCallback((initial: number) => {
    if (cooldownRef.current) clearInterval(cooldownRef.current);
    let remaining = initial;
    cooldownRef.current = setInterval(() => {
      remaining -= 1;
      if (remaining <= 0) {
        setCooldownRemaining(0);
        if (cooldownRef.current) clearInterval(cooldownRef.current);
      } else {
        setCooldownRemaining(remaining);
      }
    }, 1000);
  }, []);

  const handleSend = useCallback(async () => {
    Keyboard.dismiss();
    setIsSending(true);
    setShowError(false);

    const result = await sendFeedback(feedbackText);

    if (result.success) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      setShowSuccess(true);

      const now = Math.floor(Date.now() / 1000).toString();
      await AsyncStorage.setItem(COOLDOWN_KEY, now);
      setCooldownRemaining(COOLDOWN_DURATION);
      startCooldownTimer(COOLDOWN_DURATION);

      setFeedbackText("");

      setTimeout(() => {
        setShowSuccess(false);
        onDismiss();
      }, 2000);
    } else {
      setShowError(true);
    }

    setIsSending(false);
  }, [feedbackText, onDismiss, startCooldownTimer]);

  const handleDismiss = useCallback(() => {
    setShowSuccess(false);
    setShowError(false);
    onDismiss();
  }, [onDismiss]);

  const bg = isDark ? "#1c1c1e" : "#ffffff";
  const inputBg = isDark ? "#2c2c2e" : "#f2f2f7";
  const textColor = isDark ? "#ffffff" : "#000000";
  const dimColor = isDark ? "#8e8e93" : "#6c6c70";
  const accentColor = "#007AFF";

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleDismiss}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <KeyboardAvoidingView
          style={[styles.container, { backgroundColor: bg }]}
          behavior={Platform.OS === "ios" ? "padding" : undefined}
        >
          {/* Header */}
          <View style={styles.header}>
            <Text style={[styles.headerTitle, { color: textColor }]}>
              Feedback
            </Text>
            <Pressable onPress={handleDismiss} hitSlop={8}>
              <Text style={[styles.closeButton, { color: dimColor }]}>
                {"\u2715"}
              </Text>
            </Pressable>
          </View>

          {/* Feedback text field */}
          <TextInput
            style={[
              styles.feedbackInput,
              {
                backgroundColor: inputBg,
                color: textColor,
              },
            ]}
            placeholder={feedbackPlaceholder}
            placeholderTextColor={dimColor}
            value={feedbackText}
            onChangeText={(t) => {
              if (t.length <= MAX_CHARACTERS) setFeedbackText(t);
            }}
            multiline
            textAlignVertical="top"
          />

          {/* Character counter */}
          <Text
            style={[
              styles.counter,
              {
                color:
                  feedbackText.length > MAX_CHARACTERS ? "#FF3B30" : dimColor,
              },
            ]}
          >
            {feedbackText.length} / {MAX_CHARACTERS}
          </Text>

          {/* Send button */}
          <Pressable
            onPress={handleSend}
            disabled={isSendDisabled}
            style={[
              styles.sendButton,
              {
                backgroundColor: isSendDisabled ? dimColor : accentColor,
              },
            ]}
          >
            {isSending ? (
              <ActivityIndicator color="#ffffff" size="small" />
            ) : (
              <Text style={styles.sendButtonText}>
                {cooldownRemaining > 0
                  ? `${sendButtonText} (${cooldownRemaining}s)`
                  : sendButtonText}
              </Text>
            )}
          </Pressable>

          {/* Error message */}
          {showError && (
            <Text style={styles.errorText}>{errorMessage}</Text>
          )}

          {/* Success overlay */}
          {showSuccess && (
            <View style={styles.successOverlay}>
              <View
                style={[
                  styles.successCard,
                  { backgroundColor: bg },
                ]}
              >
                <Text style={styles.successIcon}>{"\u2705"}</Text>
                <Text style={[styles.successText, { color: textColor }]}>
                  {successMessage}
                </Text>
              </View>
            </View>
          )}
        </KeyboardAvoidingView>
      </TouchableWithoutFeedback>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    paddingTop: 16,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 16,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: "700",
  },
  closeButton: {
    fontSize: 18,
    padding: 4,
  },
  feedbackInput: {
    minHeight: 120,
    borderRadius: 12,
    padding: 14,
    fontSize: 16,
    lineHeight: 22,
  },
  counter: {
    fontSize: 12,
    textAlign: "right",
    marginTop: 4,
    marginBottom: 24,
  },
  sendButton: {
    borderRadius: 14,
    padding: 16,
    alignItems: "center",
    justifyContent: "center",
  },
  sendButtonText: {
    color: "#ffffff",
    fontSize: 16,
    fontWeight: "600",
  },
  errorText: {
    color: "#FF3B30",
    fontSize: 13,
    textAlign: "center",
    marginTop: 12,
  },
  successOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.3)",
  },
  successCard: {
    padding: 32,
    borderRadius: 20,
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 20,
    elevation: 8,
  },
  successIcon: {
    fontSize: 48,
    marginBottom: 12,
  },
  successText: {
    fontSize: 16,
    fontWeight: "700",
    textAlign: "center",
  },
});

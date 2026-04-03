import React, { useState } from "react";
import {
  Pressable,
  StyleSheet,
  Text,
  View,
  useColorScheme,
} from "react-native";
import { FeedbackSheet } from "./FeedbackSheet";

// FeedbackButton
// A card-style button that opens the feedback sheet when tapped.
// Configurable text and icon -- pass your own strings to localize or customize.

interface FeedbackButtonProps {
  icon?: string;
  title?: string;
  subtitle?: string;
  // Pass-through to FeedbackSheet
  feedbackPlaceholder?: string;
  emailPlaceholder?: string;
  sendButtonText?: string;
  successMessage?: string;
  errorMessage?: string;
}

export function FeedbackButton({
  icon = "\u{1F4A1}",
  title = "Have suggestions?",
  subtitle = "Share your ideas with us",
  feedbackPlaceholder,
  emailPlaceholder,
  sendButtonText,
  successMessage,
  errorMessage,
}: FeedbackButtonProps) {
  const [showSheet, setShowSheet] = useState(false);
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  return (
    <>
      <Pressable
        onPress={() => setShowSheet(true)}
        style={({ pressed }) => [
          styles.card,
          {
            backgroundColor: isDark ? "#1c1c1e" : "#ffffff",
            opacity: pressed ? 0.7 : 1,
          },
        ]}
      >
        <Text style={styles.icon}>{icon}</Text>
        <View style={styles.textContainer}>
          <Text
            style={[
              styles.title,
              { color: isDark ? "#ffffff" : "#000000" },
            ]}
          >
            {title}
          </Text>
          <Text
            style={[
              styles.subtitle,
              { color: isDark ? "#8e8e93" : "#6c6c70" },
            ]}
          >
            {subtitle}
          </Text>
        </View>
        <Text
          style={[
            styles.arrow,
            { color: isDark ? "#8e8e93" : "#6c6c70" },
          ]}
        >
          {"\u203A"}
        </Text>
      </Pressable>

      <FeedbackSheet
        visible={showSheet}
        onDismiss={() => setShowSheet(false)}
        feedbackPlaceholder={feedbackPlaceholder}
        emailPlaceholder={emailPlaceholder}
        sendButtonText={sendButtonText}
        successMessage={successMessage}
        errorMessage={errorMessage}
      />
    </>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: "row",
    alignItems: "center",
    padding: 20,
    borderRadius: 16,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 2,
  },
  icon: {
    fontSize: 24,
  },
  textContainer: {
    flex: 1,
    marginLeft: 12,
    gap: 2,
  },
  title: {
    fontSize: 16,
    fontWeight: "600",
  },
  subtitle: {
    fontSize: 13,
  },
  arrow: {
    fontSize: 22,
    fontWeight: "300",
  },
});

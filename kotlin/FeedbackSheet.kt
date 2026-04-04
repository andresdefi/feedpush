package com.feedpush

import android.view.HapticFeedbackConstants
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// MARK: FeedbackSheet
// A modal bottom sheet with a feedback text field,
// send button with cooldown, and character counter.

private const val MAX_CHARACTERS = 2000
private const val COOLDOWN_DURATION = 60
private const val COOLDOWN_KEY = "feedpush_last_send_timestamp"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedbackSheet(
    onDismiss: () -> Unit,
    feedbackPlaceholder: String = "What's on your mind?",
    sendButtonText: String = "Send",
    successMessage: String = "Thank you for your feedback!",
    errorMessage: String = "Could not send feedback. Please check your connection and try again."
) {
    val context = LocalContext.current
    val view = LocalView.current
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var feedbackText by remember { mutableStateOf("") }
    var isSending by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    var showError by remember { mutableStateOf(false) }
    var cooldownRemaining by remember { mutableIntStateOf(0) }

    val prefs = remember { context.getSharedPreferences("feedpush", android.content.Context.MODE_PRIVATE) }

    val isSendDisabled = feedbackText.trim().isEmpty()
            || feedbackText.length > MAX_CHARACTERS
            || isSending
            || cooldownRemaining > 0

    // Check existing cooldown on appear
    LaunchedEffect(Unit) {
        val lastSend = prefs.getLong(COOLDOWN_KEY, 0L)
        if (lastSend > 0) {
            val elapsed = ((System.currentTimeMillis() - lastSend) / 1000).toInt()
            val remaining = COOLDOWN_DURATION - elapsed
            if (remaining > 0) {
                cooldownRemaining = remaining
            }
        }
    }

    // Cooldown timer
    LaunchedEffect(cooldownRemaining) {
        if (cooldownRemaining > 0) {
            delay(1000)
            cooldownRemaining -= 1
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Box(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 32.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Feedback",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close"
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Feedback text field
                OutlinedTextField(
                    value = feedbackText,
                    onValueChange = { if (it.length <= MAX_CHARACTERS) feedbackText = it },
                    placeholder = { Text(feedbackPlaceholder) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(150.dp),
                    shape = RoundedCornerShape(12.dp)
                )

                // Character counter
                Text(
                    text = "${feedbackText.length} / $MAX_CHARACTERS",
                    fontSize = 12.sp,
                    color = if (feedbackText.length > MAX_CHARACTERS) {
                        MaterialTheme.colorScheme.error
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 4.dp),
                    textAlign = TextAlign.End
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Send button
                Button(
                    onClick = {
                        scope.launch {
                            isSending = true
                            showError = false

                            val result = FeedbackService.send(context, feedbackText)

                            when (result) {
                                is FeedbackResult.Success -> {
                                    view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                    showSuccess = true
                                    prefs.edit().putLong(COOLDOWN_KEY, System.currentTimeMillis()).apply()
                                    cooldownRemaining = COOLDOWN_DURATION
                                    feedbackText = ""
                                    delay(2000)
                                    onDismiss()
                                }
                                is FeedbackResult.Error -> {
                                    showError = true
                                }
                            }

                            isSending = false
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    enabled = !isSendDisabled,
                    shape = RoundedCornerShape(14.dp)
                ) {
                    if (isSending) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else if (cooldownRemaining > 0) {
                        Text("$sendButtonText (${cooldownRemaining}s)")
                    } else {
                        Text(sendButtonText)
                    }
                }

                // Error message
                if (showError) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = errorMessage,
                        color = MaterialTheme.colorScheme.error,
                        fontSize = 13.sp,
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center
                    )
                }
            }

            // Success overlay
            AnimatedVisibility(
                visible = showSuccess,
                enter = fadeIn() + scaleIn(),
                exit = fadeOut() + scaleOut(),
                modifier = Modifier.align(Alignment.Center)
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = "Success",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = successMessage,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

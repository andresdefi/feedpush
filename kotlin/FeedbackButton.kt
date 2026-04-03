package com.feedpush

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// MARK: FeedbackButton
// A card-style button that opens the feedback sheet when tapped.
// Configurable text and icon -- pass your own strings to localize or customize.

@Composable
fun FeedbackButton(
    modifier: Modifier = Modifier,
    icon: String = "\uD83D\uDCA1",
    title: String = "Have suggestions?",
    subtitle: String = "Share your ideas with us",
    // Pass all FeedbackSheet customization through here
    feedbackPlaceholder: String = "What's on your mind?",
    emailPlaceholder: String = "Leave your email if you'd like us to follow up (totally optional)",
    sendButtonText: String = "Send",
    successMessage: String = "Thank you for your feedback!",
    errorMessage: String = "Could not send feedback. Please check your connection and try again."
) {
    var showSheet by remember { mutableStateOf(false) }

    Card(
        onClick = { showSheet = true },
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = icon,
                fontSize = 24.sp
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = title,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = subtitle,
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }

    if (showSheet) {
        FeedbackSheet(
            onDismiss = { showSheet = false },
            feedbackPlaceholder = feedbackPlaceholder,
            emailPlaceholder = emailPlaceholder,
            sendButtonText = sendButtonText,
            successMessage = successMessage,
            errorMessage = errorMessage
        )
    }
}

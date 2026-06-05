import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a single message in a conversation.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// AI chat modes corresponding to the four home-screen cards.
enum AiMode {
  symptomNavigator,
  appointmentPrep,
  labInterpreter,
  careGap;

  String get id => switch (this) {
        AiMode.symptomNavigator => 'symptom_navigator',
        AiMode.appointmentPrep => 'appointment_prep',
        AiMode.labInterpreter => 'lab_interpreter',
        AiMode.careGap => 'care_gap',
      };

  String get title => switch (this) {
        AiMode.symptomNavigator => 'Symptom Navigator',
        AiMode.appointmentPrep => 'Appointment Prep',
        AiMode.labInterpreter => 'Lab Interpreter',
        AiMode.careGap => 'Care Gap Detector',
      };

  String get emoji => switch (this) {
        AiMode.symptomNavigator => '🔍',
        AiMode.appointmentPrep => '📋',
        AiMode.labInterpreter => '🔬',
        AiMode.careGap => '📅',
      };

  String get greeting => switch (this) {
        AiMode.symptomNavigator =>
          "Hi! I'm here to help you make sense of what you're experiencing. Tell me what symptoms you've been noticing, and I'll help you understand them and figure out your next steps.",
        AiMode.appointmentPrep =>
          "Let's get you ready for your appointment! Tell me about the type of visit — who are you seeing and what's on your mind? I'll help you prepare questions and know what to bring.",
        AiMode.labInterpreter =>
          "I can help you understand your lab results in plain language. Go ahead and share the values you have (including reference ranges if available), and I'll walk you through what they mean.",
        AiMode.careGap =>
          "Let's check in on your preventive care. To personalise your recommendations, can you share a bit about yourself — your age and any health conditions you're aware of? I'll help identify any screenings or checks you may be due for.",
      };

  /// Short mode-specific addition sent to the Edge Function alongside each
  /// request. The Edge Function appends this to the base system prompt.
  String get systemPromptAddition => switch (this) {
        AiMode.symptomNavigator =>
          'Your role in this conversation is symptom navigation. '
          'Ask clarifying questions about duration, severity, cycle phase, and '
          'lifestyle context. Summarise symptoms clearly and suggest structured '
          'next steps (monitor, lifestyle change, see a GP, see a specialist). '
          'Flag anything that may need urgent attention.',
        AiMode.appointmentPrep =>
          'Your role is appointment preparation. '
          'Ask about the appointment type, then help the user build a prioritised '
          'question list and identify what to bring. '
          'Coach them on advocating for themselves if they feel dismissed.',
        AiMode.labInterpreter =>
          'Your role is lab result interpretation. '
          'Ask the user to share their values and reference ranges. '
          'Explain each biomarker in plain language, put results in a '
          "women's health context, and flag values outside the normal range.",
        AiMode.careGap =>
          'Your role is preventive care gap detection. '
          'Ask about age, reproductive status, and known health conditions. '
          'Reference standard preventive care guidelines for women and help '
          'create a simple, actionable checklist of gaps to discuss with their doctor.',
      };
}

/// Calls the `ai-chat` Supabase Edge Function and returns the assistant reply.
class AiService {
  static final _client = Supabase.instance.client;

  static Future<String> sendMessage({
    required AiMode mode,
    required List<ChatMessage> messages,
  }) async {
    final response = await _client.functions.invoke(
      'ai-chat',
      body: {
        // The Edge Function combines its base system prompt with this
        // mode-specific addition before calling the model.
        'promptAddition': mode.systemPromptAddition,
        'messages': messages.map((m) => m.toJson()).toList(),
      },
    );

    if (response.status != 200) {
      throw Exception(
        'AI request failed (${response.status}): ${response.data}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final content =
        choices?.isNotEmpty == true
            ? (choices![0] as Map<String, dynamic>)['message']
                ['content'] as String?
            : null;
    if (content == null) {
      throw Exception('OpenAI returned no content in choices.');
    }
    return content;
  }
}

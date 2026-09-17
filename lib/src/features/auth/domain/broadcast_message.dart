import 'package:equatable/equatable.dart';

/// An instance-wide announcement (`/broadcast_messages`).
///
/// `message` arrives as rendered HTML; [plainText] strips tags for the
/// single-line banner.
class BroadcastMessage extends Equatable {
  const BroadcastMessage({
    required this.id,
    required this.message,
    this.theme,
    this.broadcastType,
    this.active = true,
    this.dismissable = false,
    this.startsAt,
    this.endsAt,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) =>
      BroadcastMessage(
        id: json['id'] as int? ?? 0,
        message: json['message'] as String? ?? '',
        theme: json['theme'] as String?,
        broadcastType: json['broadcast_type'] as String?,
        active: json['active'] as bool? ?? true,
        dismissable: json['dismissable'] as bool? ?? false,
        startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
        endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      );

  final int id;

  /// Rendered HTML body.
  final String message;
  final String? theme;

  /// `banner` or `notification`.
  final String? broadcastType;
  final bool active;
  final bool dismissable;
  final DateTime? startsAt;
  final DateTime? endsAt;

  String get plainText =>
      message.replaceAll(RegExp('<[^>]*>'), '').trim();

  @override
  List<Object?> get props => [id];
}

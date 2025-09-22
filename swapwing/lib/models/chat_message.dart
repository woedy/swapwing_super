enum MessageType { text, image, tradeProposal, systemMessage }

enum TradeProposalStatus { pending, accepted, rejected, countered }

class TradeProposal {
  final String id;
  final String proposerId;
  final List<String> offeredListingIds;
  final List<String> requestedListingIds;
  final String? message;
  final TradeProposalStatus status;
  final DateTime createdAt;

  const TradeProposal({
    required this.id,
    required this.proposerId,
    required this.offeredListingIds,
    required this.requestedListingIds,
    this.message,
    this.status = TradeProposalStatus.pending,
    required this.createdAt,
  });
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final TradeProposal? tradeProposal;
  final List<String> imageUrls;
  final DateTime sentAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.tradeProposal,
    this.imageUrls = const [],
    required this.sentAt,
    this.isRead = false,
  });

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    TradeProposal? tradeProposal,
    List<String>? imageUrls,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      tradeProposal: tradeProposal ?? this.tradeProposal,
      imageUrls: imageUrls ?? this.imageUrls,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
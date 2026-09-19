/// Endpoint AI (D2) — API chưa có trên dev, để riêng khỏi `Ep` (check_openapi
/// chỉ quét `endpoints.dart`) cho tới khi backend bổ sung.
class EpAi {
  EpAi._();

  static const status = '/v1/ai/status';
  static const conversations = '/v1/ai/conversations';
  static String conversation(String id) => '/v1/ai/conversations/$id';
  static String messages(String id) => '/v1/ai/conversations/$id/messages';
  static const digestWeekly = '/v1/ai/digest/weekly';
  static String messageFeedback(String id) => '/v1/ai/messages/$id/feedback';
}

import 'package:http/http.dart' as http;

class TelegramService {
  static const String _botToken =
      '7854661345:AAEzg74OEidhdWB7_uJ9hefKdoBlGCV94f4';
  static const String _chatId = '709273579';

  /// Método padrão (parse_mode Markdown)
  static Future<void> sendMessage(String text) async {
    final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');

    final response = await http.post(
      url,
      body: {
        'chat_id': _chatId,
        'text': text,
        'parse_mode': 'Markdown',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao enviar mensagem: ${response.body}');
    }
  }

  /// Método novo com controle do preview e markdown personalizado
  static Future<void> sendMarkdownMessage(String text, {bool disablePreview = false}) async {
    final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');

    final response = await http.post(
      url,
      body: {
        'chat_id': _chatId,
        'text': text,
        'parse_mode': 'Markdown',
        'disable_web_page_preview': disablePreview.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao enviar mensagem: ${response.body}');
    }
  }
}

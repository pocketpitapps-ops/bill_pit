// lib/features/legal/privacy_policy_page.dart
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Política de Privacidade — Bill Pit',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Última atualização: 18 de julho de 2026',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            textTheme,
            '1. Responsável pelo tratamento de dados',
            'Bill Pit (com.pocketpitapps.bill_pit)\n'
                'Email de contacto: pocketpitapps@gmail.com',
          ),
          _section(
            textTheme,
            '2. Dados que recolhemos',
            'O Bill Pit é uma aplicação totalmente local. '
                'Não recolhemos, armazenamos nem transmitimos quaisquer dados pessoais '
                'para servidores externos.\n\n'
                'Todos os dados que introduzes (despesas, categorias, valores) '
                'são armazenados exclusivamente no teu dispositivo.',
          ),
          _section(
            textTheme,
            '3. Notificações locais',
            'O Bill Pit pode enviar notificações locais para te lembrar de '
                'pagamentos, resumos e valores por atualizar. Estas notificações '
                'são geradas e processadas inteiramente no teu dispositivo '
                'e não enviam dados para nenhum servidor.',
          ),
          _section(
            textTheme,
            '4. Permissões da aplicação',
            '• Notificações: para enviar lembretes e resumos de despesas\n'
                '• Armazenamento local: para guardar os teus dados no dispositivo',
          ),
          _section(
            textTheme,
            '5. Partilha de dados',
            'Não partilhamos os teus dados com terceiros, pois todos os dados '
                'permanecem no teu dispositivo.',
          ),
          _section(
            textTheme,
            '6. Armazenamento e segurança',
            'Todos os dados são armazenados localmente no teu dispositivo '
                'utilizando Isar (base de dados local encriptada) e '
                'SharedPreferences. Não existem transferências de dados para '
                'servidores externos.',
          ),
          _section(
            textTheme,
            '7. Retenção de dados',
            'Os dados são mantidos no teu dispositivo enquanto tiveres a aplicação '
                'instalada. Podes eliminar todos os dados a qualquer momento '
                'através de Definições > Limpar dados ou Repor dados iniciais.',
          ),
          _section(
            textTheme,
            '8. Os teus direitos (GDPR)',
            'Como a aplicação é totalmente local, todos os teus dados estão '
                'sob o teu controlo direto. Tens direito a:\n'
                '• Aceder aos teus dados (abrir a app)\n'
                '• Apagar os teus dados (Definições > Limpar dados)\n'
                '• Eliminar a aplicação (remove todos os dados automaticamente)',
          ),
          _section(
            textTheme,
            '9. Alterações a esta política',
            'Reservamo-nos o direito de alterar esta política de privacidade. '
                'As alterações serão comunicadas através da aplicação.',
          ),
          _section(
            textTheme,
            '10. Contacto',
            'Para questões sobre privacidade, contacta-nos em:\n'
                'pocketpitapps@gmail.com',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(TextTheme textTheme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

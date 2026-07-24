// lib/features/legal/terms_of_service_page.dart
import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Utilização')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Termos de Utilização — Bill Pit',
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
            '1. Aceitação dos termos',
            'Ao descarregar, instalar ou utilizar a aplicação Bill Pit, '
                'concordas com estes Termos de Utilização. Se não concordares, '
                'não deves utilizar a aplicação.',
          ),
          _section(
            textTheme,
            '2. Descrição do serviço',
            'A Bill Pit é uma aplicação de controlo de despesas mensais '
                'que permite:\n'
                '• Registar despesas fixas, periódicas e únicas\n'
                '• Organizar despesas por categorias\n'
                '• Acompanhar pagamentos e receber lembretes\n'
                '• Visualizar resumos e estatísticas de gastos',
          ),
          _section(
            textTheme,
            '3. Precisão dos dados',
            'Todos os dados apresentados são introduzidos pelo utilizador. '
                'A Bill Pit não se responsabiliza por erros nos valores ou '
                'categorias introduzidos. É da responsabilidade do utilizador '
                'manter os dados corretos e atualizados.',
          ),
          _section(
            textTheme,
            '4. Utilização aceitável',
            'Concordas em não:\n'
                '• Utilizar a app para fins ilegais\n'
                '• Tentar aceder indevidamente aos sistemas da aplicação\n'
                '• Decompilar ou modificar a aplicação',
          ),
          _section(
            textTheme,
            '5. Propriedade intelectual',
            'Todo o conteúdo da aplicação (design, código, logótipos, textos) '
                'é propriedade do Bill Pit e está protegido por direitos de autor.',
          ),
          _section(
            textTheme,
            '6. Limitação de responsabilidade',
            'A Bill Pit é fornecida "tal como está" sem garantias de '
                'disponibilidade ou idoneidade para um fim particular. '
                'Não somos responsáveis por decisões financeiras tomadas '
                'com base nos dados apresentados pela aplicação.',
          ),
          _section(
            textTheme,
            '7. Alterações aos termos',
            'Reservamo-nos o direito de alterar estes termos a qualquer '
                'momento. As alterações serão comunicadas através da aplicação. '
                'A utilização continuada da app após as alterações '
                'constitui aceitação dos novos termos.',
          ),
          _section(
            textTheme,
            '8. Resolução de litígios',
            'Estes termos são regidos pela legislação portuguesa. '
                'Quaisquer litígios serão submetidos aos tribunais competentes '
                'de Portugal.',
          ),
          _section(
            textTheme,
            '9. Contacto',
            'Para questões sobre estes termos, contacta-nos em:\n'
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

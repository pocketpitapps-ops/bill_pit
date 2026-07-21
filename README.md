# Bill Pit

Aplicacao mobile para gestao de despesas mensais pessoais. Controlo completo de contas recorrentes e unicas, com calendario visual, notificacoes configuraveis e backup/restore.

## Capturas de ecrã

<!-- Adicionar screenshots aqui -->

## Funcionalidades

- **Gestao de despesas** — Criar, editar e eliminar despesas recorrentes (valor fixo ou variavel) e unicas
- **Calendario mensal** — Visualizacao de despesas por dia com indicadores de pagamento
- **Dashboard** — Resumo mensal com grafico de categorias e lista de proximas despesas
- **Categorias** — 8 categorias por defeito (Casa, Electricidade, Agua, Gas, Veiculo, Subscricoes, Credito, Saude) + "Outros", com gestao completa (criar, editar, eliminar)
- **Notificacoes** — Resumo mensal, preview semanal, alertas de atraso e lembretes individuais
- **Backup/Restore** — Exportar e importar dados via ficheiro JSON
- **Frequencia recorrente** — Mensal, bimestral, trimestral, semestral ou anual
- **Prestacoes** — Suporte a despesas com numero finito de prestacoes
- **Ajuste automatico** — Fins de semana deslocados para segunda-feira
- **Tema** — Claro, escuro ou seguir sistema
- **Localizacao** — Interface em portugues

## Stack tecnica

| Componente | Tecnologia |
|---|---|
| Framework | Flutter 3.44.2 |
| Linguagem | Dart 3.12.2 |
| Base de dados local | Isar Community 3.3.2 |
| Estado | Provider 6.x |
| Graficos | fl_chart 0.70.x |
| Notificacoes | flutter_local_notifications 18.x |
| Background tasks | WorkManager 0.9.x |
| Backup | share_plus + file_picker |
| Fonts | Google Fonts |
| Audio | audioplayers |

## Estrutura do projeto

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   └── categories.dart          # Categorias por defeito
│   ├── services/
│   │   ├── backup_service.dart      # Export/import JSON
│   │   ├── category_service.dart    # Gestao de categorias (SharedPreferences)
│   │   ├── notification_service.dart # Agendamento de notificacoes
│   │   └── value_tracking_service.dart
│   └── theme/
│       └── bill_pit_theme.dart      # Tema claro/escuro
├── data/
│   ├── models/
│   │   ├── expense.dart             # Modelo Isar
│   │   └── expense.g.dart           # Codigo gerado
│   └── repositories/
│       └── expense_repository.dart  # CRUD + seed data
└── features/
    ├── calendar/
    │   └── calendar_page.dart
    ├── categories/
    │   └── categories_page.dart
    ├── expense_form/
    │   └── expense_form_page.dart   # Formulario recorrente/unica
    ├── expenses/
    │   └── expenses_page.dart       # Lista de despesas
    ├── home/
    │   └── home_page.dart           # Dashboard + navegacao
    ├── intro/
    │   ├── splash_intro_page.dart
    │   └── splash_intro_config.dart
    ├── legal/
    │   ├── privacy_policy_page.dart
    │   └── terms_of_service_page.dart
    ├── settings/
    │   └── settings_page.dart       # Definicoes + categorias + backup
    └── statistics/
        └── statistics_page.dart
```

## Como correr

```bash
# Instalar dependencias
flutter pub get

# Correr em debug
flutter run

# Build release
flutter build apk --release --no-tree-shake-icons
```

## CI/CD

O repositorio inclui um GitHub Actions workflow (`.github/workflows/release.yml`) que:

1. Dispara ao criar uma tag `v*` ou manualmente via `workflow_dispatch`
2. Configura Java 17 (Zulu) + Flutter 3.44.2 (stable)
3. Descodifica o keystore de signing a partir de secrets
4. Faz build do APK release
5. Cria uma GitHub Release com o APK anexado

### Secrets necessarios

| Secret | Descricao |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Keystore de signing em base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Password do keystore |
| `ANDROID_KEY_PASSWORD` | Password da chave |
| `ANDROID_KEY_ALIAS` | Alias da chave |

### Publicar nova versao

```bash
git tag v1.0.0
git push origin v1.0.0
```

O workflow ira fazer build e criar a release automaticamente.

## Licenca

Proprietario. Todos os direitos reservados.

# Bill Pit

Aplicacao mobile para gestao de despesas mensais pessoais. Controlo completo de contas recorrentes e unicas, com calendario visual, notificacoes configuraveis e backup/restore.

## Funcionalidades

- **Gestao de despesas** — Criar, editar e eliminar despesas recorrentes (valor fixo ou variavel) e unicas
- **Wizard de criacao** — Assistente passo a passo para criar despesas
- **Actualizar valor** — Atualizar o valor real da factura por mes para despesas com valor variavel
- **Calendario mensal** — Visualizacao de despesas por dia com indicadores de pagamento
- **Dashboard** — Resumo mensal com grafico de categorias e lista de proximas despesas
- **Categorias** — Categorias por defeito com gestao completa (criar, editar, reordenar, eliminar)
- **Notificacoes** — Resumo mensal, preview semanal, alertas de atraso e lembretes individuais
- **Backup/Restore** — Backup automatico + export/import via partilha
- **Frequencia recorrente** — Mensal, bimestral, trimestral, semestral ou anual
- **Prestacoes** — Suporte a despesas com numero finito de prestacoes
- **Ajuste automatico** — Fins de semana deslocados para segunda-feira
- **Tema** — Claro, escuro ou seguir sistema
- **Tutorial** — Onboarding interativo + acesso nas definicoes
- **Localizacao** — Interface em portugues

## Stack tecnica

| Componente | Tecnologia |
|---|---|
| Framework | Flutter |
| Linguagem | Dart |
| Base de dados local | Isar Community |
| Estado | Provider |
| Graficos | fl_chart |
| Notificacoes | flutter_local_notifications |
| Background tasks | WorkManager |
| Backup | share_plus + path_provider |
| Fonts | Google Fonts |

## Estrutura do projeto

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   └── categories.dart
│   ├── services/
│   │   ├── backup_service.dart
│   │   ├── category_service.dart
│   │   ├── notification_service.dart
│   │   ├── theme_service.dart
│   │   └── value_tracking_service.dart
│   └── theme/
│       └── bill_pit_theme.dart
├── data/
│   ├── models/
│   │   ├── expense.dart
│   │   └── expense.g.dart
│   └── repositories/
│       └── expense_repository.dart
└── features/
    ├── calendar/
    ├── categories/
    ├── expense_form/
    ├── expense_wizard/
    ├── expenses/
    ├── home/
    ├── intro/
    ├── legal/
    ├── onboarding/
    ├── settings/
    └── statistics/
```

## Como correr

```bash
flutter pub get
flutter run
```

## Build release

```bash
flutter build apk --release --no-tree-shake-icons
```

## CI/CD

O repositorio inclui um GitHub Actions workflow (`.github/workflows/release.yml`) que:

1. Dispara ao criar uma tag `v*` ou manualmente via `workflow_dispatch`
2. Configura Java 17 (Zulu) + Flutter (stable)
3. Descodifica o keystore de signing a partir de secrets
4. Faz build do APK release com retry automatico
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

MIT License — veja o ficheiro [LICENSE](LICENSE) para detalhes.

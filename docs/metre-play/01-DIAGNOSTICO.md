# MetreViewer na Google Play — diagnóstico e caminho de submissão

Situação em **20/11/2026**. Fontes oficiais lidas nessa data (lista no fim).

Estados usados: **verificado** · **corrigido e retestado** · **corrigido, pendente de teste** · **pendente de teste** · **depende de informação externa** · **não aplicável** (com justificativa).

---

## 1. Artefato auditado (o último publicado)

| Item | Valor | Estado |
|---|---|---|
| Branch / commit | `metre` @ `a0a2dca` (igual no GitHub) | verificado |
| Relação com `master` | `metre` = tag `1.5.3` do RustDesk + 32 commits; `master` tem 12 commits do upstream a mais | verificado |
| Workflow / execução | "MetreViewer build", run nº 28 (id 44625257262), todos os jobs com sucesso | verificado |
| Release | `metre-nightly`: a tag aponta para `master` (3ccb4c4), **não** para o commit do build; arquivos sobrescritos a cada build | verificado — não usar a release como identificação |
| AAB | `metreviewer-1.5.3.aab`, SHA-256 `8a26c09936c4faba682cda44467961254dddc826907aa6a4af93e6a06e017b01` | verificado |
| APK armv7 (M10) | `rustdesk-1.5.3-armv7-signed.apk`, SHA-256 `cc26fe12…ed5`, versionCode **2028** | verificado |
| APK arm64 | `rustdesk-1.5.3-aarch64-signed.apk`, SHA-256 `1d223635…fc2`, versionCode **3028** | verificado |

O AAB do run 28 **não deve ser enviado**: versionCode 1028 é menor que o dos APKs (seção 3).

### Verificações executadas no AAB (localmente, bundletool 1.18.3, build-tools 37, JDK 25)

| Verificação | Comando | Resultado |
|---|---|---|
| Bundle válido | `bundletool validate` | OK (exit 0) |
| Assinatura | `jarsigner -verify -certs` | verificada, 1 signatário `CN=MetreViewer, O=Metre, C=BR`, SHA-256 `B9:CC:73:…:CE:CA:BF` |
| Manifesto final mesclado | `bundletool dump manifest` | pacote `com.metre.viewer`, versionName 1.5.3, versionCode 1028, minSdk 22, targetSdk 36, compileSdk 36, sem `debuggable` |
| 16 KB (config do bundle) | `bundletool dump config` | `PAGE_ALIGNMENT_16K` |
| 16 KB (ELF) | leitura dos cabeçalhos PT_LOAD de cada `.so` | **todas as 4 libs arm64-v8a ≥ 16 KB**; armeabi-v7a: `libc++_shared.so` e `librustdesk.so` em 4 KB (aceitável: 16 KB só se aplica a 64 bits) |
| APKs gerados do AAB | `bundletool build-apks --device-spec` (M10: armeabi-v7a/API 24; Lenovo: arm64/API 33) | M10 recebe `base-armeabi_v7a`; Lenovo recebe `base-arm64_v8a`; split arm64 passa `zipalign -c -P 16` |
| APKs de instalação direta | `apksigner verify -v` | v1+v2+v3 verificados, 1 signatário (mesmo certificado); `zipalign -c -P 16` OK no arm64 |

Funções de cada SDK: **minSdk 22** = menor Android que instala (o M10, Android 7 = API 24, está incluído; **não** aumentar); **targetSdk 36** = comportamento que o app declara suportar, exigido pela Play para apps novos e atualizações desde 31/08/2026; **compileSdk 36** = APIs usadas na compilação.

---

## 2. Correções feitas neste ciclo (ainda sem build)

| # | Problema → evidência | Correção | Estado |
|---|---|---|---|
| C1 | versionCode do AAB (1028) menor que os APKs (2028/3028) → Play nunca atualizaria quem instalou por APK | AAB = 10000 + run; verificação do CI exige ≥ 10000 + run | corrigido, pendente de build |
| C2 | `InputService` registrava no logcat o texto do campo em que o técnico digita (`AccessibilityNodeInfo.toString()`, "existing text") — pode incluir senha | logs mostram só se havia campo/texto | corrigido, pendente de build |
| C3 | Notificação permanente e canal com o título "RustDesk" | título e canal "MetreViewer" | corrigido, pendente de build |
| C4 | Texto do `specialUse` falava em "RustDesk host" e "unattended connections" | descreve o uso real (serviço de suporte, notificação, captura só após consentimento) | corrigido, pendente de build |
| C5 | Divulgação da Acessibilidade não dizia que o serviço lê e altera o texto do campo ativo | texto do aviso e descrição do serviço atualizados | corrigido, pendente de build |

O que o próximo build precisa comprovar (lido do arquivo final, não do CI): versionCode do AAB > 5000 + run e > versionCode dos APKs; certificado `B9:CC…`; manifesto sem novas permissões; `strings` com `MetreViewer`; libs arm64 com LOAD ≥ 16 KB.

---

## 3. Atualização das instalações existentes (APK → Play)

> **Decidido em 20/11:** chave gerada pela Google. Instalações por APK precisarão ser desinstaladas antes de instalar pela Play (ver `00-DECISOES.md`). O restante desta seção fica como registro da análise.

| Condição para a Play atualizar um app instalado por APK | Situação |
|---|---|
| Mesmo pacote `com.metre.viewer` | sim |
| Mesmo certificado de assinatura do app | **só se o Play App Signing usar a chave da Metre** (opção "exportar e enviar" pela ferramenta PEPK). Se o Google gerar a chave, as instalações por APK precisam ser desinstaladas antes. **Decisão sua**, irreversível na prática (a chave de assinatura não muda durante a vida do app) |
| versionCode maior | corrigido em C1 (pendente de build) |

Consequência inversa: depois que um aparelho recebe a versão da Play (≥ 10000), um APK de instalação direta (< 10000) não instala por cima. Aparelho que migrou para a Play deve ficar na Play.

Ainda a testar: se a atualização feita pela Play **remove a Configuração restrita** de um app que veio por APK (no Lenovo, o bloqueio é gravado no app instalado). Teste definido no plano de testes (T-L4).

---

## 4. Lenovo TB310FU — Configuração restrita (resultado de laboratório, 19–20/11)

| Fato | Evidência | Estado |
|---|---|---|
| Android 13 (SDK 33), patch 05/01/2026, build `TB310FU_S000914_260105_ROW` | `getprop` via ADB | verificado |
| Instalação nova pelo Metre Instalador (sessão do PackageInstaller, `packageSource=0`) recebeu o bloqueio ~15 s depois | `appops get … ACCESS_RESTRICTED_SETTINGS`: `allow` 08:58:02 → `deny` 08:58:17 | verificado (reproduzido 2×) |
| Esta ROM **não mostra** "Permitir configurações restritas" em Informações do app, mesmo com o estado `ignore` | árvore de interface via `uiautomator`: sem "Mais opções" | verificado |
| A liberação de 19/11 foi feita por ADB | informado por você | não vale como evidência de fluxo |
| AnyDesk AD1 instalado pela Play ativa a Acessibilidade | `pm list packages -i`: instalador `com.android.vending` | indício, não prova para o MetreViewer |

Conclusão: neste aparelho, sem ADB, o controle **só pode** funcionar se a instalação pela Play não receber o bloqueio. Isso é **pendente de teste** (teste interno, T-L1).

---

## 5. Matriz de permissões (manifesto final do AAB)

| Permissão | Recurso que usa | Necessária? | Pedido ao usuário | Declaração na Play | Evidência |
|---|---|---|---|---|---|
| INTERNET, ACCESS_NETWORK_STATE | conexão com servidor Metre e técnico | sim | não (normal) | — | manifesto |
| ACCESS_WIFI_STATE | trava de Wi-Fi em alto desempenho; Diagnóstico | sim (desempenho M10) | não | — | `MetreCompat.holdWifi` |
| WAKE_LOCK | manter CPU durante sessão | sim | não | — | `MainService` |
| FOREGROUND_SERVICE + FOREGROUND_SERVICE_MEDIA_PROJECTION | captura de tela durante a sessão | sim | **diálogo do Android de captura** (a cada início no Android 10+; após reiniciar, pede de novo) | **Declaração de serviço em primeiro plano** (tipo mediaProjection) + vídeo | manifesto `foregroundServiceType=specialUse\|mediaProjection` |
| FOREGROUND_SERVICE_SPECIAL_USE | manter o serviço conectado ao servidor antes de haver captura | **a decidir** (ver P3) | não | **Declaração specialUse** + justificativa; maior risco de questionamento | manifesto + `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` |
| BIND_ACCESSIBILITY_SERVICE (serviço `InputService`) | toques, gestos e digitação do técnico | sim, para controle | **aviso do app ("Concordo"/"Agora não") + tela de Acessibilidade do Android** | **Declaração AccessibilityService** (não é ferramenta de acessibilidade) + vídeo | `metre_pdv_page.dart` `_a11yConsent`; `accessibility_service_config.xml` |
| POST_NOTIFICATIONS | notificação de serviço e de sessão | sim | pedido do Android 13+ | — | manifesto (no Lenovo aparece "Notificações: Desativadas" — **pendente de teste**: notificação de sessão visível?) |
| RECEIVE_BOOT_COMPLETED | voltar ao ligar (opcional) | opcional | não | — | `BootReceiver` |
| SYSTEM_ALERT_WINDOW | janela flutuante que mantém o serviço com app fechado (opcional) | opcional | tela de sistema "Sobrepor a outros apps" | permissão especial; sem formulário específico encontrado | passo opcional do PDV |
| REQUEST_IGNORE_BATTERY_OPTIMIZATIONS | suporte disponível com app fechado (opcional) | opcional | diálogo do sistema | política de uso aceitável — **revisar** (P4) | passo opcional do PDV |
| `com.metre.viewer.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | gerada pelo AndroidX | sim | não | — | — |

Ausentes no artefato (verificado no manifesto final): RECORD_AUDIO, FOREGROUND_SERVICE_MICROPHONE, CAMERA, MANAGE_EXTERNAL_STORAGE, READ/WRITE_EXTERNAL_STORAGE, REQUEST_INSTALL_PACKAGES, QUERY_ALL_PACKAGES. Há `<queries>` só para os pacotes de autoinício de fabricantes (Xiaomi, Huawei, Oppo, Vivo, Asus, LeTV) — visibilidade restrita, não exige declaração.

Herdados ainda presentes, sem permissão: `com.journeyapps.barcodescanner.CaptureActivity` (leitor de QR do upstream; sem câmera não abre) — inofensivo, pode ser removido depois.

---

## 6. Fluxo de dados

| Dado | De → para | Finalidade | Armazenamento | Transporte | Estado |
|---|---|---|---|---|---|
| Imagem da tela (vídeo) | tablet → PC do técnico, direto ou pelo relay `216.128.173.155` | suporte | não gravado pelo app; relay repassa | criptografado entre os pontos (protocolo RustDesk; chaves trocadas com a chave pública do servidor Metre) | verificado no código; **não** afirmar "ponta a ponta" sem análise formal |
| Toques, teclas, rolagem | PC → tablet | suporte | não | idem | verificado no código |
| Texto do campo ativo | lido no tablet pelo `InputService` para digitar | digitação | não sai do aparelho | — | verificado (`onAccessibilityEvent` vazio; só age por comando do técnico) |
| Área de transferência | tablet ↔ PC (recurso do upstream) | copiar/colar | não | idem | **pendente de teste** (se está ativa no Android) |
| Arquivos | — | — | — | — | não aplicável: sem permissão de armazenamento |
| Áudio | — | — | — | — | não aplicável: removido |
| ID do aparelho, UUID, chave pública | tablet → servidor de ID Metre | localizar o aparelho | servidor Metre | **registro por UDP/TCP do protocolo — criptografia não confirmada** | depende de verificação técnica |
| Informações do sistema (SO, CPU, memória, versão, nome do aparelho) e heartbeat | tablet → `https://216-128-173-155.sslip.io/api/sysinfo` e `/api/heartbeat` | lista de PDVs do técnico | servidor Metre — **retenção desconhecida** | HTTPS | depende da Metre |
| Telemetria de desempenho (quadros/s, tempos, resolução, codec) + ID + UUID | tablet → `/api/metre/telemetry` | diagnóstico de desempenho | servidor Metre — **retenção desconhecida** | HTTPS | depende da Metre |
| Logs do app | armazenamento privado do app | diagnóstico | no aparelho | — | logs de texto digitado removidos (C2) |
| Fontes Google (`google_fonts`) | tablet → servidores do Google (se baixar fonte) | interface | — | HTTPS | pendente de verificação (se baixa em execução) |
| Resolução DNS `sslip.io` | tablet → serviço DNS de terceiros | resolver o nome do servidor | — | DNS | verificado na configuração |

Sem SDK de anúncios, analytics ou crash reporting de terceiros (dependências do `pubspec.yaml` conferidas). Sem criação de conta no tablet.

---

## 7. Pendências por categoria

Formato: problema → evidência → consequência → correção → responsável → validação → dependência.

### A. Bloqueios técnicos
- **A1 versionCode** → 1028 < 2028/3028 → Play não atualiza APKs → C1 → Claude (feito) → ler versionCode do novo AAB → build.
- **A2 Build com C1–C5** → código alterado sem build → nenhum AAB válido para envio → push na branch e CI → **você autoriza o push** → reauditar o AAB (mesmos comandos da seção 1) → A1.
- **A3 Link de privacidade dentro do app** → "Opções avançadas → Configurações" ainda abre `rustdesk.com/privacy.html` → política errada no app → apontar para a política da Metre → Claude, **depois que a Metre definir a URL** → abrir o link no aparelho → B2.
- **A4 Lenovo sem caminho manual** → seção 4 → APK não serve para Android 13 deste modelo → distribuir pela Play → teste interno → T-L1 → A2, C1 do Console.

### B. Políticas e declarações
- **B1 Declaração AccessibilityService** → app não é ferramenta de acessibilidade → obrigatória + vídeo → rascunho em `03-FICHA-E-DECLARACOES.md` → Metre grava o vídeo com o build novo → conferir os 7 itens do vídeo → A2.
- **B2 Política de privacidade** → inexistente → bloqueia envio → rascunho em `02-POLITICA-PRIVACIDADE.md` → **Metre preenche** responsável, contato, retenção, URL pública (não PDF) → abrir a URL sem login → —.
- **B3 Segurança dos dados** → rascunho em `03-…` → algumas respostas dependem de retenção e criptografia do registro → Metre + verificação técnica → —.
- **B4 Serviço em primeiro plano (mediaProjection e specialUse)** → obrigatória para target 34+ → rascunho + vídeo → Metre grava → —.
- **P3 specialUse** → mantém o serviço ativo para conexões sem o cliente abrir o app → é o ponto mais sujeito a questionamento; sem ele o serviço só fica em primeiro plano depois do consentimento de captura → **decisão sua**: manter e justificar (recomendo, com o texto C4) ou retirar e aceitar que o cliente abra o app a cada atendimento → —.
- **P4 Isenção de bateria e sobreposição** → opcionais, servem ao suporte com app fechado → manter só se a Metre precisar disso no primeiro envio → decisão sua.
- **B5 AGPL / marca** → base RustDesk (AGPL-3.0); repositório público; ficha não deve usar a marca RustDesk como nome do produto → citar "baseado no RustDesk (AGPL-3.0)" com link do código-fonte na descrição e no app → revisar com quem cuida de licenças na Metre.

### C. Conta e acesso à produção — **depende de informação externa**
Preciso que você informe (sem senhas ou códigos): tipo de conta (pessoal ou organização), data de criação, se o app `com.metre.viewer` já foi criado no Console, quais faixas existem, se o painel mostra o requisito de teste fechado, e avisos de política/verificação.

### D. Testes e demonstrações
Ver `04-PLANO-DE-TESTES.md` (matriz, roteiro de participantes, critérios).

### E. Prazos externos (oficiais)
- Teste fechado (contas pessoais criadas após 13/11/2023): 12 testadores inscritos por 14 dias **consecutivos** antes de pedir produção; não garante aprovação; análise do pedido "geralmente até 7 dias".
- Revisão de versões: "algumas horas até sete dias ou mais"; mudanças enviadas durante uma revisão podem mandar o app para o fim da fila.
- Teste interno: primeira versão passa por revisão; depois, geralmente disponível de imediato.
- 16 KB: obrigatório para atualizações a partir de 01/02/2027 — já atendido (seção 1).

### Caminho crítico
A2 (build) → upload no **teste interno** → T-L1/T-L4 no Lenovo e T-M no M10 → (se conta pessoal nova) **teste fechado 14 dias**, durante o qual avançam B1–B5 e os vídeos → pedido de produção → revisão.

---

## Fontes oficiais (lidas em 20/11/2026)
- Requisitos de teste: https://support.google.com/googleplay/android-developer/answer/14151465?hl=pt-BR
- Revisão e publicação: https://support.google.com/googleplay/android-developer/answer/9859654?hl=pt-BR
- Dicas para publicar: https://support.google.com/googleplay/android-developer/answer/15191715?hl=pt-BR
- API alvo: https://support.google.com/googleplay/android-developer/answer/11926878?hl=pt-BR
- AccessibilityService: https://support.google.com/googleplay/android-developer/answer/10964491?hl=pt-BR
- Serviço em primeiro plano: https://support.google.com/googleplay/android-developer/answer/13392821?hl=pt-BR
- Segurança dos dados: https://support.google.com/googleplay/android-developer/answer/10787469?hl=pt-BR
- Dados do usuário (divulgação, consentimento, política): https://support.google.com/googleplay/android-developer/answer/10144311?hl=pt-BR
- Permissões sensíveis: https://support.google.com/googleplay/android-developer/answer/9888170?hl=pt-BR
- Assinatura: https://developer.android.com/studio/publish/app-signing
- 16 KB: https://developer.android.com/guide/practices/page-sizes

Nenhuma das páginas exibia data de "última atualização".

---

## 8. Build 29 — artefato para o teste interno (auditado em 20/11/2026)

Commit `6764625` (C1–C5), run 29 (id 44737133319). Jobs Android e AAB com sucesso; job Windows falhou por **HTTP 503 ao baixar um patch do vcpkg (`mfx_dispatch`) do GitHub** — falha de rede, sem relação com as mudanças; instaladores Windows do run 28 continuam na release.

| Arquivo | SHA-256 | versionCode |
|---|---|---|
| `metreviewer-1.5.3.aab` | `9596dc0562529007899b626077d9a31d3c6736f4d67ff7eb99b2738ca5fec3f7` | **10029** |
| `rustdesk-1.5.3-armv7-signed.apk` | `ec3b424039e677dd1fdea8a137d120306507921958065e724e51913ef86ddf7d` | 2029 |
| `rustdesk-1.5.3-aarch64-signed.apk` | `f78b7915d992c37d47d68dc8483360c9edda64931a614de3289e0e0fd81ae22e` | 3029 |

| Verificação (arquivo baixado, não o status do CI) | Resultado | Estado |
|---|---|---|
| `bundletool validate` | exit 0 | verificado |
| Assinatura do AAB | `CN=MetreViewer, O=Metre, C=BR`, SHA-256 `B9:CC:73…:CE:CA:BF` (será a **chave de upload**) | verificado |
| versionCode AAB > APKs | 10029 > 3029 > 2029 | corrigido e retestado (C1) |
| minSdk / targetSdk / compileSdk | 22 / 36 / 36 | verificado |
| Permissões | idênticas ao run 28 (nenhuma nova) | verificado |
| 16 KB | `PAGE_ALIGNMENT_16K`; 4 libs arm64 com LOAD ≥ 16384 | verificado |
| Nome do app no APK gerado do AAB | `application-label:'MetreViewer'` | corrigido e retestado (C3) |
| Notificação/canal | código compilado sem "RustDesk Service"; contém "Suporte remoto Metre" | corrigido e retestado (C3) |
| Texto do `specialUse` | "Keeps the MetreViewer remote support service…" | corrigido e retestado (C4) |
| Logs com texto digitado | "existing text:" ausente do código compilado; "hasText:" presente | corrigido e retestado (C2) |
| Aviso da Acessibilidade (C5) | só verificável na tela | pendente de teste no aparelho |
| APKs | apksigner OK, mesmo certificado | verificado |

Fora deste build: link da política no app (commit local `d142922`, entra no próximo build, necessário antes da revisão de produção).

## 9. Teste T-L1 — Lenovo instalado pela Play (20/11/2026, 11:21)

| Item | Leitura (ADB, só leitura) | Estado |
|---|---|---|
| Origem | `installer=com.android.vending`, `packageSource=0`, versionCode 10029, instalação nova (APK anterior desinstalado com autorização) | verificado |
| Configuração restrita | `ACCESS_RESTRICTED_SETTINGS: allow`, dois acessos (11:21:45 e 11:21:52) e **nenhuma rejeição** | verificado |
| Acessibilidade | `MetreViewer Input` ativado pelo usuário no tablet, sem o diálogo de configuração restrita; nada liberado por ADB | verificado |
| Descrição nova do serviço (C5) | aparece na tela do MetreViewer Input | corrigido e retestado |

Conclusão: no Lenovo TB310FU (Android 13), a instalação pela Play **não** recebe a Configuração restrita — diferente do APK e do Metre Instalador (seção 4). Pendente: sessão real (imagem, toque, texto, rolagem), reinício e reconexão neste build.

# MetreViewer — plano de testes (laboratório, teste interno e teste fechado)

Regra: cada resultado registra **onde** foi obtido — aparelho físico, emulador ou análise estática — e **como** o app foi instalado (Play, APK, ADB). Instalação por ADB não comprova o comportamento da loja. Não desinstalar, apagar dados ou restaurar aparelho sem autorização.

## 1. Matriz de aparelhos

| Ambiente | Tipo | Instalação | Objetivo |
|---|---|---|---|
| M10 (K-touch?, Android 7 — **confirmar modelo e versão**) | físico | APK armv7 e, se o aparelho tiver Play, Play | desempenho, toque/texto/rolagem, reinício |
| Lenovo TB310FU, Android 13 | físico | **Play (teste interno)** | Configuração restrita, consentimentos |
| Android 15/16 recente (aparelho de alguém da equipe ou emulador Google APIs) | físico de preferência | Play | comportamento com targetSdk 36, captura a cada sessão |
| Emulador 16 KB (Android 15+ "16 KB Page Size", arm64) | emulador | AAB via bundletool | abre sem modo de compatibilidade (`getconf PAGE_SIZE` = 16384) |

## 2. Casos (todos os aparelhos, salvo indicação)

| ID | Caso | Passa quando |
|---|---|---|
| T1 | Instalar e abrir | abre na tela do PDV; nenhum diálogo além dos esperados |
| T2 | Recusar captura | app explica e permite tentar de novo; nada é transmitido |
| T3 | Aceitar captura | técnico vê a tela; texto do PDV legível |
| T4 | Aviso da Acessibilidade → "Agora não" | app segue funcionando só com visualização; aviso volta ao tocar "Ativar" |
| T5 | "Concordo" → ativar MetreViewer Input | serviço ativo; passo some |
| T6 | Toque, arrasto, rolagem, texto num campo | ação aparece no tablet; registrar atraso percebido e linhas de medição (toque→tela) |
| T7 | Encerrar pelo tablet e pelo PC | sessão termina nos dois lados; status volta a "Pronto" |
| T8 | Revogar a Acessibilidade | técnico só vê; o app mostra o passo de novo |
| T9 | Perder rede 30 s e voltar | reconecta sem abrir o app; anotar tempo |
| T10 | Reiniciar o aparelho | anotar o que o cliente precisa fazer (no Android 10+ a captura é pedida de novo) |
| T11 | Atualizar da versão anterior | ID mantido; permissões mantidas |
| T12 | 30 min de sessão | sem congelamento, sem ANR; registrar FPS e maior intervalo |
| T-L1 | Lenovo: instalação **nova pela Play** | `appops get com.metre.viewer ACCESS_RESTRICTED_SETTINGS` continua `allow`/sem operação **depois** de 1 min; MetreViewer Input pode ser ligado sem o diálogo de configuração restrita |
| T-L4 | Lenovo: APK instalado (com bloqueio `deny`) **atualizado pela Play** | registrar se o modo muda; se continuar bloqueado, clientes atuais precisam desinstalar e instalar pela Play |
| T-M | M10: desempenho | ≥ X q/s novos (definir com a Metre), sem congelamento > 1 s, toque→tela registrado; comparar com as medições do build 11 |

Leituras por ADB (só leitura, laboratório): `appops get`, `dumpsys package com.metre.viewer` (instalador, origem, versionCode), `settings get secure enabled_accessibility_services`, `getprop`.

## 3. Ferramentas do Console
- **Relatório de pré-lançamento**: roda o app em aparelhos do Google sem técnico conectado e sem conceder Acessibilidade — só detecta falhas de abertura, ANRs e problemas de acessibilidade da interface. Não testa captura, controle nem conexão.
- **Verificações pré-revisão** (se aparecerem no envio): tratar cada aviso antes de enviar.

## 4. Teste fechado (se a conta exigir)

### Recrutamento legítimo — recomendado
Fontes: técnicos e equipe da Metre com Android pessoal, clientes parceiros que aceitem participar, revendas. 12 é o mínimo; recrute ~16–20 para absorver desistências, porque quem sai antes de 14 dias não conta e a contagem precisa ser **consecutiva**.
Cada participante: conta Google na lista de testadores (Grupo do Google ou lista de e-mails), aceita pelo link de inscrição e instala pela Play.

### Testers Community (avaliação, sem contratação)
- O que é: serviço que fornece testadores pagos (planos Starter R$ 75 / Pro R$ 125 por app, conforme o site em 20/11/2026) ou troca recíproca de testes pelo app gratuito.
- Pontos que não batem com o Google: o site diz que testadores que instalam e desinstalam contam pelos 14 dias "pela política do Google"; a página oficial diz que quem sai antes de 14 dias não conta. O site promete acesso à produção ou reembolso — isso é promessa da empresa, não do Google.
- Adequação ao MetreViewer: **baixa**. O teste real precisa de um técnico conectado e de controle por Acessibilidade; testadores anônimos instalariam um app de acesso remoto em aparelhos pessoais apenas para "abrir diariamente". Isso não gera o engajamento que o formulário de produção pede ("usaram todos os recursos?", "feedback") e expõe pessoas a um app de controle remoto sem um atendimento real. Também exigiria que a Metre aceite conexões de aparelhos desconhecidos no servidor.
- Se ainda assim for usado: só como complemento, com o roteiro abaixo, sessões agendadas com um técnico, e sem afirmar no formulário um engajamento que não houve.

### Roteiro para participantes externos (dados de demonstração)
1. Aceite o convite de teste e instale o MetreViewer **pela Google Play**.
2. Anote: modelo do aparelho, versão do Android (Configurações > Sobre), versão do MetreViewer (Play > Sobre o app).
3. Abra o app e siga os passos. Anote cada tela do Android que apareceu e se algo bloqueou (ex.: "Configuração restrita").
4. No horário combinado, informe a identificação ao técnico da Metre e aceite a captura.
5. Ative o controle se quiser testar (leia o aviso). O técnico vai tocar, rolar e digitar num app de notas com texto de teste — **não abra apps com dados pessoais durante a sessão**.
6. Encerre a sessão pelo aparelho. Depois desligue MetreViewer Input em Acessibilidade.
7. Responda o formulário: funcionou? quanto demorou para o toque aparecer (rápido/aceitável/lento)? congelou? alguma tela confusa?

Formulário de registro (planilha): data · participante (apelido) · modelo · Android · versão do app · origem da instalação · casos T1–T10 (ok/falhou/não testado) · falhas · comentário. Guardar como evidência para as perguntas do pedido de produção, **sem inventar respostas ou uso**.

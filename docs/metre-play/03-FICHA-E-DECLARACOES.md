# MetreViewer — ficha da loja, declarações e materiais para revisão

> Rascunhos. `[[ ]]` = depende da Metre. Nada aqui foi enviado ao Console.

## 1. Ficha da loja

**Nome (≤ 30):** MetreViewer – Suporte Metre

**Descrição curta (≤ 80):** Suporte remoto da Metre: o técnico vê e, com sua permissão, controla o aparelho.

**Descrição completa:**
O MetreViewer é o aplicativo de suporte remoto da Metre para os aparelhos que usam os sistemas Metre.

Com ele, um técnico da Metre pode:
• ver a tela do aparelho durante o atendimento, depois que você aceita o pedido de captura de tela do Android;
• tocar, rolar e digitar no aparelho, se você ativar o controle (serviço de Acessibilidade "MetreViewer Input").

Como funciona
1. Abra o MetreViewer e siga os passos da tela inicial.
2. Informe ao técnico a identificação mostrada no aplicativo.
3. Durante o atendimento, o aplicativo mostra "Atendimento em andamento". Você pode encerrar a qualquer momento.

Uso do serviço de Acessibilidade
O MetreViewer usa a API de Acessibilidade do Android somente para executar os toques, gestos e teclas do técnico da Metre durante um atendimento. Para digitar, lê e altera o texto do campo ativo. O serviço não registra sua atividade e só age enquanto um técnico estiver conectado. Ele só é ativado depois de um aviso no aplicativo e da sua escolha nas configurações do Android, e pode ser desligado em Configurações > Acessibilidade.

O aplicativo não tem anúncios, não pede cadastro e não acessa câmera, microfone, contatos ou localização.

Baseado no RustDesk (AGPL-3.0). Código-fonte: https://github.com/bruno02034/metreviewer
Política de privacidade: [[URL]]

Não prometer: funcionamento sem nenhuma confirmação, controle em qualquer aparelho, ou "criptografia ponta a ponta".

**Categoria:** Ferramentas (ou Negócios) — [[decisão Metre]]
**Contato:** [[e-mail]], [[site]]

### Recursos gráficos necessários
- Ícone 512×512 PNG (existe arte do logo Metre; gerar no tamanho)
- Gráfico de destaque 1024×500
- Capturas de tela (mín. 2; recomendado tablet 7" e 10"): (1) tela inicial "Falta pouco" com o próximo passo; (2) aviso da Acessibilidade com "Concordo/Agora não"; (3) "Pronto para receber suporte" com a identificação; (4) "Atendimento em andamento" com o gerenciador de conexão; (5) tela do técnico no PC mostrando o tablet (opcional). **Usar dados de demonstração**, sem dados de cliente real.

### Notas da versão (primeira)
Primeira versão do MetreViewer na Google Play: suporte remoto Metre com visualização da tela e controle opcional por Acessibilidade.

## 2. Instruções de acesso para a revisão (campo "Acesso ao app")

> Pendente: confirmar como o técnico é autorizado (senha temporária ou aceitar no aparelho) — **ver pergunta Q2** — e validar o roteiro no Lenovo antes de enviar.

Rascunho:
1. Instale o MetreViewer neste aparelho e abra. Não é preciso criar conta.
2. Toque em "Ativar" no passo de captura e aceite o pedido do Android.
3. Para o controle: toque em "Ativar" no passo "Permitir que o técnico toque na tela", leia o aviso, toque em "Concordo" e ligue "MetreViewer Input" nas configurações de Acessibilidade.
4. Para conectar como técnico: em um PC Windows, baixe o MetreViewer para Windows em [[URL do instalador Windows]], digite a identificação mostrada no aparelho e clique em Conectar. [[autorização: senha mostrada em "Opções avançadas (técnico)" / botão Aceitar no aparelho]].
5. Para encerrar: no aparelho, use o botão de desconectar no cartão de atendimento; ou feche a sessão no PC. Para revogar o controle: Configurações > Acessibilidade > MetreViewer Input > desligar.
Se precisar de ajuda durante a revisão: [[contato]]. Servidores da Metre acessíveis sem restrição geográfica: [[confirmar]].

## 3. Declaração AccessibilityService (app que **não** é ferramenta de acessibilidade)
- **isAccessibilityTool:** não declarar (o app não é para pessoas com deficiência).
- **Por que usa a API:** Funcionalidade do app.
- **Coleta/compartilha dados pessoais ou sensíveis pela API?** Proposta: **Não** — o serviço lê o texto do campo ativo só para inserir o que o técnico digita; esse texto não sai do aparelho e não é guardado (verificado no código, e os logs que o registravam foram removidos em C2). A imagem da tela vai pela captura (MediaProjection), não pela API de Acessibilidade. [[confirmar com a Metre]]
- **Descrição do uso:** "Executar no aparelho os toques, gestos, rolagens e teclas enviados por um técnico da Metre durante um atendimento de suporte remoto iniciado com o consentimento do usuário. Para digitar, o serviço identifica o campo ativo e lê/altera seu texto. O serviço não monitora eventos (onAccessibilityEvent vazio) e só age por comando do técnico conectado."
- **Vídeo (≤ 2–3 min, sem cortes enganosos, sem dados reais):**
  1. Abrir o MetreViewer no tablet.
  2. Tela inicial → passo "Permitir que o técnico toque na tela" → tocar "Ativar".
  3. Mostrar o aviso inteiro (rolar devagar se necessário).
  4. Tocar **"Agora não"**: mostrar que o app continua, que o técnico só vê a tela, e como o aviso aparece de novo (tocar "Ativar" outra vez).
  5. Tocar **"Concordo"** → tela de Acessibilidade do Android → ligar "MetreViewer Input".
  6. Conectar pelo PC e mostrar o técnico tocando, rolando e digitando num campo de demonstração.
  7. Encerrar a sessão e desligar o serviço em Configurações > Acessibilidade.

## 4. Declaração de serviço em primeiro plano
| Tipo | Funcionalidade | Impacto se adiado/interrompido | Vídeo |
|---|---|---|---|
| mediaProjection | transmitir a tela ao técnico da Metre durante o atendimento, após o pedido de captura do Android | o técnico perde a imagem e o atendimento para | mostrar o usuário aceitando a captura e o técnico vendo a tela |
| specialUse (se mantido, P3) | manter o MetreViewer conectado ao servidor da Metre, com notificação permanente, para que o técnico consiga iniciar o atendimento quando o cliente pede ajuda; a captura só começa com o consentimento | o técnico não consegue alcançar o aparelho; o cliente precisa abrir o app e repetir os passos | mostrar a notificação permanente, a identificação "disponível" no PC e o pedido de captura ao iniciar |

## 5. Segurança dos dados (proposta — depende de B3)
| Pergunta | Proposta | Justificativa / pendência |
|---|---|---|
| Coleta ou compartilha dados? | **Sim** | ID/UUID, informações do aparelho e métricas saem do aparelho para a Metre e são guardados |
| Dispositivo ou outros IDs | Coletado; funcionalidade do app; obrigatório | ID MetreViewer + UUID |
| Informações e desempenho do app → Diagnóstico | Coletado; análise/funcionalidade; obrigatório | telemetria de desempenho |
| Informações e desempenho → Outros (informações do sistema) | Coletado; funcionalidade | sysinfo |
| Fotos e vídeos / conteúdo da tela | **Decisão**: o vídeo da tela é processado em tempo real e não guardado → pode ser **processamento efêmero** (não declarar). Se a Metre gravar atendimentos ou o relay guardar algo, declarar | [[confirmar que nada é gravado]] |
| Compartilhado com terceiros? | Não (hospedagem = prestador de serviço) | [[confirmar contratos]] |
| Criptografado em trânsito? | **Pendente** | API em HTTPS; registro no servidor de ID por protocolo próprio — verificar antes de responder "sim" |
| Usuário pode pedir exclusão? | [[Metre define]] | — |
| Criação de conta | Não aplicável: o app não permite criar conta | — |

## 6. Outros formulários
- Público-alvo: adultos (18+), uso profissional — [[confirmar]]. Não direcionado a crianças.
- Classificação de conteúdo: questionário IARC — app de utilitário sem conteúdo gerado/compartilhado publicamente.
- Anúncios: não contém.
- Apps de governo / financeiro / saúde: não aplicável.
- Acesso ao app: instruções da seção 2.

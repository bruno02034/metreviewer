# Política de Privacidade — MetreViewer

> **PUBLICADA em 20/11/2026:** https://bruno02034.github.io/metreviewer/privacidade.html (branch `gh-pages`). Este arquivo é a fonte; mudanças precisam ser repetidas no HTML publicado.

**Última atualização:** 20/11/2026

## 1. Quem somos
O MetreViewer é o aplicativo de suporte remoto da METRE SISTEMAS LTDA, CNPJ 27.330.329/0001-77, com sede na Rua Antonio D Maia do Amaral, 189, Bairro Val Paraíso, Patos de Minas – MG ("Metre").
Contato para privacidade: brunocarvalho@metresistemas.com.br.

## 2. Para que serve o aplicativo
O MetreViewer permite que um técnico da Metre veja a tela deste aparelho e, quando o usuário autoriza, toque e digite nele durante um atendimento de suporte. O aplicativo não tem anúncios e não exige criação de conta no aparelho.

## 3. Dados acessados, para que e para quem

| Dado | Quando | Finalidade | Quem recebe | Guarda |
|---|---|---|---|---|
| Imagem da tela | só durante um atendimento, depois que o usuário aceita o pedido de captura de tela do Android | permitir que o técnico veja o problema | o técnico da Metre conectado; quando a conexão direta não é possível, passa pelo servidor de retransmissão da Metre | o aplicativo não grava a tela; nem o aplicativo nem a Metre gravam a tela dos atendimentos |
| Toques, gestos e teclas do técnico | durante o atendimento, se o controle estiver ativado | executar a ajuda no aparelho | executados no próprio aparelho | não guardados |
| Texto do campo em que o técnico digita | durante o atendimento, se o controle estiver ativado | inserir o texto digitado pelo técnico | lido e alterado só no aparelho; não é enviado | não guardado |
| Área de transferência | durante o atendimento, quando o técnico usa copiar e colar | copiar e colar entre o PC do técnico e o aparelho | o técnico conectado | não guardada |
| Identificador do aparelho no MetreViewer, identificador interno de instalação e chave pública de conexão | enquanto o serviço está ativo | localizar o aparelho para o atendimento | servidores da Metre | enquanto cadastrado; apagado até 90 dias após a remoção |
| Informações técnicas do aparelho (modelo/nome, versão do Android, processador, memória, versão do app) e sinal de "aparelho disponível" | enquanto o serviço está ativo | mostrar ao técnico quais aparelhos estão disponíveis | servidores da Metre | enquanto cadastrado; apagado até 90 dias após a remoção |
| Métricas de desempenho do atendimento (quadros por segundo, tempos de processamento, resolução, tipo de codificador) | durante o atendimento | melhorar fluidez e diagnosticar falhas | servidores da Metre | até 90 dias |
| Endereço IP | ao conectar aos servidores | estabelecer a conexão | servidores da Metre; provedor de hospedagem Vultr (The Constant Company, LLC), com servidor em São Paulo, Brasil | até 90 dias |

Não acessamos câmera, microfone, contatos, localização, arquivos ou mensagens, e não vendemos dados.

## 4. Serviço de Acessibilidade
O MetreViewer usa o serviço de Acessibilidade do Android **somente** para executar os toques, gestos e teclas do técnico da Metre durante um atendimento. Para digitar, o serviço identifica o campo ativo e lê e altera o texto desse campo. Ele não registra a atividade do usuário, não envia o conteúdo da tela por esse serviço e não age quando não há um técnico conectado. O serviço só é ativado depois do aviso no aplicativo e da escolha do próprio usuário nas configurações do Android, e pode ser desligado a qualquer momento em Configurações > Acessibilidade > MetreViewer Input.

## 5. Segurança
A conexão entre o aparelho e o técnico é criptografada. A comunicação com a API da Metre usa HTTPS. Para iniciar um atendimento, o técnico precisa da identificação do aparelho e de uma autorização no próprio aparelho: a pessoa que está com ele toca em "Aceitar" (ou o técnico informa a senha de acesso do aplicativo). O atendimento pode ser encerrado a qualquer momento pelo aparelho..

## 6. Compartilhamento
Os dados não são compartilhados com terceiros, exceto prestadores que operam a infraestrutura da Metre em nome dela (Vultr — The Constant Company, LLC, servidor em São Paulo) e quando exigido por lei.

## 7. Seus controles
- Recusar ou interromper a captura de tela a qualquer momento (notificação do Android ou encerrando o atendimento no aplicativo).
- Desligar o controle em Configurações > Acessibilidade > MetreViewer Input.
- Desinstalar o aplicativo, o que encerra o envio de qualquer dado.
- Pedir acesso, correção ou exclusão dos dados pelo contato brunocarvalho@metresistemas.com.br. Resposta em até 15 dias.

## 8. Crianças
O aplicativo é destinado a estabelecimentos clientes da Metre e não é direcionado a crianças.

## 9. Código-fonte
O MetreViewer é baseado no RustDesk, software livre sob a licença AGPL-3.0. O código-fonte está em https://github.com/bruno02034/metreviewer.

## 10. Alterações
Mudanças nesta política serão publicadas nesta página com a nova data.

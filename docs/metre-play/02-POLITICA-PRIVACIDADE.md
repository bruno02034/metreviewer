# Política de Privacidade — MetreViewer

> **RASCUNHO.** Os campos entre `[[ ]]` dependem da Metre e não podem ser inventados.
> Publicar em URL pública, sem login, sem bloqueio geográfico, em HTML (não PDF), e usar a mesma URL no Play Console e no app.
> Revisar com o responsável jurídico/LGPD da Metre antes de publicar.

**Última atualização:** [[data]]

## 1. Quem somos
O MetreViewer é o aplicativo de suporte remoto da [[razão social da Metre]], CNPJ [[CNPJ]], com sede em [[endereço]] ("Metre").
Contato para privacidade: [[e-mail do encarregado/contato de privacidade]].

## 2. Para que serve o aplicativo
O MetreViewer permite que um técnico da Metre veja a tela deste aparelho e, quando o usuário autoriza, toque e digite nele durante um atendimento de suporte. O aplicativo não tem anúncios e não exige criação de conta no aparelho.

## 3. Dados acessados, para que e para quem

| Dado | Quando | Finalidade | Quem recebe | Guarda |
|---|---|---|---|---|
| Imagem da tela | só durante um atendimento, depois que o usuário aceita o pedido de captura de tela do Android | permitir que o técnico veja o problema | o técnico da Metre conectado; quando a conexão direta não é possível, passa pelo servidor de retransmissão da Metre | o aplicativo não grava a tela; [[confirmar se a Metre grava atendimentos — hoje o app não grava]] |
| Toques, gestos e teclas do técnico | durante o atendimento, se o controle estiver ativado | executar a ajuda no aparelho | executados no próprio aparelho | não guardados |
| Texto do campo em que o técnico digita | durante o atendimento, se o controle estiver ativado | inserir o texto digitado pelo técnico | lido e alterado só no aparelho; não é enviado | não guardado |
| Área de transferência | durante o atendimento [[confirmar após teste]] | copiar e colar entre o PC do técnico e o aparelho | o técnico conectado | não guardada |
| Identificador do aparelho no MetreViewer, identificador interno de instalação e chave pública de conexão | enquanto o serviço está ativo | localizar o aparelho para o atendimento | servidores da Metre | [[prazo de retenção]] |
| Informações técnicas do aparelho (modelo/nome, versão do Android, processador, memória, versão do app) e sinal de "aparelho disponível" | enquanto o serviço está ativo | mostrar ao técnico quais aparelhos estão disponíveis | servidores da Metre | [[prazo de retenção]] |
| Métricas de desempenho do atendimento (quadros por segundo, tempos de processamento, resolução, tipo de codificador) | durante o atendimento | melhorar fluidez e diagnosticar falhas | servidores da Metre | [[prazo de retenção]] |
| Endereço IP | ao conectar aos servidores | estabelecer a conexão | servidores da Metre; provedor de hospedagem [[nome do provedor]] | [[prazo de retenção dos registros]] |

Não acessamos câmera, microfone, contatos, localização, arquivos ou mensagens, e não vendemos dados.

## 4. Serviço de Acessibilidade
O MetreViewer usa o serviço de Acessibilidade do Android **somente** para executar os toques, gestos e teclas do técnico da Metre durante um atendimento. Para digitar, o serviço identifica o campo ativo e lê e altera o texto desse campo. Ele não registra a atividade do usuário, não envia o conteúdo da tela por esse serviço e não age quando não há um técnico conectado. O serviço só é ativado depois do aviso no aplicativo e da escolha do próprio usuário nas configurações do Android, e pode ser desligado a qualquer momento em Configurações > Acessibilidade > MetreViewer Input.

## 5. Segurança
A conexão entre o aparelho e o técnico é criptografada. A comunicação com a API da Metre usa HTTPS. [[Descrever controles de acesso dos técnicos — quem pode se conectar e como é autorizado]].

## 6. Compartilhamento
Os dados não são compartilhados com terceiros, exceto prestadores que operam a infraestrutura da Metre em nome dela ([[provedor de hospedagem]]) e quando exigido por lei.

## 7. Seus controles
- Recusar ou interromper a captura de tela a qualquer momento (notificação do Android ou encerrando o atendimento no aplicativo).
- Desligar o controle em Configurações > Acessibilidade > MetreViewer Input.
- Desinstalar o aplicativo, o que encerra o envio de qualquer dado.
- Pedir acesso, correção ou exclusão dos dados pelo contato [[e-mail]]. [[Prazo de atendimento]].

## 8. Crianças
O aplicativo é destinado a estabelecimentos clientes da Metre e não é direcionado a crianças.

## 9. Código-fonte
O MetreViewer é baseado no RustDesk, software livre sob a licença AGPL-3.0. O código-fonte está em https://github.com/bruno02034/metreviewer.

## 10. Alterações
Mudanças nesta política serão publicadas nesta página com a nova data.

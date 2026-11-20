# Decisões registradas

| Data | Decisão | Consequência |
|---|---|---|
| 20/11/2026 | Publicar na **conta pessoal** do desenvolvedor (nenhum app criado ainda) | Teste fechado obrigatório: ≥ 12 testadores inscritos por 14 dias consecutivos antes de pedir produção (vale para contas pessoais criadas após 13/11/2023 — confirmar no painel). Risco a acompanhar: app que representa a Metre publicado por pessoa física; a ficha deve deixar claro que é o app de suporte da Metre e quem o publica. A transferência para uma conta da Metre continua possível depois |
| 20/11/2026 | App criado no Console: `com.metre.viewer`, "MetreViewer", pt-BR, app | Painel confirma: teste interno liberado; **teste fechado bloqueado até terminar a configuração do app**; produção exige versão de teste fechado, ≥ 12 testadores inscritos e 14 dias com ≥ 12 |
| 20/11/2026 | **Chave de assinatura gerada pela Google** (Play App Signing) | A chave atual da Metre (`B9:CC:73…`) passa a ser só a chave de upload. Tablets com o APK instalado por arquivo **não** atualizam pela Play: precisam desinstalar o APK e instalar pela Play (o ID do aparelho no MetreViewer muda). O teste T-L4 deixa de se aplicar |
| 20/11/2026 | Autorização da sessão: o técnico usa "Aceitar" no aparelho (senha também funciona) | As instruções do revisor e dos testadores usam o fluxo de aceitar no próprio aparelho |
| 20/11/2026 | Gerar build com C1–C5 agora; o link da política no app fica para o build seguinte | Este build serve ao teste interno; para a revisão de produção será preciso outro build com o link (A3) |
| 20/11/2026 | Política de privacidade publicada no GitHub Pages: https://bruno02034.github.io/metreviewer/privacidade.html — razão social METRE SISTEMAS LTDA, contato brunocarvalho@metresistemas.com.br, guarda de 90 dias, resposta a pedidos em 15 dias | O servidor da API precisa cumprir os prazos de guarda. Link no app (tela principal e Configurações) entra no próximo build |

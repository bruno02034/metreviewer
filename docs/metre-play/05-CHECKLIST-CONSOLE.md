# Checklist do Play Console (ordem de execução)

Nada foi feito no Console. Cada passo marcado com quem executa.

1. ✅ Conta pessoal, sem apps (20/11). Conferir no painel, depois de criar o app, se aparece o requisito de teste fechado.
2. ✅ Chave de assinatura: **gerada pela Google** (ver `00-DECISOES.md`). Ao criar o app, aceitar a opção padrão do Play App Signing; o AAB assinado pela chave da Metre vira a chave de upload.
3. [você] Autorizar o push das correções C1–C5 → [Claude] reauditar o AAB gerado (versionCode, certificado, manifesto, 16 KB) e registrar SHA-256.
4. [você] Criar o app `com.metre.viewer` (se ainda não existe): nome, idioma padrão pt-BR, app (não jogo), gratuito.
5. [você] Configurar Play App Signing conforme o passo 2.
6. [Metre] Publicar a política de privacidade (rascunho `02-…`) em URL pública → [Claude] apontar o link do app para ela (A3) — entra no mesmo build do passo 3 se a URL existir antes.
7. [você] Conteúdo do app: política de privacidade, acesso ao app (instruções `03-…` §2), anúncios (não), classificação de conteúdo, público-alvo, Segurança dos dados (`03-…` §5), declaração de Acessibilidade, declaração de serviço em primeiro plano (vídeos).
8. [você] Ficha da loja: textos e gráficos (`03-…` §1).
9. [você] Teste interno: criar faixa, adicionar sua conta e a do laboratório, enviar o AAB do passo 3. A primeira versão passa por revisão.
10. [laboratório] T-L1 e T-L4 no Lenovo, T-M no M10 (se tiver Play), casos T1–T12. → só então seguir.
11. [você] Teste fechado (se exigido): faixa, lista de testadores, recrutamento (`04-…` §4), 14 dias consecutivos com ≥ 12 inscritos.
12. [você] Pedido de acesso à produção com respostas baseadas nos registros reais.
13. [você] Produção: enviar para revisão; evitar novos envios durante a revisão salvo correção necessária.

## Parecer (20/11/2026)
| Etapa | Situação | Motivo |
|---|---|---|
| Teste interno | **Ainda não** | falta build com C1 (versionCode) e a decisão de chave (passo 2). Com isso, pode ir |
| Teste fechado | **Ainda não** | depende do teste interno passar T-L1 e da política de privacidade |
| Pedido de produção | **Não** | depende da conta (C) e do teste fechado, se exigido |
| Submissão à revisão | **Não** | declarações, vídeos, política e Segurança dos dados pendentes; funcionalidade não validada em aparelho pela Play |

# Prompt de implementação — UNEX PLAY Neo Glass

Use este texto com um agente de programação que tenha acesso a todo o repositório Flutter.

---

Você é um engenheiro Flutter sênior especializado em UX de streaming para Android mobile e Android TV. Implemente a evolução visual do UNEX PLAY com base em `docs/UNEX_PLAY_UI_UX_IMPLEMENTATION.md`. Leia primeiro o documento completo e inspecione todos os arquivos existentes; não invente APIs nem assuma que trechos isolados representam o fluxo completo.

## Direção visual

Adote uma estética premium dark com superfícies em camadas, vidro sutil somente em overlays/navegação, roxo `#7657FF` e azul `#2F80FF` como cores de marca. Preserve fundo escuro, contraste, legibilidade e desempenho. Não aplique blur em cada cartão. Centralize tokens de cor, tipografia, espaçamento, formas, foco e animação em uma camada de design reutilizável.

## Ordem obrigatória

1. Antes de editar, mapeie o que funciona e identifique contratos entre `main.dart`, `mobile_screen.dart`, `tv_screen.dart`, `widgets.dart`, `player_screen.dart`, `core.dart` e `ativacao_screen.dart`.
2. A primeira iteração visual já foi parcialmente aplicada neste pacote: tokens roxo/azul, menu de ações mobile, preview adaptativo, grade responsiva e sidebar de TV mais legível. Revise esses diffs, corrija qualquer problema e não remova os comportamentos existentes.
3. Complete a migração incremental de superfícies/tipografia/espaçamento para tokens e melhore estados vazios/erro/loading.
4. Valide a navegação D-pad/Back e o foco da TV; depois, em alteração separada, introduza destinos tipados para adicionar Home e Minha Lista. Atualize conjuntamente todos os filtros/callbacks/menus que usam os números atuais. Nunca troque apenas rótulos nem renumere seções parcialmente.
5. Acrescente tratamento de imagem indisponível sem mudar o contrato de dados do player.
6. Faça revisão final de regressão e forneça lista exata dos arquivos alterados, mudanças, limitações e resultados reais de build/teste.

## Regras de proteção

- NÃO reescrever nem remover `SharedStreamEngine`, parser M3U/Xtream, lógica de autenticação/ativação, favoritos, histórico, progresso, PIN parental ou adaptação a controle remoto para atender ao design.
- NÃO remover verificações de bloqueio parental nem inventar metadados que a playlist não fornece.
- NÃO adicionar dependências externas sem explicar necessidade, custo e compatibilidade com a pipeline atual.
- NÃO substituir imagens por logos/posters fixos ou conteúdo de demonstração no build de produção.
- Manter listas longas com builders preguiçosos, controlar dimensões de imagens e evitar operações caras dentro de `build()`.
- Para TV, todo controle importante precisa de foco visível e ser operável via D-pad; Back fecha o nível mais interno antes de sair.
- Para mobile, alvos de toque devem ser confortáveis; não fazer do long-press o único caminho para uma ação.

## Validação exigida

Execute `flutter analyze`, os testes existentes e o build definido pelo workflow. Se o projeto não puder ser compilado localmente, informe isso claramente e use a pipeline configurada para validação. Não declare build aprovado sem resultado real. Teste manualmente mobile e Android TV nos fluxos de playlist, busca, canal ao vivo, tela cheia, detalhe/filme, série/episódio, favoritos, histórico, retomar reprodução e controle parental. Registre também os testes de D-pad e Back.

Entregue mudanças incrementais, consistentes com os arquivos existentes e sem refatorar funcionalidades não relacionadas. Quando alguma alteração envolver risco para o player ou dados persistidos, separe-a em commit/fase distinta.

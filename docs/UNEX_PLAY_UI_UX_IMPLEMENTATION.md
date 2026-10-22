# UNEX PLAY — Especificação de Interface e Usabilidade

**Versão:** 1.0  
**Data:** 22 de outubro de 2026  
**Escopo:** Flutter, Android mobile e Android TV/Smart TV  
**Objetivo:** transformar a direção visual do mockup (dark, vidro sutil, roxo e azul) em um sistema de interface consistente, acessível e rápido, adaptado à estrutura que já existe no repositório.

> Este documento é a especificação de produto e implementação para orientar uma refatoração incremental. Não substitui testes em dispositivos reais. O ZIP analisado não contém `pubspec.yaml` nem uma instalação local do Flutter; o workflow do GitHub Actions gera o manifesto e a estrutura Android durante o build.

### Estado desta entrega

Foram aplicadas no código as primeiras melhorias de baixo risco:

- `lib/design/unex_design_tokens.dart` centraliza a paleta de marca roxo–azul e alguns tokens básicos.
- As cores ciano usadas como destaque foram migradas para os novos tokens em telas, cartões, ativação e player.
- `lib/mobile_screen.dart` agrupa teste de velocidade, atualização de lista e troca de lista em um menu “Mais opções”, reduzindo a quantidade de ações no cabeçalho.
- A prévia de TV ao vivo passou a ter altura adaptativa com limite de 118–160 px, em vez de altura fixa de 190 px.
- A grade mobile passou a escolher 2, 3 ou 4 colunas conforme a largura disponível.
- A navegação lateral de TV ganhou mais largura e rótulos mais legíveis.

Ainda não foi adicionada a nova aba “Início” nem foi agrupado Favoritos/Histórico em “Minha Lista”. Essa etapa exige migrar de forma coordenada os índices numéricos usados nos filtros e callbacks de `main.dart`; fazer isso apenas pelo menu criaria risco de filtros errados. A aplicação dessas mudanças visuais ainda precisa de `flutter analyze`, build de CI e validação manual em celular e TV. O ambiente desta edição não tem o SDK Flutter/Dart instalado e o ZIP original delega a geração do `pubspec.yaml` ao workflow.

---

## 1. Decisão de design

A direção visual recomendada é **UNEX PLAY — Neo Glass**: fundo azul-marinho quase preto, superfícies em camadas, transparência usada com parcimônia, bordas suaves e um gradiente roxo–azul como assinatura visual. A interface deve parecer premium sem sacrificar legibilidade, velocidade ou previsibilidade.

O princípio central não é “colocar vidro em tudo”. O efeito glass deve aparecer em áreas pontuais — barra superior, menus contextuais, diálogos e controles sobre vídeo. Cartões de catálogo e listas extensas devem usar superfícies opacas leves para evitar excesso de blur e custo de renderização.

### Princípios inegociáveis

1. **O conteúdo vem primeiro.** O cabeçalho e os controles devem ocupar o mínimo necessário.
2. **A ação principal é evidente.** O usuário deve saber como reproduzir, pausar, voltar e adicionar à lista.
3. **Cada dispositivo tem sua própria ergonomia.** No celular, toque e rolagem; na TV, foco explícito e D-pad.
4. **Fluidez é parte do design.** Evitar reconstruções desnecessárias, transições longas, imagens grandes fora de escala e blur em grandes áreas repetidas.
5. **Não quebrar o que funciona.** Parser de playlist, login/ativação, engine do player, histórico, progresso, favoritos, bloqueio parental e navegação por controle remoto são contratos funcionais a preservar.
6. **Estados claros.** Carregamento, erro de rede, lista vazia, imagem indisponível, conteúdo bloqueado e ausência de EPG precisam ter um tratamento de interface explícito.

## 2. Diagnóstico do repositório atual

A implementação atual tem uma base útil; não é necessário começar do zero.

| Área encontrada | Arquivo/componente | Implicação para a evolução |
|---|---|---|
| Tema global escuro e paleta ciano/azul | `lib/main.dart` → `UnexVisionApp` | Centralizar tokens antes de trocar cores literais espalhadas pelo projeto. |
| Estado, filtro, sessão, playlist, favoritos, histórico e progresso | `lib/main.dart` → `UnexRootController` | Evitar reescrever o controlador junto com mudanças visuais. Separar estado visual de regra de negócio. |
| Interface mobile | `lib/mobile_screen.dart` → `MobileLayoutScreen` | Simplificar topo, adaptar grade à largura e reduzir a área fixa do preview ao vivo. |
| Interface TV e foco de navegação | `lib/tv_screen.dart` → `TVLayoutScreen` | Preservar o grafo de foco e melhorar legibilidade, foco, espaçamento e retorno. |
| Cartões de pôster, logos, botões e diálogos auxiliares | `lib/widgets.dart` | Tornar os elementos visuais consistentes através de componentes compartilhados. |
| Reprodução compartilhada | `lib/core.dart` → `SharedStreamEngine` e `lib/player_screen.dart` | Não alterar a engine como parte de uma refatoração puramente visual. Testar transições de preview para tela cheia. |
| Ativação por código | `lib/ativacao_screen.dart` | Atualizar estilo, mas preservar os seis campos, formatação, avanço automático e uso com controle remoto. |

### Pontos específicos observados

- A navegação atual usa índices inteiros: `0 = TV ao Vivo`, `1 = Filmes`, `2 = Séries`, `3 = Favoritos`, `4 = Histórico`. Vários filtros em `main.dart` dependem desses valores. **Não basta trocar os rótulos no menu** para criar uma aba “Início”; isso pode fazer a aba filtrar a categoria errada.
- Na interface mobile, o preview ao vivo é um contêiner fixo de `190 px` e fica abaixo do AppBar, campo de busca, chips de categoria e espaçamento. Em aparelhos baixos, o conjunto reduz a área disponível para a lista. Esta é uma prioridade de usabilidade.
- A grade de filmes/séries no celular usa `crossAxisCount: 3` fixo. Em celulares estreitos, os títulos e pôsteres podem ficar pequenos. A quantidade de colunas deve responder à largura disponível.
- O menu lateral da TV tem largura aproximada de `106 px`; os rótulos usam fonte de `10 px`. Para uso à distância, a navegação merece mais largura e texto maior, sem exagerar a área ocupada pelo menu.
- A base já possui `TVFocusableItem` e `FocusNode`s dedicados. O novo visual precisa manter um caminho previsível entre navegação, busca, categorias e conteúdo.
- O cartão de catálogo usa `Image.network` e `cacheWidth: 320`. A estratégia deve continuar dimensionada para a tela, com placeholder/erro e sem decodificar pôsteres em resolução muito maior que a necessária.

## 3. Sistema visual proposto

Centralizar os tokens em um arquivo, por exemplo `lib/design/unex_design_tokens.dart`, e aplicá-los primeiro aos componentes compartilhados. Evitar fazer substituições cegas em todos os valores de cor: rever estados selecionado/focado/erro em cada contexto.

### 3.1 Cores semânticas

| Token | Valor inicial | Uso |
|---|---|---|
| `background` | `#070A12` | Fundo geral das telas. |
| `surface` | `#0D1421` | Barra inferior, painéis e listas. |
| `surfaceElevated` | `#131D2D` | Cartões, linhas selecionadas e painéis elevados. |
| `surfaceGlass` | `#141B2BCC` | Sobreposições pontuais; alfa aproximado de 80%. |
| `primary` | `#7657FF` | Ação principal, seleção e elementos de marca. |
| `secondary` | `#2F80FF` | Complemento do gradiente e links secundários. |
| `focus` | `#B9ACFF` | Contorno de foco visível, particularmente na TV. |
| `live` | `#F0445B` | Estado “AO VIVO” e alertas de transmissão. |
| `success` | `#37C995` | Confirmações e estados bem-sucedidos. |
| `textPrimary` | `#F7F8FC` | Título e informação principal. |
| `textSecondary` | `#A8B1C2` | Metadados e textos auxiliares. |
| `textDisabled` | `#737E92` | Conteúdo desabilitado, sem ser usado em informação essencial. |
| `borderSubtle` | branco com 8–12% de opacidade | Separação de superfícies. |

Os valores são uma proposta inicial, não uma regra de contraste certificada. Validar contraste real entre cada par de texto e fundo. Para texto comum, adotar como meta WCAG 2.2 AA de pelo menos 4,5:1; para texto grande, 3:1. Não comunicar estado apenas com cor.

### 3.2 Tipografia

Usar a família sem serifa já disponível no sistema/Flutter no primeiro passo, evitando introduzir fontes externas antes de avaliar custo e licença. Criar estilos nomeados, sem tamanhos arbitrários por widget.

| Estilo | Celular | TV (referência inicial) | Aplicação |
|---|---:|---:|---|
| `display` | 28–32 sp | 36–44 sp | Título hero/título de seção principal. |
| `titleLarge` | 22–24 sp | 28–32 sp | Nome da obra e cabeçalhos. |
| `titleMedium` | 17–20 sp | 22–26 sp | Nome de canal/cartão selecionado. |
| `body` | 14–16 sp | 18–22 sp | Descrições e conteúdo geral. |
| `label` | mínimo 12 sp | mínimo 16 sp | Categoria, metadados e status. |

Os tamanhos de TV precisam ser calibrados em uma televisão real a distância normal de uso. Evitar texto de navegação de 10 sp na TV.

### 3.3 Espaçamento, formas e movimento

- Escala de espaçamento: `4, 8, 12, 16, 20, 24, 32, 40`.
- Raios: `10–12` para controles pequenos; `14–16` para cartões; `20–24` para painéis grandes.
- Toque no mobile: altura mínima alvo de `48 dp` para ação importante; garantir espaço entre botões como favorito e abrir conteúdo.
- Foco de TV: contorno de `2–3 dp`, contraste inequívoco, pequena elevação/sombra e escala discreta de aproximadamente `1.03–1.05`.
- Transições usuais: `120–180 ms`. Não animar todas as imagens ou linhas ao mesmo tempo; impedir que a animação atrase a confirmação do controle remoto.
- Efeito de vidro: reservar para superfícies de navegação e overlays. Evitar `BackdropFilter`/blur em cada item de uma grade grande.

## 4. Arquitetura de navegação sugerida

A estrutura de destino recomendada no produto é:

1. **Início** — continuar assistindo, acesso rápido ao último canal, sugestões e atalhos para gêneros.
2. **TV ao Vivo** — canais, categorias, pesquisa, canal selecionado, programação/EPG quando disponível e favoritos.
3. **Filmes** — catálogo, gêneros, pesquisa, detalhes, qualidade/idiomas quando os metadados existirem.
4. **Séries** — catálogo, temporadas e episódios, retomada do episódio, próxima reprodução quando suportada.
5. **Minha Lista** — favoritos e histórico/itens vistos, com filtros internos para canais, filmes e séries.

**Migração segura:** atualmente, o aplicativo oferece cinco destinos com índices `0–4`. Antes de introduzir “Início” e agrupar Favoritos/Histórico em “Minha Lista”, refatorar os índices mágicos para um enum ou modelo de destino tipado e atualizar, na mesma mudança, menu, callbacks, filtros, listas, categorias e lógica de back. Fazer testes de regressão de cada destino. Não colocar um novo rótulo em um índice antigo sem migrar seu comportamento.

Se a mudança de navegação completa for grande para a primeira entrega, lançar primeiro o sistema visual e a correção do mobile mantendo os cinco destinos atuais; a nova arquitetura de navegação entra numa etapa própria.

### Busca

- Manter acesso à busca sempre fácil, mas compacta.
- A busca deve preservar o texto ao voltar de detalhes para os resultados, quando apropriado.
- Oferecer limpar busca com um toque, feedback para “nenhum resultado” e resultados filtrados sem travar a digitação.
- Se for unificada entre canais/filmes/séries, permitir filtrar o tipo sem apagar a consulta.
- Na TV, o botão de pesquisa deve abrir um teclado virtual legível e navegável por D-pad; `Back` fecha primeiro o teclado, depois retorna à tela anterior.

## 5. Especificação por dispositivo

### 5.1 Celular — cabeçalho compacto

A primeira dobra precisa privilegiar conteúdo, e não controles fixos.

- AppBar de aproximadamente `48–56 dp`, com marca discreta e 1–2 ações no máximo. Agrupar velocidade, atualizar lista, trocar lista/conta e configurações num menu “Mais” ou painel de ações, mantendo o que é frequente acessível.
- Busca com altura de `44–48 dp`; não adicionar uma segunda faixa alta de controles.
- Categorias/chips numa única linha horizontal, com altura total perto de `36–40 dp` e rolagem horizontal.
- Se houver uma categoria selecionada, mostrar sua contagem quando esse dado for confiável; não acrescentar estatísticas fictícias.
- Barra inferior com cinco destinos no máximo e rótulos curtos. Ações menos frequentes vão para “Mais” ou “Minha Lista”. Respeitar a área segura do dispositivo.

### 5.2 Celular — TV ao Vivo e mini player

- Trocar a altura fixa de `190 px` por altura adaptativa baseada nas restrições disponíveis; usar proporção `16:9` como ponto de partida, com limite em telas baixas e opção evidente de expandir para tela cheia.
- No modo compacto, objetivo inicial é o player não consumir mais de cerca de 20–25% da altura útil em telas comuns; esse alvo deve ser validado por teste, não tratado como regra absoluta.
- Considerar player recolhível (mini player) ao rolar a lista. O estado do player não deve se perder ao navegar pelas categorias.
- A linha do canal precisa mostrar logo/placeholder, nome, categoria e estado ao vivo; metadados EPG só aparecem se existirem. Favorito deve ser ação independente, com feedback discreto e área de toque confortável.
- Um toque no canal seleciona/troca canal; toque no canal já selecionado ou ação dedicada abre tela cheia. A ação deve ser previsível e testada, já que hoje há diferença entre selecionar e abrir a tela cheia.
- Carregamento do player deve distinguir “conectando”, “sem sinal/erro” e “pronto”, com ação de tentar novamente quando possível.

### 5.3 Celular — filmes e séries

- Substituir a grade fixa de três colunas por uma grade adaptativa baseada na largura disponível. Como ponto de partida: 2 colunas em celulares estreitos, 3 em aparelhos largos e 4+ em tablets, sempre validando o tamanho final do cartão.
- Manter proporção de pôster próxima de `2:3` (`childAspectRatio` próximo de `0.67`), com títulos até duas linhas e sem corte que impeça distinguir títulos longos.
- Exibir pôster, título, progresso (se houver), selo de qualidade só quando confiável e favorito. Evitar muitos badges sobre a imagem.
- Tap abre detalhes ou reproduz diretamente conforme uma regra consistente por tipo de conteúdo; não usar gesto de pressão longa como única forma de descobrir como favoritar. Expor botão de favorito visível nos detalhes e, se couber sem poluição, no cartão.
- Para séries, mostrar quantidade de temporadas/episódios apenas quando calculada dos dados reais; a ação primária abre detalhes/temporadas e destaca o próximo episódio quando existir histórico compatível.

### 5.4 TV / Android TV

A TV deve ser uma interface de “10 pés”: texto grande, conteúdo destacado e navegação exclusivamente possível com controle remoto.

- Usar margem segura próxima de 5% em telas grandes para reduzir risco de corte nas bordas.
- Aumentar a largura da barra lateral além dos atuais `106 px` conforme a resolução; em 1920 px, testar algo na faixa de `132–160 px`. O menu deve ter ícone e texto legíveis, não apenas ícone pequeno.
- Organizar foco em trilhas previsíveis: navegação lateral → busca → categorias → conteúdo. A seta esquerda/direita não deve deixar o foco “preso” nem enviar o usuário aleatoriamente a outro painel.
- Elemento focado precisa ter contorno evidente e preenchimento/elevação; o elemento apenas selecionado precisa ser visualmente diferente do elemento atualmente focado.
- Não fazer autoplay de trailers ou vídeos de destaque com som. Caso a prévia exista, iniciar silenciosa e permitir desativação em configurações.
- O botão “Voltar” deve seguir uma pilha previsível: fechar teclado/diálogo/overlay, depois voltar de detalhes para catálogo, e somente então retornar para a navegação principal ou sair conforme contexto.
- Ao fechar um detalhe ou o player, restaurar o foco para o item anterior sempre que ele ainda existir.
- Cartões de TV maiores do que os de celular; títulos e descrições limitados a linhas úteis. O foco não deve ser escondido sob um overlay nem cortado por uma lista.
- Garantir operação completa sem touchscreen: abrir seções, pesquisar, selecionar categoria, navegar canais, alternar favorito, abrir detalhes, reproduzir, pausar, alterar opções disponíveis e sair.

### 5.5 Home de referência

Proposta de hierarquia para Início, quando a navegação tipada for implementada:

1. Topo compacto: marca, busca/atalho e perfil/mais.
2. Destaque principal pequeno ou médio, somente quando houver imagem e metadados de confiança.
3. “Continuar assistindo”, alimentado por `watchProgress`/histórico real.
4. “Retomar TV ao Vivo” com o último canal válido, se a origem e o estado do player permitirem.
5. Acesso rápido a TV ao Vivo, Filmes e Séries.
6. Coleções/gêneros com dados reais.

Não inventar banner, sinopse, duração, avaliação ou metadados quando a playlist não os fornece. Para catálogo baseado apenas em M3U, a primeira entrega pode usar uma Home editorial simples formada por “Continuar assistindo”, “Canais favoritos” e atalhos, com fallback claro caso não haja dados suficientes.

## 6. Detalhes, player e estados

### Detalhes de filme/série

- Informações essenciais acima da dobra: título, ano/qualidade/duração apenas quando disponível, sinopse se existir, botões “Assistir/Continuar” e “Adicionar à Minha Lista”.
- Série: seletor de temporada fácil de navegar; cada episódio mostra título/numeração e progresso quando disponível.
- Indicar claramente se o conteúdo está bloqueado por controle parental e oferecer o fluxo de PIN já existente. Não revelar conteúdo adulto por imagem ou autoplay antes do desbloqueio.

### Player

Preservar `SharedStreamEngine` como fonte central da reprodução. A camada visual precisa priorizar:

- estado do vídeo e controles básicos facilmente descobertos;
- controles que somem após inatividade, mas reaparecem com OK/toque;
- feedback visível para buffer/erro e possibilidade de nova tentativa sem voltar várias telas;
- opção de escala/proporção sem cortar conteúdo por padrão;
- preferências de áudio/legenda apenas quando a fonte oferece essas opções;
- mudança de canal e retorno à lista sem reconstruir toda a aplicação;
- proteção contra múltiplos comandos de play/troca durante a fase de inicialização.

### Estados obrigatórios

| Estado | Resposta visual e ação |
|---|---|
| Playlist carregando | Skeleton/indicador discreto e texto compreensível; bloquear apenas ações incompatíveis. |
| Playlist vazia | Explicar que nenhum conteúdo foi encontrado e oferecer atualizar lista/trocar fonte. |
| Imagem ausente ou URL inválida | Placeholder coerente com tipo de conteúdo; não deixar espaço preto inexplicável. |
| Busca sem resultado | Mostrar consulta, oferecer limpar filtros/consulta e não apresentar tela morta. |
| Stream conectando | Indicador com mensagem curta; evitar spinner indefinido sem feedback. |
| Falha de reprodução | Mensagem contextual, tentar novamente e voltar ao catálogo sem perder seleção. |
| Sem EPG | Ocultar metadados indisponíveis ou mostrar “Programação não disponível”, sem inventar dados. |
| Conteúdo bloqueado | Tela/overlay claro, acesso a PIN e retorno seguro. |
| Favorito alterado | Confirmação breve e acessível sem bloquear navegação. |

## 7. Desempenho percebido e implementação Flutter

1. Centralizar cores, raios, espaçamentos, tipografia e duração de animação em tokens.
2. Criar widgets reutilizáveis pequenos: `UnexSearchField`, `UnexCategoryChip`, `UnexPosterCard`, `UnexChannelTile`, `UnexSectionHeader`, `UnexGlassPanel`, `UnexEmptyState` e `UnexFocusOutline`.
3. Usar `ListView.builder`/`GridView.builder` para coleções. Manter o trabalho de cada `build()` leve e evitar cálculos caros para todos os itens em toda reconstrução.
4. Não decodificar imagens de tamanho excessivo; manter `cacheWidth`/`cacheHeight` proporcionais ao espaço renderizado e ao DPR, com limites razoáveis. Aplicar cache persistente de imagem só com uma estratégia/pacote avaliado no projeto.
5. Usar placeholders de dimensão estável para evitar saltos durante carregamento. Tratar falha de rede de imagens.
6. Não adicionar blur, sombras enormes ou gradientes animados em todos os cartões.
7. Evitar refazer estado global a cada tecla da busca; filtrar de maneira eficiente e preservar o foco/posição da lista.
8. Testar perfis Flutter em dispositivo real e medir frame time; não concluir que a tela é fluida só porque funciona no emulador.
9. Isolar alterações visuais da engine, parser M3U, autenticação e armazenamento. Não “otimizar” o player no mesmo commit de uma alteração grande de navegação.

## 8. Acessibilidade e controle parental

- Aplicar os critérios WCAG 2.2 AA como referência para contraste, ampliação de texto e foco; a conformidade final deve ser avaliada por plataforma.
- Todos os botões com rótulo semântico/tooltip apropriado e área de toque confortável.
- Não transmitir estado apenas por cor: “Ao vivo”, “Favorito”, “Bloqueado” e “Selecionado” também precisam de ícone/texto/semântica.
- Respeitar escala de fonte e verificar que o layout não estoura com tamanho maior.
- Na TV, todos os elementos funcionais devem ser acessíveis via D-pad, sem depender de gesto longo ou mouse.
- Manter o bloqueio parental dentro do fluxo de acesso existente; nunca remover verificação para facilitar testes visuais.
- Evitar dados pessoais na tela de TV sem necessidade, pois o dispositivo costuma ser compartilhado.

## 9. Plano de implementação incremental

### Fase 0 — proteção de regressões

- Criar baseline de comportamento e registrar quais fluxos funcionam no APK atual.
- Manter cópia/branch antes de alterações.
- Conferir o workflow do GitHub Actions, já que o repositório gera `pubspec.yaml` e estrutura Android dinamicamente.

### Fase 1 — sistema visual e mobile (menor risco)

- [x] Adicionar tokens centrais para paleta de marca e aplicá-los às cores de destaque.
- [x] Agrupar ações secundárias da AppBar mobile em “Mais opções”.
- [x] Tornar a altura da prévia ao vivo adaptativa (118–160 px).
- [x] Tornar a grade de catálogo responsiva (2/3/4 colunas conforme a largura).
- [ ] Completar a migração dos estilos de superfície, tipografia, raio e espaçamento para tokens compartilhados.
- [ ] Avaliar o cartão de pôster para tornar favorito uma ação visível sem depender apenas de pressão longa.
- [ ] Testar celular estreito, celular alto, fonte ampliada, playlist vazia e imagem inválida.
- Não alterar o índice das cinco seções existentes nesta fase.

### Fase 2 — refinamento Android TV

- Aplicar tamanhos de texto e margens seguros.
- Melhorar menu lateral e estados selecionado/focado sem alterar as rotas das teclas.
- Mapear e testar todas as transições de foco; restaurar foco após detalhes/player/diálogos.
- Validar controle remoto real e teclas de seta/OK/Back.

### Fase 3 — arquitetura de navegação e Home

- Substituir índices mágicos por um enum/modelo de destinos.
- Atualizar filtros, callbacks, categorias e navegação em uma única alteração atômica.
- Introduzir Home com dados reais; agrupar Favoritos/Histórico em “Minha Lista” se a decisão de produto for confirmada pelo protótipo.
- Preservar compatibilidade de favoritos, histórico e progresso existentes.

### Fase 4 — testes e acabamento

- Corrigir erros de overflow/foco.
- Medir fluidez e latência de início do vídeo em rede boa e ruim.
- Executar teste de regressão em APK de celular e Android TV.
- Fazer teste de usabilidade antes do lançamento; ajustar conforme observação real.

## 10. Matriz priorizada

| ID | Requisito | Prioridade | Critério de aceite |
|---|---|---|---|
| UX-01 | Corrigir proporção do preview ao vivo no celular | P0 | Em telas baixas, player não domina a primeira dobra; lista permanece claramente acessível. |
| UX-02 | Grid de catálogo responsivo | P0 | Pôsteres e títulos legíveis em larguras estreitas, sem overflow. |
| UX-03 | Tokens de design e consistência visual | P0 | Cores, raio, tipografia e foco controlados por tokens, sem divergências críticas. |
| UX-04 | Preservar reprodução e troca de canal | P0 | Preview → tela cheia → voltar à lista funciona sem reinicialização inesperada. |
| UX-05 | Regredir favoritos/histórico/progresso/PIN | P0 | Os dados e o bloqueio parental continuam funcionais após a alteração. |
| UX-06 | Foco TV e retorno previsível | P0 | Todas as ações alcançáveis com D-pad; foco não desaparece após fechar telas. |
| UX-07 | Estados vazios/erro/loading | P1 | Cada estado tem mensagem e ação útil; nenhum spinner infinito sem contexto. |
| UX-08 | Home/Minha Lista com navegação tipada | P1 | A nova tela não altera incorretamente o filtro de outros destinos. |
| UX-09 | Glass effects pontuais | P1 | Estilo aparece em superfícies selecionadas, mantendo frame time aceitável. |
| UX-10 | Telemetria de qualidade de reprodução | P1 | Medir startup, buffering, erro e abandono sem gravar dados excessivos. |
| UX-11 | Ajustes de acessibilidade | P1 | Contraste, rótulos, escala de texto e foco verificados com checklist. |
| UX-12 | Teste com usuários | P1 | Tarefas principais observadas em mobile e TV antes de considerar concluído. |

## 11. Checklist de QA para cada release

### Funcionalidade
- [ ] Carregamento por fonte/ativação continua funcionando.
- [ ] Filtrar categorias e pesquisar não bloqueia a interface.
- [ ] Favoritos adicionam/removem itens e persistem como antes.
- [ ] Histórico e progresso continuam registrados.
- [ ] PIN parental não pode ser contornado por cartão, detalhe, pesquisa ou player.
- [ ] Selecionar canal, abrir tela cheia, voltar e trocar canal preserva o comportamento esperado.
- [ ] Detalhes de série, temporada e episódio continuam navegáveis.

### Celular
- [ ] Cabeçalho, busca e categorias não empurram conteúdo desnecessariamente para baixo.
- [ ] Preview ao vivo é adaptável e existe uma ação óbvia para tela cheia.
- [ ] Grade adequada em larguras de 320, 360, 390 e 430 dp e em tablet.
- [ ] Botões de toque têm tamanho confortável; não há gestos longos como único caminho.
- [ ] Fonte ampliada não provoca overflow nem esconde ações essenciais.
- [ ] Erro de imagem, lista vazia, sem rede e busca sem resultado têm tratamento.

### Android TV
- [ ] Margem segura nas quatro bordas.
- [ ] Toda ação essencial funciona com setas, OK/Select e Back.
- [ ] Foco é visível a distância e distinto da seleção persistente.
- [ ] Não existe foco preso, salto inesperado ou ação acessível apenas por toque.
- [ ] O teclado virtual de busca abre, recebe entrada e fecha com Back.
- [ ] Ao voltar de player/detalhes, o foco retorna ao item adequado.

### Desempenho/acessibilidade
- [ ] Listas grandes usam builders preguiçosos.
- [ ] Pôsteres não decodificam dimensões excessivas; placeholders têm dimensão estável.
- [ ] Sem blur pesado em todas as células de catálogo.
- [ ] Contraste de texto comum validado em pelo menos 4,5:1 onde aplicável.
- [ ] Sem overflow ou travamento durante carregamento, busca e mudança de categoria.
- [ ] Perfilado em dispositivo real de baixo/médio desempenho e em TV real.

## 12. Métricas e roteiro de validação

Medir antes/depois, segmentando por dispositivo, versão do app e qualidade de rede:

- **Descoberta:** tempo até abrir o primeiro conteúdo; taxa de sucesso em encontrar canal/filme; consultas sem resultado.
- **Navegação:** toques/pressionamentos para executar tarefa; eventos de foco perdido; retornos inesperados.
- **Player:** tempo até primeiro frame, falhas de início, tempo em buffering, proporção do tempo em buffering, encerramentos por erro e troca de canal.
- **Estabilidade:** crashes, ANRs, erros de renderização, frame time durante scroll.
- **Satisfação:** tarefa concluída sem ajuda, erros por tarefa e questionário breve após teste.

Como metas iniciais a validar, não como padrões universais: buscar início de reprodução no percentil 75 abaixo de 3 segundos em condições de rede/dispositivo definidas; reduzir buffering; não aceitar regressão significativa na taxa de início e na estabilidade. Estabelecer a baseline real antes de fixar metas definitivas.

Roteiro mínimo de teste: (1) encontrar um canal específico; (2) marcar/remover favorito; (3) iniciar um filme e voltar; (4) retomar um item com progresso; (5) localizar episódio de uma série; (6) tentar abrir conteúdo bloqueado e cancelar/validar PIN; (7) recuperar-se de lista vazia ou falha de rede. Fazer as tarefas com toque em mobile e D-pad em TV. Rodadas formativas podem começar com 5–8 participantes por perfil; combinar com métricas instrumentadas e testes regressivos, sem tratar amostras pequenas como prova estatística.

## 13. Fontes de referência

1. Android Developers — [Build adaptive apps for TV](https://developer.android.com/develop/adaptive-apps/guides/tv/build-adaptive-apps-for-tv). Orientações de D-pad, interface de 10 pés, paisagem e margens seguras.
2. Android Developers — [TV app quality](https://developer.android.com/docs/quality-guidelines/tv-app-quality). Critérios de navegação por D-pad, acessibilidade, compatibilidade e qualidade de apps de TV.
3. Android TV Design — [Navigation on TV](https://developer.android.google.cn/design/ui/tv/guides/foundations/navigation-on-tv?hl=en) e [Focus system](https://developer.android.google.cn/design/ui/tv/guides/styles/focus-system?hl=en). Fluxo de navegação remoto e estados de foco.
4. W3C — [Web Content Accessibility Guidelines (WCAG) 2.2](https://www.w3.org/TR/wcag/). Contraste, foco, ampliação de texto e previsibilidade como referências de acessibilidade.
5. Flutter — [Performance best practices](https://github.com/flutter/website/blob/main/sites/docs/src/content/perf/best-practices.md). Custo de build, widgets menores, listas preguiçosas e operações de layout.

As recomendações de cor, hierarquia e layout acima são decisões de design para o UNEX PLAY, informadas por esses princípios; não devem ser apresentadas como especificações obrigatórias das plataformas. As metas de métricas precisam ser validadas com dados da aplicação.

---

## Resumo executivo

A próxima versão visual do UNEX PLAY deve usar **fundo escuro, superfícies discretas, roxo–azul como assinatura e glass seletivo**, com o conteúdo sempre em primeiro plano. A mudança de maior impacto imediato é reduzir a área ocupada pelo topo e tornar o mini player de TV ao vivo adaptativo no celular. Em paralelo, a grade deve responder à largura do aparelho e os cartões precisam ter estados coerentes para toque e foco.

Na TV, a prioridade é leitura à distância e navegação D-pad previsível: menu e textos maiores, foco muito visível, margens seguras e Back consistente. Uma tela “Início” inspirada no mockup é desejável, mas requer refatorar juntos os índices de navegação e os filtros hoje espalhados em `main.dart`; não deve ser simulada apenas trocando os nomes das abas.

A implementação deve ser incremental: tokens e correções mobile primeiro, refinamento de foco de TV em seguida, nova arquitetura de navegação/Home depois e, por fim, medição e QA. Preservar a engine de vídeo, parser, PIN parental, favoritos, histórico e progresso é condição de aceite.

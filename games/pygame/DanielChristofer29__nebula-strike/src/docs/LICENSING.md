# Auditoria prática de licenças

Esta página registra por que os assets do projeto acadêmico anterior foram substituídos. Ela serve como documentação de engenharia, não como parecer jurídico.

## Resumo da decisão

A versão publicável foi rebatizada como **Nebula Strike** e reescrita sem assets externos. As naves, inimigos, cenário, interface e efeitos são desenhados por código; os sons e loops musicais são sintetizados em tempo de execução. Com isso, o repositório contém apenas material original do projeto e a dependência Pygame claramente identificada.

## Pontos encontrados no projeto anterior

| Item antigo | Risco identificado | Tratamento nesta versão |
| --- | --- | --- |
| Nome “Zathura” | É também o nome de uma obra comercial e pode causar impressão de associação. A página oficial da Sony identifica o filme e seus direitos autorais. | Projeto renomeado para **Nebula Strike** e sem referências visuais à obra. |
| `music.wav` | Os metadados do arquivo mencionavam “Miyazaki” e “Nausicca”, indicando possível uso de música de obra protegida sem licença anexada. | Arquivo removido; áudio novo sintetizado pelo código. |
| `bg2.jpg` | A busca de procedência apontava para um cenário cujo uso exigia condições/crédito, mas o projeto não trazia a licença nem a atribuição necessárias. | Arquivo removido; fundo novo desenhado por código. |
| `space.png` e `heart.png` | As cópias localizadas durante a auditoria aparentavam ter termos incompatíveis com redistribuição comercial, ou não permitiam confirmar uma licença livre para esta cópia específica. | Arquivos removidos; substitutos originais desenhados por código. |
| Sprites e efeitos restantes | Não havia arquivo de licença, autoria ou URL de origem que permitisse confirmar o direito de redistribuição. | Todos foram removidos; não há assets binários externos nesta versão. |
| Faixa do Pixabay | Uma faixa parecia corresponder a conteúdo do Pixabay. A licença do Pixabay permite vários usos, mas possui condições próprias e a correspondência exata do arquivo deveria ser documentada. | A faixa não foi incluída; nenhuma dependência dela permanece. |

“Encontrado em uma busca” não prova que aquela página seja a fonte original de um arquivo. Por isso, quando a procedência não pôde ser demonstrada com a licença e a versão exata do asset, a decisão conservadora foi não redistribuí-lo.

## Fontes oficiais consultadas

- Sony Pictures — página oficial de *Zathura*: https://www.sonypictures.com/movies/zathura
- Pygame — documentação e informação de licença: https://www.pygame.org/docs/
- Pixabay — resumo oficial da licença de conteúdo: https://pixabay.com/service/license-summary/

## Situação atual

- Código do jogo: MIT, conforme o arquivo [`LICENSE`](../LICENSE).
- Visuais: originais e gerados por código, cobertos pela licença do projeto.
- Áudio: formas de onda geradas por código, cobertas pela licença do projeto.
- Pygame: dependência externa sob LGPL, documentada em [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).
- Assets externos redistribuídos: nenhum.

Se um asset externo for adicionado no futuro, registre no mesmo commit: autor, URL original, versão/data do download, texto ou identificador da licença e atribuição exigida.

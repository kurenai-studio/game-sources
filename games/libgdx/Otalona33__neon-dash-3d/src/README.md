# Neon Dash 3D

[Baixar o projeto Android completo (ZIP)](https://github.com/Otalona33/neon-dash-3d/archive/refs/heads/main.zip) · [Repositório público no GitHub](https://github.com/Otalona33/neon-dash-3d)

Um jogo 3D de corrida infinita para Android, feito em Java com libGDX. Corra por quatro distritos futuristas, troque de faixa, pule barreiras, colete moedas e use escudo, ímã e multiplicador de pontos. Desbloqueie visuais na garagem e bata seu recorde local.

## Como jogar

- Deslize para a esquerda ou para a direita para trocar de faixa.
- Deslize para cima ou toque para pular.
- Toque no botão `II` no alto à direita para pausar.
- Recolha moedas e poderes: escudo, ímã de moedas e pontuação em dobro.
- Abra a garagem pelo menu para equipar ou comprar visuais.
- No teclado: setas ou A/D para mudar de faixa; seta para cima, W ou Espaço para pular.

## Abrir e compilar

1. Instale o Android Studio, um JDK 17 e o Android SDK Platform 36.
2. Abra a pasta `neon-dash-3d` no Android Studio e aguarde a sincronização do Gradle.
3. Execute o app em um dispositivo Android ou emulador com OpenGL ES 2.0 ou superior.
4. Instale Python 3 e Pillow (`python3 -m pip install Pillow`) e execute `python3 scripts/fetch_game_assets.py` para baixar os pacotes CC0 e preparar os modelos. A primeira execução baixa cerca de 430 MiB. Com Gradle 8.11.1 instalado, gere um APK de depuração com `gradle :android:assembleDebug`. O arquivo será criado em `android/build/outputs/apk/debug/`.

O projeto usa Android `minSdk 23`, `targetSdk 35` e libGDX `1.14.2`. A primeira sincronização precisa baixar as dependências do Maven Central e do Google Maven.

## Estrutura

- `core/`: código do jogo, renderização 3D e controles.
- `android/`: inicializador Android e configuração do aplicativo.

O veículo do jogador usa o modelo gratuito Spaceship3, com opções de cor na garagem; se o arquivo não puder ser carregado, o jogo mantém o modelo 3D integrado como fallback. A biblioteca de assets CC0 acompanha o APK. O projeto mira um APK acima de 300 MB conforme solicitado; o workflow verifica esse limite e executa um teste de inicialização em emulador.

## Licença

O código original deste projeto está sob a licença MIT. Veja `LICENSE`.

## Créditos e dependências

Veja [`ASSET_CREDITS.md`](ASSET_CREDITS.md) para a origem, autoria e licença dos pacotes e modelos utilizados. As licenças originais CC0 acompanham os arquivos. O projeto usa [libGDX](https://github.com/libgdx/libgdx), framework open source para jogos Java e Android, versão `1.14.2`, sob Apache License 2.0. A dependência é obtida pelo Maven; o código-fonte do framework não foi copiado para este repositório. Veja `THIRD_PARTY_NOTICES.md`.

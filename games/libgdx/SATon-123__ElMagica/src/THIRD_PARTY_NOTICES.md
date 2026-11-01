# Сторонние библиотеки и уведомления

Код ElMagica и созданные для проекта ассеты предлагаются под MIT в пределах прав автора. У зависимостей и чужих исходников остаются собственные лицензии.

| Компонент | Версия | Лицензия / уведомление |
| --- | --- | --- |
| LibGDX core, desktop backend, platform natives | 1.14.2 | Apache-2.0; bundled native headers have their own notices |
| gdx-jnigen-loader | 2.5.2 | Apache-2.0 |
| LWJGL core, GLFW, jemalloc, OpenAL, OpenGL, stb bindings | 3.4.3 | BSD-3-Clause; native libraries below retain their licenses |
| GLFW | bundled with LWJGL | zlib/libpng-style license |
| jemalloc | bundled with LWJGL | BSD-style notice supplied upstream |
| libffi, liburing integration, miniz, stb, Khronos headers | bundled with LWJGL | Individual notices preserved verbatim in docs/third-party |
| OpenAL Soft | 1.25.2 | LGPL; source and replacement instructions included |
| JLayer | 1.0.1-gdx | LGPL-2.0-or-later in source headers; Maven metadata names LGPL 2.1 |
| JOrbis / Jogg | 0.0.17 | LGPL-2.0-or-later in source headers |
| Gradle wrapper | 9.8.0 | Apache-2.0 and upstream NOTICE |
| Construo build plugin | 2.2.2 | MIT |
| Foojay resolver build plugin | 1.0.0 | Apache-2.0 |
| StartupHelper.java | generated desktop bootstrap | Apache-2.0; Copyright 2020 damios, original header preserved |

Таблица оставлена с точными названиями лицензий. Координаты Maven, варианты платформ и хеши файлов есть в `docs/dependencies.json`.

Оригинальные заголовки и уведомления лежат в `docs/third-party/`. Это сведения об авторах библиотек, не код ElMagica. Они сохраняются в исходниках и внутри JAR: `META-INF/third-party/`. Исходники LGPL-библиотек лежат в `META-INF/third-party-sources/`. Ссылки и SHA-256 — в `docs/third-party/manifest.json`.

Как собрать и подменить эти библиотеки, описано в `docs/LIBRARY_REPLACEMENT.md`; копия инструкции также лежит рядом с готовым JAR. Там же отмечено, что пока не проверялось.

Авторы сторонних библиотек не заявляли о поддержке ElMagica. Их код не перелицензируется под MIT проекта.

Картинки сделаны через генерацию изображений OpenAI. Исходники и промпты — в `art-source/`, игровые PNG нарезаны отдельно. Шаблонные логотипы LibGDX заменены. Музыку и эффекты синтезирует `tools/generate_audio.py`, без сторонних сэмплов. Пиксельный шрифт задан в коде. Подробнее о происхождении ассетов — в `docs/ASSETS.md`.

Created by SA_Ton_. Development assisted by OpenAI Codex (GPT-6.1 Sol).

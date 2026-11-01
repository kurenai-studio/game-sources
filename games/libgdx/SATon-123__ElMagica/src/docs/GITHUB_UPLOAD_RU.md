# Публикация ElMagica на GitHub

Исходники кладём в репозиторий, архив для игроков — в Releases. Если репозиторий уже создан, второй создавать не нужно. Команды ниже для первой загрузки в пустой репозиторий. Если в нём уже есть коммиты, сначала клонируй его и обновляй файлы в этой копии, чтобы сохранить историю.

## Исходники

1. Распакуй `ElMagica-Beta1.0-source.zip` в отдельную постоянную папку. Открой папку, где находятся `README.md`, `gradlew.bat` и `LICENSE`. Публикуй её содержимое, а не сам ZIP и не весь рабочий каталог разработки.
2. Установи Git, если его ещё нет. На GitHub нажми **New repository**, назови репозиторий `ElMagica`, выбери **Public**. Не добавляй README, .gitignore и лицензию через сайт: они уже есть в проекте. Нажми **Create repository**.
3. Открой PowerShell в распакованной папке и выполни:

```powershell
git init -b main
git add .
git status
git commit -m "Publish ElMagica Beta1.0"
git remote add origin https://github.com/YOUR_USERNAME/ElMagica.git
git push -u origin main
```

Замени `YOUR_USERNAME` своим логином. При первом push Git может открыть вход через браузер. Если Git попросит имя и email автора коммитов, задай их через `git config user.name "SA_Ton_"` и `git config user.email "EMAIL"`. Для приватности можно взять адрес noreply из GitHub → Settings → Emails.

Перед коммитом посмотри `git status`: не добавляй личные файлы, ключи и локальные настройки. Сохрани LICENSE, THIRD_PARTY_NOTICES.md, docs/third-party и third-party-sources: это сведения и исходники сторонних компонентов.

## Готовая игра

В репозитории открой **Releases → Draft a new release**. Создай тег `v1.0.0-beta.1`, укажи название `ElMagica Beta1.0`, отметь **Set as a pre-release**. Прикрепи `ElMagica-Beta1.0-play.zip` и `SHA256SUMS.txt`, затем нажми **Publish release**. При желании приложи также source.zip; в файле контрольных сумм каждый архив указан по имени.

В описании напиши, что требуется Java 17 или новее (рекомендуется Java 21). На Windows игру запускают через `Run-ElMagica.bat` после распаковки. Java в архив игры не включена.

Не загружай готовую игру в исходники: для неё предназначен Release. Рабочие build, .gradle и GitHub-ready тоже не нужны в репозитории.

## Следующие обновления

Обнови файлы в той же папке репозитория, затем:

```powershell
git add .
git diff --cached --stat
git commit -m "Update ElMagica"
git push
```

Для новой сборки создай новый тег и Release. Не удаляй папку `.git`.

Официальные инструкции: [публикация локального проекта](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github), [создание Release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

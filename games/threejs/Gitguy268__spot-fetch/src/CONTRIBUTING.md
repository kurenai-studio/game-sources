# Contributing

Thanks for helping with Spot apporteert.

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting a bug or asking for a feature

Open an [issue](https://github.com/Gitguy268/spot-fetch/issues/new/choose) and use the template. For a bug, say which browser and version, what you did, what you expected and what happened.

Report security problems privately: see [SECURITY.md](SECURITY.md).

## Making a change

1. Fork the repository and create a branch from `main`.
2. Set it up and run it:

   ```sh
   npm ci
   npm run dev
   ```

3. Make your change. Keep commits small, each with a clear message.
4. Run the checks below and update the README if behaviour changed.
5. Open a pull request and fill in the template.

## Checks

```sh
npm test           # node --test over src/
npm run build
```

## Licences

The code is MIT licensed (see [LICENSE](LICENSE)), and your contribution is accepted under the same licence. Don't add models, textures, sounds or libraries unless their licence allows redistribution, and credit each one in [NOTICE](NOTICE).

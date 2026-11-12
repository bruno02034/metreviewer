# Mudanças do MetreViewer em relação ao RustDesk 1.5.3

Fork do [RustDesk](https://github.com/rustdesk/rustdesk) (AGPL-3.0), base: tag `1.5.3`.
Cada mudança no código do upstream está listada aqui, para facilitar a atualização para versões novas.

| Arquivo | Mudança | Motivo |
|---|---|---|
| `.github/workflows/metre-build.yml`, `metre-flutter-build.yml` | Build só de Windows x64 e Android (aarch64, armv7), gerado a partir de `flutter-build.yml` | CI do MetreViewer |

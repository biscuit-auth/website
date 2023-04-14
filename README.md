# Biscuit website

The website is made up of two parts: the main website (<https://biscuitsec.org>)
and the documentation website (<https://doc.biscuitsec.org>). Both sites
require a JS bundle for editor components to work correctly.

## Required tools

The website requires the following tools:

- `npm` for bundling frontend assets
- `zola` for building the main website
- `mdbook` for building the documentation website

`zola` and `mdbook` can be downloaded from the release pages:

- <https://github.com/getzola/zola/releases>
- <https://github.com/rust-lang/mdBook/releases>

`npm` can be installed through your operating system tooling or via `nvm`.

## Frontend build 

- go to the `wc/` directory
- `npm install`
- `npm run build`

## Preview the main website output

- make sure you've built the frontend bundle
- run `zola serve`
- point your browser to the URL displayed in the console output

Running `zola build` and opening generated files directly in your browser won't
work as the datalog component files require being served over HTTP.

## Preview the documentation output

- make sure you've built the frontend bundle
- go to the `docs/` directory
- run `mdbook serve`
- point your browser to the URL displayed in the console output

Running `mdbook serve` and opening generated files directly in your browser won't
work as the datalog component files require being served over HTTP.


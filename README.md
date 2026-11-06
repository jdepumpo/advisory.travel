<h1 align="center">advisory.travel</h1>
<p>
  <img alt="Version" src="https://img.shields.io/badge/version-0.5-blue.svg?cacheSeconds=2592000" />
</p>

> advisory.travel helps keep international travelers safe by providing country travel advisories that are updated continuously.

## Built With
![Ruby](https://img.shields.io/badge/-Ruby-AE0700?&logo=Ruby&logoColor=fff&style=for-the-badge)
![Ruby on Rails](https://img.shields.io/badge/-Rails-CC0000?&logo=Ruby-On-Rails&logoColor=fff&style=for-the-badge)
![JavaScript](https://img.shields.io/badge/-JavaScript-F4DC1E?&logo=JavaScript&logoColor=000&style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/-PostgreSQL-2F6792?&logo=PostgreSQL&logoColor=fff&style=for-the-badge)

### ✨ [Take a look!](https://advisory.travel/)

## Install

```sh
bundle install && yarn build
```

## Deploy

```sh
fly deploy
gh workflow run refresh-advisories.yml   # also purges the Cloudflare cache
```

Pages are cached at Cloudflare for up to a day (`ApplicationController#allow_edge_caching`). The
daily *Refresh advisories* workflow purges that cache after importing, so run it after each deploy
too; otherwise cached pages keep pointing at the previous build's CSS/JS until it expires.

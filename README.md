<h1 align="center">Travel Advisories</h1>
<p>
  <img alt="Version" src="https://img.shields.io/badge/version-1.0-blue.svg?cacheSeconds=2592000" />
</p>

> Travel Advisories helps keep international travelers safe by providing country travel advisories that are updated continuously.

## Built With
![Ruby](https://img.shields.io/badge/-Ruby-AE0700?&logo=Ruby&logoColor=fff&style=for-the-badge)
![Ruby on Rails](https://img.shields.io/badge/-Rails-CC0000?&logo=Ruby-On-Rails&logoColor=fff&style=for-the-badge)
![JavaScript](https://img.shields.io/badge/-JavaScript-F4DC1E?&logo=JavaScript&logoColor=000&style=for-the-badge)
![PostgreSQL](https://img.shields.io/badge/-PostgreSQL-2F6792?&logo=PostgreSQL&logoColor=fff&style=for-the-badge)

### ✨ [Take a look!](https://travel-advisories.jfd.is/)

## Install

```sh
bundle install && yarn build
```

## Deploy

```sh
fly deploy
gh workflow run refresh-advisories.yml   # also purges the Cloudflare cache
```

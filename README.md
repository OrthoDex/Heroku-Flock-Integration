# SlashHeroku

## Development

```
$ ./bin/setup
$ rails s
```

### Tests

The full test suite can be run with:

```
$ ./bin/cibuild
```

### Deploying to Heroku

* [Create a GitHub OAuth app](https://github.com/settings/applications/new)
* [Create a Heroku OAuth app](https://dashboard.heroku.com/account/clients/new)
* [Create this app on Heroku](https://heroku.com/deploy?template=https://github.com/atmos/slash-heroku)
* heroku plugins:install heroku-redis
* heroku redis:promote HEROKU_REDIS_SOMECOLOR -a heroku-app-you-created

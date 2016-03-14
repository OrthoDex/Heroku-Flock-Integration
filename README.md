# SlashHeroku <a href="https://slack.heroku.tools/auth/slack"><img alt="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack.png" srcset="https://platform.slack-edge.com/img/add_to_slack.png 1x, https://platform.slack-edge.com/img/add_to_slack@2x.png 2x" /></a>

[SlashHeroku](https://github.com/atmos/slash-heroku) is a web app for working with the [Heroku Platform API](https://devcenter.heroku.com/articles/platform-api-reference) via a `/heroku` command in Slack. This is done with Heroku and Slack OAuth. Each set of credentials are scope to the team you're chatting in, so you can key personal and work credentials separated.

## Usage

Get recent releases for your applications:

![recent releases](https://cloud.githubusercontent.com/assets/38/13562087/075e635a-e3e9-11e5-85c4-22747664cb25.png)

Ideally we can port a lot of useful commands over from the Heroku CLI.

![implemented commands](https://cloud.githubusercontent.com/assets/38/13562075/ea2e351c-e3e8-11e5-8998-9c8467dfa887.png)

### FAQ

* **Why not pump straight to the heroku toolbelt?** I don't want to handle the myriad of inputs that could introduce unforeseen security issues.
* **Why do you need global access on Heroku?"** I'm open to fewer permissions once the feature set looks better.
* **Are you looking at stuff with my token?** No.

## Development

```
$ ./bin/bootstrap
```

### Tests

The full test suite can be run with:

```
$ ./bin/cibuild
```

### Deploying to Heroku

You can run this yourself on heroku.

[![Launch on Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/atmos/slash-heroku)


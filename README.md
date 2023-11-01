# RailsRouteChecker

A linting tool that helps you find any routes defined in your `routes.rb` file that don't have a corresponding 
controller action, and find any `_path` or `_url` calls that don't have a corresponding route in the `routes.rb` file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-route-checker', require: false
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-route-checker

## Usage

Run `rails-route-checker` from your command line while in the root folder of your Rails application.

You may also specify a custom config file using the `-c` or `--config` flag. By default, the config file
is search for at `.rails-route-checker.yml`. More information on the config file can be found below.

`rails-route-checker` will scan controllers along with Haml and ERb view files.

```
bundle exec rails-route-checker

The following 1 routes are defined, but have no corresponding controller action.
If you have recently added a route to routes.rb, make sure a matching action exists in the controller.
If you have recently removed a controller action, also remove the route in routes.rb.
 - oauth_apps/authorizations#show


The following 1 url and path methods don't correspond to any route.
 - app/controllers/application_controller.rb:L707 - call to potential_url
```

## Config file

By default, `rails-route-checker` will look for a config file `.rails-route-checker.yml`. However, you can override
this by using the `--config` command line flag.

The following is an example config file:

```YAML
# Any controllers you don't want to check
ignored_controllers:
  - oauth_apps/authorizations

# Any paths or url methods that you want to be globally ignored
# i.e. confirmation_url and confirmation_path will never be linted against
ignored_paths:
  - confirmation

# For specific files, ignore specific path or url calls
ignored_path_whitelist:
  app/controllers/application_controller.rb:
      - potential_url
  app/views/my_controller/my_view.haml:
    - paginate_url

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Feel free to fork this repo and open a PR. Alongside your changes, please add a line to `CHANGELOG.md`.

### Testing

To test this gem in different envrionments with different gem version (such as the haml gem), we are using [Appraisal](https://github.com/thoughtbot/appraisal).

First, you need to generate the differents Gemfiles, only needed for the tests:

```bash
bundle exec appraisal install
```

Then, to run the tests, you have to use the following command:

```bash
bundle exec appraisal rake test
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rails::Route::Checker project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/daveallie/rails-route-checker/blob/master/CODE_OF_CONDUCT.md).

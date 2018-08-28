# ActsAsTaggableOnMongoid

[ActsAsTaggableOn](https://github.com/mbleigh/acts-as-taggable-on) is the clear leader in tagging
solutions in Rails.  Unfortunately it does not appear to work well with Mongoid.  For Mongo the
clear leader for tagging solutions is to include an indexed array of strings as tags.  There are
several solutions that use this mechanism.  Unfortunately, sometimes you actually do need a
many-to-many table solution even in Mongo which happens to be the situation I somehow have found
myself in.

Therefore, we are building a new solution to implement an `ActsLikeTaggableOn` like solution using
Mongo.  The general goal is to mimic the features and interface of ActsLikeTaggableOn as much as
feasible/possible.

This is not a direct port of `ActsLikeTaggableOn` at this time for several reason, the main one being
time.  Mongoid and ActiveRecord are enough different that the complications that would arise from forking
and trying to modify it to work with Mongoid do not seem insignificant.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'acts-as-taggable-on-mongoid'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts-as-taggable-on-mongoid

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/acts-as-taggable-on-mongoid. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActsAsTaggableOnMongoid project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/acts-as-taggable-on-mongoid/blob/master/CODE_OF_CONDUCT.md).

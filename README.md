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

Setup

```ruby
class User
  include ::Mongoid::Document

  acts_as_taggable # Alias for acts_as_taggable_on :tags
  acts_as_taggable_on :skills, :interests
end

class UsersController < ApplicationController
  def user_params
    params.require(:user).permit(:name, :tag_list) ## Rails 4 strong params usage
  end
end

@user = User.new(:name => "Bobby")
```

Add and remove a single tag

```ruby
@user.tag_list.add("awesome")   # add a single tag. alias for <<
@user.tag_list.remove("awesome") # remove a single tag
@user.save # save to persist tag_list
```

Add and remove multiple tags in an array

```ruby
@user.tag_list.add("awesome", "slick")
@user.tag_list.remove("awesome", "slick")
@user.save
```

You can also add and remove tags in format of String. This would
be convenient in some cases such as handling tag input param in a String.

Pay attention you need to add `parse: true` as option in this case.

You may also want to take a look at delimiter in the string. The default
is comma `,` so you don't need to do anything here. However, if you made
a change on delimiter setting, make sure the string will match. See
[configuration](#configuration) for more about delimiter.

```ruby
@user.tag_list.add("awesome, slick", parse: true)
@user.tag_list.remove("awesome, slick", parse: true)
```

You can also add and remove tags by direct assignment. Note this will
remove existing tags so use it with attention.

```ruby
@user.tag_list = "awesome, slick, hefty"
@user.save
@user.reload
@user.tags
=> [#<ActsAsTaggableOn::Tag id: 1, name: "awesome", taggings_count: 1>,
 #<ActsAsTaggableOn::Tag id: 2, name: "slick", taggings_count: 1>,
 #<ActsAsTaggableOn::Tag id: 3, name: "hefty", taggings_count: 1>]
```

With the defined context in model, you have multiple new methods at disposal
to manage and view the tags in the context. For example, with `:skill` context
these methods are added to the model: `skill_list`(and `skill_list.add`, `skill_list.remove`
`skill_list=`), `skills`(plural), `skill_counts`.

```ruby
@user.skill_list = "joking, clowning, boxing"
@user.save
@user.reload
@user.skills
=> [#<ActsAsTaggableOn::Tag id: 1, name: "joking", taggings_count: 1>,
 #<ActsAsTaggableOn::Tag id: 2, name: "clowning", taggings_count: 1>,
 #<ActsAsTaggableOn::Tag id: 3, name: "boxing", taggings_count: 1>]

@user.skill_list.add("coding")

@user.skill_list
# => ["joking", "clowning", "boxing", "coding"]

@another_user = User.new(:name => "Alice")
@another_user.skill_list.add("clowning")
@another_user.save

User.skill_counts
=> [#<ActsAsTaggableOn::Tag id: 1, name: "joking", taggings_count: 1>,
 #<ActsAsTaggableOn::Tag id: 2, name: "clowning", taggings_count: 2>,
 #<ActsAsTaggableOn::Tag id: 3, name: "boxing", taggings_count: 1>]
```

To preserve the order in which tags are created use `acts_as_ordered_taggable`:

```ruby
class User < ActiveRecord::Base
  # Alias for acts_as_ordered_taggable_on :tags
  acts_as_ordered_taggable
  acts_as_ordered_taggable_on :skills, :interests
end

@user = User.new(:name => "Bobby")
@user.tag_list = "east, south"
@user.save

@user.tag_list = "north, east, south, west"
@user.save

@user.reload
@user.tag_list # => ["north", "east", "south", "west"]
```

### Finding most or least used tags

You can find the most or least used tags by using:

```ruby
ActsAsTaggableOn::Tag.most_used
ActsAsTaggableOn::Tag.least_used
```

You can also filter the results by passing the method a limit, however the default limit is 20.

```ruby
ActsAsTaggableOn::Tag.most_used(10)
ActsAsTaggableOn::Tag.least_used(10)
```

### Finding Tagged Objects

Acts As Taggable On uses scopes to create an association for tags.
This way you can mix and match to filter down your results.

```ruby
class User < ActiveRecord::Base
  acts_as_taggable_on :tags, :skills
  scope :by_join_date, order("created_at DESC")
end

User.tagged_with("awesome").by_join_date
User.tagged_with("awesome").by_join_date.paginate(:page => params[:page], :per_page => 20)

# Find users that matches all given tags:
# NOTE: This only matches users that have the exact set of specified tags. If a user has additional tags, they are not returned.
User.tagged_with(["awesome", "cool"], :match_all => true)

# Find users with any of the specified tags:
User.tagged_with(["awesome", "cool"], :any => true)

# Find users that have not been tagged with awesome or cool:
User.tagged_with(["awesome", "cool"], :exclude => true)

# Find users with any of the tags based on context:
User.tagged_with(['awesome', 'cool'], :on => :tags, :any => true).tagged_with(['smart', 'shy'], :on => :skills, :any => true)
```

You can also use `:wild => true` option along with `:any` or `:exclude` option. It will be looking for `%awesome%` and `%cool%` in SQL.

__Tip:__ `User.tagged_with([])` or `User.tagged_with('')` will return `[]`, an empty set of records.


### Relationships

You can find objects of the same type based on similar tags on certain contexts.
Also, objects will be returned in descending order based on the total number of
matched tags.

```ruby
@bobby = User.find_by_name("Bobby")
@bobby.skill_list # => ["jogging", "diving"]

@frankie = User.find_by_name("Frankie")
@frankie.skill_list # => ["hacking"]

@tom = User.find_by_name("Tom")
@tom.skill_list # => ["hacking", "jogging", "diving"]

@tom.find_related_skills # => [<User name="Bobby">, <User name="Frankie">]
@bobby.find_related_skills # => [<User name="Tom">]
@frankie.find_related_skills # => [<User name="Tom">]
```

### Dynamic Tag Contexts

In addition to the generated tag contexts in the definition, it is also possible
to allow for dynamic tag contexts (this could be user generated tag contexts!)

```ruby
@user = User.new(:name => "Bobby")
@user.set_tag_list_on(:customs, "same, as, tag, list")
@user.tag_list_on(:customs) # => ["same", "as", "tag", "list"]
@user.save
@user.tags_on(:customs) # => [<Tag name='same'>,...]
@user.tag_counts_on(:customs)
User.tagged_with("same", :on => :customs) # => [@user]
```

### Tag Parsers

If you want to change how tags are parsed, you can define your own implementation:

```ruby
class MyParser < ActsAsTaggableOn::GenericParser
  def parse
    ActsAsTaggableOn::TagList.new.tap do |tag_list|
      tag_list.add @tag_list.split('|')
    end
  end
end
```

Now you can use this parser, passing it as parameter:

```ruby
@user = User.new(:name => "Bobby")
@user.tag_list = "east, south"
@user.tag_list.add("north|west", parser: MyParser)
@user.tag_list # => ["north", "east", "south", "west"]

# Or also:
@user.tag_list.parser = MyParser
@user.tag_list.add("north|west")
@user.tag_list # => ["north", "east", "south", "west"]
```

Or change it globally:

```ruby
ActsAsTaggableOn.default_parser = MyParser
@user = User.new(:name => "Bobby")
@user.tag_list = "east|south"
@user.tag_list # => ["east", "south"]
```

### ~~Tag Ownership~~

NOTE:  This feature of [ActsAsTaggableOn](https://github.com/mbleigh/acts-as-taggable-on) has not been implimented/ported yet.

Tags can have owners:

```ruby
class User < ActiveRecord::Base
  acts_as_tagger
end

class Photo < ActiveRecord::Base
  acts_as_taggable_on :locations
end

@some_user.tag(@some_photo, :with => "paris, normandy", :on => :locations)
@some_user.owned_taggings
@some_user.owned_tags
Photo.tagged_with("paris", :on => :locations, :owned_by => @some_user)
@some_photo.locations_from(@some_user) # => ["paris", "normandy"]
@some_photo.owner_tags_on(@some_user, :locations) # => [#<ActsAsTaggableOn::Tag id: 1, name: "paris">...]
@some_photo.owner_tags_on(nil, :locations) # => Ownerships equivalent to saying @some_photo.locations
@some_user.tag(@some_photo, :with => "paris, normandy", :on => :locations, :skip_save => true) #won't save @some_photo object
```

#### Working with Owned Tags
Note that `tag_list` only returns tags whose taggings do not have an owner. Continuing from the above example:
```ruby
@some_photo.tag_list # => []
```
To retrieve all tags of an object (regardless of ownership) or if only one owner can tag the object, use `all_tags_list`.

##### Adding owned tags
Note that **owned tags** are added all at once, in the form of ***comma seperated tags*** in string.
Also, when you try to add **owned tags** again, it simply overwrites the previous set of **owned tags**.
So to append tags in previously existing **owned tags** list, go as follows:
```ruby
def add_owned_tag
    @some_item = Item.find(params[:id])
    owned_tag_list = @some_item.all_tags_list - @some_item.tag_list
    owned_tag_list += [(params[:tag])]
    @tag_owner.tag(@some_item, :with => stringify(owned_tag_list), :on => :tags)
    @some_item.save
end

def stringify(tag_list)
    tag_list.inject('') { |memo, tag| memo += (tag + ',') }[0..-1]
end
```
##### Removing owned tags
Similarly as above, removing will be as follows:
```ruby
def remove_owned_tag
    @some_item = Item.find(params[:id])
    owned_tag_list = @some_item.all_tags_list - @some_item.tag_list
    owned_tag_list -= [(params[:tag])]
    @tag_owner.tag(@some_item, :with => stringify(owned_tag_list), :on => :tags)
    @some_item.save
end
```

### Dirty objects

```ruby
@bobby = User.find_by_name("Bobby")
@bobby.skill_list # => ["jogging", "diving"]

@bobby.skill_list_changed? #=> false
@bobby.changes #=> {}

@bobby.skill_list = "swimming"
@bobby.changes.should == {"skill_list"=>["jogging, diving", ["swimming"]]}
@bobby.skill_list_changed? #=> true

@bobby.skill_list_change.should == ["jogging, diving", ["swimming"]]
```

### Tag cloud calculations

To construct tag clouds, the frequency of each tag needs to be calculated.
Because we specified `acts_as_taggable_on` on the `User` class, we can
get a calculation of all the tag counts by using `User.tag_counts_on(:customs)`. But what if we wanted a tag count for
a single user's posts? To achieve this we call tag_counts on the association:

```ruby
User.find(:first).posts.tag_counts_on(:tags)
```

A helper is included to assist with generating tag clouds.

Here is an example that generates a tag cloud.

Helper:

```ruby
module PostsHelper
  include ActsAsTaggableOn::TagsHelper
end
```

Controller:

```ruby
class PostController < ApplicationController
  def tag_cloud
    @tags = Post.tag_counts_on(:tags)
  end
end
```

View:

```erb
<% tag_cloud(@tags, %w(css1 css2 css3 css4)) do |tag, css_class| %>
  <%= link_to tag.name, { :action => :tag, :id => tag.name }, :class => css_class %>
<% end %>
```

CSS:

```css
.css1 { font-size: 1.0em; }
.css2 { font-size: 1.2em; }
.css3 { font-size: 1.4em; }
.css4 { font-size: 1.6em; }
```

## Configuration

If you would like to remove unused tag objects after removing taggings, add:

```ruby
ActsAsTaggableOn.remove_unused_tags = true
```

If you want force tags to be saved downcased:

```ruby
ActsAsTaggableOn.force_lowercase = true
```

If you want tags to be saved parametrized (you can redefine to_param as well):

```ruby
ActsAsTaggableOn.force_parameterize = true
```

If you would like tags to be case-sensitive and not use LIKE queries for creation:

```ruby
ActsAsTaggableOn.tags_table = 'aato_tags'
ActsAsTaggableOn.taggings_table = 'aato_taggings'
```

If you want to change the default delimiter (it defaults to ','). You can also pass in an array of delimiters such as ([',', '|']):

```ruby
ActsAsTaggableOn.delimiter = ','
```

```shell
USE my_wonderful_app_db;
ALTER TABLE tags MODIFY name VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin;
```

#### Upgrading

see [UPGRADING](UPGRADING.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/acts-as-taggable-on-mongoid. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActsAsTaggableOnMongoid project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/acts-as-taggable-on-mongoid/blob/master/CODE_OF_CONDUCT.md).

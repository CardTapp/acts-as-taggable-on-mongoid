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

## Architecture and design concepts

### Termonology.

* **tag_list** - a generic term for the list field in a `Taggable` object that is
  defined using the `acts_as_taggable_on` method.  Each tag_list is definied
  independentally and can have separate settings.
* **tag_type, context** - For whatever reason, these two terms are both used and
  are synonymous with each other.  `context` is used in the Tag and Taggable
  tables to differentiate that a record is associated with a particular tag_list
* **Taggable object** - A database model object which can have tag_lists associated with
  it.  All taggable objects can have multiple tag_lists in it.
* **Tagging table** - A Table for storing the which Tags are associated with a Taggable
  object.  The Tag details are denormalized into the Tagging table to allow efficient
  querying of Taggable objects without having to go through the Taggings table.
* **Tag table** - A Table for storing the tags.  Tags are used primarily to maintain
  a usage counter as the tag details are denormalized into the Tagging tagle

  **NOTE**: Unlike the `ActsAsTaggableOn` gem, I group Tags by context.  Tags with the same
  name for different contexts keep separate counts and are considered different Tags.
  It is simpler to combine Tags and their counts by name then it is to split them out.

The database structure is:
  ```
  +----------+    +---------+    +-----+
  | Taggable | -> | Tagging | <- | Tag |
  +----------+    +---------+    +-----+
  ```

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
is comma `,` so you don't need to do anything here. However, if you want to
use a different delimiter you will have to change the delmiter on the
`DefaultParser` or create a new Parser which splits the string using the
algorithm or method you want/need.  See the `GenericParser` class for details
on creating a new custom parser of your own design.

```ruby
@user.tag_list.add("awesome, slick", parse: true)
@user.tag_list.remove("awesome, slick", parse: true)
```

You can also add and remove tags by direct assignment.  By default, direct
assignment will parse values passed into it.  Note this will
remove existing tags so use it with attention.

```ruby
@user.tag_list = "awesome, slick, hefty"
@user.save
@user.reload
@user.tags
=> [#<ActsAsTaggableOnMongoid::Models::Tag id: 1, name: "awesome", taggings_count: 1>,
 #<ActsAsTaggableOnMongoid::Models::Tag id: 2, name: "slick", taggings_count: 1>,
 #<ActsAsTaggableOnMongoid::Models::Tag id: 3, name: "hefty", taggings_count: 1>]
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
=> [#<ActsAsTaggableOnMongoid::Models::Tag id: 1, name: "joking", taggings_count: 1>,
 #<ActsAsTaggableOnMongoid::Models::Tag id: 2, name: "clowning", taggings_count: 1>,
 #<ActsAsTaggableOnMongoid::Models::Tag id: 3, name: "boxing", taggings_count: 1>]

@user.skill_list.add("coding")

@user.skill_list
# => ["joking", "clowning", "boxing", "coding"]

@another_user = User.new(:name => "Alice")
@another_user.skill_list.add("clowning")
@another_user.save

User.skill_counts
=> [#<ActsAsTaggableOnMongoid::Models::Tag id: 1, name: "joking", taggings_count: 1>,
 #<ActsAsTaggableOnMongoid::Models::Tag id: 2, name: "clowning", taggings_count: 2>,
 #<ActsAsTaggableOnMongoid::Models::Tag id: 3, name: "boxing", taggings_count: 1>]
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

#### `acts_as_taggable_on` documentation details

```Ruby
class MyTaggable
  include ::Mongoid::Document

  acts_as_taggable_on :my_tags,
                      :your_tags,
                      :other_tags,
                      :etc_tags,
                      parser:             MyCustomParser,
                      preserve_tag_order: true,
                      cached_in_model:    true,
                      force_lowercase:    true,
                      force_parameterize: true,
                      remove_unused_tags: true,
                      tags_table:         CustomTag,
                      taggings_table:     CusomTagging,
                      default:            "defalut, values"
end
```

`acts_as_taggable_on` will define the following methods and relationships based on the values passed in
(only methods for the `my_tags` tag_list are shown, but methods for each of the other tag_lists will be
created also.)

* `custom_taggings` -  a relationship on a `MyTaggable` object which will return all `CustomTagging`s across
  all contexts/tag_types for a particular tagging.  Usage:
  ```Ruby
  my_taggable = MyTaggable.find(taggable_id)
  my_taggable.custom_taggings.to_a

  => [#<CustomTagging context: "my_tags", taggable_id: my_taggable.id>,
      #<CustomTagging context: "your_tags", taggable_id: my_taggable.id>, ...]
  ```
* `base_custom_tags` - Returns a `Criteria` for all `CustomTag`s which are associated with any `MyTaggable`.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.find(taggable_id)
  my_taggable.base_custom_tags.to_a

  => [#<CustomTag context: "my_tags", taggable_type: "MyTaggable">,
      #<CustomTag context: "your_tags", taggable_type: "MyTaggable">, ...]
  ```
* `my_tag_custom_taggings` - Returns all `CustomTagging`s for a particular `MyTaggable` object for the
  named context in the appropriate sorted order for that context (based on if `preserve_tag_order` is true.)
  Usage:
  ```Ruby
  my_taggable = MyTaggable.find(taggable_id)
  my_taggable.my_tag_custom_taggings.to_a

  => [#<CustomTagging context: "my_tags", taggable_id: my_taggable.id>,
      #<CustomTagging context: "my_tags", taggable_id: my_taggable.id>, ...]
  ```
* `my_tags` - Returns all `CustomTag`s for a particular `MyTaggable` object for the named context sorted in the order
  that the tags were added to that object if `preserve_tag_order` is true.
  NOTE:  This is done through a mapping from the `custom_taggings` relationship and is therefore not very efficient.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.find(taggable_id)
  my_taggable.my_tags.to_a

  => [#<CustomTag context: "my_tags", taggable_type: "MyTaggable">,
      #<CustomTag context: "my_tags", taggable_type: "MyTaggable">, ...]
  ```
* `my_tag_list` - Returns an array of all tag values that are associated with a context for a `MyTaggable` object.
  The array will be a simple array of strings that are sorted in the appropriate order based on the
  value of `preserve_tag_order`.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.find(taggable_id)
  my_taggable.my_tag_list

  => ["tag value 1", "tag value 2", "tag value 3", ...]
  # This list will be sorted in the order that the values were added to the list if `preserve_tag_order` is true.
  ```
* `my_tag_list=` - Sets the list of tags for that context for a particular `MyTaggable` object.  Setting the value
  in this way will automatically parse the string.  You can force the string to not be parsed or to use a particular
  parser by passing an array with the appropriate options (`parse` and `parser`).  If `preserve_tag_order` is true
  then values will be removed and re-added as necessary to ensure that the tag order is preserved for the set.
  Changes to the `my_tag_list` will not be persisted until after the object is saved just like any other field.
  Usage:
  ```Ruby
  # Set list and save - Sets the list of tags for the list
  my_taggable = MyTaggable.find(taggable_id)

  # preserve_tag_order = false
  my_taggable.my_tag_list = "tag value 3, tag value 2, tag value 1"
  my_taggable.save!
  my_taggable.reload.my_tag_list

  => ["tag value 3", "tag value 2", "tag value 1"]
  ```
  ```Ruby
  # Use update_attributes - Sets the list of tags for the list as if assigned (i.e. parsing is assumed)
  # preserve_tag_order = false
  my_taggable.update_attributes! my_tag_list: "tag value 2, tag value 1, tag value 3"
  my_taggable.reload.my_tag_list

  => ["tag value 3", "tag value 2", "tag value 1"]
  ```
  ```Ruby
  # Use update_attributes - Sets the list of tags for the list - keep the passed in order.
  # preserve_tag_order = true
  my_taggable.update_attributes! my_tag_list: "tag value 2, tag value 1, tag value 3"
  my_taggable.reload.my_tag_list

  => ["tag value 2", "tag value 1", "tag value 3"]
  ```
  ```Ruby
  # Set list and save - disabling parsing.  The string passed in i used as-is
  # preserve_tag_order = false
  my_taggable.my_tag_list = ["tag value 3, tag value 2, tag value 1", parse: false]
  my_taggable.save!
  my_taggable.reload.my_tag_list

  => ["tag value 3, tag value 2, tag value 1"]
  ```
  ```Ruby
  # Set the list and save using a custom parser:
  # preserve_tag_order = false
  my_taggable.my_tag_list = ["tag value 2;tag value 1;tag value 3", parser: SemiColonParser]
  my_taggable.save!
  my_taggable.reload.my_tag_list

  => ["tag value 2", "tag value 1", "tag value 3"]
  ```
  ```Ruby
  # Use add, remove, concat and << to change the list and save.
  # preserve_tag_order = false
  # parse is ONLY assumed true for assignment and default values.
  my_taggable.my_tag_list.add "1, 2", "3, 4", "5", parse: true
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "2", "3", "4", "5"]
  my_taggable.my_tag_list.add "6, 7", "8, 9", "10"
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "2", "3", "4", "5", "6, 7", "8, 9", "10"]
  my_taggable.my_tag_list.remove "2, 3", "4, 9", parse: true
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "5", "6, 7", "8, 9", "10"]
  my_taggable.my_tag_list.remove "6, 7", "10", "not in list"
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "5", "8, 9"]
  my_taggable.my_tag_list << ["11, 12", "13, 14", parse: true]
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "5", "8, 9", "11", "12", "13", "14"]
  my_taggable.my_tag_list << ["15, 16", "17, 18"]
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "5", "8, 9", "11", "12", "13", "14", "15, 16", "17, 18"]
  my_taggable.my_tag_list << "19"
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "5", "8, 9", "11", "12", "13", "14", "15, 16", "17, 18", "19"]

  # NOTE:  Unlike the other methods, passing options for concat is not supported.
  my_taggable.my_tag_list.concat ["20", "21"]
  # my_tag_list => ["tag value 2", "tag value 1", "tag value 3", "1", "5", "8, 9", "11", "12", "13", "14", "15, 16", "17, 18", "19", "20", "21"]

  # assignment will apply preferences:
  # force_lowercase = true
  my_taggable.my_tag_list = "Tag Value 1, Tag Value 2, Tag Value 3"
  # my_tag_list => ["tag value 3", "tag value 2", "tag value 1"]
  my_taggable.my_tag_list.remove "TAG VALUE 1"
  # my_tag_list => ["tag value 3", "tag value 2"]

  # force_parameterize = true
  my_taggable.my_tag_list = "tag value 1, tag value 2, tag value 3"
  # my_tag_list => ["tag-value-1", "tag-value-2", "tag-value-3"]
  my_taggable.my_tag_list.remove "tag value 1"
  # my_tag_list => ["tag-value-2", "tag-value-3"]
  ```
  ```Ruby
  # Values are not stored until save is called.
  # preserve_tag_order = false
  my_taggable.my_tag_list = "tag value 3, tag value 2, tag value 1"
  my_taggable.reload.my_tag_list

  => []
  ```
* `all_my_tags_list` - Returns all `CustomTag`s for the given context for any `MyTaggable` object.
  NOTE:  Unlike `ActsAsTaggableOn`, the Tags returned represent all Tags that have ever been used for that context
  for the `MyTaggable` context.  There is no guarantee that the `CustomTag`s returned are currently being used
  by any `MyTaggable` object.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.find(taggable_id)
  my_taggable.all_my_tags_list.to_a

  => [#<CustomTag context: "my_tags", taggable_type: "MyTaggable">,
      #<CustomTag context: "my_tags", taggable_type: "MyTaggable">, ...]
  ```
* `my_tag_list?` - Returns true if the list has been set to a value.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.find(taggable_id)
  my_taggable.my_tag_list?
  => false

  my_taggable.my_tag_list = "tag value 1, tag_value 2"
  my_taggable.my_tag_list?
  => true
  ```
* `my_tag_list_change` - Returns the old and new values for a changed list.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.create!(my_tag_list: "tag value 1, tag_value 2")
  my_taggable.my_tag_list = "tag value 2, tag value 3"
  my_taggable.my_tag_list_change
  => [["tag value 1", "tag value 2"], ["tag value 2", "tag value 2"]]
  ```
* `my_tag_list_changed?` - Returns the old and new values for a changed list.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.create!(my_tag_list: "tag value 1, tag_value 2")
  my_taggable.my_tag_list_changed?
  => false

  my_taggable.my_tag_list = "tag value 2, tag value 3"
  my_taggable.my_tag_list_changed?
  => true
  ```
* `my_tag_list_will_change` - Tells the model that the `my_tag_list` field will be changing.
  This method is primarily intended for internal use. 
  Usage:
  ```Ruby
  my_taggable = MyTaggable.create!(my_tag_list: "tag value 1, tag_value 2")
  my_taggable.my_tag_list_will_change
  ```
* `my_tag_list_changed_from_default?` - Returns true if the value does not match the default for the field
  Usage:
  ```Ruby
  my_taggable = MyTaggable.create!
  my_taggable.my_tag_list_changed_from_default?
  => false

  my_taggable.my_tag_list = "tag value 2, tag value 3"
  my_taggable.my_tag_list_changed_from_default?
  => true
  ```
* `my_tag_list_was` - Returns the old values for a changed list.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.create!(my_tag_list: "tag value 1, tag_value 2")
  my_taggable.my_tag_list = "tag value 2, tag value 3"
  my_taggable.my_tag_list_was
  => ["tag value 1", "tag value 2"]
  ```
* `reset_my_tag_list!` - Resets a changed value back to what it was before
  Usage:
  ```Ruby
  my_taggable = MyTaggable.create!(my_tag_list: "tag value 1, tag_value 2")
  my_taggable.my_tag_list = "tag value 2, tag value 3"
  my_taggable.reset_my_tag_list!
  => ["tag value 1", "tag value 2"]
  ```
* `reset_my_tag_list_to_default!` - Resets a changed value back to the default values.
  Usage:
  ```Ruby
  my_taggable = MyTaggable.create!(my_tag_list: "tag value 1, tag_value 2")
  my_taggable.my_tag_list = "tag value 2, tag value 3"
  my_taggable.reset_my_tag_list_to_default!
  => ["default", "values"]
  ```

### Finding most or least used tags

You can find the most or least used tags by using:

```ruby
ActsAsTaggableOnMongoid::Models::Tag.most_used
ActsAsTaggableOnMongoid::Models::Tag.least_used
```

You can also filter the results by passing the method a limit, however the default limit is 20.

```ruby
ActsAsTaggableOnMongoid::Models::Tag.most_used(10)
ActsAsTaggableOnMongoid::Models::Tag.least_used(10)
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


### ~~Relationships~~ Not implimented yet

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

### ~~Dynamic Tag Contexts~~ Not implimented yet

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
class MyParser < ActsAsTaggableOnMongoid::GenericParser
  def parse  
    tags.each_with_object do |tag, tag_list|
      tag_list.add tag.split('|')
    end
  end

  def to_s
    tags.join("|")
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
ActsAsTaggableOnMongoid.default_parser = MyParser
@user = User.new(:name => "Bobby")
@user.tag_list = "east|south"
@user.tag_list # => ["east", "south"]
```

### ~~Tag Ownership~~ Not implimented yet

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
@some_photo.tagger_tags_on(@some_user, :locations) # => [#<ActsAsTaggableOnMongoid::Models::Tag id: 1, name: "paris">...]
@some_photo.tagger_tags_on(nil, :locations) # => Ownerships equivalent to saying @some_photo.locations
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

### ~~Tag cloud calculations~~ Not implimented yet

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
  include ActsAsTaggableOnMongoid::TagsHelper
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

### Custom Tag and Tagging tables

Each Tag that is defined allows you to specify a custom `Tags` or `Taggings` table for the data.
This allows you to add custom columns or features as needed.

#### Custom Tags
To create a custom `Tag`, you can either include `ActsAsTaggableOnMongoid::Models::Concerns::TagModel` or
you can include one or more of the sub-concerns to add the features you want to inherit and define your own
version of those features yourself.  If you do not include the `TagModel` concern and you pick the modules
you want to add yourself, please note that the order of the included modules is important and that if you
do not include the modules in the order specified, some features may not perform as you expect in some
fringe cases.

Because the Tags tables and the Taggings tables refer to each other with the `taggings` and `tags` relationships
respectively, if you create a custom Tags table you should create a custom Taggings table as well.  This means
that you will need to redefine the respective relationships in the two custom models.

```ruby
class CustomTag
  include ActsAsTaggableOnMongoid::Models::Concerns::TagModel

  has_many :taggings, dependent: :destroy, class_name: "CustomTagging"
end

class CustomTag
  include ActsAsTaggableOnMongoid::Models::Concerns::TagFields
  include ActsAsTaggableOnMongoid::Models::Concerns::TagMethods

  has_many :taggings, dependent: :destroy, class_name: "CustomTagging"

  include ActsAsTaggableOnMongoid::Models::Concerns::TagValidations
  include ActsAsTaggableOnMongoid::Models::Concerns::TagScopes
end
```  

#### Custom Taggings
To create a custom `Tagging`, you can either include `ActsAsTaggableOnMongoid::Models::Concerns::TaggingModel` or
you can include one or more of the sub-concerns to add the features you want to inherit and define your own
version of those features yourself.  If you do not include the `TagModel` concern and you pick the modules
you want to add yourself, please note that the order of the included modules is important and that if you
do not include the modules in the order specified, some features may not perform as you expect in some
fringe cases.

Because the Tags tables and the Taggings tables refer to each other with the `taggings` and `tags` relationships
respectively, if you create a custom Taggings table you should create a custom Tags table as well.  This means
that you will need to redefine the respective relationships in the two custom models.

NOTE:  If you include the `TaggingAssociations` module, do NOT include the `counter_cache` option in the `belongs_to`
relationship for the `tag` or the `taggings_count` will be doubled.  If you do not include that module, then you can
include it or not as you wish to get the count.

```ruby
class CustomTagging
  include ActsAsTaggableOnMongoid::Models::Concerns::TaggingModel

  # Do NOT include `counter_cache` here
  belongs_to :tag, inverse_of: :taggings
end

class CustomTagging
  include ActsAsTaggableOnMongoid::Models::Concerns::TaggingFields
  include ActsAsTaggableOnMongoid::Models::Concerns::TaggingMethods

  # `counter_cache` is optional here.
  # `remove_unused_tags` will not work properly if this is not included though. 
  belongs_to :tag, counter_cache: true, inverse_of: :taggings
  belongs_to :taggable, polymorphic: true

  include ActsAsTaggableOnMongoid::Models::Concerns::TaggingValidations
  include ActsAsTaggableOnMongoid::Models::Concerns::TaggingScopes
end
```  

## Configuration

Configurations set on the `ActsAsTaggableOnMongoid` (also `ActsAsTaggableOnMongoid.configuration` or
`ActsAsTaggableOnMongoid.configure { |config| }`) set global defaults for these settings.  Individual
tags can override the values to whatever they want.  Custom contexts will be created using the configuration
defaults.

If you would like to remove unused tag objects after removing taggings, add:

```ruby
ActsAsTaggableOnMongoid.remove_unused_tags = true
```

If you want force tags to be saved downcased:

```ruby
ActsAsTaggableOnMongoid.force_lowercase = true
```

If you want tags to be saved parametrized (you can redefine to_param as well):

```ruby
ActsAsTaggableOnMongoid.force_parameterize = true
```

If you would like tags to be case-sensitive and not use LIKE queries for creation:

```ruby
ActsAsTaggableOnMongoid.tags_table = AatoTags
ActsAsTaggableOnMongoid.taggings_table = AatoTaggings
```

If you want to change the default delimiter (it defaults to ','). You can also pass in an array of delimiters such as ([',', '|']):

```ruby
ActsAsTaggableOnMongoid::DefaultParser.delimiter = ','
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/acts-as-taggable-on-mongoid. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActsAsTaggableOnMongoid project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/acts-as-taggable-on-mongoid/blob/master/CODE_OF_CONDUCT.md).

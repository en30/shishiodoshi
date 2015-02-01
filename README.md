# Shishiodoshi

Shishiodoshi is a toy Sinatra app to buffer messages through HTTP.

| method | path | parameters | description |
| ------ | ---- | ---------- | ----------- |
| POST  | /shishiodoshi/:id | flushed_at, max_items | |
| DELTE | /shishiodoshi/:id | | |
| POST  | /shishiodoshis/:id/item | | params are stored |

A shishiodoshi flushes at `flushed_at`, or when the number of items reaches `max_items`.
You can change its flush behavior by overriding `flush!` method.

## Example Usage

```ruby
# Gemfile
gem 'shishiodoshi', git: 'git://github.com/en30/shishiodoshi.git'
```

```ruby
# example.rb
require 'shishiodoshi'

class Shishiodoshi::Sample < Shishiodoshi::Base
  def flush!
    if full?
      items.each { |item| puts item }
    else
      puts 'oops'
    end
  end
end

Shishiodoshi::App.class_eval do
  set :poll_per, 10 # sec
  set :shishiodoshi_type, Shishiodoshi::Sample
end
Shishiodoshi::App.run!(daemon: false)
```

and then
```sh
$ bundle exec ruby example.rb
$ curl -F 'flushed_at=2015-02-1 23:15:00' -F 'max_items=2' http://localhost:4567/shishiodoshis/test
$ curl -F 'msg=foo' http://localhost:4567/shishiodoshis/test/item
$ curl -F 'msg=bar' http://localhost:4567/shishiodoshis/test/item
```

[Another example](https://github.com/en30/shishiodoshi-sample)

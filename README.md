[![Build Status](https://travis-ci.org/Cohen-Carlisle/bihash.svg?branch=master)](https://travis-ci.org/Cohen-Carlisle/bihash)
# Bihash

A simple gem that implements a bidrectional hash

## Usage

Use as a hash, except that keys and values are interchangeable.

```ruby
abbreviations = Bihash["abbr" => "abbreviation"]
# => Bihash["abbr"=>"abbreviation"]
abbreviations["lol"] = "laugh out loud"
# => "laugh out loud"
puts abbreviations
# => Bihash["abbr"=>"abbreviation", "lol"=>"laugh out loud"]
abbreviations["lol"]
# => "laugh out loud"
abbreviations["laugh out loud"]
# => "lol"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the specs. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/Cohen-Carlisle/bihash. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

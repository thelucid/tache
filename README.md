# Tache
## Full Mustache implementation plus 'safe views'.

Tache is a **fully spec-compliant [Mustache](http://mustache.github.com/) implementation** with the *addition* of 'safe views' for end user applications.

Safe views allow Tache templates to be edited by end users, without the risk jeopardising your application's security. When using safe views, only explicitly allowed methods are ever invoked and therefore calls to potentially destructive methods such as 'eval' or 'destroy' are ignored.

#### Now with RubyMotion support.

## Usage

Tache's safe views are an opt-in feature, so Tache will behave just as you'd expect a standard Mustache implementation to behave, unless *you* say otherwise.

### Standard Views

Quick example:

```ruby
require 'tache'

Tache.render('Hello {{planet}}', 'planet' => 'World')

=> "Hello World"
```

Please note that all hash keys must be defined as strings when working with any Tache view. This minimises the risk of memory leaks caused by symbols when used in an end-user environment and is therefore a general requirement of Tache, regardless of whether or not you are using safe views.

Here's another way of doing things (no real departure from standard Mustache):

```ruby
class MyView < Tache
  def planet
    'World'
  end
  
  def star
    '*'
  end
  
  def stars
    star * 5
  end
end

view = MyView.compile("{{planet}} (rating: {{stars}})")
view.render
```
    
Result:

    World (rating: *****)

### Safe Views

In order make use of Tache's safe views, you simply use `Tache::Safe` instead:

```ruby
require 'tache/safe'

Tache::Safe.render('Hello {{planet}}', 'planet' => 'World')
=> "Hello World"
```
    
The first thing you will notice about safe views (other than them looking a lot like unsafe views), is that only values that have been explicitly exposed via safe view methods will be invoked. Therefore anything that has not been explicitly exposed will not be invoked or output to the rendered template:

```ruby
Tache::Safe.render('Hello {{planet.inspect}}', 'planet' => 'World')
=> "Hello "
```

Another example, this time subclassing `Tache::Safe`:

```ruby
class MySafeView < Tache::Safe
  def thing
    'World'
  end

  def present
    "I'm here!"
  end

  def bold
    lambda do |text|
      '<b>' + render(text) + '</b>'
    end
  end
end
```

Template:

    Hello {{thing}}, here's safe view in action:

    self            -> {{.}}
    inspect         -> {{inspect}}
    to_sym          -> {{to_sym}}
    thing           -> {{thing}}
    present         -> {{present}}
    present.upcase  -> {{present.upcase}}

    Bold: {{#bold}}{{thing}}{{/bold}}

Render:

```ruby
view = MySafeView.compile(template)
view.render
```
   
Result:

    Hello World, here's safe view in action:

    self            -> 
    inspect         -> 
    to_sym          -> 
    thing           -> World
    present         -> I'm here!
    present.upcase  -> 

    Bold: <b>World</b>
  
Notice how lambda's still work just as you'd expect but only explicitly exposed values are in the rendered output.

So, what if we want to expose something other than hash values or view object methods to our templates? Just subclass `Tache::Safe` and you're good to go, it's turtles all the way down:

Example:

```ruby
class Product
  def title
    'iPhone'
  end

  def price
    399
  end

  def destroy
    'Deleted product from database!'
  end

  # Returns product from database
  def self.first
    Product.new
  end
end

class ProductView < Tache::Safe
  def initialize(product)
    @product = product
  end

  def title
    @product.title
  end

  def price
    "$#{@product.price}"
  end
end

class CartView < Tache::Safe
  def product
    ProductView.new(Product.first)
  end
end
```

Template:

    Product price: {{product.price}}
    Trying to destroy: {{product.destroy}}

    {{^destroy}}Bad luck hacker!{{/destroy}}

Render:

```ruby
view = CartView.compile(template)
view.render
```

Result:

    Product price: $399
    Trying to destroy: 

    Bad luck hacker!

<!--
###Safe view shortcut

It can become monotonous having to create a safe view class for any object you would like to expose to a template, therefore Tache also provides a shortcut for creating safe views from existing objects.

Simply include the `Tache::Safe::Auto` module and call the `tache` class method, supplying it with a list of methods you would like to be available in your templates and Tache will dynamically create a safe view for you behind the scenes:

```ruby
class Person
  include Tache::Safe::Auto

  tache :name, :occupation
  
  def name
    'Jamie'
  end
  
  def occupation
    'Developer'
  end
  
  def age
    "Don't ask"
  end
end
```
    
Template

    {{#person}}
    Name: {{name}}
    Occupation: {{occupation}}
    Age: {{age}}
    {{/person}}
    
Render
  
```ruby
Tache::Safe.render(template, { 'person' => Person.new })
```
    
Result
    
    Name: Jamie
    Occupation: Developer
    Age: 
-->

### Compiled templates and partials

Proper documentation on compiled templates and partials coming soon! For now, just see the code (it's pretty straight forward):

```ruby
# Compiled
compiled = MyView.compile('Hello {{thing}}')
compiled.render

# Partials
Tache::Safe.render('Hello {{>partial}}', { 'a' => 'b' }, { 'partial' => 'World' })

# Both
compiled = MyView.compile('Hello {{>partial}}')
compiled.partials['partial'] = 'World'
compiled.render
```
    
You can even precompile a punch of partials (they'll get compiled for you automatically anyway but handy to know):

```ruby
compiled = MyView.compile('Hello {{>partial1}}, {{>partial2}}')
compiled.partials = { 
  'partial1' => Tache::Template.compile('{{a.b.c}}'),
  'partial2' => Tache::Template.compile('{{a.b.c.d}}')
}
compiled.render
```

## Installation

Add this line to your application's Gemfile:

    gem 'tache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tache

Note: Tache requires at least Ruby 1.9.

### RubyMotion

As above, then just require it in your Rakefile:

    require 'tache'

## Testing

Tests are written with Test::Unit and can be run with Guard:

    bundle
    bundle exec guard   

## Acknowledgements

Thanks to [Chris Wanstrath](https://github.com/defunkt) for the original Ruby implementation and [Jan Lehnardt](https://github.com/janl) for his JavaScript port (I took a great deal of inspiration, understanding and tests from this version).

Thanks also to the guys at [Shopify](https://github.com/Shopify) for their `Liquid::Drop` inspiration and [Gwendal Roué](https://github.com/groue) for putting up with my brainstorming on GitHub.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

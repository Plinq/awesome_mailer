# AwesomeMailer

AwesomeMailer is an ActionMailer extension that supports rad stuff like inline CSS embedded through `stylesheet_link_tag` or just, you know, stylesheets.

## Installation

Add this to your Gemfile:

	gem 'awesomemailer'

Then bundle. And some chips. And a soda.

## Example

Suppose you have the following mailer:

```ruby
class UserMailer < ActionMailer::Base
  def signup(user_id)
    @user = User.find(user_id)
    mail(:to => @user.email, :from => "no-reply@example.com")
  end
end
```

... and you have a template `app/views/user_mailer/signup.html.erb`. It might look something like this:

```html
<html>
  <%= stylesheet_link_tag 'email' %>
  <body>
    <div id="header"><%= link_to raw(image_tag('logo.png')), root_url %></div>
    <div id="content">
      <p>Welcome to AwesomeMailer, <%= @user.name %>! We think you might be neat.</p>
    </div>
    <div id="footer">
      Copyright &copy 2013 <a href="http://www.delightfulwidgets.com">Delightful Widgets</a>
    </div>
  </body>
</html>
```

... and your style sheet (email.css) might be kinda like this:

```css
body {
  background: #f0f0f0;
  font: 12pt Arial normal;
}

a img {
  border-width: 0;
}

#header {
  border-bottom: 1px solid black;
  margin-bottom: 1em;
}

#content {
  font-family: Helvetica;
  padding: 1em 0;
}

#content p {
  line-height: 1.3em;
}

#footer {
  border-top: 1px dotted orange;
  font-size: 10pt;
}
```

... you might be unhappy because most mail viewers couldn't care less that you included a stylesheet. But wait!
There's AwesomeMailer! Just change your mailer to look like this:

```ruby
class UserMailer < AwesomeMailer::Base
```

... and voila! Now your templates will render like this:

```html
<html>
  <body style="background: #f0f0f0; font: 12pt Arial normal;">
    <div id="header" style="border-bottom: 1px solid black; margin-bottom: 1em;">
      <a href="http://www.delightfulwidgets.com/">
        <img src="http://www.delightfulwidgets.com/assets/logo.png" style="border-width: 0;" />
      </a>
    </div>
    <div id="content" style="font-family: Helvetica; padding: 1em 0;">
      <p style="line-height: 1.3em;">Welcome to AwesomeMailer, <%= @user.name %>! We think you might be neat.</p>
    </div>
    <div id="footer" style="border-top: 1px dotted orange; font-size: 10pt;">
      Copyright &copy 2012 <a href="http://www.delightfulwidgets.com">Delightful Widgets</a>
    </div>
  </body>
</html>
```

WOW!

## Additional Features

### @import

AwesomeMailer (or really, the library it relies on, CSS parser) is smart enough to load up stylesheets through
@import statements. So go ahead and add `@import url('global.css')` to email.css, and we'll handle the rest.

### Pseudo-classes

AwesomeMailer supports more than just inline styles. If you define pseudo-classes like :hover, :after, etc, it'll
make sure they get included in a &lt;style&gt; tag in the &lt;head&gt; of your e-mail. Don&#x27;t have a &lt;head&gt;? That&#x27;s cool;
AwesomeMailer will add one.

### @font-face

AwesomeMailer will also load up font-face declarations, if'n you have 'em. That means you can add custom fonts to
your e-mails the same way you do with your websites, and if your user's mail client supports them, UP they'll go!

## Bugs
File bugs using the issues tab in Github. **Don't** e-mail me. _Please_.

## LEGAL FUNSIES

AwesomeMailer is copyright (c) 2013 Delightful Widgets Inc.

It was built by [Flip Sasser](http://www.inthebackforty.com/). CSS parsing is courtesy of ([css_parser](https://github.com/alexdunae/css_parser)) by Alex Dunae. Thanks, b.

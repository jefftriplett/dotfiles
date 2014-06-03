My Dotfiles
===========

There are my personal dotfiles. They are managed using:

- [Homebrew][4] for OS X package management
- [Homesick][1] for managing dotfiles
- [Maid][2] "Hazel for hackers" for automating various tasks
- [Whenever][3] for autmating cron jobs
- [Slate][5]: a window manager

Installation
------------

    gem install bundler
    bundle install

    homesick symlink

    maid clean

Inspiration
-----------

- https://github.com/JohnColvin/.maid/blob/master/rules.rb
- https://github.com/mitchty/src/blob/master/dotfiles/maid/rules.rb

[1]: https://github.com/technicalpickles/homesick
[2]: https://github.com/benjaminoakes/maid
[3]: https://github.com/javan/whenever
[4]: http://brew.sh/
[5]: https://github.com/jigish/slate

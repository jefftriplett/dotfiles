My Dotfiles
===========

There are my personal dotfiles. They are managed using:

- [Homebrew][4] for OS X package management
- [cider][7]: Hassle-free bootstrapping using Homebrew. cider is pip/gem tool for Homebrew
- [Homesick][1] for managing dotfiles
- [Maid][2] "Hazel for hackers" for automating various tasks
- [Whenever][3] for autmating cron jobs
- [Slate][5]: a window manager
- [pip][6]: The PyPA recommended tool for installing and managing Python packages.
- [pipsi][8]: pip script installer. pipsi is a nice tool for Python tools which need to be installed system wide.

Installation
------------

    # bundler speaks ruby
    gem install bundler

    # install our system level ruby tools
    bundle install

    # install / manage dotfiles
    homesick symlink

    # cleans up my desktop, trash, etc
    maid clean

    # install system level python libraries and tools (as few as possible)
    pip install -U -r requirements.txt

    # install isolated python apps (see `requirements-pipsi.txt` for more)
    pipsi install cider

    # homebrew install all the things
    cider restore

Inspiration
-----------

- https://github.com/JohnColvin/.maid/blob/master/rules.rb
- https://github.com/mitchty/src/blob/master/dotfiles/maid/rules.rb

Terminal theme
--------------

- https://github.com/mdo/ocean-terminal


[1]: https://github.com/technicalpickles/homesick
[2]: https://github.com/benjaminoakes/maid
[3]: https://github.com/javan/whenever
[4]: http://brew.sh/
[5]: https://github.com/jigish/slate
[6]: https://pip.pypa.io/en/latest/
[7]: https://github.com/msanders/cider
[8]: https://github.com/mitsuhiko/pipsi

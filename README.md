My Dotfiles
===========

There are my personal dotfiles. They are managed using:

- [cider][7]: Hassle-free bootstrapping using Homebrew. cider is pip/gem tool for Homebrew
- [Homebrew][4] for OS X package management
- [Homesick][1] for managing dotfiles
- [Maid][2] "Hazel for hackers" for automating various tasks
- [pip][6]: The PyPA recommended tool for installing and managing Python packages.
- [pipsi][8]: pip script installer. pipsi is a nice tool for Python tools which need to be installed system wide.
- [Slate][5]: a window manager
- [Whenever][3] for automating cron jobs

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

    # install pyenv (via Homebrew)
    brew install pyenv

    # install pyenv plugins
    git clone https://github.com/yyuu/pyenv-doctor.git ~/.pyenv/plugins/pyenv-doctor
    git clone https://github.com/yyuu/pyenv-update.git ~/.pyenv/plugins/pyenv-update
    git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
    git clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ~/.pyenv/plugins/pyenv-virtualenvwrapper
    git clone https://github.com/yyuu/pyenv-which-ext.git ~/.pyenv/plugins/pyenv-which-ext

    # pyenv setup; switch default to 2.7.x; install py3
    pyenv update
    pyenv install 2.7.10
    pyenv global 2.7.10
    pyenv install 3.4.3
    pyenv install 3.5.0

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

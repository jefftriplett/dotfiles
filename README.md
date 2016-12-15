My Dotfiles
===========

There are my personal dotfiles. They are managed using:

- [Hammerspoon][5]: An macOS automation tool (tiling windows manager)
- [Homebrew][4] for macOS package management
- [Homesick][1] for managing dotfiles
- [pip][6]: The PyPA recommended tool for installing and managing Python packages.
- [pipsi][7]: pip script installer. pipsi is a nice tool for Python tools which need to be installed system wide.
- [pyenv][8]: Simple Python version management
- ~~[Maid][2] "Hazel for hackers" for automating various tasks~~
- ~~[Whenever][3] for automating cron jobs~~

Installation
------------

1. Install pipsi

```bash
$ pip install pipsi
```

2. Install ansible

```bash
$ pipsi install ansible
```

3. Let ansible do it's thing

```bash
$ make install
```


Terminal theme
--------------

- https://github.com/mdo/ocean-terminal

Inspiration / Thank you!
------------------------

- https://github.com/epicserve/dotfiles
- https://github.com/geerlingguy/mac-dev-playbook
- https://github.com/JohnColvin/.maid/blob/master/rules.rb
- https://github.com/mathiasbynens/dotfiles/blob/master/.osx
- https://github.com/mitchty/src/blob/master/dotfiles/maid/rules.rb
- http://blog.palcu.ro/2014/06/dotfiles-and-dev-tools-provisioned-by.html

[1]: https://github.com/technicalpickles/homesick
[2]: https://github.com/benjaminoakes/maid
[3]: https://github.com/javan/whenever
[4]: http://brew.sh/
[5]: http://www.hammerspoon.org/
[6]: https://pip.pypa.io/en/latest/
[7]: https://github.com/mitsuhiko/pipsi
[8]: https://github.com/yyuu/pyenv

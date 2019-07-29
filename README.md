My Dotfiles
===========

There are my personal dotfiles. They are managed using:

- [direnv][10]: Securely loads or unloads environment variables depending on the current directory
- [Hammerspoon][5]: An macOS automation tool (tiling windows manager)
- [Homebrew][4] for macOS package management
- [Homesick][1] for managing dotfiles
- [pip][6]: The PyPA recommended tool for installing and managing Python packages.
- [pipenv][9]: Pipenv is a project that aims to bring the best of all packaging worlds to the Python world.
- [pipx][11]: 
- [pyenv][8]: Simple Python version management
- ~~[Maid][2] "Hazel for hackers" for automating various tasks~~
- ~~[pipsi][7]: pip script installer. pipsi is a nice tool for Python tools which need to be installed system wide.
- ~~[Whenever][3] for automating cron jobs~~

Installation
------------

1. Bootstrap our environment (install ansible via pipsi)

```bash
$ make bootstrap
```

2. Let ansible do it's thing

```bash
$ make install
```

Terminal theme
--------------

- https://github.com/mdo/ocean-terminal

Inspiration / Thank you!
------------------------

- [The Geeky Way: What are dotfiles?](http://www.thegeekyway.com/what-are-dotfiles/)
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
[9]: http://docs.pipenv.org/en/latest/
[10]: https://direnv.net/
[11]: https://pipxproject.github.io/pipx/

## Contact / Social Media

Here are a few ways to keep up with me online. If you have a question about this project, please consider opening a GitHub Issue. 

[![](https://jefftriplett.com/assets/images/social/github.png)](https://github.com/jefftriplett)
[![](https://jefftriplett.com/assets/images/social/globe.png)](https://jefftriplett.com/)
[![](https://jefftriplett.com/assets/images/social/twitter.png)](https://twitter.com/webology)
[![](https://jefftriplett.com/assets/images/social/docker.png)](https://hub.docker.com/u/jefftriplett/)

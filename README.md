My Dotfiles
===========

There are my personal dotfiles. They are managed using:

- [Homebrew][4] for OS X package management
- [Homesick][1] for managing dotfiles
- [Maid][2] "Hazel for hackers" for automating various tasks
- [pip][6]: The PyPA recommended tool for installing and managing Python packages.
- [pipsi][7]: pip script installer. pipsi is a nice tool for Python tools which need to be installed system wide.
- [Slate][5]: a window manager
- [Whenever][3] for automating cron jobs

Installation
------------

1. Install pipsi

    ```
    $ pip install pipsi
    ```

2. Install ansible

    ```
    $ pipsi install ansible
    ```

3. Let ansible do it's thing

    ```
    $ make setup
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
[5]: https://github.com/jigish/slate
[6]: https://pip.pypa.io/en/latest/
[7]: https://github.com/mitsuhiko/pipsi

# LUA plugin for [Far Manager](https://www.farmanager.com) 3.0 to manage Python 3.x virtual environments

This plugin can be used to create, activate, deactivate, and delete Python 3.x
virtual environments. By default it uses folder pointed with environment
variable `WORKON_HOME` to store virtualenvs, but if this variable is not set
plugin will use folder `.virtualenvs` in `USERPROFILE`.

In case if folder does not exist, it will be created automatically.

To make it easy to use the plugin **FarMenu.ini** added to the package.

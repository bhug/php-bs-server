# PHP BS Server

An Atom package to run PHP's built-in development server and display the log in a bottom pane. Can be started from any folder in the tree, the currently opened file, or the project root.
This project is a fork of https://github.com/leijou/php-server.

![Screenshot](http://i.imgur.com/FhVtl9v.png)

## Requirements

PHP must be installed on your machine, version 5.4 or greater.

If `php` is not in your system PATH you will need to put in the full path to your PHP executable in the settings of this package.

## Commands

* `php-bs-server:start` &mdash; Start / Restart PHP server from project path
* `php-bs-server:start-tree` &mdash; Start / Restart PHP server from folder/file selected in tree
* `php-bs-server:start-public` &mdash; Start / Restart PHP server from 'public' folder

# docksend.sh ![stability-deprecated](https://img.shields.io/badge/stability-deprecated-red.svg)  [![Build Status](https://travis-ci.org/lukasmartinelli/docksend.svg)](https://travis-ci.org/lukasmartinelli/docksend)

> :warning: This repository is no longer maintained by Lukas Martinelli.

A common use case with Docker is executing a virtualized process on a directory and capture stdout and mutated files.
`docksend.sh` is a quick and dirty solution for doing that remotely via SSH without setting up Docker Remote API access.

`docksend.sh` is a 100 line bash script which let's you send docker commands
to a remote Docker host and capture the output and modified files:

1. connect to your Docker host server
2. rsync local directory to server
3. pull down image
4. run docker command on server and print stdout
5. rsync changes made to directory

`docksend.sh` is thought for relatively short tasks like:

- Generate PDF
- Compile C++ code
- Linting code


## Installation

1. install rsync and ssh client
2. download `docksend.sh`

```
wget https://raw.githubusercontent.com/lukasmartinelli/docksend/master/docksend.sh
chmod +x docksend.sh
```

Or if you are using Arch install it with `yaourt docksend` which will put `docksend` into `/usr/bin`.

## Usage

```
usage: ./dockdo.sh [-v docker_volume] [user@]hostname docker_image [command]
```

### Options

- `-v`: bind a local directory to a docker volume (default: `$(pwd):/root`)
- `-d`: sync local directory to specific folder on remote machine (default: temp directory that is deleted afterwards)
- `-i`: ssh key used for connection
- `-p`: pull docker image silently before running command (no cluttered stdout)

If you want verbose output specify the `VERBOSE`
env variable (`export VERBOSE=true`).

# Examples

## Create PDF with LaTeX

Create a PDF without installing the full texlive suite locally.
After running `docksend.sh` you should now have a tex.pdf file in your folder.

```bash
./docksend.sh core@104.236.232.214 ontouchstart/texlive-full pdftex tex.tex
```

In this example we omited the `-v` volume binding. This means that `docksend.sh`
will automatically bind the current directory to `/root` and set the working
directory to `/root` as well.

## C++ Linting

Let's say we want to run [Facebook's C++ linter](https://code.facebook.com/posts/729709347050548/under-the-hood-building-and-open-sourcing-flint/) on the
[markov](https://github.com/NathanEpstein/markov) codebase we are working
on locally.

```
git clone git@github.com:NathanEpstein/markov.git
./docksend.sh -v markov:/root core@104.236.232.214 lukasmartinelli/docker-flint /root
```

Short explanation:
- with `-v` we bind the local `markov` directory to the docker `/root` directory
- because we did not specify an explicit destination a temp directory is created
- we pull the `lukasmartinelli/docker-flint` docker image and execute it with `/root`

Verbose output:

```
created tempdir core@104.236.232.214:/tmp/tmp.2ap1z7oX9G for syncing
syncing markov up to core@104.236.232.214:/tmp/tmp.2ap1z7oX9G
sending incremental file list
./
.gitignore
Makefile
README.md
markov.cpp
markov.h

sent 3,006 bytes  received 117 bytes  694.00 bytes/sec
total size is 6,832  speedup is 2.19
/root/markov.h(1): Missing include guard.
/root/markov.h(1): Missing include guard.
syncing core@104.236.232.214:/tmp/tmp.2ap1z7oX9G down to markov
receiving incremental file list

sent 21 bytes  received 112 bytes  29.56 bytes/sec
total size is 6,832  speedup is 51.37
deleted tempdir core@104.236.232.214:/tmp/tmp.2ap1z7oX9G
```

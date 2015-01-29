# Docksend

A common use case with Docker is executing a virtualized process on a directory and capture stdout and mutated files. But because docker images can require
alot of space and process might take alot of ressource I often times run
them on a server.

`docksend.sh` is a 100 line bash script which let's you send docker commands
to a remote Docker host and capture the output and modified files:

1. connect to your Docker host server
2. rsync local directory to server
3. run docker command on server and print stdout
4. rsync changes made to directory

```
usage: ./dockdo.sh [-v docker_volume] [-i ssh_identity_file] [user@]hostname docker_image [command]
```

## Example - C++ Linting

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

Output:

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

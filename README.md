# r-in-docker
A script to spin up an R (Studio) project that runs in Docker

Since I've had to change computers at work more often than I'd like (looking at you, HP), I built a workflow around running R and its packages within a Docker container. The benefit of this is that my environments are fully reproducible, and can be spun up within minutes, including dependencies.

The downside is that it takes a bit of prep work to get to this point. This repository automates that work in a single script.

## Assumptions

* UNIX-like operating system (real or virtualised)
* Docker is installed
* Current user is in the `docker` group

## How to use

### Setup

1. `git clone https://github.com/AntheSevenants/r-in-docker.git`
2. `cd r-in-docker`
3. `chmod +x r-in-docker.sh`
4. `sudo cp r-in-docker.sh /usr/local/bin/r-in-docker.sh`

### Use

1. Navigate to the directory where you want the project folder to be created.
2. Run `r-in-docker.sh`. If you supply an argument, that argument will be used as the project name. Else, the script will ask for the project name.
3. The project directory and files will be created automatically. All that remains to do is to run `docker compose up` in the project directory.

## Notice

- You will have to rebuild your images if you add dependencies. You can do this by running `sh .docker/build.sh` from within the project directory. Make sure to snapshot your dependencies with `renv:snapshot()` from within R. This will update the lockfile (`renv.lock`)
- Docker images will be generated with the 'anthesevenants/' prefix and my git credentials. That's me, after all. If you want to change this, feel free to fork this repository.
#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Enter project name: (prefer A-za-z, no spaces)"
    read project_name
  else
    project_name=$1
    echo "Using '$project_name' as project name"
fi


project_root="$(pwd)/$project_name/"

# Make Docker-safe
project_name_image=${project_name,,}
echo "Docker image name will be '$project_name_image'"

mkdir $project_root

#
# renv.lock
#
echo "{}" > $project_root/renv.lock

#
# Dockerfile.base
#
dockerfile_base="# I don't really care about storage, I care about reusability
# So, the base image will be the rocker/rstudio image
# This already contains R and R studio, which is mostly what we'll need
FROM rocker/rstudio:4

# First, I copy all dependencies into the container
COPY renv.lock renv.lock

# Install some linux libraries that R packages need
RUN apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev libodbc1 libxt6

# Then, I install 'renv', and then restore all dependencies
# renv will download and install everything as needed
RUN R -q -e \"install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))\"
RUN R -q -e \"renv::restore()\"


# This image can now be used to launch an R Studio environment"
echo "$dockerfile_base" > $project_root/Dockerfile.base

#
# Dockerfile.rstudio
#
dockerfile_rstudio="FROM anthesevenants/$project_name_image:base
# We start from the R Studio base

RUN apt-get install -y lsof

# Let's set the working directory correctly (also for the R environment itself)
RUN echo \"setwd(\\\"/home/rstudio/$project_name/\\\")\" > ~/../home/rstudio/.Rprofile
RUN mkdir -p \"/home/rstudio/.local/share/rstudio/projects_settings/\"
RUN mkdir -p \"/root/.local/share/rstudio/projects_settings/\"
RUN chmod -R 777 \"/home/rstudio/.local/\"
RUN chmod -R 777 \"/root/.local/\"
RUN echo \"/home/rstudio/$project_name/$project_name.Rproj\" > \"/home/rstudio/.local/share/rstudio/projects_settings/last-project-path\"
RUN echo \"/home/rstudio/$project_name/$project_name.Rproj\" > \"/root/.local/share/rstudio/projects_settings/last-project-path\""

echo "$dockerfile_rstudio" > $project_root/Dockerfile.rstudio

#
# docker-compose.yml
#
docker_compose_yml="version: \"3\"

services:
  rstudio:
    image: \"anthesevenants/$project_name_image:rstudio\"
    ports: 
      - "8787:8787"
      - "8788:8788"
    environment:
      DISABLE_AUTH: true
    volumes:
      - .:/home/rstudio/$project_name/:Z"
echo "$docker_compose_yml" > $project_root/docker-compose.yml

# projectname.Rproj
project_name_Rproj="Version: 1.0

RestoreWorkspace: Default
SaveWorkspace: Default
AlwaysSaveHistory: Default

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8

RnwWeave: Sweave
LaTeX: pdfLaTeX"

echo "$project_name_Rproj" > "$project_root/$project_name.Rproj"

#
# .docker/
#
mkdir "$project_root/.docker/"

#
# .docker/build.sh
#
build_sh="docker build \\
    -f Dockerfile.base \\
    -t anthesevenants/$project_name_image:base .

docker build \\
    -f Dockerfile.rstudio \\
    -t anthesevenants/$project_name_image:rstudio ."
build_sh_path=$project_root/.docker/build.sh
echo "$build_sh" > $build_sh_path

echo "Building Docker images"
chmod +x $build_sh_path
cd $project_root && sh $build_sh_path
cd $project_root && git init
cd $project_root && git config user.name "Anthe Sevenants"
cd $project_root && git config user.email "anthe.sevenants@kuleuven.be"

echo "All done!"
echo "Navigate to '$project_root' and run 'docker compose up'"
echo "- Anthe signing off... 2024-10-24, 20:46"
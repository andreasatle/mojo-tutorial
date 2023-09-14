# Use an official Ubuntu base image
FROM ubuntu:20.04

# Update package lists and install curl
# If emacs is not installed, then the curl script default to user input, and fails.
RUN apt-get update && apt-get install -y curl emacs

# Install modular/mojo
RUN curl https://get.modular.com | \
  MODULAR_AUTH=mut_485a3f6ba5dd4ad3b15a93e6b43b5f3c \
  sh -
RUN modular install mojo

# Append PATH with the path to the mojo binary
ENV PATH="${PATH}:/root/.modular/pkg/packages.modular.com_mojo/bin"

# Set the path to the python packages
ENV MOJO_PYTHON_LIBRARY="/usr/lib/x86_64-linux-gnu/libpython3.8.so"
# Set a user directory
WORKDIR /usr/app

# Start a shell
CMD ["bash"]

## To build the image
# docker build -t mojo .

## To run the image mounting the current directory
# docker run -it -v `pwd`:/usr/app mojo

## Inside the docker container, run the following to e.g. run my_script.mojo
# mojo < my_script.mojo

## Alt. you can compile with
# mojo build my_script.mojo

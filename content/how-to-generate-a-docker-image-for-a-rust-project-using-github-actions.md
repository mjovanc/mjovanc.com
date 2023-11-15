+++
title = "How to generate a Docker image for a Rust project using GitHub Actions"
description = "In this article we are going through how to generate a Docker image for a Rust project, using web framework Rocket, with GitHub Actions."
date = 2023-10-25
path = "tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions"

[taxonomies]
categories = ["tooling", "ci/cd", "virtualization"]
tags = ["docker", "rust", "github actions", "rocket"]
+++

In this article we are going through how to generate a [Docker](http://docker.com) image for a Rust project, using web framework [Rocket](http://rocket.rs), with [GitHub Actions](https://github.com/features/actions).

It’s very straight forward. But I will go step by step here in case you haven’t touched Docker or GitHub Actions before.
<!-- more -->

## Initialize Rust project

First we need to create a repo on GitHub and clone the repo:

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-0.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

Then we are going to initialize a Rust binary project:

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-1.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

Now we need to add the Rocket v0.5.0 release candidate 3 to the dependencies in Cargo.toml. Note: you might need to change this later when it actually is a proper release.

```toml
[dependencies]
rocket = "=0.5.0-rc.3"
```

We also need to specify the target name (bin) for the project in the same file (we call it rocket in this example):

```toml
[[bin]]
name = "rocket"
path = "src/main.rs"
```

Now we are going to open up the file in src/main.rs and remove the main function and then add the external crate rocket with the macro attribute #[macro_use] and then import the rocket::Request struct so we can use that later.

```toml
#[macro_use]
extern crate rocket;

use rocket::Request;
```

We are now going to create our first endpoint. This will basically just print out “Hello, world!” when we send a GET request to the root / path.

```rust
#[get("/")]
fn index() -> &'static str {
    "Hello, world!"
}
```

Then we are adding a second endpoint just for fun that can take request parameters such as name and age so we can send a more interesting response back when we send a request to it.

```rust
#[get("/hello/<name>/<age>")]
fn hello(name: &str, age: u32) -> String {
    format!("Hello, {}! You are {} years old.", name, age)
}
```

And we are also adding some error response handling if we for some reason trying to request something that does not exist, just so we get some proper feedback. Here we are using the struct we imported as a function parameter.

```rust
#[catch(404)]
fn not_found(req: &Request) -> String {
    format!("Sorry, {} was not found.", req.uri())
}
```

Now the most important step is to actually mount the endpoints we created. We first use the macro attribute #[launch] before we define a new function. Then we add the function name as rocket and we return a new instance of the Rocket application by calling build() and mounting the routes index and hello and finally register the not_found function so Rocket knows it will use that for 404 responses if we request something which might not be registered.

```rust
#[launch]
fn rocket() -> _ {
    rocket::build()
        .mount("/", routes![index, hello])
        .register("/", catchers![not_found])
}
```

That’s it for the source code part, now we are ready to make our Dockerfile!

## Create a Dockerfile for the Rust application

We are going to produce a multi-stage Docker build so we can reduce the size of the Docker image as much as possible. Dependencies for building the Rust project is not neccessary to have after so we can skip files like that with the multi-stage build process.

To begin, in the root of the repository create a file called Dockerfile.

Now we are adding our first stage and set the current working directory to /app

```Dockerfile
FROM rust:latest as builder
WORKDIR /app
```

Now we are creating a temporary src directory and copying over our files from src/ to the newly created src directory and also copying over Cargo.toml file:

```Dockerfile
COPY Cargo.toml ./
RUN mkdir src
COPY src/ src/
```

Now we are ready to build so we add the RUN command with cargo build and the flag release. This will make the binary smaller.

```Dockerfile
RUN cargo build --release
```

We now define our second build step:

```Dockerfile
FROM ubuntu:latest
```

Setting the working directory to /app and installing dependencies:

```Dockerfile
WORKDIR /app

RUN apt-get update && apt-get install -y \
    libssl1.1
```

Now we are copying the target we created in the first build step to the second build step:

```Dockerfile
COPY --from=builder /app/target/release/rocket . 
```

And lastly we are exposing the port 8000 and set a command that will run once we start the container. In this case ./rocket which is our name of the binary we specified in the Cargo.toml file.

```Dockerfile
EXPOSE 8000

CMD ["./rocket"]
```

Here is the complete Dockerfile:

```Dockerfile
# step 1: build the rust application
FROM rust:latest as builder

WORKDIR /app

COPY Cargo.toml ./
RUN mkdir src
COPY src/ src/

RUN cargo build --release

# step 2: create the runtime image
FROM ubuntu:latest

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libssl-dev

COPY --from=builder /app/target/release/rocket . 

EXPOSE 8000

CMD ["./rocket"]
```

We can now try build this locally to see if it works. Run it with:

```sh
docker build -t rust-rocket .
```

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-2.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

Yey, it works to build. Now we just need to run it to see if the application starts. Run it with:

```sh
docker run -p 8000:8000 rust-rocket
```

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-3.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

And it works! We have now a working Dockerfile for our Rust project. Now we just have to make the final step to produce this Docker image on GitHub Actions and save it to the GitHub registry.

## Create a GitHub Actions workflow

### Create personal access token

First we need to setup GitHub so login and go to https://github.com/settings/token and generate an token with these settings:

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-4.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

Now save the value temporary and go to the repository settings and select “Secrets and variables” and then “Actions”.

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-5.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

Add a new repository secret called GHCR_PAT and enter the token we generated and press save.


### Create the GitHub Actions workflow

Now we are ready to create the GitHub Actions workflow. So in the root of the repository create a directory called .github and inside it create another directory called workflows.

Now create a new file called ci.yml and place the code below inside it. First we name the name of the workflow to build. Then we are setting environment variables we are going to use later. In this case we set the GITHUB_REGISTRY so we know which Docker registry we are targeting, GITHUB_OWNER to your account or organization and GITHUB_DOCKER_IMAGE to the name of the Docker image we are producing.

Then we are adding two trigger rules, on-push and on-pull-request:

- on-push will trigger if we push to the master branch
- on-pull-request will trigger if we are targetting the master branch and we are also adding which files or paths we are ignoring. For example, if we make a change to README.md we don’t want to trigger a build since it does not effect the source code.

```yaml
name: build

env:
  GITHUB_REGISTRY: "ghcr.io"
  GITHUB_OWNER: "mjovanc"
  GITHUB_DOCKER_IMAGE: "medium-rust-docker"

on:
  push:
    branches:
      - master
  pull_request:
    branches:
      - master
    paths-ignore:
      - "**/README.md"
      - "**/LICENSE"
      - "**/.gitignore"
```

Now we add a simple job below the on: section for building the Rust application, run clippy for linting and running unit tests (if we would add it later).

```yaml
jobs:
  build:
    name: build
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          profile: minimal
          toolchain: stable

      - name: Cache Cargo Dependencies
        uses: actions/cache@v2
        with:
          path: |
            ~/.cargo
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}

      - name: Run Clippy
        run: cargo clippy --all-targets --all-features

      - name: Build Project
        run: cargo build --release

      - name: Run Tests
        run: cargo test
```

And lastly we add the Docker job. This this will depend on the build job to succeed before starting and it will checkout the code, login to GitHub registry with the personal access token we generated before, build a docker image and tag it to latest, tag a new image with the commit SHA value and then finally push up both the image tagged with latest and the image tagged with the commit SHA.

```yaml
docker:
    name: Build and Publish Docker Image
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v3
      - uses: benjlevesque/short-sha@v2.2

      - name: Log into registry ghcr.io
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_PAT }}

      - name: Build Docker
        run: |
          docker build -t $GITHUB_REGISTRY/$GITHUB_OWNER/$GITHUB_DOCKER_IMAGE:${{ env.SHA }} . --no-cache

      - name: Tag Image
        run: |
          docker tag $GITHUB_REGISTRY/$GITHUB_OWNER/$GITHUB_DOCKER_IMAGE:${{ env.SHA }} $GITHUB_REGISTRY/$GITHUB_OWNER/$GITHUB_DOCKER_IMAGE:latest

      - name: Publish Docker Image to GitHub Repository
        run: |
          docker push $GITHUB_REGISTRY/$GITHUB_OWNER/$GITHUB_DOCKER_IMAGE:${{ env.SHA }}
          docker push $GITHUB_REGISTRY/$GITHUB_OWNER/$GITHUB_DOCKER_IMAGE:latest
```

Now we push everything up to GitHub and let’s check. You are going to se a dot (could differ in color depending on theme) next to the commit SHA value. That means there is a workflow running.

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-6.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

Press on the dot and you will be able to se status of the workflow, you can also press on the tab “Actions”.

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-7.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

So now we can clearly see it passed on both jobs.

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-8.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

Let’s just check one final thing, if we actually have something up on GitHub registry, to confirm. Go to your GitHub profile and select “Packages” tab. And here it is! It’s private by default, but you can go into it and update it to be public if you want others to be able to pull the Docker image.

<div style="text-align: center;">
  <img src="/tooling/how-to-generate-a-docker-image-for-a-rust-project-using-github-actions/image-9.webp" alt="Docker Rust GitHub Actions Screenshot 0" style="max-width: 100%; display: inline-block;">
</div>

## Summary

This was a very basic guide on how to setup a basic Rust project using Rocket, create a Dockerfile for it and configure a GitHub Actions workflow to automate the process.

The repository used you can find here: [https://github.com/mjovanc/medium-rust-docker](https://github.com/mjovanc/medium-rust-docker)

## Resources

- [Github Actions Docs](https://docs.github.com/en/actions)
- [Rocket](https://rocket.rs/v0.5-rc/guide/)
- [Docker Docs](https://docs.docker.com/)
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker multi-stage](https://docs.docker.com/build/building/multi-stage/)

## Connect with me
- [𝕏](https://x.com/mjovanc)
- [GitHub](https://github.com/mjovanc)
- [LinkedIn](https://www.linkedin.com/in/marcuscvjeticanin/)
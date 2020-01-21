# Info
[![Actions Status](https://github.com/mirzamerdovic/docker-semver-github-action/workflows/Test/badge.svg)](https://github.com/mirzamerdovic/docker-semver-github-action/actions)
[![Actions Status](https://github.com/mirzamerdovic/docker-semver-github-action/workflows/Integration%20Test/badge.svg)](https://github.com/mirzamerdovic/docker-semver-github-action/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/mirzamerdovic/publish-docker-github-action)](https://hub.docker.com/r/mirzamerdovic/publish-docker-github-action)

This Action for [Docker](https://www.docker.com/) uses the [SemVer](https://semver.org/) version for image tagging.  
That means that if you are pushing an image:
``` docker push myimage:1.4.2```  
It will be tagged as _latest_ and pushed, but also images:
* myimage:1.4
* myimage:1
will be tagged as _latest_ and pushed.

This way when you specify in your Docker file:  
``` FROM myimage:latest```  
you will pull version 1.4.2, but if you specify:  
``` FROM myimage:1.4``` or   
``` FROM myimage:1```  
you will also pull the version 1.4.2

Now lets image that there is an image with version 1.3.6 and also 1.4.0 if you specify:  
```FROM myimage:1.3```  
it will pull the 1.3.6 (_assuming that next version is 1.4.x_) and if you specify:  
```FROM myimage:1.4.0```  
it will pul the version _1.4.0_ although there is a more recent release (_1.4.2_).

This might not be useful to everyone but it does suite my needs.

## Usage

```yaml
name: Docker SemVer
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Publish to Registry
      uses: mirzamerdovic/docker-semver-github-action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        semver: 1.2.5
```

### Arguments

Required:  
`name` is the name of the image you would like to push  
`username` the login username for the registry  
`password` the login password for the registry  

Optional:  
`semver`: the tag name e.g. 1.2.3 (if ommited latest will be used as tag)
`dockerfile`: when you would like to explicitly build a Dockerfile
`workdir` if you need to change the work directory 
`context` when you would like to change the Docker build context.
`buildargs` when you want to pass a list of environment variables as [build-args](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg). Identifiers are separated by comma.

### Output

`tag` is the tag, which was pushed  

## Automatic versions via VERSION file
Action also supports a way of automatic version using the VERSION file.

VERSION file is a simple text file that contains the version number for example:  
```1.4.12```

The action will try to extract the file from built image, so if you want to use it you will need to add it as a part of your repository and your Dockerfile.  
Let's imagine that you have a _VERSION_ file in the same folder as the _Dockerfile_. In the _Dockerfile_ you'd need to add a line:  
```ADD VERSION .```  
so the _VERSION_ file gets copied.  

If you have done all this the action will extract the _VERSION_ file and read the version value that will be used as a tag for your image.  
If you think that all this is bollocks your build will still work without adding the _VERSION_ file.

## What's missing?
* I have no support for properly tagging images built from branches or PRs one would expect to be able to just specify 1.4.5 and when you are pushing 
an image from a branch to get a tag: 1.4.5-mybranch same goes for PR
Current workaround for that is that you specify the suffix yourself.
* More tests

## Credits
I need to say a big **thank you** to [elghor](https://github.com/elgohr) who made [Publish-Docker-Github-Action](https://github.com/elgohr/Publish-Docker-Github-Action) that I forked and built this one from. He also has some other useful actions that you might one to check out.

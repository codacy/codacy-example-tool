# Contributing guide

## Build

To build the tool docker, run:

```bash
docker build -t codacy-example-tool -f Dockerfile .
```

The docker is ran with the following command:

```bash
docker run -it -v $srcDir:/src -v $codacyrcFile:/.codacyrc codacy-example-tool:<DOCKER_VERSION>
```

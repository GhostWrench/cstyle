# Using docker development container with this project

## Build the container

```bash
$ docker compose build
```

## Start the container

```bash
$ docker compose up -d
```

## Attach to a running container

```bash
$ docker compose exec cstyle bash
```

## Start and attach to a running container

```bash
$ docker compose run --rm cstyle bash
```

## Stop the container

```bash
docker compose down
```

## Run the build inside the container and exit

```bash
docker compose run --rm cstyle make {options}
```

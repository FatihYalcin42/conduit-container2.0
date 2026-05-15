# Conduit Container 2.0

Containerized deployment setup for the Conduit application with a Django backend, Angular frontend, and PostgreSQL database. This repository packages the app for VM-based hosting with Docker Compose and environment-driven configuration.

## Table of Contents

- [Quickstart](#quickstart)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Environment Variables](#environment-variables)
- [Services and Ports](#services-and-ports)
- [Deployment Workflow](#deployment-workflow)
- [API Reference](#api-reference)
- [Logs](#logs)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before running the stack on a VM, make sure the following tools and conditions are available:

- Docker is installed and the daemon is running
- Docker Compose is available via `docker compose`
- Git is installed on the VM
- SSH access to the VM is configured
- GitHub Actions secrets are configured for the deployment workflow
- Inbound traffic for port `8282` is allowed
- Inbound traffic for port `8000` is allowed if direct backend access is required

## Quickstart

These steps are intended for deployment on a VM server.

1. Clone the repository on the VM:

   ```bash
   git clone git@github.com:FatihYalcin42/conduit-container2.0.git
   cd conduit-container2.0
   ```

2. Create the runtime environment file and adjust the Django or database settings as needed:

   ```bash
   cp .env.example .env
   ```

3. Trigger the GitHub Actions deployment workflow from the PR branch or by updating the pull request.

4. Open the hosted frontend in the browser:

   ```text
   http://<VM-IP>:8282
   ```

5. Check container status:

   ```bash
   docker compose ps
   ```

## Project Structure

```text
.
├── conduit-backend/       Django API application
├── conduit-frontend/      Angular frontend application
├── docker-compose.yml     Service orchestration for VM hosting
├── .env.example           Environment template
└── README.md              Project documentation
```

## Usage

### Start the application

```bash
docker compose --env-file .deploy.env pull
docker compose --env-file .deploy.env up -d
```

### Stop the application

```bash
docker compose down
```

### Pull updated images after a new deployment

```bash
docker compose --env-file .deploy.env pull
docker compose --env-file .deploy.env up -d
```

### Remove containers and volumes

```bash
docker compose down -v
```

### Access the application on the VM

- Frontend: `http://<VM-IP>:8282`
- Backend API: `http://<VM-IP>:8000/api`

## Environment Variables

The repository uses a root `.env` file. Do not store secrets directly in the Dockerfiles or application source when runtime configuration can be injected through `.env`.

The required environment variables are documented in [.env.example](.env.example).

Example workflow:

```bash
cp .env.example .env
```

Then adjust values in `.env` for the VM IP or domain, allowed hosts, and production secrets.

## Services and Ports

The deployment is orchestrated by `docker-compose.yml` and includes three services:

- `frontend`: Angular application served by Nginx on port `8282`, using `FRONTEND_IMAGE`
- `backend`: Django application served by Gunicorn on port `8000`, using `BACKEND_IMAGE`
- `database`: PostgreSQL service available only inside the Docker network on port `5432`

Persistent data is stored through the `postgres_data` Docker volume.

## Deployment Workflow

Deployment is automated with GitHub Actions via [docker-publish.yml](.github/workflows/docker-publish.yml).

- On pull requests to `main`, the workflow builds and pushes backend and frontend images to `ghcr.io`
- Images are tagged with the current commit SHA, not `latest`
- The deploy job connects to the VM over SSH
- The workflow writes the exact image tags into a temporary `.deploy.env` file on the VM
- `docker compose --env-file .deploy.env pull` and `docker compose --env-file .deploy.env up -d` start the deployment without rebuilding on the server

Required GitHub Actions secrets:

- `SSH_HOST`
- `SSH_USER`
- `SSH_PRIVATE_KEY`
- `SSH_PORT`
- `GHCR_PAT`

## API Reference

Main backend entrypoint:

- Base URL: `http://<VM-IP>:8000/api`

Example endpoints:

- `GET /api/articles`
- `POST /api/users/login`
- `POST /api/users`
- `GET /api/profiles/:username`

The frontend consumes the backend through the runtime-configured `FRONTEND_API_URL`.

## Logs

View all service logs:

```bash
docker compose logs
```

View logs for a single service:

```bash
docker compose logs frontend
docker compose logs backend
docker compose logs database
```

Save logs to a file:

```bash
docker logs conduit-backend > conduit-backend-logs.txt
```

## Troubleshooting

### Frontend is not reachable

- Check whether the VM firewall allows port `8282`
- Run `docker compose ps`
- Inspect frontend logs with `docker compose logs frontend`

### Backend cannot connect to the database

- Verify `DJANGO_DB_*` values in `.env`
- Check database logs with `docker compose logs database`
- Restart the stack after changes:

  ```bash
  docker compose down
  docker compose --env-file .deploy.env pull
  docker compose --env-file .deploy.env up -d
  ```

### Django host or CORS errors

- Update `DJANGO_ALLOWED_HOSTS`
- Update `DJANGO_CORS_ORIGIN_WHITELIST`
- Recreate the containers after editing `.env`

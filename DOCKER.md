# Docker Setup for Six Degrees of Wikipedia

This document explains how to build and run the Six Degrees of Wikipedia application using Docker.

## Overview

The Docker setup consists of three main parts:

1.  `Dockerfile`: This file defines the steps to build a Docker image containing the frontend and backend of the application. It's a multi-stage build that first builds the React frontend and then sets up a Python environment with Nginx and Supervisor to run the Flask backend and serve the frontend.

2.  `docker-compose.yml`: This file makes it easy to run the application container. It's configured to use a pre-built image from GitHub Container Registry, and it sets up volumes for persisting database files and SSL certificates.

3.  `.github/workflows/docker-publish.yml`: This GitHub Actions workflow automatically builds the `Dockerfile` and pushes the resulting image to the GitHub Container Registry on every push to the `main` branch.

## Running the Application

### Prerequisites

-   [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) are installed on your server.
-   You have cloned this repository.

### 1. Database

The Docker image is configured to use mock databases by default. For a production environment, you should use real databases.

1.  Create a `data/sdow` directory in the root of the project:
    ```bash
    mkdir -p data/sdow
    ```
2.  Place your `sdow.sqlite` and `searches.sqlite` files inside the `data/sdow` directory. If your `sdow.sqlite` file is compressed (`.gz`), you need to decompress it first.

The `docker-compose.yml` file will mount this `data/sdow` directory into the container at `/app/sdow`.

### 2. Run with Docker Compose

To run the application, use the following command from the root of the repository:

```bash
docker-compose up -d
```

This will pull the latest image from GitHub Container Registry and start the container in detached mode. The web application will be available on port 80.

### 3. Setting up SSL (HTTPS)

The provided `nginx.conf` is configured to support SSL with Let's Encrypt. The `docker-compose.yml` file creates volumes to store the certificates.

**Note:** If your domain is not `api.sixdegreesofwikipedia.com`, you must update the domain in `config/nginx.conf` and `docker-compose.yml`, then have the image rebuilt and pushed (e.g., by pushing the change to the `main` branch).

Follow these steps to obtain and install an SSL certificate:

1.  Start the container (if not already running):
    ```bash
    docker-compose up -d
    ```

2.  Run Certbot inside the running container to obtain the certificate. Make sure to replace `your-domain.com` and `your-email@example.com` with your actual domain and email. The domain should match the one in `config/nginx.conf`.
    ```bash
    docker-compose exec sdow certbot certonly --webroot --webroot-path /var/www/certbot -d your-domain.com --email your-email@example.com --agree-tos --no-eff-email --non-interactive
    ```

3.  After Certbot successfully obtains the certificate, restart nginx to load it:
    ```bash
    docker-compose exec sdow supervisorctl restart nginx
    ```
    Alternatively, you can restart the entire container:
    ```bash
    docker-compose restart
    ```

The application should now be accessible via HTTPS on port 443. The Certbot setup includes a cron job that will automatically renew your certificate.

## Building the Image Locally

If you need to build the image locally instead of using the one from GitHub Container Registry, you can use this command:

```bash
docker build -t my-sdow-image .
```

Then, you would need to edit the `docker-compose.yml` file to use `my-sdow-image` as the image instead of `ghcr.io/jwngr/sdow:latest`.

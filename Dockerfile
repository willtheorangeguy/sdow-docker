# Dockerfile for Six Degrees of Wikipedia

# Stage 1: Build the frontend
FROM node:20-slim AS frontend-builder
WORKDIR /app/website
COPY website/package.json website/package-lock.json ./
RUN npm install
COPY website/ ./
RUN npm run build

# Stage 2: Setup the backend
FROM python:3.11-slim-bookworm
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY . .

# Install Python dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# Copy built frontend from the builder stage
COPY --from=frontend-builder /app/website/dist /app/website/dist

# Create mock databases
RUN python scripts/create_mock_databases.py

# Copy configurations
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80 for nginx
EXPOSE 80

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

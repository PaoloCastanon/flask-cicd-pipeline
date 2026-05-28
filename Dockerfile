# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Install dependencies into an isolated directory so the final image never
# contains pip, wheel, or any build tooling.
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .

# --prefix puts everything into /install; we copy that folder to the next stage.
# --no-cache-dir keeps this layer small.
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: production ───────────────────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Pull only the installed packages from the builder stage.
COPY --from=builder /install /usr/local

# Copy only the application source — tests and dev files are excluded by .dockerignore.
COPY app/ ./app/

# Running as a non-root user limits the blast radius if the container is ever
# compromised (a container running as root can more easily escape to the host).
RUN adduser --disabled-password --gecos "" appuser
USER appuser

EXPOSE 5000

# gunicorn is a production-grade WSGI server. Flask's built-in server prints a
# warning if used in production and is single-threaded.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:create_app()"]

# Docker will call GET /health every 30 s. If it fails 3 times the container is
# marked "unhealthy" and orchestrators (Kubernetes, ECS) can restart it.
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

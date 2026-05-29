# Flask CI/CD Pipeline

![CI/CD Pipeline](https://github.com/PaoloCastanon/flask-cicd-pipeline/actions/workflows/ci.yml/badge.svg)
![Python](https://img.shields.io/badge/python-3.12-blue)
![Docker](https://img.shields.io/badge/docker-multi--stage-blue)
![License](https://img.shields.io/badge/license-MIT-green)

A minimal Python/Flask web application with a complete CI/CD pipeline built with Docker and GitHub Actions. Every push triggers automated tests; merges to `main` build and publish a Docker image to Docker Hub automatically.

Built as a DevOps portfolio project to demonstrate end-to-end software delivery practices.

---

## Architecture

```
Developer
    │
    │  git push
    ▼
┌─────────────────────────────────────────────────────────────┐
│                       GitHub                                │
│                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────────┐  │
│  │          │    │          │    │                      │  │
│  │  test    │───▶│  build   │───▶│  push  (main only)   │  │
│  │  (pytest)│    │ (docker) │    │  (docker hub login)  │  │
│  │          │    │          │    │                      │  │
│  └──────────┘    └──────────┘    └──────────┬───────────┘  │
│                                             │               │
└─────────────────────────────────────────────┼───────────────┘
                                              │  docker push
                                              ▼
                                    ┌─────────────────┐
                                    │   Docker Hub    │
                                    │                 │
                                    │  username/      │
                                    │  flask-cicd-    │
                                    │  pipeline:latest│
                                    └─────────────────┘
```

Pipeline rules:
- **All branches**: `test` and `build` jobs run on every push.
- **`main` only**: the `push` job runs after `build` succeeds, publishing the image to Docker Hub.
- **Pull requests**: only `test` and `build` run — no image is published until the PR is merged.

---

## Tech Stack

| Tool | Version | Why |
|------|---------|-----|
| Python | 3.12 | Clean, readable; ideal for teaching DevOps concepts without language complexity |
| Flask | 3.1 | Minimal web framework — the whole app fits in two files |
| gunicorn | 23 | Production WSGI server; Flask's dev server is single-threaded and not safe for production |
| pytest | 8 | Standard Python test runner with a clean fixture system |
| Docker | multi-stage | Separates build deps from the runtime image; final image is smaller and has no build tools |
| GitHub Actions | — | Native to GitHub, YAML-based, generous free tier for public repos |
| Docker Hub | — | Most widely used container registry; free public repositories |

---

## Project Structure

```
flask-cicd-pipeline/
├── app/
│   ├── __init__.py          # App factory (create_app)
│   └── routes.py            # GET /, /health, /version
├── tests/
│   ├── __init__.py
│   └── test_routes.py       # pytest tests for all endpoints
├── .github/
│   └── workflows/
│       └── ci.yml           # GitHub Actions: test → build → push
├── Dockerfile               # Multi-stage build
├── .dockerignore            # Keeps tests and dev files out of the image
├── requirements.txt         # Production deps (flask, gunicorn)
├── requirements-dev.txt     # Dev deps (pytest, pytest-flask)
└── README.md
```

---

## Running Locally

### Option 1 — Plain Python

```bash
# 1. Clone the repo
git clone https://github.com/PaoloCastanon/flask-cicd-pipeline.git
cd flask-cicd-pipeline

# 2. Create a virtual environment (keeps dependencies isolated)
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\Scripts\activate

# 3. Install dev dependencies (includes Flask + test tools)
pip install -r requirements-dev.txt

# 4. Run the app
flask --app "app:create_app" run

# 5. Visit http://localhost:5000
```

### Option 2 — Docker

```bash
# Build the image
docker build -t flask-cicd-pipeline:local .

# Run the container (maps port 5000 on your machine to 5000 in the container)
docker run -p 5000:5000 flask-cicd-pipeline:local

# Visit http://localhost:5000
```

### Running the tests

```bash
pytest --tb=short -v
```

Expected output:

```
tests/test_routes.py::TestIndex::test_status_ok        PASSED
tests/test_routes.py::TestIndex::test_returns_json     PASSED
tests/test_routes.py::TestIndex::test_has_message_and_timestamp PASSED
tests/test_routes.py::TestHealth::test_status_ok       PASSED
tests/test_routes.py::TestHealth::test_returns_healthy PASSED
tests/test_routes.py::TestVersion::test_status_ok      PASSED
tests/test_routes.py::TestVersion::test_has_version_key PASSED
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Welcome message + current UTC timestamp |
| GET | `/health` | Health check — returns `{"status": "healthy"}` |
| GET | `/version` | App version — returns `{"version": "1.0.0"}` |

---

## How the Pipeline Works

The pipeline is defined in `.github/workflows/ci.yml` and has three jobs that run in sequence:

### Job 1 — `test`
Runs on every push to any branch.

1. Checks out the code.
2. Installs Python 3.12.
3. Installs `requirements-dev.txt` (Flask + pytest).
4. Runs `pytest`. If any test fails, the pipeline stops here.

### Job 2 — `build`
Runs only if `test` passed (`needs: test`).

1. Sets up Docker Buildx (the modern Docker build engine).
2. Runs `docker build` — validates the Dockerfile without pushing anything.
3. Uses GitHub's cache (`cache-from/cache-to: type=gha`) so subsequent builds reuse unchanged layers.

### Job 3 — `push`
Runs only if `build` passed AND the push is to the `main` branch.

```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

1. Logs in to Docker Hub using credentials stored in GitHub Secrets.
2. Builds and pushes two tags:
   - `:latest` — always points to the most recent `main` build.
   - `:<git-sha>` — pinned to the exact commit (useful for rollbacks).

---

## Configuring GitHub Secrets

The `push` job needs two secrets. Never commit credentials to your repository.

### Step 1 — Create a Docker Hub Access Token

1. Log in at [hub.docker.com](https://hub.docker.com)
2. Click your avatar → **Account Settings** → **Security**
3. Click **New Access Token**
4. Name it `github-actions`, set permissions to **Read, Write, Delete**
5. Copy the token — you won't see it again

### Step 2 — Add secrets to GitHub

1. Go to your GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

| Name | Value |
|------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | The access token from Step 1 |

Once added, GitHub Actions can read them as `${{ secrets.DOCKERHUB_USERNAME }}` without exposing them in logs.

---

## What I Learned

> _Replace this section with your own reflection after building the project._

- **Why containers matter**: Docker packages the app with all its dependencies, so "works on my machine" becomes "works everywhere." The multi-stage build taught me to separate *building* software from *running* it.

- **CI vs CD**: Continuous Integration (running tests automatically) gives fast feedback. Continuous Delivery (pushing the image) closes the loop so every green build on `main` is deployable.

- **Secrets management**: Hard-coding credentials in YAML files is a serious security risk. GitHub Secrets encrypt values and inject them only at runtime, so they never appear in logs or source code.

- **Job dependencies in GitHub Actions**: The `needs:` keyword creates a dependency graph. Failing fast in the `test` job saves compute time — no point building a broken image.

- **Non-root containers**: Running a process as root inside a container is risky. A container escape vulnerability would give an attacker root access on the host. Creating an unprivileged `appuser` follows the principle of least privilege.

---

## License

MIT

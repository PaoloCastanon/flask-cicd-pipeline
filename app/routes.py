from datetime import datetime, timezone
from flask import Blueprint, jsonify

bp = Blueprint("main", __name__)

VERSION = "1.0.0"


@bp.route("/")
def index():
    return jsonify(
        message="Flask CI/CD Pipeline — up and running",
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@bp.route("/health")
def health():
    # Used by Docker HEALTHCHECK and load balancers to verify the container is alive.
    return jsonify(status="healthy")


@bp.route("/version")
def version():
    return jsonify(version=VERSION)

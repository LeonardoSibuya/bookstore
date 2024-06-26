# python-base sets up all our shared environment variables
FROM python:3.8.1-slim as python-base

# python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # poetry
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=1.1.11 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # make poetry create the virtual environment in the project's root
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1 \
    \
    # paths
    # this is where our requirements + virtual environment will live
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# prepend poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        # deps for installing poetry
        curl \
        # deps for building python deps
        build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Install poetry - respects $POETRY_VERSION & $POETRY_HOME
    && curl -sSL https://install.python-poetry.org | python3 - \
    # Install postgres dependencies inside of Docker
    && apt-get update \
    && apt-get -y install libpq-dev gcc \
    && pip3 install --no-cache-dir psycopg2 \
    # Copy project requirement files here to ensure they will be cached.
    && mkdir -p $PYSETUP_PATH \
    && cd $PYSETUP_PATH \
    && poetry config virtualenvs.create false \
    && poetry add --no-cache-dir psycopg2 \
    && cd / \
    && rm -rf $PYSETUP_PATH \
    # Copy the rest of the app
    && mkdir -p /app \
    && cp -r . /app \
    && cd /app \
    && poetry install --no-dev \
    && rm -rf /root/.cache \
    # Expose port
    && EXPOSE 8000 \
    # Command to run the application
    && CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

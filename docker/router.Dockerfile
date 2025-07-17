# Base image for building
ARG ROUTER_BUILD_IMAGE=cgr.dev/chainguard/python:latest-dev

# Runtime image
ARG ROUTER_RUNTIME_IMAGE=cgr.dev/chainguard/python:latest-dev

# Builder stage
FROM $ROUTER_BUILD_IMAGE AS builder

# Set the working directory to /app
WORKDIR /app

USER root

# Install build dependencies
RUN apk add --no-cache gcc python3-dev openssl openssl-dev

RUN pip install --upgrade pip && \
    pip install build

# Copy the current directory contents into the container at /app
COPY . .

# The package name in requirements.txt is router-proxy-extras and router-enterprise
# Create a requirements file without these local packages first
RUN grep -v "router-proxy-extras\|router-enterprise" requirements.txt > requirements-no-local.txt

# Install the pre-built local packages
RUN pip install router-proxy-extras/dist/router_proxy_extras-0.2.10-py3-none-any.whl || \
    pip install router-proxy-extras/dist/litellm_proxy_extras-0.2.10-py3-none-any.whl

# Build and install router-enterprise
RUN cd enterprise && python -m build && pip install dist/*.whl && cd ..

# Build Admin UI
RUN chmod +x docker/build_admin_ui.sh && ./docker/build_admin_ui.sh

# Build the package
RUN rm -rf dist/* && python -m build

# There should be only one wheel file now, assume the build only creates one
RUN ls -1 dist/*.whl | head -1

# Install the package
RUN pip install dist/*.whl

# install dependencies as wheels
RUN pip wheel --no-cache-dir --wheel-dir=/wheels/ -r requirements-no-local.txt

# ensure pyjwt is used, not jwt
RUN pip uninstall jwt -y
RUN pip uninstall PyJWT -y
RUN pip install PyJWT==2.9.0 --no-cache-dir

# Runtime stage
FROM $ROUTER_RUNTIME_IMAGE AS runtime

# Ensure runtime stage runs as root
USER root

# Install runtime dependencies
RUN apk add --no-cache openssl tzdata

WORKDIR /app
# Copy the current directory contents into the container at /app
COPY . .
RUN ls -la /app

# Copy the built wheel from the builder stage to the runtime stage; assumes only one wheel file is present
COPY --from=builder /app/dist/*.whl .
COPY --from=builder /wheels/ /wheels/
COPY --from=builder /app/enterprise/dist/*.whl ./enterprise-wheels/

# Install local packages first
RUN pip install router-proxy-extras/dist/router_proxy_extras-0.2.10-py3-none-any.whl || \
    pip install router-proxy-extras/dist/litellm_proxy_extras-0.2.10-py3-none-any.whl
RUN pip install enterprise-wheels/*.whl && rm -rf enterprise-wheels/

# Install the built wheel using pip; again using a wildcard if it's the only file
RUN pip install *.whl /wheels/* --no-index --find-links=/wheels/ && rm -f *.whl && rm -rf /wheels

# Generate prisma client
RUN prisma generate
RUN chmod +x docker/entrypoint.sh
RUN chmod +x docker/prod_entrypoint.sh

EXPOSE 4000/tcp

ENTRYPOINT ["docker/prod_entrypoint.sh"]

# Append "--detailed_debug" to the end of CMD to view detailed debug logs
CMD ["--port", "4000"]
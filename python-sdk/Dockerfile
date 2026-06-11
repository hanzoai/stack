FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy project files
COPY . .

# Install Python dependencies
RUN uv sync --all-extras || pip install -e .

# Expose port
EXPOSE 8000

# Run the service
CMD ["python", "-m", "hanzo.api"]
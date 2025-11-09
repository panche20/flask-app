# --- Stage 1: Builder (For installing dependencies) ---
FROM python:3.9-slim AS builder

# Set environment variable to prevent Python from writing .pyc files to disc
ENV PYTHONDONTWRITEBYTECODE 1
# Set environment variable to prevent Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED 1

# Install necessary build dependencies
# We use a non-default location for pip cache to ensure we can remove it later
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libc-dev && \
    rm -rf /var/lib/apt/lists/*

# Create a directory for dependencies
WORKDIR /temp_deps
COPY requirements.txt .

# Install dependencies into a separate site-packages folder for portability
# The --target flag tells pip where to install the packages
RUN pip install --no-cache-dir --target=/install -r requirements.txt

# --- Stage 2: Final (Minimal runtime environment) ---
FROM python:3.9-slim

# Copy only the built dependencies from the builder stage
COPY --from=builder /install /usr/local/lib/python3.9/site-packages
# Copy any necessary build-time libraries (like libc-dev dependencies) if needed, 
# though for simple python apps this is often minimal or none.

WORKDIR /app

# Copy application source code (this step should be last to maximize caching)
COPY . .

# Expose the application port
EXPOSE 80

# Command to run the application
CMD ["python", "run.py"]
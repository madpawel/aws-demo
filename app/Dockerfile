# Multi-stage Dockerfile for Python Flask app
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app

# Copy Python dependencies from builder stage to app user's home
COPY --from=builder /root/.local /home/app/.local

# Copy application code
COPY app.py .

# Change ownership to app user
RUN chown -R app:app /app /home/app/.local

# Switch to app user
USER app

# Set PATH for the app user
ENV PATH=/home/app/.local/bin:$PATH

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Run the application
CMD ["python", "app.py"]

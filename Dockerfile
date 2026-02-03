FROM public.ecr.aws/docker/library/python:3.9-slim

WORKDIR /app

# Install system dependencies if needed (e.g. for psycopg2 if using the non-binary version, but binary is fine for simple use)
# RUN apt-get update && apt-get install -y libpq-dev gcc

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Default command - can be overridden to run specific scripts
# Example: docker run my-image python sonar.py
CMD ["python", "sonar.py"]

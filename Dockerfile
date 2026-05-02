FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -r backend/requirements.txt

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

EXPOSE 5001

# Explicit factory so Flask CLI always finds the app (no discovery ambiguity)
CMD ["python", "-m", "flask", "--app", "backend.app:create_app", "run", "--host", "0.0.0.0", "--port", "5001"]

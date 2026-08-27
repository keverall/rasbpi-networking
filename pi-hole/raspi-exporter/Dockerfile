FROM python:3.14-alpine
WORKDIR /app
COPY raspi_exporter.py /app/raspi_exporter.py
RUN pip install --no-cache-dir prometheus_client
EXPOSE 9779
CMD ["python", "/app/raspi_exporter.py", "9779"]

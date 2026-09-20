FROM python:3.13-alpine
WORKDIR /app
RUN pip install --no-cache-dir flask==3.1.2 gunicorn==23.0.0
COPY app.py test_harness.py /app/
RUN addgroup -S otaadmin && adduser -S -G otaadmin otaadmin
USER otaadmin
EXPOSE 8090
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8090/healthz || exit 1
CMD ["gunicorn","--bind=0.0.0.0:8090","--workers=1","--threads=4","--access-logfile=-","app:app"]

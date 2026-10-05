FROM python:3.13-alpine
RUN pip install --no-cache-dir zeroconf==0.148.0
COPY gateway.py /app/gateway.py
USER 1040:65539
CMD ["python", "/app/gateway.py"]

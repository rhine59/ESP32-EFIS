FROM python:3.12-alpine
WORKDIR /app
COPY server.py ./server.py
COPY fixtures/ ./fixtures/
USER 65534:65534
EXPOSE 8193
CMD ["python", "-u", "server.py"]

FROM python:3.12-alpine
WORKDIR /app
RUN pip install --no-cache-dir cryptography==46.0.3 cbor2==5.7.1
COPY app.py /app/app.py
COPY static /app/static
EXPOSE 8080
CMD ["python","/app/app.py"]

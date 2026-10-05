FROM python:3.13-alpine
ARG REDONE_UID=1040
ARG REDONE_GID=65539
RUN pip install --no-cache-dir zeroconf==0.148.0 \
 && addgroup -g "$REDONE_GID" redone \
 && adduser -D -H -u "$REDONE_UID" -G redone redone
COPY gateway.py /app/gateway.py
USER redone
CMD ["python", "/app/gateway.py"]

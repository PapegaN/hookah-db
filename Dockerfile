FROM postgres:17-alpine

WORKDIR /opt/hookah-db

COPY docker/initdb/01-apply-sql.sh /docker-entrypoint-initdb.d/01-apply-sql.sh
COPY migrations ./migrations
COPY seeds ./seeds

RUN chmod +x /docker-entrypoint-initdb.d/01-apply-sql.sh

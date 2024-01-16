FROM node:19.3.0
COPY . /src
# COPY duckdb-utils /src/duckdb-utils
WORKDIR /src/duckdb-utils/dist
RUN npm i
RUN npm link
WORKDIR /src
RUN npm i
# RUN npm run build

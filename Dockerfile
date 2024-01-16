FROM node:19.3.0
COPY . /src

# ✅ Build succeeds with local duckdb-utils install
RUN cd /src/duckdb-utils/dist && npm i
WORKDIR /src
RUN npm i
# This fails in Github Actions, but not in this Docker build, or on the underlying host, on my M1 macbook or an Amazon Linux EC2 instance
RUN npm run build

# ❌ Build fails with `npm link`ed duckdb-utils
RUN cd /src/duckdb-utils/dist && npm link
RUN npm link duckdb-utils
RUN npm run build  # ❌ `worker terminated with 1 pending requests` inside AsyncDuckDB constructor

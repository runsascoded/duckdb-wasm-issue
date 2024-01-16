# Next.js / duckdb-wasm / `npm link` issue

Repro:
```bash
git clone --recurse-submodules https://github.com/runsascoded/duckdb-wasm-npm-link
cd duckdb-wasm-npm-link
docker build -t duckdb-wasm-npm-link .  # ❌ fails
```

Per [Dockerfile](Dockerfile):
```Dockerfile
FROM node:19.3.0
COPY . /src

# ✅ Build succeeds with local duckdb-utils install
RUN cd /src/duckdb-utils/dist && npm i
WORKDIR /src
RUN npm i
RUN npm run build

# ❌ Build fails with `npm link`ed duckdb-utils
RUN cd /src/duckdb-utils/dist && npm link
RUN npm link duckdb-utils
RUN npm run build  # ❌ `worker terminated with 1 pending requests` inside AsyncDuckDB constructor
```

[duckdb-utils/src/duckdb.ts](duckdb-utils/src/duckdb.ts) instantiates an `AsyncDuckDB`:
```typescript

```

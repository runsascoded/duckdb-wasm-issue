# Next.js / duckdb-wasm / `npm link` issue

[duckdb-utils/src/duckdb.ts](duckdb-utils/src/duckdb.ts) calls [`AsyncDuckDB.instantiate`]:
```typescript
const { worker, bundle } = await nodeWorkerBundle()
const logger = { log: () => {}, }
const db = new AsyncDuckDB(logger, worker)
await db.instantiate(bundle.mainModule, bundle.pthreadWorker)  // ❌ worker terminated with 1 pending requests
```

In some situations, [`AsyncDuckDB.instantiate`] emits this error and hangs `next build`:
```
worker terminated with 1 pending requests
```
## Github Action repro
[Here's an example of the error in a Github Action][GHA error].

## Dockerfile repro

Clone this repo, and build the [Dockerfile](Dockerfile):
```bash
git clone --recurse-submodules https://github.com/runsascoded/duckdb-wasm-npm-link
cd duckdb-wasm-npm-link
docker build -t duckdb-wasm-npm-link .  # ❌ fails
```

For some reason, the error only happens in the [Dockerfile](Dockerfile) when the [duckdb-utils](duckdb-utils) module is `npm link`ed:
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

This holds true both in Docker, and on the host, on my M1 macbook as well as on an Amazon Linux instance I tested on.

[`AsyncDuckDB.instantiate`]: https://github.com/duckdb/duckdb-wasm/blob/v1.28.0/packages/duckdb-wasm/src/parallel/async_bindings.ts#L329-L341
[GHA error]: https://github.com/runsascoded/duckdb-wasm-npm-link/actions/runs/7548011239/job/20549200841#step:6:58

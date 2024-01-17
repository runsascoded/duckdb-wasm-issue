# duckdb-wasm  `AsyncDuckDB.instantiate` error/hang

In some situations, [`AsyncDuckDB.instantiate`] emits this error and hangs `next build`:
```
worker terminated with 1 pending requests
```

I've filed this as [duckdb-wam#1588].

## Repro

[duckdb-utils/src/duckdb.ts](duckdb-utils/src/duckdb.ts) calls [`AsyncDuckDB.instantiate`]:
```typescript
const { worker, bundle } = await nodeWorkerBundle()
console.log("bundle:", bundle)
const logger = { log: () => {}, }
const db = new AsyncDuckDB(logger, worker)
console.log("instantiating db")
await db.instantiate(bundle.mainModule, bundle.pthreadWorker)  // ❌ "worker terminated with 1 pending requests"
console.log("instantiated db")
worker terminated with 1 pending requests
```

### Github Actions repro
[Here's an example of the error in a Github Action][GHA error]:

```
bundle: {
  mainModule: '/home/runner/work/duckdb-wasm-npm-link/duckdb-wasm-npm-link/node_modules/@duckdb/duckdb-wasm/dist/duckdb-eh.wasm',
  mainWorker: '/home/runner/work/duckdb-wasm-npm-link/duckdb-wasm-npm-link/node_modules/@duckdb/duckdb-wasm/dist/duckdb-node-eh.worker.cjs',
  pthreadWorker: null
}
instantiating db
worker terminated with 1 pending requests
 ⚠ Restarted static page generation for / because it took more than 60 seconds
```

### Dockerfile repro
For some reason, the error only happens in the [Dockerfile](Dockerfile) when the [duckdb-utils](duckdb-utils) module is `npm link`ed:
```Dockerfile
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
```

#### Clone + `docker build`
Clone this repo, and build the [Dockerfile](Dockerfile):
```bash
git clone --recurse-submodules https://github.com/runsascoded/duckdb-wasm-issue
cd duckdb-wasm-issue
docker build -t duckdb-wasm-issue .  # ❌ fails
# 7.865 bundle: {
# 7.865   mainModule: '/src/node_modules/@duckdb/duckdb-wasm/dist/duckdb-eh.wasm',
# 7.865   mainWorker: '/src/node_modules/@duckdb/duckdb-wasm/dist/duckdb-node-eh.worker.cjs',
# 7.865   pthreadWorker: null
# 7.865 }
# 7.865 instantiating db
# 7.868 worker terminated with 1 pending requests
# 68.12  ⚠ Restarted static page generation for / because it took more than 60 seconds
# … etc.
```

I observe the same `docker build` failure on my M1 macbook and an Amazon Linux instance I tested.

#### Host repro
I also see the same failure when running directly on each underlying host (macbook / AZLinux), without Docker:
- `npm run build` succeeds when `duckdb-utils` is `npm install`ed directly.
- `npm run build` fails when `duckdb-utils` is `npm link`ed.

I don't know why Github Actions' `ubuntu-latest` demonstrates the problem more easily (without the `npm link` step).

### Earlier repro: [next.js#57819]
I previously filed a repro at [next.js#57819].

All the repros I've found involve Next.js, but the fact that the failure occurs within duckdb-wasm, and manifests as a hang instead of a normal `Error` / exception, makes me feel like it may be primarily a duckdb-wasm problem. I have only tried to use duckdb-wasm within Next.js, so I'm not sure it's specific to Next.


[`AsyncDuckDB.instantiate`]: https://github.com/duckdb/duckdb-wasm/blob/v1.28.0/packages/duckdb-wasm/src/parallel/async_bindings.ts#L329-L341
[GHA error]: https://github.com/runsascoded/duckdb-wasm-issue/actions/runs/7548011239/job/20549200841#step:6:58
[next.js#57819]: https://github.com/vercel/next.js/discussions/57819
[duckdb-wam#1588]: https://github.com/duckdb/duckdb-wasm/issues/1588

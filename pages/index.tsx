import React from 'react'
import type { GetStaticProps } from "next";
import { initDuckDb } from "duckdb-utils/duckdb";

export const getStaticProps: GetStaticProps = async () => {
  const db = await initDuckDb()
  return { props: {}, }
}

export default function Page() {
  return <div>yay</div>
}

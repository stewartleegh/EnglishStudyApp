import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

/**
 * 集成测试配置（T-0102 CI 骨架，测试方案 §6）。
 * - `pnpm test:integration`，CI 中 services 起本地 Postgres（自托管 Supabase 的
 *   db 容器等价物；rest/storage/kong 视后续任务需要再挂）；
 * - 外部 LLM/Whisper 一律 MSW mock（project_rules §7.2），禁止真调；
 * - 命名约定：`*.integration.test.ts(x)` 与单测 `*.test.ts(x)` 区分。
 */
export default defineConfig({
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./", import.meta.url)),
    },
  },
  test: {
    name: "integration",
    environment: "node",
    include: ["**/*.integration.test.ts", "**/*.integration.test.tsx"],
    exclude: ["node_modules/**", ".next/**", "out/**"],
    testTimeout: 30_000,
    hookTimeout: 30_000,
  },
});
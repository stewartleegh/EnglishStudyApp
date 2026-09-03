import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

/**
 * 单测配置（T-0102 CI 骨架，测试方案 §6 + project_rules §7）。
 * - `pnpm test:unit`，无网络、无数据库；
 * - 覆盖率门槛（project_rules §7.3 / 测试方案 §6）：
 *   lib/ai ≥90%、app/api ≥80%、整体 ≥70%，CI 卡线；
 * - 仅统计被测试导入的文件（Vitest 4 默认行为，骨架期无测试时流水线保持全绿，
 *   真实任务（T-0113 等）落地测试后门槛自动生效）。
 */
export default defineConfig({
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./", import.meta.url)),
    },
  },
  test: {
    name: "unit",
    environment: "node",
    include: ["**/*.test.ts", "**/*.test.tsx"],
    exclude: [
      "**/*.integration.test.ts",
      "**/*.integration.test.tsx",
      "tests/e2e/**",
      "node_modules/**",
      ".next/**",
      "out/**",
    ],
    coverage: {
      provider: "v8",
      // 不设 include：Vitest 4 仅统计被测试导入的文件（未导入文件不计入，
      // 否则骨架期 app/page.tsx 等 0% 会直接卡红）。真实任务落地测试后门槛自动生效。
      thresholds: {
        lines: 70,
        statements: 70,
        functions: 70,
        branches: 70,
        "lib/ai/**": { lines: 90, statements: 90, functions: 90, branches: 90 },
        "app/api/**": {
          lines: 80,
          statements: 80,
          functions: 80,
          branches: 80,
        },
      },
    },
  },
});
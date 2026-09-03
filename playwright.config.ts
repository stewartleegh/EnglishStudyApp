import { defineConfig, devices } from "@playwright/test";

/**
 * E2E 配置（T-0102 CI 骨架，测试方案 §6）。
 * - chromium 项目随 PR 全量跑；webkit 项目仅在 ci-nightly 跑（省 CI 时长）；
 * - 浏览器内核映射测试方案 §4：E1 系 chromium Mobile (Pixel)，E2 系 webkit (iPhone 14)；
 * - webServer 复用 `pnpm start`（需先 `pnpm build`，CI 中显式执行）。
 */
const baseURL = process.env.E2E_BASE_URL ?? "http://localhost:3000";

export default defineConfig({
  testDir: "./tests/e2e",
  timeout: 60_000,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI
    ? [["line"], ["html", { open: "never" }]]
    : "list",
  use: {
    baseURL,
    trace: "on-first-retry",
  },
  projects: [
    { name: "chromium", use: { ...devices["Pixel 7"] } },
    { name: "webkit", use: { ...devices["iPhone 14"] } },
  ],
  webServer: {
    command: "pnpm start",
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
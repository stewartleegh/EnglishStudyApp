/**
 * E2E 冒烟（T-0102 CI 骨架）：空壳首页可访问。
 * 后续里程碑用例按测试方案 §4（E1～E9）逐条落地。
 */
import { expect, test } from "@playwright/test";

test("首页加载并展示占位内容", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveTitle(/用英语学音乐/);
  await expect(
    page.getByRole("heading", { name: "用英语学音乐" }),
  ).toBeVisible();
  await expect(page.getByText("课程地图 · 开发中")).toBeVisible();
});
/**
 * 单测冒烟（T-0102 CI 骨架）：验证测试链路与覆盖率采集可用。
 * 后续任务按测试方案 §7 在各模块旁补充真实单测。
 */
import { describe, expect, it } from "vitest";

import { cn } from "@/lib/utils";

describe("单测冒烟：lib/utils cn", () => {
  it("合并 class 并去重 Tailwind 冲突", () => {
    expect(cn("a", "px-2", "px-4")).toContain("px-4");
    expect(cn("a", "px-2", "px-4")).not.toContain("px-2");
  });
});
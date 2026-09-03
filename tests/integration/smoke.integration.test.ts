/**
 * 集成测试冒烟（T-0102 CI 骨架）：验证 integration 运行环境可用。
 * 后续任务在 app/api 等真实集成测试中替换（MSW mock 外部，project_rules §7.2）。
 */
import { describe, expect, it } from "vitest";

describe("集成冒烟：运行环境", () => {
  it("Node 22+ fetch 可用（后续 API 测试基础）", () => {
    expect(typeof fetch).toBe("function");
  });
});
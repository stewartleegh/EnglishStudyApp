/**
 * 空壳首页（T-0101：脚手架里程碑占位页）。
 * 后续里程碑：T-0106 知情同意页 → 简化 onboarding → T-0115 课程地图。
 */
export default function Home() {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center gap-5 bg-background px-6 text-center">
      <h1 className="text-2xl font-bold tracking-tight text-foreground">
        用英语学音乐
      </h1>
      <p className="max-w-xs text-sm leading-relaxed text-muted-foreground">
        面向初中生的英语音乐素养闯关课程（内部试用版）
      </p>
      <span className="mt-1 inline-flex h-9 items-center rounded-md bg-card px-4 text-sm text-foreground">
        课程地图 · 开发中
      </span>
    </main>
  );
}
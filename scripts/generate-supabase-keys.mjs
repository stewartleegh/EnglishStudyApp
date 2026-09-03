/**
 * 生成 Supabase 自托管本地开发密钥：JWT_SECRET / ANON_KEY / SERVICE_ROLE_KEY。
 * 用法：node scripts/generate-supabase-keys.mjs
 * 产物为 HS256 签名的 JWT（payload.role = anon / service_role），供
 * 本机 docker-compose.yml 与 supabase/kong.yml 使用（T-0101 / T-0118）。
 * 注意：本地开发默认值，生产部署必须更换（.env.example 注释同口径）。
 */
import { randomBytes, createHmac } from "node:crypto";

function base64url(value) {
  return Buffer.from(value).toString("base64url");
}

const secret = randomBytes(32).toString("base64"); // 32 字节 → 44 字符
const iat = Math.floor(Date.now() / 1000);
const exp = iat + 60 * 60 * 24 * 365 * 10; // 10 年有效期，本地开发足够

function sign(role) {
  const header = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payload = base64url(
    JSON.stringify({ role, iss: "supabase", iat, exp })
  );
  const signature = createHmac("sha256", secret)
    .update(`${header}.${payload}`)
    .digest("base64url");
  return `${header}.${payload}.${signature}`;
}

console.log("JWT_SECRET=" + secret);
console.log("ANON_KEY=" + sign("anon"));
console.log("SERVICE_ROLE_KEY=" + sign("service_role"));
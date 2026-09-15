"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const LINKS = [
  { href: "/admin/codes", label: "Mã kích hoạt" },
  { href: "/admin/packages", label: "Gói" },
  { href: "/admin/keys", label: "API keys" },
  { href: "/admin/payment", label: "Thanh toán" },
] as const;

export function AdminFrame({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const isLogin = pathname === "/admin/login";

  async function logout() {
    await fetch("/api/admin/session", { method: "DELETE" });
    router.replace("/admin/login");
    router.refresh();
  }

  return (
    <>
      <div className="atmosphere" aria-hidden="true">
        <div className="orb orb-violet" />
        <div className="orb orb-cyan" />
        <div className="orb orb-indigo" />
      </div>
      {isLogin ? (
        children
      ) : (
        <>
          <header className="admin-nav glass">
            <Link className="brand" href="/admin/codes">
              <img
                className="brand-mark"
                src="/app-icon.png"
                alt=""
                width={30}
                height={30}
              />
              Studee
            </Link>
            <nav className="admin-nav-links" aria-label="Admin">
              {LINKS.map((link) => {
                const on =
                  pathname === link.href || pathname.startsWith(`${link.href}/`);
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={on ? "on" : undefined}
                    aria-current={on ? "page" : undefined}
                  >
                    {link.label}
                  </Link>
                );
              })}
            </nav>
            <button className="btn btn-ghost" type="button" onClick={logout}>
              Đăng xuất
            </button>
          </header>
          {children}
        </>
      )}
    </>
  );
}

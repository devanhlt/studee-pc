import { AdminFrame } from "./frame";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AdminFrame>{children}</AdminFrame>;
}

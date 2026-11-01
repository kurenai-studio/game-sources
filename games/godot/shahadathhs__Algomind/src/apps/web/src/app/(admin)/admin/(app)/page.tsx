import { ApiStatus } from "@/components/admin/api-status";
import { HomeOverview } from "@/components/admin/home-overview";
import { PageHeading } from "@/components/admin/ui";

export default function HomePage() {
  return (
    <>
      <PageHeading caption="Admin" title="Home" />
      <HomeOverview />
      <ApiStatus />
    </>
  );
}

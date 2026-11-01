import type { Metadata } from "next";
import Link from "next/link";
import { connection } from "next/server";
import { ContactSection } from "@/components/public/contact-section";
import { ProsePage } from "@/components/public/prose-page";
import { ProseSection } from "@/components/public/prose-section";
import { getContact } from "@/lib/contact";
import { pageMetadata } from "@/lib/seo";

const DESCRIPTION =
  "How to reach the developer of Algomind with a bug report, a question, or a deletion request.";

export const metadata: Metadata = pageMetadata({
  title: "Contact",
  shareTitle: "Contact Algomind",
  description: DESCRIPTION,
  path: "/contact",
});

// Rendered per request, like the landing page: a build made while the API is down or asleep must not
// bake in the "could not be loaded" notice and serve it until the next refresh. The fetch inside
// still caches for a minute.
export default async function ContactPage() {
  await connection();
  const contact = await getContact();
  const hasAddress = contact.status === "available" && contact.details.email !== "";
  return (
    <ProsePage title="Contact" lead="Write to report a bug or to ask a question." wide>
      <ContactSection contact={contact} />

      <ProseSection title="What to include">
        <ul>
          <li>The Algomind version, shown on the download page and in the app&apos;s settings.</li>
          <li>Your Android version and phone model.</li>
          <li>What you did, what you expected, and what happened instead.</li>
          <li>The level number, if the problem is in one level.</li>
        </ul>
      </ProseSection>

      <ProseSection title="Privacy and deletion">
        <p>
          {hasAddress
            ? "To ask for your data to be deleted, write to the address above from the email address of the account."
            : "To ask for your data to be deleted, use the contact details on this page once an address is published."}{" "}
          What is and is not collected is on the <Link href="/privacy">privacy page</Link>.
        </p>
      </ProseSection>
    </ProsePage>
  );
}

import { jsonLdString } from "@/lib/seo";

/** Structured data as inline JSON. It is data, not a script that runs, and loads nothing. */
export function JsonLd({ data }: { data: unknown }) {
  return (
    <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: jsonLdString(data) }} />
  );
}

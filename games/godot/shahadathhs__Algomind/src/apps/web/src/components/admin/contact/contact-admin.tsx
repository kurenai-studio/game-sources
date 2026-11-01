"use client";

import Link from "next/link";
import { useCallback, useState } from "react";
import { ApiError } from "@/lib/api/errors";
import { issueProblems, type ContactProblems } from "@/lib/admin/contact-form";
import type { ContactInput } from "@/lib/admin/social-api";
import { when } from "@/lib/admin/format";
import { useAdminResource } from "../use-admin-resource";
import { useSocialApi } from "../use-social-api";
import { ResourceMessages } from "../resource-messages";
import { OutlineAction, PageHeading } from "../ui";
import { ContactForm } from "./contact-form";

/** The public contact details: edited here, shown on the site's contact page. */
export function ContactAdmin() {
  const api = useSocialApi();
  const load = useCallback(() => api.getContact(), [api]);
  const { data, error, notice, busy, run, reload } = useAdminResource(load);
  const [serverProblems, setServerProblems] = useState<ContactProblems>({});

  async function save(input: ContactInput) {
    setServerProblems({});
    return run(async () => {
      try {
        return await api.saveContact(input);
      } catch (err) {
        if (err instanceof ApiError) setServerProblems(issueProblems(err.issues));
        throw err;
      }
    }, "Contact details saved.");
  }

  return (
    <div>
      <PageHeading caption="Admin" title="Contact" />
      <p className="mb-8 max-w-[640px] text-base font-semibold text-mute">
        These details are public. They appear on the{" "}
        <Link href="/contact" className="text-ink underline underline-offset-4">
          contact page
        </Link>{" "}
        of the website, which can take up to a minute to show a change. A field left empty is not
        shown.
      </p>
      <ResourceMessages notice={notice} error={error} loading={!data} what="contact details" />
      {!data && error && (
        <OutlineAction type="button" onClick={() => void reload()}>
          Try again
        </OutlineAction>
      )}
      {data && (
        <>
          <ContactForm
            key={data.updatedAt}
            saved={data}
            busy={busy}
            serverProblems={serverProblems}
            onSave={save}
          />
          <p className="mt-8 text-sm font-semibold text-mute">
            Last changed {when(data.updatedAt)}
            {data.updatedByEmail ? ` by ${data.updatedByEmail}` : ""}.
          </p>
        </>
      )}
    </div>
  );
}

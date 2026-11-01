import { ProseSection } from "@/components/public/prose-section";
import { ISSUES_URL, type ContactState } from "@/lib/contact";

function Line({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <li className="list-none! flex flex-col sm:flex-row sm:gap-4">
      <span className="w-24 flex-none text-xs tracking-[2px] uppercase">{label}</span>
      <span className="min-w-0 break-words text-ink">{children}</span>
    </li>
  );
}

/** The Contact section: the published details, or a plain notice when there are none to show. */
export function ContactSection({ contact }: { contact: ContactState }) {
  if (contact.status === "unavailable") {
    return (
      <ProseSection title="Contact">
        <p>
          The contact details could not be loaded just now. Report a problem on the{" "}
          <a href={ISSUES_URL} rel="noopener noreferrer">
            GitHub issues page
          </a>{" "}
          or try this page again later.
        </p>
      </ProseSection>
    );
  }
  const d = contact.details;
  if (d.email === "") {
    return (
      <ProseSection title="Contact">
        <p>No contact address has been published yet, so there is nothing to write to for now.</p>
        <p>
          Problems can be reported on the{" "}
          <a href={ISSUES_URL} rel="noopener noreferrer">
            GitHub issues page
          </a>
          .
        </p>
      </ProseSection>
    );
  }
  return (
    <ProseSection title="Contact">
      <ul className="list-none! pl-0! gap-2 flex flex-col">
        {d.displayName && <Line label="Name">{d.displayName}</Line>}
        <Line label="Email">
          <a href={`mailto:${d.email}`}>{d.email}</a>
        </Line>
        {d.github && (
          <Line label="GitHub">
            <a href={d.github} rel="noopener noreferrer">
              {d.github}
            </a>
          </Line>
        )}
        {d.website && (
          <Line label="Website">
            <a href={d.website} rel="noopener noreferrer">
              {d.website}
            </a>
          </Line>
        )}
        <Line label="Issues">
          <a href={d.issues || ISSUES_URL} rel="noopener noreferrer">
            {d.issues || ISSUES_URL}
          </a>
        </Line>
      </ul>
      {d.note && <p>{d.note}</p>}
    </ProseSection>
  );
}

import { Notice } from "./ui";

/** The result notice and the error of an admin screen, and a loading line until data arrives. */
export function ResourceMessages({
  notice,
  error,
  loading,
  what,
}: {
  notice: string | null;
  error: string | null;
  loading: boolean;
  what: string;
}) {
  return (
    <>
      {notice && (
        <div className="mb-4">
          <Notice kind="info">{notice}</Notice>
        </div>
      )}
      {error && (
        <div className="mb-4">
          <Notice>{error}</Notice>
        </div>
      )}
      {loading && !error && (
        <p role="status" className="py-6 text-sm tracking-[2px] uppercase">
          Loading {what}
        </p>
      )}
    </>
  );
}

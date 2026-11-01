import { SignInForm } from "@/components/admin/sign-in-form";
import { Wordmark } from "@/components/ui/wordmark";
import { safeNext } from "@/lib/admin/config";
import { END_NOTES, SIGN_IN_ERRORS } from "@/lib/admin/messages";

type SearchParams = Promise<Record<string, string | string[] | undefined>>;

function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export default async function SignInPage({ searchParams }: { searchParams: SearchParams }) {
  const params = await searchParams;
  const error = first(params.error);
  const reason = first(params.reason);
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-[420px] flex-col justify-center px-5 py-10">
      <div className="mb-10">
        <Wordmark />
      </div>
      <h1 className="mb-8 text-[34px] leading-tight tracking-[1px] uppercase">Sign in</h1>
      <SignInForm
        next={safeNext(first(params.next))}
        initialError={error ? (SIGN_IN_ERRORS[error] ?? SIGN_IN_ERRORS.unavailable) : undefined}
        note={reason ? END_NOTES[reason] : undefined}
      />
    </main>
  );
}

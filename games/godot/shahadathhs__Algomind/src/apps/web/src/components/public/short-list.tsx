import { Caption } from "@/components/ui/caption";
import { Section } from "@/components/ui/section";

const ITEMS = [
  { title: "Offline first", text: "Levels you have downloaded work without a connection." },
  { title: "No ads", text: "Nothing interrupts a run." },
  { title: "No purchases", text: "Nothing is for sale." },
  { title: "No account needed", text: "Progress saves on your device." },
  { title: "Sync if you want", text: "Sign in to keep progress across devices." },
  { title: "Light and dark", text: "Follows your system setting." },
];

export function ShortList() {
  return (
    <Section reveal>
      <Caption as="h2">The short list</Caption>
      <ul className="mt-8 grid gap-x-8 md:grid-cols-3">
        {ITEMS.map((item) => (
          <li key={item.title} className="view-rise border-t-2 border-ink py-4 pb-6">
            <h3 className="text-lg tracking-[1px] uppercase">{item.title}</h3>
            <p className="mt-1 text-[13px] leading-normal font-semibold tracking-[0.3px] text-mute">
              {item.text}
            </p>
          </li>
        ))}
      </ul>
    </Section>
  );
}

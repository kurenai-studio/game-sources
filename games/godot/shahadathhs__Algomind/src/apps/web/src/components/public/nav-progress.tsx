"use client";

import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";

type Phase = "idle" | "loading" | "done";

/**
 * A bar across the top of the screen while the next page of the site is on its way. A click on a link
 * to another page starts it at once. The address changes as soon as the loading screen of the next
 * page shows, so the bar goes on until that screen (or any other placeholder marked `data-loading`)
 * has been replaced by the content. It moves only while a page is loading, never while idle, and with
 * reduced motion it simply appears and disappears.
 */
export function NavProgress() {
  const pathname = usePathname();
  const [phase, setPhase] = useState<Phase>("idle");
  const pathRef = useRef(pathname);

  useEffect(() => {
    function onClick(event: MouseEvent) {
      if (event.defaultPrevented || event.button !== 0) return;
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      const link = (event.target as Element | null)?.closest("a");
      if (!link || (link.target && link.target !== "_self") || link.hasAttribute("download"))
        return;
      const url = new URL(link.href, window.location.href);
      if (url.origin !== window.location.origin) return;
      if (url.pathname === window.location.pathname) return;
      setPhase("loading");
    }
    document.addEventListener("click", onClick, true);
    return () => document.removeEventListener("click", onClick, true);
  }, []);

  useEffect(() => {
    if (pathRef.current === pathname) return;
    pathRef.current = pathname;
    let timer = 0;
    const finish = () => {
      setPhase("done");
      timer = window.setTimeout(() => setPhase("idle"), 400);
    };
    const waiting = () => document.querySelector("[data-loading]") !== null;
    const observer = new MutationObserver(() => {
      if (!waiting()) {
        observer.disconnect();
        finish();
      }
    });
    const start = window.setTimeout(() => {
      if (waiting()) observer.observe(document.body, { childList: true, subtree: true });
      else finish();
    }, 60);
    return () => {
      window.clearTimeout(start);
      window.clearTimeout(timer);
      observer.disconnect();
    };
  }, [pathname]);

  return (
    <>
      <div aria-hidden="true" className="nav-progress" data-phase={phase} />
      <p role="status" className="sr-only">
        {phase === "loading" ? "Loading page" : ""}
      </p>
    </>
  );
}

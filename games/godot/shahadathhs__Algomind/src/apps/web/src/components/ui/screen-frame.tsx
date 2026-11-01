import type { ReactNode } from "react";
import { Key } from "@/components/ui/key";

/**
 * A chamfered frame around a drawn game screen: an ink rim with the top-right corner cut, lifted
 * off the page by its lip and shadow. `sm` is for the row of small screens.
 */
export function ScreenFrame({
  children,
  size = "lg",
  className = "",
}: {
  children: ReactNode;
  size?: "lg" | "sm";
  className?: string;
}) {
  const large = size === "lg";
  return (
    <Key tone="ink" lip={large ? 6 : 4} className={`flex ${className}`}>
      <div
        className={`tile bg-ink ${large ? "p-[3px]" : "p-[2px]"}`}
        style={{ ["--chamfer" as string]: large ? "20px" : "12px" }}
      >
        <div
          className="tile bg-ground"
          style={{ ["--chamfer" as string]: large ? "18.3px" : "10.8px" }}
        >
          {children}
        </div>
      </div>
    </Key>
  );
}

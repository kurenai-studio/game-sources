"use client";

import { motion, useReducedMotion } from "motion/react";
import type { ReactNode } from "react";

const SHOWN = { opacity: 1, y: 0 };

/**
 * Slides its content up 40 px and fades it in the first time it scrolls into view (200 ms, once, never
 * again). With reduced motion it is shown at once, without moving. The server draws it hidden, so the
 * first client render must match; without JavaScript the server markup carries the `.reveal` class,
 * which the root layout's <noscript> style turns back into plain visible content.
 */
export function Reveal({ children, className = "" }: { children: ReactNode; className?: string }) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      className={`reveal ${className}`}
      initial={{ opacity: 0, y: 40 }}
      animate={reduce ? SHOWN : undefined}
      whileInView={SHOWN}
      viewport={{ once: true, margin: "0px 0px -80px 0px" }}
      transition={{ duration: reduce ? 0 : 0.2, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}

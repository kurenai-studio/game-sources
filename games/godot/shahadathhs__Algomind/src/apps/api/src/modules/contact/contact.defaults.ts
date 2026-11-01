import type { AppConfig } from "../../core/config/app-config.js";
import type { ContactInput } from "./contact.schemas.js";

/**
 * What the contact page starts with: the CONTACT_* settings of the environment, and nothing else. No
 * personal detail lives in the source. Without settings the page has no address to show until an
 * admin fills the Contact page in the dashboard.
 */
export function contactSeed(config: AppConfig): ContactInput {
  const c = config.contact;
  return {
    displayName: c.name || "The Algomind developer",
    email: c.email ?? "",
    github: c.github ?? "",
    website: c.website ?? "",
    issues: c.issues ?? "",
    note: "",
  };
}

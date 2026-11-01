"use client";

import { useMemo } from "react";
import { createApiClient } from "@/lib/api/client";
import { socialApi } from "@/lib/admin/social-api";
import { useSessionManager } from "./session-provider";

/** The typed social admin API (daily, badges, reports, statistics), bound to the session. */
export function useSocialApi() {
  const manager = useSessionManager();
  return useMemo(() => socialApi(createApiClient(manager.request)), [manager]);
}

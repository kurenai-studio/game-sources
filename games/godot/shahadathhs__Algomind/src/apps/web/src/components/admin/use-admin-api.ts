"use client";

import { useMemo } from "react";
import { createApiClient } from "@/lib/api/client";
import { adminApi } from "@/lib/admin/admin-api";
import { useSessionManager } from "./session-provider";

/** The typed admin API, bound to the signed-in session (bearer, one refresh and retry). */
export function useAdminApi() {
  const manager = useSessionManager();
  return useMemo(() => adminApi(createApiClient(manager.request)), [manager]);
}

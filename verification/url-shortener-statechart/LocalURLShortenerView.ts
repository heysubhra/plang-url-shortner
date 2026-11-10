const text = (value: unknown): string => String(value ?? "");

export const title = "Local URL shortener lifecycle";

export const colors = {
  startup: "blue",
  serving: "teal",
  mutation: "orange",
  redirect: "purple",
  failure: "pink",
};

export const state = (v: any) => {
  const response = text(v.last_response?.kind);
  const runtime = text(v.runtime);
  const active = Array.isArray(v.active) ? v.active.length : 0;
  const retired = Array.isArray(v.retired_ids) ? v.retired_ids.length : 0;

  if (response === "redirect") return `Serving · redirecting (${active} active link${active === 1 ? "" : "s"})`;
  if (response === "not_found") return `Serving · not found (${retired} retired code${retired === 1 ? "" : "s"})`;
  if (response === "created") return `Serving · link created (${active} active link${active === 1 ? "" : "s"})`;
  if (response === "removed") return `Serving · link removed (${retired} retired code${retired === 1 ? "" : "s"})`;
  if (response === "rejected") return "Serving · request rejected";
  if (runtime === "Starting") return "Starting";
  if (runtime === "StartupFailed") return "Startup failed";
  return `Serving (${active} active link${active === 1 ? "" : "s"})`;
};

export const group = (v: any) => {
  const response = text(v.last_response?.kind);
  if (response === "redirect") return "redirect";
  if (response === "created" || response === "removed") return "mutation";
  if (response === "rejected" || response === "not_found") return "failure";
  if (text(v.runtime) === "Serving") return "serving";
  return "startup";
};

const labels: Record<string, string> = {
  StartServing: "configuration and database are ready",
  FailStartup: "required startup configuration fails",
  RetryStartup: "restart after configuration is fixed",
  Restart: "the application restarts",
  SignIn: "a user signs in",
  SignOut: "the user signs out",
  ListAccepted: "the owner requests their links",
  ListRejected: "a signed-out visitor requests protected links",
  CreateAccepted: "the owner creates a valid link",
  CreateRejected: "the link request is rejected",
  RemoveAccepted: "the owner removes their link",
  RemoveRejected: "the removal is rejected",
  ResolveActive: "a visitor follows an active code",
  ResolveMissing: "a visitor follows an unknown or retired code",
};

export const step = (action: string) => labels[action] ?? null;

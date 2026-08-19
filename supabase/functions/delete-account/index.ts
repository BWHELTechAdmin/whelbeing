import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: Record<string, string>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
function secretKey() {
  const legacyKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacyKey != null) return legacyKey;
  try {
    const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}") as
      Record<string, string>;
    return keys.default ?? null;
  } catch (_) {
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  const authorization = req.headers.get("Authorization");
  if (authorization == null) {
    return json({ error: "Unauthorized." }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = secretKey();
  if (supabaseUrl == null || serviceRoleKey == null) {
    console.error("Missing Supabase environment configuration.");
    return json({ error: "Account deletion is unavailable." }, 500);
  }
  const adminClient = createClient(supabaseUrl, serviceRoleKey);
  const accessToken = authorization.replace(/^Bearer\s+/i, "");
  const {
    data: { user },
    error: userError,
  } = await adminClient.auth.getUser(accessToken);
  if (userError != null || user == null) {
    return json({ error: "Unauthorized." }, 401);
  }
  try {
    // Storage objects are not database-cascaded and must be removed before
    // deleting their owner. Current uploads are one level under `{userId}/`.
    const { data: avatarObjects, error: listError } = await adminClient.storage
      .from("avatars")
      .list(user.id);
    if (listError != null) throw listError;
    if (avatarObjects.length > 0) {
      const { error: avatarError } = await adminClient.storage
        .from("avatars")
        .remove(avatarObjects.map((object) => `${user.id}/${object.name}`));
      if (avatarError != null) throw avatarError;
    }

    // Deleting auth.users cascades to public.users and its dependent records.
    // The requested ID is always the JWT-authenticated caller's ID.
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      user.id,
    );
    if (deleteError != null) throw deleteError;

    return json({ status: "deleted" });
  } catch (error) {
    console.error("Account deletion failed.", error);
    return json({ error: "We could not delete your account." }, 500);
  }
});

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!);

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0)).buffer;
}

function base64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = base64url(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" }))
  );
  const payload = base64url(
    new TextEncoder().encode(
      JSON.stringify({
        iss: FCM_SERVICE_ACCOUNT.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
      })
    )
  );

  const signingInput = `${header}.${payload}`;

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(FCM_SERVICE_ACCOUNT.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signingInput)
  );

  const signature = base64url(new Uint8Array(signatureBuffer));
  const jwt = `${signingInput}.${signature}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    throw new Error(`Gagal ambil FCM token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

async function kirimFcm(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: {
            priority: "high",
            notification: { channel_id: "posyandu_channel" },
          },
        },
      }),
    }
  );

  if (!res.ok) {
    const err = await res.text();
    console.error(`FCM error untuk token ${fcmToken.slice(0, 20)}...: ${err}`);
  }
}

serve(async (req) => {
  try {
    const { record } = await req.json();

    if (!record?.user_id) {
      return new Response("no user_id", { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: devices, error } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("user_id", record.user_id);

    if (error || !devices?.length) {
      return new Response("no devices", { status: 200 });
    }

    const accessToken = await getAccessToken();

    const title = record.title ?? "Posyandu Merpati";
    const body = record.message ?? "";
    const data: Record<string, string> = {
      id: record.id ?? "",
      type: record.type ?? "general",
    };

    await Promise.all(
      devices.map((d) => kirimFcm(accessToken, d.fcm_token, title, body, data))
    );

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error("Edge function error:", e);
    return new Response(`error: ${e}`, { status: 500 });
  }
});

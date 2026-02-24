# Supabase Edge Functions

## Standard Edge Function Template

```typescript
// supabase/functions/function-name/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role for admin operations
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Create Supabase client with user's JWT for RLS-respecting operations
    const authHeader = req.headers.get("Authorization")!
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verify the user
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Parse request body
    const body = await req.json()

    // ... function logic here ...

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
```

## Webhook Handler Pattern

```typescript
// supabase/functions/webhook-handler/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const signature = req.headers.get("x-webhook-signature")
  const body = await req.text()

  // Verify webhook signature
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(Deno.env.get("WEBHOOK_SECRET")!),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  )
  const signed = await crypto.subtle.sign("HMAC", key, encoder.encode(body))
  const expectedSignature = btoa(String.fromCharCode(...new Uint8Array(signed)))

  if (signature !== expectedSignature) {
    return new Response("Invalid signature", { status: 401 })
  }

  const payload = JSON.parse(body)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  // Process webhook event
  switch (payload.type) {
    case "order.completed":
      await supabase.from("orders").update({ status: "completed" }).eq("id", payload.order_id)
      break
    // ... other event types
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 })
})
```

## Scheduled Task Pattern (Invoked via pg_cron or external cron)

```typescript
// supabase/functions/daily-cleanup/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // Verify this is called by an authorized source
  const authHeader = req.headers.get("Authorization")
  if (authHeader !== `Bearer ${Deno.env.get("CRON_SECRET")}`) {
    return new Response("Unauthorized", { status: 401 })
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  // Delete expired sessions
  const { error: sessionError } = await supabase
    .from("sessions")
    .delete()
    .lt("expires_at", new Date().toISOString())

  // Archive old soft-deleted records
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
  const { data: archived } = await supabase
    .from("posts")
    .select("id")
    .not("deleted_at", "is", null)
    .lt("deleted_at", thirtyDaysAgo)

  return new Response(
    JSON.stringify({
      cleaned_sessions: !sessionError,
      archived_count: archived?.length ?? 0,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  )
})
```

## Stripe Integration Pattern

```typescript
// supabase/functions/stripe-webhook/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import Stripe from "https://esm.sh/stripe@13?target=deno"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  const body = await req.text()
  const signature = req.headers.get("stripe-signature")!
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session
      await supabase.from("subscriptions").upsert({
        user_id: session.metadata?.user_id,
        stripe_customer_id: session.customer as string,
        stripe_subscription_id: session.subscription as string,
        status: "active",
        plan: session.metadata?.plan,
      })
      break
    }
    case "customer.subscription.updated": {
      const subscription = event.data.object as Stripe.Subscription
      await supabase
        .from("subscriptions")
        .update({ status: subscription.status })
        .eq("stripe_subscription_id", subscription.id)
      break
    }
    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription
      await supabase
        .from("subscriptions")
        .update({ status: "canceled" })
        .eq("stripe_subscription_id", subscription.id)
      break
    }
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 })
})
```

## Email Sending Pattern

```typescript
// supabase/functions/send-email/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { to, subject, html } = await req.json()

  // Send via Resend (or any email provider)
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
    },
    body: JSON.stringify({
      from: "noreply@yourdomain.com",
      to,
      subject,
      html,
    }),
  })

  const data = await res.json()

  if (!res.ok) {
    return new Response(JSON.stringify({ error: data }), { status: 500 })
  }

  // Log email in database
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )
  await supabase.from("email_log").insert({
    to_address: to,
    subject,
    status: "sent",
    provider_id: data.id,
  })

  return new Response(JSON.stringify({ success: true, id: data.id }), { status: 200 })
})
```

## File Processing Pattern

```typescript
// supabase/functions/process-upload/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { record } = await req.json()
  // This function is triggered by a database webhook on storage.objects INSERT

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  // Download the uploaded file
  const { data: fileData, error: downloadError } = await supabase.storage
    .from(record.bucket_id)
    .download(record.name)

  if (downloadError) {
    console.error("Download error:", downloadError)
    return new Response(JSON.stringify({ error: downloadError }), { status: 500 })
  }

  // Process the file (example: extract text, generate thumbnail, etc.)
  const fileBuffer = await fileData.arrayBuffer()
  // ... processing logic ...

  // Update metadata in database
  await supabase.from("file_metadata").insert({
    storage_path: `${record.bucket_id}/${record.name}`,
    size_bytes: fileBuffer.byteLength,
    content_type: record.metadata?.mimetype,
    processed_at: new Date().toISOString(),
  })

  return new Response(JSON.stringify({ processed: true }), { status: 200 })
})
```

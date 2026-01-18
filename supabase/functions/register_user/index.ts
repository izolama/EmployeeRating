// Edge Function: register_user
// Membuat user Auth + memasukkan baris ke public.profiles
// Hanya boleh dipanggil oleh user dengan role super_admin atau admin.

import { serve } from "https://deno.land/std@0.181.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseAdmin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response("Unauthorized", { status: 401 });
  }
  const jwt = authHeader.replace("Bearer ", "").trim();

  // Pastikan pemanggil adalah super_admin/admin
  const { data: callerData, error: callerErr } = await supabaseAdmin.auth.getUser(jwt);
  if (callerErr || !callerData.user) {
    return new Response("Invalid token", { status: 401 });
  }

  const callerId = callerData.user.id;
  const { data: profileCaller, error: profileErr } = await supabaseAdmin
    .from("profiles")
    .select("role")
    .eq("user_id", callerId)
    .maybeSingle();

  const callerRole = profileCaller?.role;
  if (profileErr || !callerRole || !["super_admin", "admin"].includes(callerRole)) {
    return new Response("Forbidden", { status: 403 });
  }

  try {
    const { email, password, role, class_id, full_name } = await req.json();
    if (!email || !password || !role) {
      return new Response("Missing fields", { status: 400 });
    }

    const allowedRoles = ["siswa", "wali", "admin", "super_admin"];
    if (!allowedRoles.includes(role)) {
      return new Response("Invalid role", { status: 400 });
    }

    // Admin tidak boleh membuat super_admin
    if (callerRole === "admin" && role === "super_admin") {
      return new Response("Admin cannot create super_admin", { status: 403 });
    }

    const resolvedFullName = (full_name ?? "").toString().trim() || email.split("@")[0];
    let studentId: string | null = null;
    if (role === "siswa") {
      const classId = (class_id ?? "").toString().trim();
      const { data: studentMatch } = await supabaseAdmin
        .from("student")
        .select("student_id")
        .ilike("student_name", resolvedFullName)
        .eq("student_class", classId)
        .maybeSingle();
      studentId = studentMatch?.student_id ?? null;
    }

    const { data: userResp, error: createErr } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: resolvedFullName, name: resolvedFullName, role },
    });
    if (createErr || !userResp?.user) {
      return new Response(`Create user error: ${createErr?.message}`, { status: 400 });
    }

    const userId = userResp.user.id;
    const { error: profErr } = await supabaseAdmin.from("profiles").upsert({
      user_id: userId,
      role,
      class_id: class_id ?? null,
      full_name: resolvedFullName,
      student_id: studentId,
    });
    if (profErr) {
      return new Response(`Profiles insert error: ${profErr.message}`, { status: 400 });
    }

    return new Response(JSON.stringify({ user_id: userId }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(`Unexpected error: ${e}`, { status: 500 });
  }
});

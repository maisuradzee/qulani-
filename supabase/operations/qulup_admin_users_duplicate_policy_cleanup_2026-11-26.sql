-- Remove one exact duplicate permissive SELECT policy.
-- The retained policy has the same role, command, USING expression and access scope.
-- This does not narrow or broaden effective access.
DROP POLICY IF EXISTS "Users can read own admin status" ON public.admin_users;

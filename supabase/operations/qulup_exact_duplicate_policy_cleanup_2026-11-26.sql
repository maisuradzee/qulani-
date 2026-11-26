-- QULUP: remove only byte-for-byte-equivalent permissive policy duplicates.
-- Each retained policy has the same table, command, roles, USING and WITH CHECK
-- expressions as the dropped policy. Effective row access is therefore unchanged.

-- Homepage banners: keep homepage_banner_public_read_v102.
DROP POLICY IF EXISTS "Public can read active homepage banners"
  ON public.homepage_banner_slides;

-- Public challenges: keep qulup_challenges_public_read_v102.
DROP POLICY IF EXISTS "Anyone can view active Qulup challenges"
  ON public.qulup_challenges;
DROP POLICY IF EXISTS "Anyone can view active challenges"
  ON public.qulup_challenges;

-- Site feedback: keep the newer "site feedback" policy names.
DROP POLICY IF EXISTS "Admins can delete feedback inbox"
  ON public.site_feedback;
DROP POLICY IF EXISTS "Users can submit own feedback"
  ON public.site_feedback;
DROP POLICY IF EXISTS "Admins can read feedback inbox"
  ON public.site_feedback;
DROP POLICY IF EXISTS "Admins can update feedback inbox"
  ON public.site_feedback;

-- Intentionally not changing any non-identical permissive policies.

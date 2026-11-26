-- The ALL policy grants the same DELETE predicate as the specific DELETE policy.
-- Keep the broader business profile admin policy; the dedicated DELETE rule is redundant.
DROP POLICY IF EXISTS qulup_business_profiles_admin_delete_v102
  ON public.qulup_business_profiles;

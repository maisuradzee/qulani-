-- QULUP: harden SECURITY DEFINER functions against temporary-schema shadowing.
-- The reviewed function bodies use schema-qualified application relations/types
-- (public.* and auth.*), so an empty search_path preserves resolution while
-- preventing temporary objects from shadowing application objects.

ALTER FUNCTION public.admin_manage_user(uuid, text) SET search_path = '';
ALTER FUNCTION public.admin_process_reward_redemption(uuid, text, text) SET search_path = '';
ALTER FUNCTION public.admin_review_submission(uuid, text, text) SET search_path = '';
ALTER FUNCTION public.is_admin() SET search_path = '';
ALTER FUNCTION public.q_award_user_achievements(uuid) SET search_path = '';
ALTER FUNCTION public.q_check_achievements_after_redemption() SET search_path = '';
ALTER FUNCTION public.q_check_achievements_after_submission() SET search_path = '';
ALTER FUNCTION public.q_recheck_all_user_achievements() SET search_path = '';
ALTER FUNCTION public.qulani_notify_published_task() SET search_path = '';
ALTER FUNCTION public.qulup_admin_set_top_visibility(bigint, boolean) SET search_path = '';
ALTER FUNCTION public.qulup_award_challenge_winner(uuid) SET search_path = '';
ALTER FUNCTION public.qulup_business_handle_new_user() SET search_path = '';
ALTER FUNCTION public.qulup_credit_challenge_lari_on_approval() SET search_path = '';
ALTER FUNCTION public.qulup_finalize_weekly_like_contest(date) SET search_path = '';
ALTER FUNCTION public.qulup_is_admin() SET search_path = '';
ALTER FUNCTION public.qulup_review_challenge_submission(uuid, boolean) SET search_path = '';
ALTER FUNCTION public.qulup_review_challenge_submission(uuid, text) SET search_path = '';
ALTER FUNCTION public.qulup_set_weekly_prize(integer) SET search_path = '';
ALTER FUNCTION public.qulup_toggle_challenge_favorite(uuid) SET search_path = '';
ALTER FUNCTION public.redeem_reward(uuid) SET search_path = '';

-- rls_auto_enable() remains restricted to pg_catalog search_path; it is an
-- internal event-trigger function and is not part of the public RPC surface.

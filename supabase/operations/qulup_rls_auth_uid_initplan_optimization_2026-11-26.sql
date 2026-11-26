-- QULUP: cache auth.uid() once per statement for eligible RLS policies.
-- This is a semantic-preserving optimization recommended by Supabase:
-- (select auth.uid()) is an initPlan value, not a per-row auth function call.
-- Policy names, roles, permissive/restrictive mode, commands and row predicates
-- remain unchanged; only bare auth.uid() expressions are scalar-subquery wrapped.

ALTER POLICY "Admins manage achievements" ON public."achievements" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Anyone can read active achievements" ON public."achievements" USING (((is_active = true) OR (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "Users can read own admin status" ON public."admin_users" USING ((user_id = (select auth.uid())));

ALTER POLICY "Admins can manage homepage banners" ON public."homepage_banner_slides" USING ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid())))));

ALTER POLICY "Admins can add partner companies" ON public."partner_companies" WITH CHECK ((((select auth.uid()) = created_by) AND (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "Admins can delete partner companies" ON public."partner_companies" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Admins can update partner companies" ON public."partner_companies" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Public can view published partner companies" ON public."partner_companies" USING (((is_published = true) OR (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "qulani_profiles_select_own" ON public."profiles" USING (((select auth.uid()) = id));

ALTER POLICY "qulani_profiles_update_own" ON public."profiles" USING (((select auth.uid()) = id)) WITH CHECK (((select auth.uid()) = id));

ALTER POLICY "admins read own membership" ON public."qulup_admins" USING ((user_id = (select auth.uid())));

ALTER POLICY "qbc_submissions_insert_own" ON public."qulup_business_campaign_submissions" WITH CHECK (((user_id = (select auth.uid())) AND (status = 'pending'::text) AND (reviewed_at IS NULL) AND (reviewed_by IS NULL) AND (awarded_points = 0) AND (awarded_at IS NULL) AND (EXISTS ( SELECT 1
   FROM qulup_business_campaigns c
  WHERE ((c.id = qulup_business_campaign_submissions.campaign_id) AND (c.status = 'active'::text) AND ((c.ends_at IS NULL) OR (c.ends_at >= CURRENT_DATE)))))));

ALTER POLICY "business profile create own pending" ON public."qulup_business_profiles" WITH CHECK (((id = (select auth.uid())) AND (status = 'pending'::text)));

ALTER POLICY "users read own challenge progress" ON public."qulup_challenge_progress" USING (((user_id = (select auth.uid())) OR qulup_is_admin()));

ALTER POLICY "Users and admins read Qulup challenge submissions" ON public."qulup_challenge_submissions" USING (((user_id = (select auth.uid())) OR (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "Users can submit own pending Qulup challenge" ON public."qulup_challenge_submissions" WITH CHECK ((((select auth.uid()) = user_id) AND (status = 'pending'::text) AND (reviewed_by IS NULL) AND (reviewed_at IS NULL) AND (is_favorite = false) AND (is_winner = false) AND (coins_awarded = 0) AND (show_in_top = true) AND (EXISTS ( SELECT 1
   FROM qulup_challenges c
  WHERE ((c.id = qulup_challenge_submissions.challenge_id) AND (c.active = true))))));

ALTER POLICY "Users can view own submissions" ON public."qulup_challenge_submissions" USING (((select auth.uid()) = user_id));

ALTER POLICY "users read own submissions admins all" ON public."qulup_challenge_submissions" USING (((user_id = (select auth.uid())) OR qulup_is_admin() OR ((status = 'approved'::text) AND (is_favorite = true))));

ALTER POLICY "Public can read published Qulup challenge top performances" ON public."qulup_challenge_top_performances" USING (((is_published = true) OR (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "Qulup admins can delete challenge top performances" ON public."qulup_challenge_top_performances" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Qulup admins can insert challenge top performances" ON public."qulup_challenge_top_performances" WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Qulup admins can update challenge top performances" ON public."qulup_challenge_top_performances" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "users read own coin ledger" ON public."qulup_coin_ledger" USING (((user_id = (select auth.uid())) OR qulup_is_admin()));

ALTER POLICY "users read own coin wallet" ON public."qulup_coin_wallets" USING (((user_id = (select auth.uid())) OR qulup_is_admin()));

ALTER POLICY "Users can view own game achievements" ON public."qulup_game_user_achievements" USING ((user_id = (select auth.uid())));

ALTER POLICY "Qulup admins can update game availability" ON public."qulup_games" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "users read own lari ledger" ON public."qulup_lari_ledger" USING (((user_id = (select auth.uid())) OR (EXISTS ( SELECT 1
   FROM qulup_admins a
  WHERE (a.user_id = (select auth.uid()))))));

ALTER POLICY "Users can like once" ON public."qulup_submission_likes" WITH CHECK (((user_id = (select auth.uid())) AND (EXISTS ( SELECT 1
   FROM qulup_challenge_submissions s
  WHERE ((s.id = qulup_submission_likes.submission_id) AND (s.status = 'approved'::text) AND (s.user_id <> (select auth.uid())))))));

ALTER POLICY "Users can remove own like" ON public."qulup_submission_likes" USING ((user_id = (select auth.uid())));

ALTER POLICY "Admins update weekly prize settings" ON public."qulup_weekly_prize_settings" USING ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid())))));

ALTER POLICY "Users read own reward redemptions" ON public."reward_redemptions" USING (((user_id = (select auth.uid())) OR is_admin()));

ALTER POLICY "Admins can add rewards" ON public."rewards" WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Admins can delete rewards" ON public."rewards" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Admins can read all rewards" ON public."rewards" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Admins can update rewards" ON public."rewards" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Admins can delete site feedback" ON public."site_feedback" USING ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid())))));

ALTER POLICY "Admins can read site feedback" ON public."site_feedback" USING ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid())))));

ALTER POLICY "Admins can update site feedback" ON public."site_feedback" USING ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users a
  WHERE (a.user_id = (select auth.uid())))));

ALTER POLICY "Users can submit own site feedback" ON public."site_feedback" WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Admins can add site news" ON public."site_news" WITH CHECK ((((select auth.uid()) = created_by) AND (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "Admins can delete site news" ON public."site_news" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Admins can update site news" ON public."site_news" USING ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid())))));

ALTER POLICY "Public can view published site news" ON public."site_news" USING (((is_published = true) OR (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "Admins read all submissions for review" ON public."submissions" USING ((is_admin() OR (user_id = (select auth.uid()))));

ALTER POLICY "Users read own achievements" ON public."user_achievements" USING (((user_id = (select auth.uid())) OR (EXISTS ( SELECT 1
   FROM admin_users au
  WHERE (au.user_id = (select auth.uid()))))));

ALTER POLICY "Users can mark own notifications read" ON public."user_notifications" USING ((user_id = (select auth.uid()))) WITH CHECK ((user_id = (select auth.uid())));

ALTER POLICY "Users can read own notifications" ON public."user_notifications" USING ((user_id = (select auth.uid())));

-- Verification: all 47 policies should keep the same authorization semantics.

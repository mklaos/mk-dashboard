-- =============================================================================
-- Automation: Auto-create app_users profile on Signup
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if profile already exists (from manual seed)
  -- If yes, update it with the auth_id
  IF EXISTS (SELECT 1 FROM public.app_users WHERE email = NEW.email) THEN
    UPDATE public.app_users 
    SET auth_id = NEW.id 
    WHERE email = NEW.email;
  ELSE
    -- If no, create a basic viewer profile
    INSERT INTO public.app_users (auth_id, email, name, role)
    VALUES (NEW.id, NEW.email, split_part(NEW.email, '@', 1), 'viewer');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

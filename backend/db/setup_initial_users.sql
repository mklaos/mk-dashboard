-- =============================================================================
-- Initial User & Role Setup
-- Run this in the Supabase SQL Editor
-- =============================================================================

-- 1. Get Brand IDs for mapping
DO $$
DECLARE
    mk_id UUID;
    miya_id UUID;
    hr_id UUID;
    owner_email TEXT := 'owner@mklaos.com'; -- CHANGE THESE
    mk_mgr_email TEXT := 'mk_manager@mklaos.com';
    miya_mgr_email TEXT := 'miya_manager@mklaos.com';
BEGIN
    -- Fetch existing Brand IDs
    SELECT id INTO mk_id FROM brands WHERE name = 'MK Restaurants' LIMIT 1;
    SELECT id INTO miya_id FROM brands WHERE name = 'Miyazaki' LIMIT 1;
    SELECT id INTO hr_id FROM brands WHERE name = 'Hard Rock Cafe' LIMIT 1;

    -- Note: You must first create the users in the "Authentication" tab of Supabase
    -- After creating them there, use their UID here or use this logic to seed app_users.
    
    -- Clear existing test users if any
    DELETE FROM app_users WHERE email IN (owner_email, mk_mgr_email, miya_mgr_email);

    -- Insert Owner (All Brands)
    INSERT INTO app_users (name, email, role, allowed_brands)
    VALUES ('System Owner', owner_email, 'owner', ARRAY[mk_id, miya_id, hr_id]);

    -- Insert MK Manager (MK Only)
    INSERT INTO app_users (name, email, role, allowed_brands)
    VALUES ('MK Branch Manager', mk_mgr_email, 'manager', ARRAY[mk_id]);

    -- Insert Miyazaki Manager (Miyazaki Only)
    INSERT INTO app_users (name, email, role, allowed_brands)
    VALUES ('Miyazaki Manager', miya_mgr_email, 'manager', ARRAY[miya_id]);

    RAISE NOTICE 'Users seeded successfully. Please ensure these emails exist in Auth > Users.';
END $$;

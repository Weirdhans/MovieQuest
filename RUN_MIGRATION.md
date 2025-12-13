# Christmas Mode Database Migration

## Quick Start - Run Migration via Supabase Dashboard

1. **Open Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your project**: MovieQuest / MovieMatcher
3. **Go to SQL Editor** (left sidebar)
4. **Copy and paste this SQL**:

```sql
-- Add is_christmas_mode column to sessions table
-- Migration: Add Christmas movies filter support
-- Date: 2025-12-10

-- Add column (nullable for backward compatibility)
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS is_christmas_mode BOOLEAN DEFAULT NULL;

-- Add comment for documentation
COMMENT ON COLUMN sessions.is_christmas_mode IS 'Christmas movies filter enabled (NULL = false for backward compatibility)';

-- Create index for Christmas mode queries (improves query performance)
CREATE INDEX IF NOT EXISTS idx_sessions_christmas_mode
ON sessions(is_christmas_mode)
WHERE is_christmas_mode = true;
```

5. **Click "Run"**
6. **Verify**: Run `SELECT * FROM sessions LIMIT 1;` to confirm column exists

## Alternative: Via Supabase CLI

If you have Supabase CLI installed and local instance running:

```bash
npx supabase migration up
```

Or connect to remote:

```bash
npx supabase db push
```

## Verification

After running the migration, verify it worked:

```sql
-- Check if column exists
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'sessions'
AND column_name = 'is_christmas_mode';

-- Check if index exists
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'sessions'
AND indexname = 'idx_sessions_christmas_mode';
```

Expected results:
- Column: `is_christmas_mode` of type `boolean`, nullable
- Index: `idx_sessions_christmas_mode` on `sessions(is_christmas_mode) WHERE (is_christmas_mode = true)`

## Rollback (if needed)

If you need to undo this migration:

```sql
-- Remove index
DROP INDEX IF EXISTS idx_sessions_christmas_mode;

-- Remove column
ALTER TABLE sessions DROP COLUMN IF EXISTS is_christmas_mode;
```

## Next Steps

After migration is complete:
1. Test creating a new session with Christmas mode enabled
2. Verify movies are filtered correctly (only Christmas films appear)
3. Deploy the Flutter app to production

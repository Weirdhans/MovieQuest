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

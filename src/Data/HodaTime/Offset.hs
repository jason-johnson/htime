-----------------------------------------------------------------------------
-- |
-- Module      :  Data.HodaTime.Offset
-- Copyright   :  (C) 2016 Jason Johnson
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Jason Johnson <jason.johnson.081@gmail.com>
-- Stability   :  experimental
-- Portability :  TBD
--
-- An 'Offset' is a period of time offset from UTC time.  This module contains constructors and functions for working with 'Offsets'.
--
-- === Clamping
--
-- An offset must be between 18 hours and -18 hours (inclusive).  If you go outside this range the functions will clamp to the nearest value.
----------------------------------------------------------------------------
module Data.HodaTime.Offset
(
  -- * Constructors
   fromSeconds
  ,fromMinutes
  ,fromHours
  -- * Lenses
  ,seconds
  ,minutes
  ,hours
  -- * Math
  ,add
  ,minus
)
where

import Data.HodaTime.OffsetDateTime.Internal
import Data.HodaTime.Constants (secondsPerHour)

-- Offset specific constants

maxOffsetHours :: Num a => a
maxOffsetHours = 18

minOffsetHours :: Num a => a
minOffsetHours = negate maxOffsetHours

maxOffsetSeconds :: Num a => a
maxOffsetSeconds = maxOffsetHours * secondsPerHour

minOffsetSeconds :: Num a => a
minOffsetSeconds = negate maxOffsetSeconds

maxOffsetMinutes :: Num a => a
maxOffsetMinutes = maxOffsetHours * 60

minOffsetMinutes :: Num a => a
minOffsetMinutes = negate maxOffsetMinutes

clamp :: Ord a => a -> a -> a -> a
clamp small big = min big . max small

-- | Create an 'Offset' of (clamped) s seconds.
fromSeconds :: Integral a => a -> Offset
fromSeconds = Offset . fromIntegral . clamp minOffsetSeconds maxOffsetSeconds

-- | Create an 'Offset' of (clamped) m minutes.
fromMinutes :: Integral a => a -> Offset
fromMinutes = Offset . fromIntegral . (*60) . clamp minOffsetMinutes maxOffsetMinutes

-- | Create an 'Offset' of (clamped) h hours.
fromHours :: Integral a => a -> Offset
fromHours = Offset . fromIntegral . (*secondsPerHour) . clamp minOffsetHours maxOffsetHours

-- | Lens for the seconds component of the 'Offset'
seconds :: Functor f => (Int -> f Int) -> Offset -> f Offset
seconds f (Offset secs) = fromSeconds . (r+) . fromIntegral <$> f (fromIntegral s)
  where
    s = secs `mod` 60
    r = secs - s
{-# INLINE seconds #-}

-- | Lens for the minutes component of the 'Offset'
minutes :: Functor f => (Int -> f Int) -> Offset -> f Offset
minutes f (Offset secs) = fromSeconds . (r+) . (*60) . fromIntegral <$> f (fromIntegral m)
  where
    m = secs `mod` secondsPerHour `div` 60
    r = secs - (m*60)
{-# INLINE minutes #-}

-- | Lens for the hours component of the 'Offset'
hours :: Functor f => (Int -> f Int) -> Offset -> f Offset
hours f (Offset secs) = fromSeconds . (r+) . (*secondsPerHour) . fromIntegral <$> f (fromIntegral h)
  where
    h = secs `div` secondsPerHour
    r = secs - (h*secondsPerHour)
{-# INLINE hours #-}

-- | Add one 'Offset' to another  NOTE: if the result of the addition is outside the accepted range it will be clamped
add :: Offset -> Offset -> Offset
add (Offset lsecs) (Offset rsecs) = fromSeconds $ lsecs + rsecs

-- | Subtract one 'Offset' to another.  /NOTE: See 'add' above/
minus :: Offset -> Offset -> Offset
minus (Offset lsecs) (Offset rsecs) = fromSeconds $ lsecs - rsecs

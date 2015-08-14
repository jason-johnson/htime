module Data.HodaTime.LocalTime.Internal
(
   LocalTime(..)
  ,fromInstant
)
where

import Data.HodaTime.Instant.Internal (Instant(..))
import Data.Word (Word32)

-- | Represents a specific time of day with no reference to any calendar, date or time zone.
data LocalTime = LocalTime { ltSecs :: Word32, ltNsecs :: Word32 }
    deriving (Eq, Ord, Show)    -- TODO: Remove Show

fromInstant :: Instant -> LocalTime                             -- TODO: Move this to top level LocalTime, I don't think we need an Internal for this small type
fromInstant (Instant _ secs nsecs) = LocalTime secs nsecs
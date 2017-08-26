{-# LANGUAGE TypeFamilies #-}

module Data.HodaTime.Calendar.Internal
(
   DayNth(..)
  ,Year
  ,DayOfMonth
  ,CalendarDate(..)
  ,CalendarDateTime(..)
  ,IsCalendar(..)
  ,HasDate(..)
)
where

import Data.HodaTime.LocalTime.Internal (LocalTime(..))
import Data.Int (Int32)
import Data.Word (Word8, Word32)

data DayNth =
    First
  | Second
  | Third
  | Fourth
  | Fifth
  | Last
  | SecondToLast
  | ThirdToLast
  | FourthToLast
    deriving (Eq, Show, Enum)

type Year = Int
type DayOfMonth = Int

data CalendarDateTime calendar = CalendarDateTime (CalendarDate calendar) LocalTime
  deriving (Eq, Show, Ord)

-- | Represents a specific date within its calendar system, with no reference to any time zone or time of day.
-- Note: We keep the date in 2 formats, redundantly.  We depend on lazy evaluation to only produce the portion that is actually used
data CalendarDate calendar = CalendarDate { cdDays :: Int32, cdDay :: Word8, cdMonth :: Word8, cdYear :: Word32 }
  deriving (Eq, Show, Ord)

-- NOTE: This is a test form of the calendar date that only stores the cycle.  Everything else will be pulled from the date cache table, as required
--data CalendarDate o calendar = CalendarDate { cdDays :: Int32, cdCycle :: Word8, ldOptions :: o }
--  deriving (Eq, Show, Ord)

class IsCalendar cal where
  type Date cal
  data DayOfWeek cal
  data Month cal
  day' :: Functor f => (DayOfMonth -> f DayOfMonth) -> CalendarDate cal -> f (CalendarDate cal)
  month' :: CalendarDate cal -> Month cal
  year' :: Functor f => (Year -> f Year) -> CalendarDate cal -> f (CalendarDate cal)
  dayOfWeek' :: CalendarDate cal -> DayOfWeek cal
  next' :: Int -> DayOfWeek cal -> CalendarDate cal -> CalendarDate cal
  previous' :: Int -> DayOfWeek cal -> CalendarDate cal -> CalendarDate cal

class HasDate d where
  type DoW d
  type MoY d
  -- | Lens for the day component of a 'HasDate'.  Please note that days are not clamped: if you add e.g. 400 days then the month and year will roll
  day :: Functor f => (DayOfMonth -> f DayOfMonth) -> d -> f d
  month :: d -> MoY d
  -- | Lens for the year component of a 'HasDate'.  Please note that the rest of the date is left as is, with two exceptions: Feb 29 will clamp to 28 in a non-leapyear
  --   and if the new year is earlier than the earliest supported year it will clamp back to that year
  year :: Functor f => (Year -> f Year) -> d -> f d
  dayOfWeek :: d -> DoW d
  next :: Int -> DoW d -> d -> d
  previous :: Int -> DoW d -> d -> d

instance (IsCalendar cal) => HasDate (CalendarDate cal) where
  type DoW (CalendarDate cal) = DayOfWeek cal
  type MoY (CalendarDate cal) = Month cal
  day = day'
  month = month'
  year = year'
  dayOfWeek = dayOfWeek'
  next = next'
  previous = previous'

instance (IsCalendar cal) => HasDate (CalendarDateTime cal) where
  type DoW (CalendarDateTime cal) = DayOfWeek cal
  type MoY (CalendarDateTime cal) = Month cal
  day f (CalendarDateTime cd lt) = flip CalendarDateTime lt <$> day f cd
  month (CalendarDateTime cd _) = month cd
  year f (CalendarDateTime cd lt) = flip CalendarDateTime lt <$> year f cd
  dayOfWeek (CalendarDateTime cd _) = dayOfWeek cd
  next i dow (CalendarDateTime cd lt) = CalendarDateTime (next i dow cd) lt
  previous i dow (CalendarDateTime cd lt) = CalendarDateTime (previous i dow cd) lt

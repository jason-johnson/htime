{-# LANGUAGE TypeFamilies #-}

module Data.HodaTime.Calendar.Gregorian
(
  -- * Constructors
   calendarDate
  ,fromNthDay
  ,fromWeekDate
  -- * Types
  ,Month(..)
  ,DayOfWeek(..)
)
where

import Data.HodaTime.Calendar.Gregorian.Internal
import Data.HodaTime.Calendar.Internal
import Data.HodaTime.Constants (daysPerYear, monthDayOffsets)
import Control.Monad (guard)

minDate :: Int
minDate = 1582

epochDayOfWeek :: DayOfWeek Gregorian
epochDayOfWeek = Wednesday

-- types

data Gregorian

instance IsCalendar Gregorian where
  type Date Gregorian = CalendarDate Gregorian
  data DayOfWeek Gregorian = Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday
    deriving (Show, Eq, Ord, Enum, Bounded)
  data Month Gregorian = January | February | March | April | May | June | July | August | September | October | November | December      -- TODO: Move January and February to the back so the Enums work without adjustment
    deriving (Show, Eq, Ord, Enum, Bounded)                                                                                               -- TODO: Note that if we do this, we can't derive Ord and possibly not bounded, they have to be hand written (is this true?  Do we need Jan == 0?)

  day' f (CalendarDate _ d m y) = to . (rest+) <$> f (fromIntegral d)
    where
      to days = CalendarDate (fromIntegral days) d' m' y'
      rest = pred $ yearMonthDayToDays (fromIntegral y) (toEnum . fromIntegral $ m) 1
      (d', m', y') = (0, 0, 0)    -- TODO: day, month, year not calculated
  {-# INLINE day' #-}
  month' (CalendarDate _ _ m _) = toEnum . fromIntegral $ m
  year' (CalendarDate _ _ _ y) = fromIntegral y
  dayOfWeek' (CalendarDate days _ _ _) = toEnum . dayOfWeekFromDays . fromIntegral $ days

  next' = undefined
  previous' = undefined

-- | Smart constuctor for Gregorian calendar date.
calendarDate :: DayOfMonth -> Month Gregorian -> Year -> Maybe (Date Gregorian)
calendarDate d m y = do
  guard $ y > minDate
  guard $ d > 0 && d <= maxDaysInMonth m y
  let days = fromIntegral $ yearMonthDayToDays y m d
  return $ CalendarDate days (fromIntegral d) (fromIntegral . fromEnum $ m) (fromIntegral y)

-- | Smart constuctor for Gregorian calendar date based on relative month day.
fromNthDay :: DayNth -> DayOfWeek Gregorian -> Month Gregorian -> Year -> Maybe (Date Gregorian)
fromNthDay nth dow m y = do
  guard $ adjustment < fromIntegral mdim           -- NOTE: we have to use < not <= because we're adding to first of the month or subtracting from the end of the month
  return $ CalendarDate (fromIntegral days) (fromIntegral d) (fromIntegral . fromEnum $ m) (fromIntegral y)
  where
    mdim = maxDaysInMonth m y
    somDays = yearMonthDayToDays y m 1
    eomDays = yearMonthDayToDays y m mdim
    startDow = dayOfWeekFromDays days'
    targetDow = fromEnum dow
    adjustment = 7 * multiple + adjust startDow targetDow
    (days', multiple, adjust, d, days) = frontOrBack (fromEnum nth)
    frontOrBack nth'
      | nth' < 5  = (somDays, nth', weekdayDistance, adjustment + 1, somDays + adjustment)
      | otherwise = (eomDays, nth' - 5, flip weekdayDistance, mdim - adjustment, eomDays - adjustment)

-- helper functions

dayOfWeekFromDays :: Int -> Int
dayOfWeekFromDays = normalize . (fromEnum epochDayOfWeek +) . flip mod 7
  where
    normalize n = if n >= 7 then n - 7 else n

weekdayDistance :: (Ord a, Num a) => a -> a -> a
weekdayDistance s e = e' - s
  where
    e' = if e >= s then e else e + 7

maxDaysInMonth :: Month Gregorian -> Year -> Int
maxDaysInMonth February y
  | isLeap                                = 29
  | otherwise                             = 28
  where
    isLeap
      | 0 == y `mod` 100                  = 0 == y `mod` 400
      | otherwise                         = 0 == y `mod` 4
maxDaysInMonth n _
  | n == April || n == June || n == September || n == November  = 30
  | otherwise                                                   = 31

yearMonthDayToDays :: Year -> Month Gregorian -> DayOfMonth -> Int
yearMonthDayToDays y m d = days
  where
    m' = if m > February then fromEnum m - 2 else fromEnum m + 10
    years = if m < March then y - 2001 else y - 2000
    yearDays = years * daysPerYear + years `div` 4 + years `div` 400 - years `div` 100
    days = yearDays + monthDayOffsets !! m' + d - 1

{-
yearMonthDayToDays :: Int -> Month Gregorian -> Int -> Int
yearMonthDayToDays year month day = days
  where
    m = fromEnum month
    m' = if m > 1 then m - 2 else m + 10
    y = if m < 2 then year - 1 else year
    era = (/ 400) $ if y >= 0 then y else y-399   -- TODO: this is wrong, we should probably just do: div 400.  The -399 is only for certain C++ compilers, but we should test it
    yoe = y - era * 400                             -- [0,399]
    doy = (153*(m + (m >= 2 ? -2 : 10)) + 2)/5 + d-1  -- TODO: What does this do?
-}

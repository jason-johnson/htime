{-# LANGUAGE TypeFamilies #-}

module Data.HodaTime.Calendar.Gregorian
(
   calendarDate
  ,Month(..)
  ,DayOfWeek(..)
)
where

import Data.HodaTime.Calendar.Gregorian.Internal
import Data.HodaTime.Calendar.Internal
import Data.HodaTime.Constants (daysPerYear, monthDayOffsets)
import Data.HodaTime.Instant.Internal (Instant(..))
import Data.Int (Int32)
import Control.Monad (guard)

minDate :: Int
minDate = 1582

-- types

data Gregorian

instance IsCalendar Gregorian where
  type Date Gregorian = CalendarDate (Month Gregorian) Gregorian
  data DayOfWeek Gregorian = Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday
    deriving (Show, Eq, Ord, Enum, Bounded)
  data Month Gregorian = January | February | March | April | May | June | July | August | September | October | November | December
    deriving (Show, Eq, Ord, Enum, Bounded)

  next' = undefined

calendarDate :: Int -> Month Gregorian -> Int -> Maybe (Date Gregorian)
calendarDate d m y = do
  guard $ y > minDate
  guard $ validDay d m y
  return $ CalendarDate (fromIntegral y) m (fromIntegral d)

validDay _ _ _ = True

-- helper functions

yearMonthDayToDays :: Int -> Int -> Int -> Int32
yearMonthDayToDays year month day = fromIntegral days
  where
    month' = if month > 1 then month - 2 else month + 10
    years = if month < 2 then year - 2001 else year - 2000
    yearDays = years * daysPerYear + years `div` 4 + years `div` 400 - years `div` 100
    days = yearDays + monthDayOffsets !! month' + day - 1

{-# OPTIONS_GHC -Wno-missing-export-lists #-}
{-
Supreme Source (c) 2023
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * Neither the name of Supreme Source nor the names of other
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-}
module Util
{-
-- ! DESCRIPTION 
idefining the majority of task specific functions / accumulators (similart to lib)
-}
 where

-- | importing external libraries
import           Data.Foldable (toList)
import           Data.Sequence (Seq, empty, fromList, singleton, (><), ViewL (EmptyL, (:<)), viewl,index)
import           System.Random (Random (randomRs))
-- | internal libraries
import           Colours
import           DataTypes
import           Lib
import           RunSettings


--  ACCUMULATORS
initialBookDetails :: BookStats
initialBookDetails =
  BookStats
    { startingPoint = 0.0
    , maxMinLimit = (0,0)
    , asksTotal = 0
    , bidsTotal = 0
    , totakefromwall = 0
    , lengthchangeBID = 0
    , lengthchangeASK = 0
    , listASK = empty
    , listBID = empty
    , vSide = Buy
    , volumeAmount = 0
    , spread = 0.0
    , startingprice = 0.0
    , bidAskRatio = 0.0
    }

-- ? position acccumulator
initialPositionData :: [PositionData]
initialPositionData = []

-- | accumulators for future info
futureAccLong :: FutureInfo
futureAccLong = [(0, 0, "")]

futureAccShort :: FutureInfo
futureAccShort = [(0, 0, "")]

initPositioningAcc :: (Seq (Int, String), Seq (Int, String))
initPositioningAcc = (empty, empty)

initLiquidationAcc :: Seq (Int, String, String)
initLiquidationAcc = empty

-- | helper funciton for the funciton below (where everything is starting at)
initStats :: Stats
initStats = Stats 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0



setupBookDetails :: InitBookStats -> BookStats
setupBookDetails (startingP', maxMinL', asksTot', bidsTot', takewall', lengchngBid', lengchngAsk', listASK', listBID', vSide', volumeA', sprd', sprice', bidAskR') =
  BookStats
    { startingPoint = startingP'
    , maxMinLimit = maxMinL'
    , asksTotal = asksTot'
    , bidsTotal = bidsTot'
    , totakefromwall = takewall'
    , lengthchangeBID = lengchngBid'
    , lengthchangeASK = lengchngAsk'
    , listASK =  listASK'
    , listBID =  listBID'
    , vSide = vSide'
    , volumeAmount = volumeA'
    , spread = sprd'
    , startingprice = sprice'
    , bidAskRatio = bidAskR'
    }


-- | aggregating  stats together
aggregateStats :: (TakerPositions, MakerPositions) -> Stats -> Stats
aggregateStats (taker, makers) stats =
  Stats
    { overallOI =
        overallOI stats + interestorPlus taker makers -
        interestorMinus taker makers
    , totalVolume = totalVolume stats + foldl (\acc (x, _) -> acc + x) 0 taker
    , buyVolume =
        buyVolume stats +
        foldl
          (\acc (x, y) ->
             if y == "x" || y == "z"
               then acc + x
               else acc)
          0
          taker
    , sellVolume =
        sellVolume stats +
        foldl
          (\acc (x, y) ->
             if y == "y" || y == "f"
               then acc + x
               else acc)
          0
          taker
    , takerXc = takerXc stats + countElements "x" taker
    , takerYc = takerYc stats + countElements "y" taker
    , takerZc = takerZc stats + countElements "z" taker
    , takerFc = takerFc stats + countElements "f" taker
    , makerXc = makerXc stats + countElements "x" makers
    , makerYc = makerYc stats + countElements "y" makers
    , makerZc = makerZc stats + countElements "z" makers
    , makerFc = makerFc stats + countElements "f" makers
    , offX = offX stats + elementSize "x" taker + elementSize "x" makers
    , offY = offY stats + elementSize "y" taker + elementSize "y" makers
    , offZ = offZ stats + elementSize "z" taker + elementSize "z" makers
    , offF = offF stats + elementSize "f" taker + elementSize "f" makers
    , takerX = takerX stats + elementSize "x" taker
    , takerY = takerY stats + elementSize "y" taker
    , takerZ = takerZ stats + elementSize "z" taker
    , takerF = takerF stats + elementSize "f" taker
    , makerX = makerX stats + elementSize "x" makers
    , makerY = makerY stats + elementSize "y" makers
    , makerZ = makerZ stats + elementSize "z" makers
    , makerF = makerF stats + elementSize "f" makers
    }

settingcheck :: VolumeSide -> Int -> Int -> Int -> IO ()
settingcheck vSide' volumeA' asksTot' bidsTot' = do
  let check :: String
        | vSide' /= Buy && vSide' /= Sell =
          error $ red "wrong volume specification !"
        | vSide' == Buy && volumeA' > asksTot' =
          error $ red "THE VOLUME EXCEEDED THE ORDERBOOK CAPACITY !"
        | vSide' == Sell && volumeA' > bidsTot' =
          error $ red "THE VOLUME EXCEEDED THE ORDERBOOK CAPACITY !"
        | otherwise = ""
  putStrLn check

calculateVolumes :: VolumeSide -> Int -> (Int, Int)
calculateVolumes vSide' volumeA' =
  ( if vSide' == Sell
      then volumeA'
      else 0
  , if vSide' == Buy
      then volumeA'
      else 0)

calculateBooks :: Int -> Int -> SeqOrderBook -> SeqOrderBook -> (SeqOrderBook, SeqOrderBook)
calculateBooks volumeBID volumeASK bidBook askBook =
  let bidUpdateBook = orderbookChange bidBook volumeBID
      askUpdateBook = orderbookChange askBook volumeASK
   in (bidUpdateBook, askUpdateBook)


-- TODO implement sequencing
calculateFinalBooks ::
     VolumeSide
  -> SeqOrderBook 
  -> Seq (Double, Int) 
  -> SeqOrderBook 
  -> SeqOrderBook 
  -> Seq (Double, Int) 
  -> SeqOrderBook 
  -> (SeqOrderBook, SeqOrderBook) 
calculateFinalBooks vSide' askUpdateBook listASK' askBook bidUpdateBook listBID' bidBook =
  let currentbookASK =
        if vSide' == Buy
          then askUpdateBook
          else listASK' >< askBook
     
      currentbookBID =
        if vSide' == Sell
          then bidUpdateBook
          else listBID' >< bidBook
   in (currentbookASK, currentbookBID)

lengthChanges :: SeqOrderBook -> SeqOrderBook -> SeqOrderBook -> SeqOrderBook -> (Int, Int)
lengthChanges bidUpdateBook bidBook askUpdateBook askBook =
  (bookNumChange bidUpdateBook bidBook, bookNumChange askUpdateBook askBook)  

startingPrices :: VolumeSide -> SeqOrderBook -> SeqOrderBook -> Double
startingPrices vSide' bidUpdateBook askUpdateBook =
  max
    (if vSide' == Sell
       then case viewl bidUpdateBook of
              (price, _) :< _ -> price
              EmptyL          -> 0
       else 0)
    (if vSide' == Buy
       then case viewl askUpdateBook of
              (price, _) :< _ -> price
              EmptyL          -> 0
       else 0)

divisionValue :: Double
divisionValue = 1.10

calculateListTuples ::
     [Double]
  -> [Double]
  -> [Int]
  -> [Int]
  -> (SeqOrderBook, SeqOrderBook)
calculateListTuples askSetupInsert bidSetupInsert pricesASK pricesBID =
  let listASK' =
        zipToTuples
          askSetupInsert
          (map
             (round . ((/ divisionValue) :: Double -> Double) . fromIntegral)
             pricesASK)
      listBID' =
        zipToTuples
          bidSetupInsert
          (map
             (round . ((/ divisionValue) :: Double -> Double) . fromIntegral)
             pricesBID)
   in (listASK', listBID')

calculateFirstElements :: SeqOrderBook -> SeqOrderBook -> (Double, Double)
calculateFirstElements finalBookAsk finalBookBid =
  let firstelemASK = fst $ index finalBookAsk 0
      firstelemBID = fst $ index finalBookBid 0
   in (firstelemASK, firstelemBID)

calculateTotals :: SeqOrderBook -> SeqOrderBook -> (Int, Int)
calculateTotals finalBookAsk finalBookBid =
  let asksTot' = sumInts finalBookAsk
      bidsTot' = sumInts finalBookBid
   in (asksTot', bidsTot')

calculateSetupInserts ::
     Int -> Int -> Double -> Generator -> Generator -> ([Double], [Double])
calculateSetupInserts lengchngAsk' lengchngBid' sPrice gen1 gen2 =
  let upMovesInsert = take takeamountASK $ randomRs (minUpMove, maxUpMove) gen1
      downMovesInsert =
        take takeamountBID $ randomRs (minDownMove, maxDownMove) gen2
      askSetupInsert =
        take
          lengchngAsk'
          (tail (infiniteListUpChange sPrice gen1 upMovesInsert))
      bidSetupInsert =
        take
          lengchngBid'
          (tail (infiniteListDownChange sPrice gen2 downMovesInsert))
   in (askSetupInsert, bidSetupInsert)

calculateTotalsCount :: SeqOrderBook -> SeqOrderBook -> (Double, Double)
calculateTotalsCount finalBookAsk finalBookBid =
  let asktotal = fromIntegral (length finalBookAsk)
      bidtotal = fromIntegral (length finalBookBid)
   in (asktotal, bidtotal)

-- Conversion functions
futureInfoToSeq :: FutureInfo -> Seq (Double, Int, String)
futureInfoToSeq = fromList

seqToFutureInfo :: Seq (Double, Int, String) -> FutureInfo
seqToFutureInfo = toList

sumList :: Num a => [a] -> [a]
sumList xs = [sum xs]

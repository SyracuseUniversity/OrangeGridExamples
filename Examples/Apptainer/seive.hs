module Main (main) where

main :: IO ()

sieve (x:xs) = x:(sieve $ filter (\a -> a `mod` x /= 0) xs)
ans = takeWhile (<200) (sieve [2..])

main = do
  print ans

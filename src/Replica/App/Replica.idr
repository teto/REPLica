module Replica.App.Replica

import Control.App
import Control.App.Console

import Data.List
import Data.Maybe
import Data.String

import Language.JSON

import System.Path

import Replica.App.FileSystem
import Replica.App.System
import Replica.Command.Run
import Replica.Core.Parse
import Replica.Core.Types
import Replica.Option.Global
import Replica.Other.Decorated
import Replica.Other.String
import Replica.Other.Validation


%default total

export
data CurrentTest : Type where

export
data GlobalConfig : Type where

public export
data ReplicaError
  = CantAccessTestFile String
  | InvalidJSON (List String)

export
Show ReplicaError where
  show (CantAccessTestFile x) = "Can't access file \{x}"
  show (InvalidJSON xs) = unlines $ "Can't parse JSON:" ::xs

export
testDir : String -> String
testDir = (</> "test")

export
logDir : String -> String
logDir = (</> "log")

export
lastRunLog : String -> String
lastRunLog rdir = logDir rdir </> "last.json"

export
getReplicaDir : State GlobalConfig Global e => App e String
getReplicaDir = map replicaDir $ get GlobalConfig

export
setAbsoluteReplicaDir : Has [State GlobalConfig Global, FileSystem] e => App e ()
setAbsoluteReplicaDir = do
  rdir <- getReplicaDir
  if isAbsolute rdir
     then pure ()
     else do
       pwd <- getCurrentDir
       modify GlobalConfig (record {replicaDir = pwd </> rdir})

export
getSingleTestDir : Has
  [ State CurrentTest Test
  , State GlobalConfig Global ] e => App e String
getSingleTestDir = do
  d <- map replicaDir $ get GlobalConfig
  t <- get CurrentTest
  pure $ testDir d </> t.name


export
getInputFile : Has
  [ State CurrentTest Test
  , State GlobalConfig Global ] e => App e String
getInputFile = do
  d <- map replicaDir $ get GlobalConfig
  t <- getSingleTestDir
  pure $ t </> defaultInput

export
getOutputFile : Has
  [ State CurrentTest Test
  , State GlobalConfig Global ] e => App e String
getOutputFile = do
  d <- map replicaDir $ get GlobalConfig
  t <- getSingleTestDir
  pure $ t </> defaultOutput

export
getExpectedOutput : Has
  [ State CurrentTest Test
  , State GlobalConfig Global ] e => App e String
getExpectedOutput = do
  d <- map replicaDir $ get GlobalConfig
  t <- getSingleTestDir
  pure $ t </> defaultExpected

export
getExpectedFile : Has
  [ State CurrentTest Test
  , State GlobalConfig Global ] e => App e String
getExpectedFile = do
  d <- map replicaDir $ get GlobalConfig
  t <- getSingleTestDir
  pure $ t </> defaultFile

export
getReplica :
  FileSystem (FSError :: e) =>
  Has [ State GlobalConfig Global
      , Exception ReplicaError ] e => App e Replica
getReplica = do
  ctx <- get GlobalConfig
  let f = ctx.file
  content <- handle (readFile f)
                    pure
                    (\err : FSError => throw $ CantAccessTestFile f)
  let Just json = parse content
        | Nothing => throw $ InvalidJSON []
  let Valid repl = jsonToReplica json
        | Error xs => throw $ InvalidJSON xs
  pure repl

export
when : Bool -> App e () -> App e ()
when cond x = if cond then x else pure ()

export
catchNew : App (err :: e) a -> (err -> App e a) -> App e a
catchNew x f = handle x pure (\er : err => f er)

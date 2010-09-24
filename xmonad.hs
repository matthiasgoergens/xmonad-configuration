import XMonad hiding (Tall)
import qualified XMonad as X
import XMonad.Config.Gnome
import System.Exit
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run
import XMonad.Layout.NoBorders

import qualified XMonad.StackSet as W
import qualified Data.Map        as M

-- For additionalKeysP,
-- but that does not seem to work with AudioRaiseVolume and LowerVolume (yet?)
import XMonad.Util.EZConfig

import XMonad.Layout.HintedGrid
import XMonad.Layout.Tabbed
import XMonad.Layout.Accordion
import XMonad.Layout.MosaicAlt
import XMonad.Layout.HintedTile
import XMonad.Layout.Spiral

defaults = defaultConfig
           { terminal           = "gnome-terminal"
           , logHook = updatePointer (Relative 0.5 0.5)  -- $ defaultPP { ppOutput = hPutStrLn h }
           , manageHook  = myManageHook
           , layoutHook = noBorders Full
                          ||| smartBorders
                          (MosaicAlt M.empty
                           ||| Mirror (MosaicAlt M.empty)
                           ||| noBorders (tabbed shrinkText defaultTheme)
--                           ||| Mirror (spiral (6/7))
--                           ||| tiled ||| Mirror tiled
                          )
             
-- smartBorders $ layoutHook defaultConfig
           , modMask = mod4Mask
           }
           `additionalKeysP`
           [ ("<XF86AudioRaiseVolume>", spawn "setxkbmap dvorak")
           , ("<XF86AudioLowerVolume>", spawn "setxkbmap de")
           ]
    -- default tiling algorithm partitions the screen into two panes
    -- The default number of windows in the master pane
    where tiled   = X.Tall nmaster delta ratio 
          nmaster    = 1
          ratio      = 1/2
          delta      = 3/100


-- Define the workspace an application has to go to
myManageHook = (className =? "rdesktop" --> doF (W.shift "6")) <+> manageHook defaultConfig
               -- composeAll . concat $
--            [  -- The applications that float
            --   [ className =? i --> doFloat | i <- myClassFloats]
--              [
--            ]
--		where
--		  myClassFloats	      = ["xvncviewer"]




main = do
  spawn "setxkbmap -option terminate:ctrl_alt_bksp"
  xmonad $ defaults

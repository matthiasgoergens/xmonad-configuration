-- import XMonad.Util.Run

import Data.Default (def)
import Data.Map qualified as M
import XMonad
import XMonad qualified as X
-- For additionalKeysP,
-- but that does not seem to work with AudioRaiseVolume and LowerVolume (yet?)

-- import XMonad.Layout.Accordion

-- import XMonad.Layout.HintedTile hiding (Tall)
-- import XMonad.Layout.Spiral
import XMonad.Actions.SinkAll (sinkAll)
import XMonad.Actions.UpdatePointer (updatePointer)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Layout.HintedGrid
import XMonad.Layout.MosaicAlt
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.Tabbed
import XMonad.StackSet qualified as W
import XMonad.Util.EZConfig
import XMonad.Util.Hacks (fixSteamFlicker)

-- import XMonad.Actions.WithAll

modm = mod4Mask

-- modm = XMonad.modMask

myLayout = noBorders Full ||| MosaicAlt M.empty ||| noBorders (tabbed shrinkText def) ||| tiled ||| Mirror tiled
  where
    tiled = Tall nmaster delta ratio
    nmaster = 1
    ratio = 1 / 2
    delta = 3 / 100

-- smartBorders (layoutHook defaultConfig)

--                           noBorders Full
--                           ||| smartBorders
--                           (MosaicAlt M.empty
--                            ||| Mirror (MosaicAlt M.empty)
--                            ||| noBorders (tabbed shrinkText defaultTheme)
-- --                           ||| Mirror (spiral (6/7))
-- --                           ||| tiled ||| Mirror tiled
--                           )

-- smartBorders $ layoutHook defaulConfig

defaults =
  def
    { terminal = "terminator",
      -- In xmonad focus follows mouse, this line also makes mouse follow focus:
      logHook = updatePointer (0.5, 0.5) (0, 0), -- (Relative 0.5 0.5)
      manageHook = myManageHook,
      layoutHook = myLayout,
      -- make mod := left Windows key
      modMask = mod4Mask,
      keys = newKeys,
      handleEventHook =
        fixSteamFlicker
        -- handleEventHook def <+> ewmhFullscreen
    }
  where
    -- default tiling algorithm partitions the screen into two panes
    -- The default number of windows in the master pane
    tiled = X.Tall nmaster delta ratio
    nmaster = 1
    ratio = 1 / 2
    delta = 3 / 100

-- pushes all floating windows back into tiling with mod-shift-t:
myKeys conf@XConfig {XMonad.modMask = modm} =
  [((modm .|. shiftMask, xK_t), sinkAll)]

newKeys x = M.union (keys def x) (M.fromList (myKeys x))

-- Define the workspace an application has to go to
myManageHook = (className =? "rdesktop" --> doF (W.shift "6")) <+> manageHook def

-- composeAll . concat $
--            [  -- The applications that float
--   [ className =? i --> doFloat | i <- myClassFloats]
--              [
--            ]
-- 		where
-- 		  myClassFloats	      = ["xvncviewer"]

-- main = xmonad . ewmh =<< statusBar myBar myPP toggleStrutsKey defaults

main = do
  spawn "setxkbmap -option terminate:ctrl_alt_bksp"
  xmonad $ ewmhFullscreen . ewmh $ defaults

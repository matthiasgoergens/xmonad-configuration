import XMonad
import qualified XMonad as X
import XMonad.Actions.UpdatePointer ( updatePointer )
import XMonad.Hooks.DynamicLog
import XMonad.Layout.NoBorders ( noBorders )
import XMonad.Util.Run         (spawnPipe, safeSpawn, runProcessWithInput) 

import qualified XMonad.StackSet as W
import qualified Data.Map        as M
import Data.Default (def)

-- For additionalKeysP,
-- but that does not seem to work with AudioRaiseVolume and LowerVolume (yet?)
import XMonad.Util.EZConfig

import XMonad.Layout.HintedGrid
import XMonad.Layout.Tabbed
import XMonad.Layout.MosaicAlt
import XMonad.Actions.WithAll (sinkAll)

import XMonad.Hooks.EwmhDesktops
import XMonad.Util.Hacks (fixSteamFlicker)


modm = mod4Mask


myLayout = noBorders Full ||| MosaicAlt M.empty ||| noBorders (tabbed shrinkText def) ||| tiled ||| Mirror tiled 
  where tiled = Tall nmaster delta ratio
        nmaster = 1
        ratio = 1/2
        delta = 3/100

defaults = def
           { terminal           = "terminator"
           -- In xmonad focus follows mouse, this line also makes mouse follow focus:
           , logHook = updatePointer (0.5, 0.5) (0, 0) -- (Relative 0.5 0.5)
           , manageHook  = myManageHook
           , layoutHook = myLayout

          -- make mod := left Windows key
           , modMask = mod4Mask
           , keys = newKeys
           , handleEventHook =
            fixSteamFlicker
              -- handleEventHook def <+> ewmhFullscreen 
           }
    -- default tiling algorithm partitions the screen into two panes
    -- The default number of windows in the master pane
    where tiled   = X.Tall nmaster delta ratio 
          nmaster    = 1
          ratio      = 1/2
          delta      = 3/100

-- pushes all floating windows back into tiling with mod-shift-t:
myKeys conf@XConfig {XMonad.modMask = modm} =
    [((modm .|. shiftMask, xK_t), sinkAll)
    , ((modm, xK_s), showCenteredWorkspacePopup)
    ]
newKeys x  = M.union (keys def x) (M.fromList (myKeys x))

-- Define the workspace an application has to go to
myManageHook = (className =? "rdesktop" --> doF (W.shift "6")) <+> manageHook def

main = do
  spawn "setxkbmap -option terminate:ctrl_alt_bksp"
  xmonad $ ewmhFullscreen . ewmh $ defaults

showCenteredWorkspacePopup :: X ()
showCenteredWorkspacePopup = do
    -- 1. Create a 'PP' for how you want to format workspace info
    let pp = def
             { ppCurrent         = wrap "[" "]"
             , ppVisible         = id
             , ppHidden          = id
             , ppHiddenNoWindows = id
             , ppTitle           = const ""   -- Don't show window titles
             , ppSep             = " "
             }

    -- 2. Grab the current workspace info string
    wsString <- dynamicLogString pp

    -- 3. Get screen geometry from XMonad
    winset   <- gets windowset
    let screenDetail = W.screenDetail (W.current winset)
        rect         = screenRect screenDetail
        scrX         = fromIntegral (rect_x rect)
        scrY         = fromIntegral (rect_y rect)
        scrW         = fromIntegral (rect_width rect)
        scrH         = fromIntegral (rect_height rect)

    -- 4. Desired dzen2 window width/height
    let popupWidth   = 400
        popupHeight  = 50
        displayTime  = 2      -- seconds to remain visible

    -- 5. Calculate the centered coordinates
    let xPos = scrX + (scrW `div` 2) - (popupWidth  `div` 2)
        yPos = scrY + (scrH `div` 2) - (popupHeight `div` 2)

    -- 6. Spawn dzen2 in the center
    -- Using safeSpawn (from XMonad.Util.Run)
    safeSpawn "bash"
      [ "-c"
      , unwords
          [ "echo '" ++ wsString ++ "' |"
          , "dzen2"
            ++ " -p " ++ show displayTime
            ++ " -x " ++ show xPos
            ++ " -y " ++ show yPos
            ++ " -w " ++ show popupWidth
            ++ " -h " ++ show popupHeight
            ++ " -fn 'Monospace-9'"
            ++ " -bg '#222222' -fg '#ffffff'"
          ]
      ]

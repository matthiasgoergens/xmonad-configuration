import XMonad
import XMonad.Config.Gnome
import System.Exit
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run
import XMonad.Layout.NoBorders
 
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
 
myTerminal      = "gnome-terminal"
myModMask       = mod5Mask
 
defaults = defaultConfig
           -- simple stuff
           { terminal           = myTerminal
--           , modMask            = myModMask
           , logHook = updatePointer (Relative 0.5 0.5)  -- $ defaultPP { ppOutput = hPutStrLn h }
--           , manageHook  = myManageHook
           , layoutHook = smartBorders $ layoutHook defaultConfig
           , modMask = mod4Mask
           }

-- Define the workspace an application has to go to
myManageHook = composeAll . concat $
            [  -- The applications that float
               [ className =? i --> doFloat | i <- myClassFloats]
            ]
		where
		  myClassFloats	      = ["xvncviewer"]



main = do
  xmonad $ defaults

 

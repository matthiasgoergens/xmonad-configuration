import XMonad
import XMonad.Config.Gnome
import System.Exit
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run
 
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
 
myTerminal      = "gnome-terminal"
myModMask       = mod5Mask
 
defaults = defaultConfig
           -- simple stuff
           { terminal           = myTerminal
--           , modMask            = myModMask
--           , logHook = updatePointer (Relative 0.5 0.5)
           , logHook = updatePointer (Relative 0.5 0.5)  -- $ defaultPP { ppOutput = hPutStrLn h }
           }


-- myLogHook = dynamicLogWithPP .... 

-- logHook = 

-- main = dzen $ \conf -> xmonad $ conf defaults


--main = xmonad defaults

main = do
--  spawn "beep"

  xmonad $ defaults

--  h <- spawnPipe "xmobar -options -foo -bar"

-- myKeys x -- conf@(XConfig {XMonad.modMask = modMask, workspaces = ws})
--     = M.fromList $
--       [-- ((modMask x, xK_1), spawn "setxkbmap dvorak")
-- --      , ((modMask x, xK_2), spawn "setxkbmap de")
--        ((modMask x, xK_F2), spawn "beep")
--       , ((modMask x, xK_F3), spawn "gedit")
-- --      , ((0, xK_F2  ), spawn "beep") -- %! Launch gnome-terminal

--       ]





import XMonad
import XMonad.Config.Gnome
import System.Exit
 
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
 
myTerminal      = "gnome-terminal"
myModMask       = mod4Mask
 
defaults = defaultConfig
           -- simple stuff
           { terminal           = myTerminal
           , modMask            = myModMask
           }

main = xmonad defaults

-- myKeys x -- conf@(XConfig {XMonad.modMask = modMask, workspaces = ws})
--     = M.fromList $
--       [-- ((modMask x, xK_1), spawn "setxkbmap dvorak")
-- --      , ((modMask x, xK_2), spawn "setxkbmap de")
--        ((modMask x, xK_F2), spawn "beep")
--       , ((modMask x, xK_F3), spawn "gedit")
-- --      , ((0, xK_F2  ), spawn "beep") -- %! Launch gnome-terminal

--       ]


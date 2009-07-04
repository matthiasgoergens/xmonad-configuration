-- import XMonad
 
-- main = xmonad defaultConfig

--
-- xmonad example config file.
--
-- A template showing all available configuration hooks,
-- and how to override the defaults in your own xmonad.hs conf file.
--
-- Normally, you'd only override those defaults you care about.
--
 
import XMonad
import System.Exit
 
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
 
-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal      = "gnome-terminal"
 
-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--

myModMask       = mod4Mask
 

 
------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.
 
-- Run xmonad with the settings you specify. No need to modify this.
--
main = xmonad defaults
 
-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will 
-- use the defaults defined in xmonad/XMonad/Config.hs
-- 
-- No need to modify this.
--
defaults = defaultConfig
           -- simple stuff
           { terminal           = myTerminal
           , modMask            = myModMask
           }

myKeys x -- conf@(XConfig {XMonad.modMask = modMask, workspaces = ws})
    = M.fromList $
      [-- ((modMask x, xK_1), spawn "setxkbmap dvorak")
--      , ((modMask x, xK_2), spawn "setxkbmap de")
       ((modMask x, xK_F2), spawn "beep")
      , ((modMask x, xK_F3), spawn "gedit")
--      , ((0, xK_F2  ), spawn "beep") -- %! Launch gnome-terminal

      ]


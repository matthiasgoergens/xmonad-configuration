import Data.Default (def)
import Data.Foldable
import Data.Function (on)
import Data.List (groupBy, sortOn)
import Data.Map qualified as M
import XMonad
import XMonad qualified as X
import XMonad.Actions.Navigation2D (screenGo, windowToScreen)
import XMonad.Actions.UpdatePointer (updatePointer)
import XMonad.Actions.Warp (warpToScreen, warpToWindow)
-- For additionalKeysP,
-- but that does not seem to work with AudioRaiseVolume and LowerVolume (yet?)

import XMonad.Actions.WithAll (sinkAll)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Layout.HintedGrid
import XMonad.Layout.MosaicAlt
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.Tabbed
import XMonad.StackSet qualified as W
import XMonad.Util.EZConfig
import XMonad.Util.Hacks (fixSteamFlicker)
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.Types (Direction2D (..))

modm = mod4Mask

myLayout = noBorders Full ||| MosaicAlt M.empty ||| noBorders (tabbed shrinkText def) ||| tiled ||| Mirror tiled
  where
    tiled = Tall nmaster delta ratio
    nmaster = 1
    ratio = 1 / 2
    delta = 3 / 100

defaults =
  def
    { terminal = "terminator",
      -- In xmonad focus follows mouse, this line also makes mouse follow focus:
      logHook = updatePointer (0.5, 0.5) (0, 0), -- (Relative 0.5 0.5)
      -- Pass the click that focuses a window on to it, instead of swallowing it:
      clickJustFocuses = False,
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
  [ ((modm .|. shiftMask, xK_t), sinkAll),
    ((modm, xK_s), showAllScreensPopup),
    -- Focus the monitor to the left/right/above/below, with the pointer on the window
    -- focused there (the one mod-w/e/r would pick):
    ((modm, xK_Left), screenGo L False >> warpToFocus),
    ((modm, xK_Right), screenGo R False >> warpToFocus),
    ((modm, xK_Up), screenGo U False >> warpToFocus),
    ((modm, xK_Down), screenGo D False >> warpToFocus),
    -- Move the focused window to the monitor in that direction; focus and pointer follow it:
    ((modm .|. shiftMask, xK_Left), moveWindowToScreen L),
    ((modm .|. shiftMask, xK_Right), moveWindowToScreen R),
    ((modm .|. shiftMask, xK_Up), moveWindowToScreen U),
    ((modm .|. shiftMask, xK_Down), moveWindowToScreen D),
    -- Move the workspaces up/down within each column of monitors (with two rows, both
    -- swap the rows), or one monitor clockwise (left) / counter-clockwise (right):
    ((modm .|. controlMask, xK_Up), shuffleScreens (inColumns (-1))),
    ((modm .|. controlMask, xK_Down), shuffleScreens (inColumns 1)),
    ((modm .|. controlMask, xK_Left), shuffleScreens (aroundRing 1)),
    ((modm .|. controlMask, xK_Right), shuffleScreens (aroundRing (-1))),
    -- Re-apply the monitor layout (see ~/.local/bin/screen-layout), wait for it, then have
    -- xmonad reread the screens: it notices changes by itself only when the size of the
    -- whole X screen changes, not when a monitor moves or is rescaled within it.
    ((modm .|. shiftMask, xK_s), runProcessWithInput "screen-layout" [] "" >> rescreen),
    -- Lock the screen (xss-lock.service hands it to xsecurelock):
    ((modm .|. shiftMask, xK_l), spawn "loginctl lock-session"),
    -- Screenshots (saved under ~/Desktop/screenshot, see ~/.local/bin/screenshot):
    ((noModMask, xK_Print), spawn "~/.local/bin/screenshot window"),
    ((shiftMask, xK_Print), spawn "~/.local/bin/screenshot select"),
    ((controlMask, xK_Print), spawn "~/.local/bin/screenshot full")
  ]

newKeys x = M.union (keys def x) (M.fromList (myKeys x))

-- Send the focused window to the monitor next to the current one in the given
-- direction, then focus that monitor: the window arrives focused, with the
-- pointer on it.
moveWindowToScreen :: Direction2D -> X ()
moveWindowToScreen dir = do
  windowToScreen dir False
  screenGo dir False
  warpToFocus

-- Put the pointer in the middle of the focused window, or of the current screen
-- if it has no windows.  updatePointer in the logHook does not do it after a
-- change of screen: it leaves the pointer alone while it is over a window of
-- another screen's workspace.
warpToFocus :: X ()
warpToFocus = do
  ws <- gets windowset
  case W.peek ws of
    Just _ -> warpToWindow 0.5 0.5
    Nothing -> warpToScreen (W.screen (W.current ws)) 0.5 0.5

type WScreen = W.Screen WorkspaceId (Layout Window) Window ScreenId ScreenDetail

-- Move workspaces between monitors.  The plan maps each screen to the screen whose
-- workspace it should show (screens it leaves out keep theirs).  The focused
-- workspace keeps the focus wherever it lands, and the pointer follows it.
shuffleScreens :: ([WScreen] -> M.Map ScreenId ScreenId) -> X ()
shuffleScreens plan = (>> warpToFocus) . windows $ \ws ->
  let scrs = W.current ws : W.visible ws
      from = plan scrs
      onScreen = M.fromList [(W.screen s, W.workspace s) | s <- scrs]
      source s = M.findWithDefault (W.screen s) (W.screen s) from
      moved = [s {W.workspace = M.findWithDefault (W.workspace s) (source s) onScreen} | s <- scrs]
      focused = W.currentTag ws
   in case break ((== focused) . W.tag . W.workspace) moved of
        (before, cur : after) -> ws {W.current = cur, W.visible = before ++ after}
        _ -> ws

-- Each screen in the list takes the workspace of the screen k places before it
-- (cyclically), so the workspaces move k places along the list.
takeFrom :: Int -> [ScreenId] -> M.Map ScreenId ScreenId
takeFrom _ [] = M.empty
takeFrom k xs = M.fromList (zip xs (drop (negate k `mod` length xs) (cycle xs)))

screenRectOf :: WScreen -> Rectangle
screenRectOf = screenRect . W.screenDetail

-- Columns are the screens sharing a left edge, ordered top to bottom; the
-- workspaces move k places down each column (negative k: up).
inColumns :: Int -> [WScreen] -> M.Map ScreenId ScreenId
inColumns k scrs =
  M.unions
    [ takeFrom k (map W.screen (sortOn (rect_y . screenRectOf) column))
      | column <- groupBy ((==) `on` (rect_x . screenRectOf)) (sortOn (rect_x . screenRectOf) scrs)
    ]

-- The ring orders screens clockwise by the angle of their centre around the
-- mean of all centres; the workspaces move k places clockwise (negative k:
-- counter-clockwise).
aroundRing :: Int -> [WScreen] -> M.Map ScreenId ScreenId
aroundRing k scrs = takeFrom k (map W.screen (sortOn angle scrs))
  where
    centre s = let Rectangle x y w h = screenRectOf s in (fromIntegral x + fromIntegral w / 2, fromIntegral y + fromIntegral h / 2) :: (Double, Double)
    n = fromIntegral (length scrs)
    cx = sum (map (fst . centre) scrs) / n
    cy = sum (map (snd . centre) scrs) / n
    -- y grows downwards, so increasing atan2 runs clockwise on the screen
    angle s = let (x, y) = centre s in atan2 (y - cy) (x - cx)

main = do
  spawn "setxkbmap -option terminate:ctrl_alt_bksp"
  xmonad $ ewmhFullscreen . ewmh $ defaults

showAllScreensPopup :: X ()
showAllScreensPopup = do
  -- 1. Create a 'PP' for how you want to format workspace info
  let pp =
        def
          { ppCurrent = wrap "[" "]",
            ppVisible = id,
            ppHidden = const "",
            ppHiddenNoWindows = const ""
            -- ppTitle = const "", -- Don't show window titles
            -- ppSep = " "
          }
  -- 2. Grab the current workspace info string
  wsString <- dynamicLogString pp

  -- 3. Get screen geometry from XMonad
  winset <- gets windowset

  -- For each screen in W.screens, spawn a dzen2 in the center
  forM_ (W.screens winset) $ \scr -> do
    let scrRect = screenRect (W.screenDetail scr)
        scrX = fromIntegral $ rect_x scrRect
        scrY = fromIntegral $ rect_y scrRect
        scrW = fromIntegral $ rect_width scrRect
        scrH = fromIntegral $ rect_height scrRect
        S id_ = W.screen scr
        w = W.tag $ W.workspace scr

    -- 4. Desired dzen2 window width/height
    let popupWidth = 100
        popupHeight = 50
        displayTime = 2 -- seconds to remain visible

    -- 5. Calculate the centered coordinates
    let xPos = scrX + (scrW `div` 2) - (popupWidth `div` 2)
        yPos = scrY + (scrH `div` 2) - (popupHeight `div` 2)

    -- 6. Spawn dzen2 in the center
    safeSpawn
      "bash"
      [ "-c",
        unwords
          -- [ "echo '" ++ show id_ ++ "$" ++ w ++ "' |",
          [ "echo '" ++ w ++ "' |",
            "dzen2"
              -- ++ "-xs" ++ show id_
              ++ " -p "
              ++ show displayTime
              ++ " -x "
              ++ show xPos
              ++ " -y "
              ++ show yPos
              ++ " -w "
              ++ show popupWidth
              ++ " -h "
              ++ show popupHeight
              ++ " -fn 'Monospace-30'"
              ++ " -bg '#222222' -fg '#ffffff'"
          ]
      ]

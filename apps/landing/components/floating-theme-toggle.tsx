"use client"

import * as React from "react"
import { Moon, Sun } from "lucide-react"
import { useTheme } from "next-themes"

const subscribe = () => () => undefined
const getClientSnapshot = () => true
const getServerSnapshot = () => false

export function FloatingThemeToggle() {
  const mounted = React.useSyncExternalStore(
    subscribe,
    getClientSnapshot,
    getServerSnapshot
  )
  const { resolvedTheme, setTheme } = useTheme()

  if (!mounted) {
    return null
  }

  const isDark = resolvedTheme === "dark"

  return (
    <button
      type="button"
      onClick={() => setTheme(isDark ? "light" : "dark")}
      aria-label={`Switch to ${isDark ? "light" : "dark"} theme`}
      title={`Switch to ${isDark ? "light" : "dark"} theme`}
      className="fixed right-5 bottom-5 z-50 grid size-11 place-items-center rounded-full border border-border bg-card/90 text-foreground shadow-lg backdrop-blur transition-transform hover:scale-105 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
    >
      {isDark ? (
        <Sun aria-hidden="true" className="size-4.5" />
      ) : (
        <Moon aria-hidden="true" className="size-4.5" />
      )}
    </button>
  )
}

"use client"

import * as React from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { useTheme } from "next-themes"
import {
  Activity,
  ChevronDown,
  CircleDot,
  FilePlus2,
  Files,
  LayoutDashboard,
  Moon,
  Sun,
} from "lucide-react"

import { Logo } from "@/components/logo"
import { Address, CleanverseStatus } from "@/components/receivable-primitives"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Popover, PopoverPopup, PopoverTrigger } from "@/components/ui/popover"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarRail,
  SidebarSeparator,
  SidebarTrigger,
  useSidebar,
} from "@/components/ui/sidebar"
import { Switch } from "@/components/ui/switch"
import { ToastProvider } from "@/components/ui/toast"

const NAVIGATION = [
  { href: "/app", label: "Overview", icon: LayoutDashboard, exact: true },
  {
    href: "/app/receivables",
    label: "Receivables",
    icon: Files,
    exact: false,
  },
  {
    href: "/app/receivables/new",
    label: "Create receivable",
    icon: FilePlus2,
    exact: true,
  },
  { href: "/app/activity", label: "Activity", icon: Activity, exact: false },
] as const

const subscribe = () => () => undefined
const getClientSnapshot = () => true
const getServerSnapshot = () => false

export function WalletMenu() {
  const mounted = React.useSyncExternalStore(
    subscribe,
    getClientSnapshot,
    getServerSnapshot
  )
  const { resolvedTheme, setTheme } = useTheme()
  const isDark = mounted && resolvedTheme === "dark"

  return (
    <Popover>
      <PopoverTrigger
        render={
          <Button
            variant="ghost"
            className="h-auto gap-2 px-2 py-1.5 text-left"
          />
        }
      >
        <Avatar className="size-7 border">
          <AvatarFallback>VS</AvatarFallback>
        </Avatar>
        <div className="hidden sm:block">
          <p className="text-xs font-medium">Base Sepolia</p>
          <Address value="0x128…91A" className="text-muted-foreground" />
        </div>
        <ChevronDown
          className="size-3.5 text-muted-foreground"
          aria-hidden="true"
        />
      </PopoverTrigger>
      <PopoverPopup align="end" className="w-64" sideOffset={8}>
        <div className="space-y-4">
          <div>
            <p className="text-sm font-medium">Connected account</p>
            <Address
              value="0x128B7c92…f91A"
              className="mt-1 block text-muted-foreground"
            />
          </div>
          <div className="flex items-center justify-between border-t pt-4">
            <div className="flex items-center gap-2 text-sm">
              {isDark ? (
                <Moon className="size-4" />
              ) : (
                <Sun className="size-4" />
              )}
              Dark mode
            </div>
            <Switch
              checked={isDark}
              onCheckedChange={(checked) =>
                setTheme(checked ? "dark" : "light")
              }
              aria-label="Toggle dark mode"
            />
          </div>
        </div>
      </PopoverPopup>
    </Popover>
  )
}

export function AppSidebar() {
  const pathname = usePathname()
  const { setOpenMobile } = useSidebar()

  return (
    <Sidebar collapsible="offcanvas" className="border-r border-sidebar-border">
      <SidebarHeader className="px-4 py-5">
        <Link href="/app" onClick={() => setOpenMobile(false)}>
          <Logo mono className="text-sidebar-accent-foreground" />
        </Link>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup className="px-3">
          <SidebarGroupContent>
            <SidebarMenu>
              {NAVIGATION.map((item) => {
                const active =
                  item.href === "/app/receivables"
                    ? pathname === item.href ||
                      (pathname.startsWith(`${item.href}/`) &&
                        pathname !== "/app/receivables/new")
                    : item.exact
                      ? pathname === item.href
                      : pathname === item.href ||
                        pathname.startsWith(`${item.href}/`)
                const Icon = item.icon

                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton
                      isActive={active}
                      tooltip={item.label}
                      render={
                        <Link
                          href={item.href}
                          onClick={() => setOpenMobile(false)}
                        />
                      }
                    >
                      <Icon aria-hidden="true" />
                      <span>{item.label}</span>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                )
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter className="gap-3 p-3">
        <SidebarSeparator className="mx-0" />
        <div className="space-y-1 px-2 py-1 text-xs">
          <p className="text-sidebar-foreground/60">Network</p>
          <p className="flex items-center gap-2 font-medium text-sidebar-accent-foreground">
            <CircleDot className="size-3 text-success" aria-hidden="true" />
            Base Sepolia
          </p>
        </div>
        <div className="rounded-lg bg-sidebar-accent p-2.5">
          <div className="mb-2 flex items-center justify-between gap-2">
            <span className="text-xs text-sidebar-foreground/60">Account</span>
            <CleanverseStatus />
          </div>
          <Address
            value="0x128…91A"
            className="text-sidebar-accent-foreground"
          />
        </div>
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  )
}

export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <ToastProvider position="bottom-right">
      <SidebarProvider
        style={{ "--sidebar-width": "14.5rem" } as React.CSSProperties}
      >
        <AppSidebar />
        <SidebarInset>
          <div className="sticky top-0 z-30 flex h-14 items-center justify-between border-b bg-background/95 px-4 backdrop-blur md:px-8">
            <div className="flex items-center gap-3">
              <SidebarTrigger className="md:hidden" />
              <Badge variant="outline" className="hidden sm:inline-flex">
                Demo mode
              </Badge>
            </div>
            <WalletMenu />
          </div>
          <div className="mx-auto w-full max-w-[1240px] flex-1 px-4 py-8 md:px-8 md:py-10">
            {children}
          </div>
        </SidebarInset>
      </SidebarProvider>
    </ToastProvider>
  )
}

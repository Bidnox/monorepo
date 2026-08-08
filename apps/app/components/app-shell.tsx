"use client"

import * as React from "react"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { useTheme } from "next-themes"
import {
  Activity,
  Factory,
  Files,
  Landmark,
  LayoutDashboard,
  LogOut,
  Moon,
  PlugZap,
  Sun,
} from "lucide-react"
import { useDisconnect } from "wagmi"

import { Logo } from "@/components/logo"
import {
  type AppRole,
  RoleOnboarding,
} from "@/components/role-onboarding"
import {
  CleanverseStatus,
  CopyableAddress,
} from "@/components/receivable-primitives"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
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
import { baseSepolia } from "@/lib/wagmi"

const NAVIGATION = {
  supplier: [
    { href: "/", label: "Overview", icon: LayoutDashboard, exact: true },
    {
      href: "/receivables",
      label: "Receivables",
      icon: Files,
      exact: false,
    },
    { href: "/activity", label: "Activity", icon: Activity, exact: false },
  ],
  financier: [
    { href: "/", label: "Overview", icon: LayoutDashboard, exact: true },
    {
      href: "/receivables",
      label: "Opportunities",
      icon: Files,
      exact: false,
    },
    { href: "/activity", label: "Activity", icon: Activity, exact: false },
  ],
} as const

const subscribe = () => () => undefined
const getClientSnapshot = () => true
const getServerSnapshot = () => false

function shortAddress(address: string) {
  return `${address.slice(0, 6)}…${address.slice(-4)}`
}

export function AppSidebar({
  walletAddress,
  role,
  wrongNetwork,
  onConnect,
  onSwitchNetwork,
  onDisconnect,
}: {
  walletAddress: string | null
  role: AppRole | null
  wrongNetwork: boolean
  onConnect: () => void
  onSwitchNetwork: () => void
  onDisconnect: () => void
}) {
  const pathname = usePathname()
  const { setOpenMobile } = useSidebar()
  const mounted = React.useSyncExternalStore(
    subscribe,
    getClientSnapshot,
    getServerSnapshot
  )
  const { resolvedTheme, setTheme } = useTheme()
  const isDark = mounted && resolvedTheme === "dark"

  return (
    <Sidebar collapsible="offcanvas" className="border-r border-sidebar-border">
      <SidebarHeader className="px-4 py-5">
        <Link href="/" onClick={() => setOpenMobile(false)}>
          <Logo mono className="text-sidebar-accent-foreground" />
        </Link>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup className="px-3">
          <SidebarGroupContent>
            <SidebarMenu>
              {(role ? NAVIGATION[role] : NAVIGATION.supplier).map((item) => {
                const active =
                  item.href === "/receivables"
                    ? pathname === item.href || pathname.startsWith(`${item.href}/`)
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
        <div className="rounded-lg bg-sidebar-accent p-2.5">
          {walletAddress ? (
            <>
              <div className="mb-2 flex items-center justify-between gap-2">
                <span className="text-xs text-sidebar-foreground/60">
                  Account
                </span>
                {wrongNetwork ? (
                  <span className="text-xs text-warning-foreground">
                    Wrong network
                  </span>
                ) : (
                  <CleanverseStatus />
                )}
              </div>
              <div className="flex items-center gap-2">
                <Avatar className="size-7 border border-sidebar-border">
                  <AvatarImage
                    src="/avatars/vivek.svg"
                    alt="Wallet avatar"
                    draggable={false}
                  />
                  <AvatarFallback>WA</AvatarFallback>
                </Avatar>
                <CopyableAddress
                  value={walletAddress}
                  display={shortAddress(walletAddress)}
                />
              </div>
              {wrongNetwork ? (
                <Button
                  variant="secondary"
                  size="xs"
                  className="mt-3 w-full"
                  onClick={onSwitchNetwork}
                >
                  Switch network
                </Button>
              ) : null}
            </>
          ) : (
            <Button size="sm" className="w-full" onClick={onConnect}>
              Connect wallet
            </Button>
          )}
          <div className="mt-3 flex items-center justify-between border-t border-sidebar-border pt-3">
            <div className="flex items-center gap-2 text-xs text-sidebar-accent-foreground">
              {isDark ? (
                <Moon className="size-3.5" />
              ) : (
                <Sun className="size-3.5" />
              )}
              Theme
            </div>
            <Switch
              checked={isDark}
              onCheckedChange={(checked) =>
                setTheme(checked ? "dark" : "light")
              }
              aria-label="Toggle dark mode"
            />
          </div>
          {walletAddress ? (
            <Button
              variant="ghost"
              size="xs"
              className="mt-2 w-full justify-start"
              onClick={onDisconnect}
            >
              <LogOut />
              Disconnect
            </Button>
          ) : null}
        </div>
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  )
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const { disconnect } = useDisconnect()

  return (
    <ToastProvider position="bottom-right">
      <ConnectButton.Custom>
        {({
          account,
          chain,
          mounted,
          openConnectModal,
          openChainModal,
        }) => {
          const connected = Boolean(mounted && account && chain)
          const wrongNetwork = Boolean(
            connected &&
              (chain?.unsupported || chain?.id !== baseSepolia.id)
          )
          return (
            <AppExperience
              mounted={mounted}
              walletAddress={connected ? (account?.address ?? null) : null}
              wrongNetwork={wrongNetwork}
              onConnect={() => openConnectModal?.()}
              onSwitchNetwork={() => openChainModal?.()}
              onDisconnect={() => disconnect()}
            >
              {children}
            </AppExperience>
          )
        }}
      </ConnectButton.Custom>
    </ToastProvider>
  )
}

function AppExperience({
  children,
  mounted,
  walletAddress,
  wrongNetwork,
  onConnect,
  onSwitchNetwork,
  onDisconnect,
}: {
  children: React.ReactNode
  mounted: boolean
  walletAddress: string | null
  wrongNetwork: boolean
  onConnect: () => void
  onSwitchNetwork: () => void
  onDisconnect: () => void
}) {
  const [selection, setSelection] = React.useState<{
    wallet: string
    role: AppRole | null
  } | null>(null)

  React.useEffect(() => {
    if (!walletAddress) return

    const wallet = walletAddress.toLowerCase()
    const roleTimer = window.setTimeout(() => {
      const savedRole = window.localStorage.getItem(`bidnox-role:${wallet}`)
      setSelection({
        wallet,
        role:
          savedRole === "supplier" || savedRole === "financier"
            ? savedRole
            : null,
      })
    }, 0)

    return () => window.clearTimeout(roleTimer)
  }, [walletAddress])

  const walletKey = walletAddress?.toLowerCase() ?? null
  const roleReady = !walletKey || selection?.wallet === walletKey
  const role = roleReady ? (selection?.role ?? null) : null
  const RoleIcon = role === "supplier" ? Factory : Landmark

  function selectRole(nextRole: AppRole) {
    if (!walletKey) return
    window.localStorage.setItem(`bidnox-role:${walletKey}`, nextRole)
    setSelection({ wallet: walletKey, role: nextRole })
  }

  function changeRole() {
    if (!walletKey) return
    window.localStorage.removeItem(`bidnox-role:${walletKey}`)
    setSelection({ wallet: walletKey, role: null })
  }

  return (
    <SidebarProvider
      style={{ "--sidebar-width": "14.5rem" } as React.CSSProperties}
    >
      <AppSidebar
        walletAddress={walletAddress}
        role={role}
        wrongNetwork={wrongNetwork}
        onConnect={onConnect}
        onSwitchNetwork={onSwitchNetwork}
        onDisconnect={onDisconnect}
      />
      <SidebarInset>
        <div className="sticky top-0 z-30 flex h-12 items-center justify-between border-b bg-background/95 px-3 backdrop-blur md:h-14 md:px-8">
          <div className="md:hidden">
            <SidebarTrigger />
          </div>
          {role && walletAddress && !wrongNetwork ? (
            <Button
              variant="ghost"
              size="xs"
              className="ml-auto text-muted-foreground hover:text-foreground"
              onClick={changeRole}
            >
              <RoleIcon aria-hidden="true" />
              <span className="hidden sm:inline">
                Viewing as <span className="capitalize">{role}</span>
              </span>
              <span className="sr-only sm:hidden">
                Change {role} view
              </span>
            </Button>
          ) : null}
        </div>
        <div className="mx-auto w-full max-w-[1240px] flex-1 px-4 py-8 md:px-8 md:py-10">
          {!mounted ? null : !walletAddress ? (
            <WalletGate
              title="Connect your wallet"
              description="Connect to view receivables, place private bids, and manage settlements."
              action="Connect wallet"
              onAction={onConnect}
            />
          ) : wrongNetwork ? (
            <NetworkSwitchGate onAction={onSwitchNetwork} />
          ) : !roleReady ? null : !role ? (
            <RoleOnboarding onSelect={selectRole} />
          ) : (
            children
          )}
        </div>
      </SidebarInset>
    </SidebarProvider>
  )
}

function NetworkSwitchGate({ onAction }: { onAction: () => void }) {
  const opened = React.useRef(false)

  React.useEffect(() => {
    if (!opened.current) {
      opened.current = true
      onAction()
    }
  }, [onAction])

  return (
    <WalletGate
      title="Switch to Base Sepolia"
      description="Bidnox runs on Base Sepolia. Switch networks in your wallet to continue."
      action="Switch network"
      onAction={onAction}
    />
  )
}

function WalletGate({
  title,
  description,
  action,
  onAction,
}: {
  title: string
  description: string
  action: string
  onAction: () => void
}) {
  return (
    <div className="grid min-h-[calc(100dvh-8rem)] place-items-center">
      <div className="max-w-sm text-center">
        <div className="mx-auto mb-5 grid size-11 place-items-center rounded-xl border bg-muted/50">
          <PlugZap className="size-5" aria-hidden="true" />
        </div>
        <h1 className="text-xl font-medium tracking-tight">{title}</h1>
        <p className="mt-2 text-sm leading-6 text-muted-foreground">
          {description}
        </p>
        <Button className="mt-6" onClick={onAction}>
          {action}
        </Button>
      </div>
    </div>
  )
}

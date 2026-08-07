"use client"

import Image from "next/image"
import { ArrowRight } from "lucide-react"

export type AppRole = "supplier" | "financier"

const ROLES: Array<{
  role: AppRole
  title: string
  description: string
  image: string
  alt: string
}> = [
  {
    role: "supplier",
    title: "Supplier",
    description: "Turn confirmed invoices into working capital.",
    image: "/onboarding-supplier.jpg",
    alt: "Blank invoices organized inside a document folder",
  },
  {
    role: "financier",
    title: "Financier",
    description: "Discover receivables and place sealed private bids.",
    image: "/onboarding-financier.jpg",
    alt: "Sealed bid envelopes beside a blank invoice",
  },
]

export function RoleOnboarding({
  onSelect,
}: {
  onSelect: (role: AppRole) => void
}) {
  return (
    <div className="mx-auto flex min-h-[calc(100dvh-8rem)] max-w-4xl flex-col justify-center py-8">
      <div className="mb-7 text-center">
        <p className="text-xs font-medium text-muted-foreground">
          Welcome to Bidnox
        </p>
        <h1 className="mt-2 text-2xl font-medium tracking-tight sm:text-3xl">
          How do you want to use Bidnox?
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Choose a view for this wallet. You can switch at any time.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        {ROLES.map((item) => (
          <button
            key={item.role}
            type="button"
            onClick={() => onSelect(item.role)}
            className="group overflow-hidden rounded-2xl border bg-card text-left transition-colors hover:border-foreground/20 hover:bg-accent focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
          >
            <Image
              src={item.image}
              alt={item.alt}
              width={960}
              height={720}
              sizes="(max-width: 640px) calc(100vw - 32px), 420px"
              className="aspect-[4/3] w-full object-cover"
              draggable={false}
            />
            <div className="flex items-start justify-between gap-4 p-5">
              <div>
                <h2 className="font-medium">{item.title}</h2>
                <p className="mt-1 text-sm leading-6 text-muted-foreground">
                  {item.description}
                </p>
              </div>
              <ArrowRight
                className="mt-0.5 size-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5 group-hover:text-foreground"
                aria-hidden="true"
              />
            </div>
          </button>
        ))}
      </div>
    </div>
  )
}

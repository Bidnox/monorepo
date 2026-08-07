import type { Metadata } from "next"
import Image from "next/image"
import Link from "next/link"

import { Button } from "@/components/ui/button"

export const metadata: Metadata = {
  title: "Page not found | bidnox",
}

export default function NotFound() {
  return (
    <main className="grid min-h-[calc(100dvh-5rem)] place-items-center py-6">
      <div className="w-full max-w-md text-center">
        <div className="overflow-hidden rounded-xl border bg-muted">
          <Image
            src="/404-invoice.jpg"
            alt="A blank invoice misplaced beneath a document folder"
            width={1200}
            height={900}
            sizes="(max-width: 480px) calc(100vw - 40px), 448px"
            className="aspect-[4/3] w-full object-cover"
            draggable={false}
          />
        </div>

        <p className="mt-7 text-xs font-medium tracking-widest text-muted-foreground uppercase">
          Error 404
        </p>
        <h1 className="mt-2 text-2xl font-medium tracking-tight">
          This invoice is nowhere to be found.
        </h1>
        <p className="mx-auto mt-2 max-w-sm text-sm leading-6 text-muted-foreground">
          The page may have moved, or the link may no longer be valid.
        </p>

        <div className="mt-6 flex items-center justify-center gap-3">
          <Button render={<Link href="/" />}>Back to app</Button>
          <Button
            variant="secondary"
            render={<Link href="https://bidnox.xyz" />}
          >
            Visit website
          </Button>
        </div>
      </div>
    </main>
  )
}

import {
  faucetDemoRole,
  type DemoRole,
} from "../lib/server/cleanverse"

const roles = new Set<DemoRole>(["buyer", "seller", "financier"])
const role = process.argv[2] as DemoRole | undefined
const amount = process.argv[3] ?? "1"
const symbol = process.argv[4] === "usdc" ? "usdc" : "ausdc"

if (!role || !roles.has(role)) {
  throw new Error(
    "Usage: bun run cleanverse:faucet -- <buyer|seller|financier> [amount] [ausdc|usdc]"
  )
}

const response = await faucetDemoRole(role, amount, symbol)
if (response.code !== "0000") {
  throw new Error(
    `Cleanverse faucet failed (${response.code}): ${response.message}`
  )
}

console.log(
  JSON.stringify(
    {
      role,
      symbol,
      amount: response.data && response.data.amount,
      transactionHash: response.data && response.data.tx_hash,
    },
    null,
    2
  )
)

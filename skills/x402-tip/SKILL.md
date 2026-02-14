---
name: x402-tip
description: Create non-custodial USDC tip claim pages using x402. Use when someone asks to tip a person, create a tip link, send money via a claim page, or build a tip jar. Generates a funded burner wallet, builds a claim page, and uploads it — all gasless via x402facilitator.dev.
---

# x402 Tip Claim Page

Create a non-custodial USDC tip page: generate a burner wallet, fund it, build an HTML claim page, upload to agentupload.dev. The recipient claims gaslessly via x402facilitator.dev — no gas ETH needed, no backend, one static HTML file.

## Prerequisites

- `@x402/core`, `@x402/evm`, `viem`, `ethers` installed in `/tmp/node_modules`
- A funded facilitator account on x402facilitator.dev (Craig's: `cddea943-c042-4546-9111-8900b4968319`)
- Craig's x402 wallet (via mcporter) for funding the burner

## Architecture

The x402 protocol uses EIP-3009 `transferWithAuthorization` for gasless USDC transfers. A **facilitator** submits the signed authorization on-chain and pays gas via Coinbase CDP. The tip page embeds a burner private key and signs the transfer in the browser.

```
[Burner Wallet] --signs transferWithAuthorization--> [Facilitator] --submits on-chain via CDP--> [Recipient gets USDC]
```

The facilitator settle endpoint has CORS enabled (PR #8 on x402facilitator), so browsers can call it directly.

## Step-by-Step Flow

### 1. Generate a burner wallet

```javascript
const { ethers } = require('ethers');
const wallet = ethers.Wallet.createRandom();
// Save: wallet.address and wallet.privateKey
```

### 2. Fund the burner via x402scan

```bash
NODE_OPTIONS="--max-old-space-size=128" mcporter call x402 fetch \
  url="https://www.x402scan.com/api/send?address=BURNER_ADDRESS&amount=AMOUNT&chain=base" \
  method=POST body='{}'
```

This uses Craig's x402 wallet to pay x402scan, which transfers USDC to the burner.

### 3. Build the claim page

The HTML page must:

1. Import x402 libraries via esm.sh:
   ```javascript
   import { x402Client, x402HTTPClient } from 'https://esm.sh/@x402/core@2.3.1/client';
   import { registerExactEvmScheme } from 'https://esm.sh/@x402/evm@2.3.1/exact/client';
   import { privateKeyToAccount } from 'https://esm.sh/viem@2.21.26/accounts';
   import { isAddress } from 'https://esm.sh/viem@2.21.26';
   ```

2. Set up the x402 client with the burner PK as signer:
   ```javascript
   const account = privateKeyToAccount(BURNER_PK);
   const client = new x402Client();
   registerExactEvmScheme(client, { signer: account });
   const httpClient = new x402HTTPClient(client);
   ```

3. Claim flow (when user enters their address):
   ```javascript
   // Step 1: Get 402 challenge from x402scan
   const res = await fetch(
     `https://www.x402scan.com/api/send?address=${recipientAddress}&amount=${amount}&chain=base`,
     { method: 'POST' }
   );
   // res.status === 402

   // Step 2: Parse and sign the x402 payment
   const paymentRequired = httpClient.getPaymentRequiredResponse(
     (name) => res.headers.get(name)
   );
   const paymentPayload = await httpClient.createPaymentPayload(paymentRequired);
   const requirements = paymentRequired.accepts[0]; // Select EVM/Base

   // Step 3: Settle via facilitator (gasless!)
   const settleRes = await fetch(`${FACILITATOR_URL}/settle`, {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({
       x402Version: paymentPayload.x402Version,
       paymentPayload,
       paymentRequirements: requirements,
     }),
   });
   const data = await settleRes.json();
   // data.success === true, data.transaction === "0x..."
   ```

4. Check if already claimed on page load:
   ```javascript
   // Read USDC balance of burner via viem
   const bal = await publicClient.readContract({
     address: USDC_ADDRESS, // 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
     abi: [balanceOf ABI],
     functionName: 'balanceOf',
     args: [BURNER_ADDRESS],
   });
   if (bal === 0n) { /* show "already claimed" state */ }
   ```

5. Offer two claim methods:
   - **Connect Wallet** (window.ethereum) — for users with browser wallets
   - **Paste address** — for anyone with a Base wallet address

### 4. Upload to agentupload.dev

```bash
NODE_OPTIONS="--max-old-space-size=128" mcporter call x402 fetch \
  url="https://agentupload.dev/api/x402/upload" method=POST \
  body='{"filename":"tip.html","contentType":"text/html","tier":"10mb"}'
# Returns uploadUrl and publicUrl
curl -X PUT "$uploadUrl" -H "Content-Type: text/html" --data-binary @/tmp/tip.html
```

### 5. Send the link to the recipient

Via x402email, Discord message, or any other channel.

## Key Constants

| Constant | Value |
|----------|-------|
| USDC on Base | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Base chain ID | `eip155:8453` |
| x402scan send | `https://www.x402scan.com/api/send` |
| Facilitator URL | `https://x402facilitator.dev/api/facilitator/v2/cddea943-c042-4546-9111-8900b4968319` |
| Facilitator settle cost | $0.01 per claim |
| x402scan send cost | equal to amount sent |

## Cost Breakdown Per Tip

| Item | Cost |
|------|------|
| Fund burner (x402scan send) | $TIP_AMOUNT (passed through) |
| Facilitator settle | $0.01 |
| agentupload hosting | $0.01 |
| **Total overhead** | **$0.02 + tip amount** |

## Design Notes

- Follow the `frontend-design` skill for page styling — NO generic AI aesthetics
- Each tip page should feel unique and contextual (music tips get music emoji, food tips get food, etc.)
- Include confetti or celebration animation on successful claim
- Always show a BaseScan link after claim so the recipient can verify on-chain
- Include a "What is this?" explainer for non-crypto users pointing to Coinbase Wallet

## Testing

Test the flow from Node.js before deploying (simulates what the browser does):

```javascript
// Same flow as above but in Node instead of browser
// Verify: 402 challenge → sign → settle → success === true
```

Always send a test claim to Craig's own wallet first (`0x6B173bf632a7Ee9151e94E10585BdecCd47bDAAf`) before giving the link to anyone.

## Facilitator Management

Craig's facilitator account was created with a $2.50 deposit. Each settle costs $0.01, so that's 250 claims before needing a top-up. Check balance:

```bash
# SIWX-authenticated — use the siwx_poll.cjs pattern
# Or just count: facilitator started with $2.50, each settle is $0.01
```

To deposit more:
```bash
NODE_OPTIONS="--max-old-space-size=128" mcporter call x402 fetch \
  url="https://x402facilitator.dev/api/deposit?amount=5" method=POST \
  body='{"walletAddress":"0x6B173bf632a7Ee9151e94E10585BdecCd47bDAAf","notificationEmail":"craig@craig.x402email.com"}'
```

## What NOT to Do

- ❌ Don't try direct on-chain USDC transfer (burner has no ETH for gas)
- ❌ Don't use x402scan /api/send from the browser (CORS blocked, and adding CORS there is a security risk)
- ❌ Don't expose Craig's main wallet PK in any page — only burner PKs
- ❌ Don't embed the facilitator API key in any non-tip context

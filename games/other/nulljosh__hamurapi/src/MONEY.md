# Hamurapi Money

How Hamurapi makes money. The fleet-wide ledger is `GTM.md` in the Code root.

## Price

Free for the first week after Apple approves it. Then $0.99, once. The web game stays free.

## Rail

App Store paid download, iPhone and Mac. Apple keeps 15%, so each sale pays out $0.84.

## Why

A free week gets the first game played and reviewed. After that, one dollar, once, with no ads and nothing to unlock. The website is the trial and the store is the checkout.

## Cost

Nothing a month. The site is static files on Cloudflare. There is no server and no account system.

## Next

The day Apple approves it, schedule the price for seven days later:

`asc pricing schedule create --app <id> --price 0.99 --base-territory USA --start-date YYYY-MM-DD`

No build, no review. Anyone who got it in the free week keeps it.

*Set 2026-10-04 by Joshua: free for a week, then $1.*

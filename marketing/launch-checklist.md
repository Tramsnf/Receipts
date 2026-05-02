# Launch Checklist

> The order matters. Each step compounds the previous one.

## Pre-launch (before going public)

- [ ] Confirm repo is public and pinned on your GitHub profile
- [ ] Check `README.md` install commands actually work end-to-end (`git clone …`)
- [ ] Verify `LICENSE` shows correct attribution
- [ ] Verify `skill.json` `author.github` matches your handle
- [ ] Add social preview image:
  - **Easy path**: upload `assets/og-card.png` (already 1280×640) → GitHub → repo Settings → Social preview → Upload
  - **If you tweak the design first**: edit `assets/og-card.svg`, regenerate PNG with `npx -y -p sharp-cli sharp -i og-card.svg -o og-card.png resize 1280 640 --fit fill`, then upload
  - **Browser screenshot fallback**: open `assets/og-card.html` in Chrome → DevTools device toolbar → custom 1280×640 → screenshot the card
- [ ] Star your own repo (one star helps, especially on a new repo)
- [ ] Add the repo to your GitHub profile pinned section

## Day-of launch

### T-0: Tweet thread
- [ ] Post `marketing/launch-tweet-thread.md` as a thread
- [ ] Pin the first tweet
- [ ] Reply to the first tweet with the GitHub link (boosts CTR)

### T+15min: Show HN
- [ ] Post `marketing/launch-posts.md` → Show HN section to https://news.ycombinator.com/submit
- [ ] Share the HN link in any relevant Slack / Discord communities you're in
- [ ] Reply to every comment within 30 minutes for the first 2 hours

### T+2h: Reddit
- [ ] r/LocalLLaMA — `marketing/launch-posts.md` → r/LocalLLaMA section
- [ ] r/ChatGPTCoding
- [ ] r/programming (after the others — strict mod queue)
- [ ] r/devops

### T+4h: Compounding
- [ ] If HN is on the front page, tweet a screenshot
- [ ] Quote-tweet anyone with a meaningful reaction
- [ ] DM 5–10 builders you respect with a direct link and a "would love your honest take"

## Post-launch (week one)

- [ ] Add a "Trusted by" or "Used by" badge section to README if any orgs adopt it
- [ ] Open issues for the most-requested missing pieces (cookbooks for other languages, etc.)
- [ ] Submit to `awesome-claude-code` / `awesome-ai-coding-agents` lists
- [ ] Write a longer "why" blog post if HN traction is real
- [ ] If it lands, ship `v0.2.0` within 2 weeks with the top user-requested addition — keeps momentum

## What to track

- GitHub stars / forks (daily)
- Unique visitors to the repo (GitHub Insights)
- HN comment count + position
- Reddit upvotes + comments per sub
- Tweet impressions on the thread
- Any inbound DMs or issues with "we're using this for X"

## What to ignore

- "Have you considered X language" without a PR — track in issues, don't get distracted
- "This is just a prompt" — yes, that's the point
- Drive-by negativity that doesn't engage with the design

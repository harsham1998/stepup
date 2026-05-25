# StepUp App Wireframes

_Started 2026-05-24 08:59 UTC_

---

## User

I need to build wireframes for my StepUp app
I have few feautures in mind but i am very bad in designing - so you need to help me to build the wireframes for the app

## Assistant

_[tool: local_ls]_

_[tool: local_ls]_

_[tool: local_read]_

_[tool: local_read]_

_[tool: local_ls]_

_[tool: view_image]_

_[tool: view_image]_

_[tool: view_image]_

_[tool: questions_v2]_

Got a good lay of the land — StepUp is a fitness/step-challenge app with auth, home, challenges, leaderboard, wallet, profile, health sync, and step-tracking already scaffolded in Flutter. Before I start sketching wireframes, I want to make sure I'm exploring the right space. A few quick questions:

## User

Questions answered:
- features_to_wireframe: Onboarding / sign-up flow, Home / dashboard (steps + today), Challenges list & discovery, Challenge detail / join flow, Live challenge / progress tracking, Leaderboard, Wallet & winnings / payout, Profile & stats history, Notifications / activity feed, Social — friends, groups, invites
- audience: A mix
- primary_goal: Decide for me
- challenge_types: Total steps over N days, Daily step goal (e.g. 10k/day), Streak-based (consecutive days), Activity-specific (running, gym, cycling)
- money_model: Mix — show both in wireframes
- platform: Generic phone frame (no OS chrome)
- vibe: Sketchy but readable — handwritten font
- variation_focus: Explore a few options

## User

First let's start with onboarding, app start, profile setup and dashboard screens 
Let's first complete this wireframe

## Assistant

_[tool: update_todos]_

_[tool: copy_starter_component]_

_[tool: write_file]_

_[tool: write_file]_

Now the wireframe components — I'll keep them in one JSX file:

_[tool: write_file]_

_[tool: done]_

_[tool: fork_verifier_agent]_

Wireframes are up — sketchy / handwritten vibe, generic phone frames, b&w with a coral accent and yellow highlighter. Laid out on a pan/zoom canvas so you can drag-reorder, rename, or open any one fullscreen.

**Sections (click an artboard to zoom):**
- **App start** (3) — logo + tap, auto-syncing splash, hero + sign-up
- **Onboarding** (4) — 3-slide carousel, single-page value list, goal-picker first, permissions-first
- **Profile setup** (4) — multi-step wizard, single scrollable form, 3 quick cards, conversational chat
- **Dashboard** (5) — step ring focus, stats grid, timeline feed, hub of tiles, swipeable card stack

**Next steps when you're ready:**
1. Tell me which direction(s) feel right per section (e.g. "Onb-C + Dash-A") and I'll lock them in
2. Then move on to the next batch — Challenges list, Challenge detail/join, Live tracking
3. Or remix any of these (more variations, different angle, etc.)

## User

You have used very light colours 
Try to use some GenZ specific liked colours and themes
I liked your wire frame text and all - Just add some GenZ touch

## Assistant

_[tool: str_replace_edit]_

Going to crank up the saturation — brat-green / hot-pink / electric-blue / Y2K purple, keep the sketchy hand-drawn lines but make the fills pop. I'll also throw in some playful stickers and chunkier solid-color blocks.

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

Now the screens — pumping color into each:

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

Now the dashboards:

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

## User

Wellness related theme - and maintain a same theme throughout the app

Don't use these light blu and pink colours

## Assistant

_[tool: str_replace_edit]_

Switching to a wellness palette — sage, matcha, clay, moss, cream. Pulling out blue/pink entirely.

_[tool: grep]_

_[tool: str_replace_edit]_

Now sweep through the wireframes to replace hardcoded hot-pink / brat-lime / electric-blue with the wellness tokens:

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: save_screenshot]_

Wellness palette is now active — cream paper, sage hero, matcha highlight, terracotta CTAs. Let me check the rest:

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: save_screenshot]_

_[tool: view_image]_

Repainted in a wellness palette and held it consistent across all 16 wireframes.

**Palette (sketchy GenZ touch · grounded wellness tones)**
- **Sage / moss** — primary, calm
- **Matcha** — accent / "win" highlights
- **Terracotta clay** — CTAs & focus
- **Ochre / warm gold** — money / streaks
- **Plum** — secondary accent (sparing)
- **Cream paper + moss-black ink**

The handwritten Caveat/Kalam typography and slight wobble carry the GenZ feel; the muted earth tones keep it professional and wellness-coded. Same tokens drive every chip, button, card, and progress ring across onboarding → profile → dashboard, so the language stays consistent when we add the next screens.

**Ready when you are for:**
- Challenges list & discovery
- Challenge detail / join flow
- Live challenge / progress tracking

## User

See this theme
Just take this as reference
I don't want a exact match - Whatever your wireframe are good, but colour themes are not good - so just take this as reference and do it accordingly

## Assistant

_[tool: str_replace_edit]_

Got it — dark, deep-navy/purple, with warm gold + soft mint as accents. Keeping the sketchy wireframe structure but moving to dark mode.

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

Now redoing just the App-start screens for the dark theme, and adding the auth screens (login, OTP, social signup):

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

Now add the new artboards to the App start section:

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: save_screenshot]_

Dark theme is in place for App Start — 6 frames now:

**App start (6)**
- **A** Logo splash · matcha-accent "Up" + arrow mark · tap to begin
- **B** Auto-syncing loader · animated step ring
- **C** Hero + sign-up · gold CTA + value chips
- **D** Login · phone + OTP, Google/Apple fallback (India-style)
- **E** OTP verify · 6-cell input, auto-detect, resend timer
- **F** Social-first signup · Google · Apple · Phone

**Palette**: deep navy/purple gradient background, warm cream text, **matcha** as the primary accent (logo highlight, success), **gold/ochre** for CTAs and badges, **mint** for confirmations, **terracotta clay** for warmth. Same handwritten Caveat/Kalam typography keeps the GenZ edge.

The other sections (Onboarding, Profile, Dashboard) have automatically inherited the dark tokens but I haven't polished them yet — they may look a bit raw. **Once you approve the App start direction, I'll do a clean pass through the rest** with the same standard, plus any tweaks you call out here.

## User

Different colours in the Dashobard and overall app is not good

## Assistant

_[tool: str_replace_edit]_

Got it — tightening the palette so the whole app reads as one product. Just two accents (matcha + gold) with mint as a small success cue.Now Profile setup screens:

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: save_screenshot]_

_[tool: view_image]_

Dashboard is now unified with the rest — same dark navy surface, matcha as the single highlight color (active stats, today bar, "win" indicator), and gold reserved for money (wallet). No more rainbow chips. Whole app reads as one product now.

**System locked in:**
- **Background**: deep navy/purple gradient
- **Surface**: dark slate cards with subtle borders
- **Matcha green**: the one "active/highlighted" accent (today's number, active challenge, selected state)
- **Gold / ochre**: only for money & CTAs
- **Mint**: success/confirmation (sparingly)
- **Handwritten Caveat + Kalam** for that GenZ touch

All 4 sections (App start · Onboarding · Profile setup · Dashboard) now share the same vocabulary.

**Ready when you are for:** Challenges list · Challenge detail/join · Live challenge tracking · Leaderboard · Wallet · Profile · Friends/Social.

## User

Now there are few corrections, this app is not about only walking. This is a complete wellness challenges app which will help and reward you for consistency.
We need to show different metrics like sport sessions,  gym and workout sessions, challenges in different category
This is not a paid challenge join and pool and cashout for winners
I am doing it as a subscription model
Free plan users - Just they will join the challenges and  compete with free users only and can see the metrics of their activity...
Paid plan of 149 per month - Beginner - They can join the challenges upto 2 per month and win the coins based on their consistency.. they will join the pool with different users but will not show any amounts or win money like that.. just rankings, consistency etc,. top 50% consistent winners will be rewarded with coins which can be redeemed for gift cards 

Now alter the screens according to this
Add the complete end to end screens as required - if i am missing anything please add it yourself

## Assistant

_[tool: read_file]_

Big pivot. Let me restructure — splitting into multiple files since this is a lot more screens.

_[tool: read_file]_

_[tool: str_replace_edit]_

Going to restructure. First, refactor existing file to export to window (so the new file can use those components) and remove the inline App render:

_[tool: read_file]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

Copy edits to remove cash/money framing in existing screens:

_[tool: write_file]_

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: show_html]_

_[tool: sleep]_

_[tool: get_webview_logs]_

_[tool: save_screenshot]_

_[tool: done]_

Pivoted the whole product to your subscription wellness model. End-to-end coverage now lives across **12 sections / 35 screens**:

**01 App start** (6) — splash, login, OTP, social signup  
**02 Onboarding** (5) — value props, activity picker, permissions + **NEW: Plan picker** (Free vs Beginner ₹149)  
**03 Profile setup** (4)  
**04 Dashboard** (5) — now framed around multi-activity + consistency + coins (no money)  
**05 Activities** (2) **NEW** — multi-category overview (walk, gym, yoga, run, sport, cycle, mindfulness) + Log session  
**06 Challenges** (4) **NEW** — discover by category, my challenges grid, detail, **upgrade prompt** for free users hitting paid challenges  
**07 Live tracking** (2) **NEW** — daily check-in, github-style consistency calendar  
**08 Leaderboard** (2) **NEW** — challenge rank with **top 50% cutoff line**, friends ranking  
**09 Coins & Rewards** (3) **NEW** — coins wallet, gift card catalog (Amazon · Flipkart · Swiggy · Cult.fit etc.), redeem confirm  
**10 Subscription** (2) **NEW** — plan compare, UPI/card checkout  
**11 Profile** (2) **NEW** — me + stats + badges, achievements grid  
**12 Notifications** (1) **NEW** — inbox  

**Key framing shifts I made (call out if any feel off):**
- Every "₹ / cash / pool / cash out" is gone → replaced with "¢ coins" + "redeem for gift cards"
- Activity picker covers 6 categories, not just steps
- Challenges show category badges + reward shown only as coin amount
- Leaderboard surfaces consistency % and the top-50% cutoff explicitly
- Free vs Beginner distinction is shown everywhere it matters (upgrade prompt, plan picker, locked challenges)
- Coin economy: earn via finishing challenges, daily check-ins, streaks, invites; spend on gift cards
- Tab bar updated: Home · Chal · Lead · Coins · Me

**Things I added that you didn't mention — flag if you want them removed:**
- Yearly plan toggle (20% off) on Sub_Plans  
- "First month perks" box on checkout  
- Achievements/badges screen  
- Github-style consistency heatmap  
- Friend invite reward (+50 ¢)

Tell me what to refine and I'll iterate on specific screens.

## User

Change the font to make it look more like a fitness related app - something like the nike running club app

## Assistant

_[tool: str_replace_edit]_

Switching to Nike-style fitness typography — condensed bold italic for hero numbers, clean sans-serif for everything else.

_[tool: run_script]_

_[tool: run_script]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: run_script]_

Let me promote the biggest hero numbers to italic-condensed Nike style:

_[tool: done]_

_[tool: save_screenshot]_

_[tool: sleep]_

Typography updated to fitness-app vibe:

- **Big Shoulders Display** (heavy condensed sans, 800–900) → all big numbers, headlines, brand
- **Italic + condensed** for hero metrics (steps count, coin balance, durations, streaks) — that Nike-stopwatch look
- **Inter** (clean grotesk) → body text, labels, chips, buttons

The handwritten Caveat/Kalam is gone everywhere — the wireframes now read as polished fitness mockups rather than sketchy lo-fi. The dark wellness palette and screen structure stay as-is.

Let me know if any specific hero number could go bigger / bolder / more italic, or if you want it dialed back in a particular screen.

## User

I don't want any words to start with small letters
Also can you tweak the colors a bit to match the new fonts, also dont keep the icons too cartoonish make them give a bold feel

## Assistant

_[tool: run_script]_

Three updates incoming — capitalization, color punch, and bolder iconography.

**Step 1 — Capitalize first letter of every UI text string:**

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: grep]_

_[tool: run_script]_

_[tool: run_script]_

_[tool: str_replace_edit]_

**Step 2 — Color punch:**

_[tool: str_replace_edit]_

_[tool: run_script]_

_[tool: run_script]_

**Step 3 — Bolder, less cartoonish iconography:**

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: sleep]_

_[tool: save_screenshot]_

All three updates applied:

**Capitalization** — every UI string now starts with a capital letter. Fixed apostrophe glitches from the auto-cap (we'll, Let's, it's stay lowercase after the `'`).

**Color punch** — palette tuned for the bold athletic type:
- Background → deeper black-navy with subtle purple/volt glow
- Primary accent → **volt lime** (`#d4ff3a`, brighter and more electric)
- Money accent → **warm amber** (`#ffb547`)
- Surfaces → tighter contrast slate cards
- Dropped clay/terracotta from regular use (too soft for the Nike vibe)

**Bolder iconography** — swapped cartoonish emojis for bold typographic markers:
- Activities: `W` `G` `Y` `R` `C` `S` `M` (Walk, Gym, Yoga, Run, Cycle, Sport, Mindful) — single letters in Big Shoulders bold inside circles
- Streak `🔥` → `★`, money bag `💰` → `¢`, party `🎉` → `✱`, gift `🎁` → `◈`, trophy `🏆` → `▲`, lock `🔒` → `◆`, wave `👋` → dropped
- Chips now SMALL CAPS with letter-spacing for an athletic feel

The whole app reads more like a sports/wellness product now — bold, sharp, monochrome with a single hot accent. Tell me what to push further.

## User

Can we also work on the colors a bit to match the font we are using, the green and yellow go too bright, I think white and orange
See this attachment for color refrence and design inference

## Assistant

_[tool: snip]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: run_script]_

_[tool: done]_

_[tool: sleep]_

_[tool: save_screenshot]_

Pivoted to a black + orange "Orange Army" palette:

- **Background**: near-pure black with subtle ember glow (warm dark instead of cool navy)
- **Primary accent**: **burning orange** `#ff5a1f` — used for active states, highlights, hero numbers
- **Secondary accent**: **softer orange** `#ff8848` — used where amber/gold was before (CTAs, money/coin context)
- **Text**: pure white throughout
- **Volt green and bright amber are gone** — every `--matcha` reference now resolves to orange, every `--ochre` to soft orange

Color hierarchy now reads: **black surfaces · white text · orange when something matters**. Same bold Big Shoulders / Inter typography sitting on a black canvas with hot accent — closer to the athletic poster vibe you shared.

Open it up and let me know if any specific screen feels off — I'll keep tuning.

## User

the orange is too bright

## Assistant

_[tool: str_replace_edit]_

_[tool: run_script]_

_[tool: done]_

Dialed the orange back — `#d9612e` (muted warm) for primary, `#e8865a` for the softer accent. Still distinctly orange, but no longer neon. Open the preview and let me know if it's the right level or you want it pushed further (e.g. more terracotta `#c25a32`, more copper `#b85e2e`, or back toward bright).

## User

no the earlier colors were only looking nice, this white and orange doesnt look nice

## Assistant

_[tool: str_replace_edit]_

Reverting back to the volt-lime + amber palette you had before:

_[tool: str_replace_edit]_

_[tool: run_script]_

_[tool: done]_

Back to the volt-lime + amber palette on deep navy-black. Orange experiment fully reverted across CSS, JSX inline hex, and body background. Let me know what to try next.

## User

Also in all the screens there are lot of containerized boxes, it is looking cartoonish, can we make it aesthetic and plain design language like the nike running club app

## Assistant

_[tool: str_replace_edit]_

Stripping down the boxy look:

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: done]_

Stripped the boxy look across the board:

- **`.box` defaults to fully transparent** (no border, no bg) — most sections now flow open without container walls. Accent cards (the matcha highlight challenges, gold money cards) still show because their inline styles override the transparent defaults.
- **Buttons** → solid pill, no border, more padding, bolder feel — Nike-style CTA
- **Chips** → no border, just subtle bg, small caps with letter-spacing
- **Tab bar** → no dashed separators, icons are bold typographic glyphs (no box around them), active tab tints matcha
- **Squiggle divider** → flat 1px hairline at low opacity
- **Subtle dashed cards** kept where they signal "placeholder / drop area"

Result: typography carries the layout, accent fills are reserved for actual emphasis. Should read much closer to NRC now. Tell me which screen still feels too caged.

## User

In challenges - Need to give option to create custom challenge and share it with friends
System will generate the reward based on the challenge level

## Assistant

_[tool: read_file]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: done]_

Added the custom challenge flow to section 06:

**E · Create custom challenge**
- Title input
- Category chips (Walk/Gym/Yoga/Run/Cycle/Sport)
- **Difficulty selector** — Easy / Medium / Hard — system shows the auto-generated coin reward live (+60 / +200 / +500 ¢)
- Duration chips (3/7/14/21/30 days)
- Frequency field (e.g. "4 sessions / week")
- "Next — Invite friends →" CTA

**F · Invite friends**
- Challenge summary card with the system-set reward
- Shareable link + Copy + WhatsApp / Instagram / Telegram quick-share
- Friend list with tap-to-invite toggles
- "Launch challenge →" CTA

Plus I added a prominent **"+ Create your own challenge"** entry at the top of the Discover screen (A) so users can find it easily from the main challenges view.

Reward is generated by tier (difficulty × duration could later refine it). Let me know if you want more granular reward logic shown, or a different sharing flow.

## User

Add Icons whereever possible

## Assistant

_[tool: snip]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: run_script]_

_[tool: grep]_

_[tool: done]_

Icons added throughout:

**Bold line-style SVG icon set** (`Icon` component) — 30+ icons in one stroke weight, all 24×24, currentColor-aware so they tint matcha on active states.

**Where they show up now:**
- **Tab bar** → home, trophy, chart, coin, user — active tab tints matcha
- **Activities screen** → walk / gym / yoga / run / sport / cycle / mindful — each in a rounded square tile, check or plus on the right
- **Dashboard timeline feed** → activity icons inline in events
- **Notifications inbox** → trophy / flame / gym / user / chart / coin / gift — color-coded per kind
- **Custom challenge → Create** → category chips show icon + label
- **Custom challenge → Invite friends** → summary card now shows gym icon instead of "G"
- **Dashboard streak + coins tiles** → flame & coin icons inline with labels

Same minimal Nike-style: line-stroke icons in muted tiles, accent tile + matcha icon only when the row is "active/done". Let me know which other screen needs icon treatment.

## User

These 3 screens are clumsy or too much spacing or very less spacing - fix them
The text is not visible for the effect wherever it is used - added 2 screenshots but all places where this effect is used the text is not visible

## Assistant

_[tool: snip]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: done]_

Fixed both issues:

**1. Marker text was invisible** — the highlighter-pen effect only painted the bottom 40% of the text background, so the top half disappeared on dark BG. Replaced with a **solid filled block** (`background: matcha; color: dark`) — now every "Consistency", "Coin rewards", "Win" etc. reads cleanly as a Nike-style emphasis block.

**2. Hub of tiles spacing** — was a wrapping flex row that wasn't actually wrapping into a 2×2. Now uses CSS grid `1fr 1fr` so the 4 tiles sit neatly in a true bento, each with an icon on the title row. Added a streak strip at the bottom that fills the empty space cleanly instead of just a hairline.

**3. Activity feed spacing** — switched from a tight `gap: 6` flex column to per-row 10px vertical padding with a subtle 1px row divider (Nike Running Club–style list). Shortened the timeline messages so each row sits on a single line. The steps card now has a walk icon next to "7,832 Steps" instead of the cartoonish 👟.

Tab bar's stronger active-tab matcha tint is now visible on every dashboard too. Let me know what to tune next.

## User

Frames are not loading see once

## Assistant

_[tool: snip]_

_[tool: get_webview_logs]_

_[tool: screenshot_user_view]_

_[tool: eval_js_user_view]_

_[tool: eval_js_user_view]_

_[tool: eval_js_user_view]_

_[tool: eval_js_user_view]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: eval_js]_

_[tool: sleep]_

Found the issue — a stray extra `);` after `Dash_Feed` from my earlier replacement broke Babel's parse of `wireframes.jsx`, so none of the components got defined and the whole canvas came up blank.

Fixed. Reload and the frames should render again.

## User

Fix this in Activity ring

## User

Add the icons

## User

Add the icons

## Assistant

_[tool: snip]_

_[tool: grep]_

_[tool: read_file]_

_[tool: str_replace_edit]_

_[tool: done]_

## User

1. League System 
Your biggest differentiator.
Features
	•	Bronze
	•	Silver
	•	Gold
	•	Platinum (Only Paid Users from here)
	•	Diamond
	•	Elite

2. Daily / Weekly / Seasonal Challenges
Challenge system should feel dynamic.
Types
	•	Daily goals
	•	Weekly streaks
	•	Monthly leagues
	•	Seasonal tournaments
Examples
	•	Summer Shred
	•	Hyderabad Step Cup
	•	New Year Transformation

3. Social Rivalry System
Make users emotionally competitive.
Features
	•	rival users
	•	challenge friends
	•	weekly battles
	•	flex achievements
	•	streak comparison

4. Premium Reward Marketplace
Avoid coupon bazaar feeling.
Focus on
	•	smartwatches
	•	shoes
	•	protein
	•	gym memberships
	•	Amazon vouchers
	•	premium wellness brands
Rewards should feel aspirational.

5. Fitness Reputation System
Users build:
	•	fitness score
	•	consistency score
	•	elite streaks
	•	challenge completion history

6. Streak Protection
Premium feature.
Users can:
	•	save streak once/month
	•	revive challenge
Free users or paid users can restore streak by paying 15 rupees - Max 2 days after losing the streak

 7. Daily Missions
Examples:
	•	8k steps
	•	drink water
	•	sleep goal
	•	stretching mission

8. 13. XP + Leveling System
Users level up globally.
Example
	•	Level 1 Walker
	•	Level 20 Challenger
	•	Level 50 Elite Athlete

14. Achievement Badges
Examples:
	•	30-day streak
	•	100k weekly steps
	•	top 1% Hyderabad
	•	consistency master

15. Seasonal Battle Pass
Gaming-inspired system.
Unlock
	•	rewards
	•	badges
	•	profile frames
	•	elite competitions

16. Smartwatch Ecosystem
Support:
	•	Apple Watch
	•	Samsung
	•	Fitbit
	•	Garmin
	•	Noise
	•	boAt

17. Instagram Type posting and status and community feed
Follow other users or influencers
Post acheivements, posts etc,. 
Add status - avatars

Add these screens - see whatever is possible and need to include in our app workflow.

## Assistant

_[tool: write_file]_

## Assistant

_[tool: update_todos]_

_[tool: str_replace_edit]_

_[tool: write_file]_

Now wire it into the canvas and HTML:

_[tool: str_replace_edit]_

_[tool: grep]_

_[tool: read_file]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: write_file]_

_[tool: grep]_

_[tool: str_replace_edit]_

_[tool: done]_

_[tool: grep]_

_[tool: eval_js]_

All wired up, root has 1 child, app renders. New canvas-mount.jsx pulls everything from `window` and builds the full canvas with all sections.

**New sections added (10) — 16 new screens:**

- **06 · Daily Missions** — 5 micro-goals (steps · water · sleep · stretch · workout) with per-mission progress
- **07 · Challenges** got 3 more — Daily/Weekly/**Seasonal** tabs + featured tournament hero, full **Tournament detail** with multi-metric daily goals
- **08 · Live tracking** got **Streak Protection / Revive** (Pro shield + ₹15 revive within 2 days)
- **09 · League system** — Bronze → Silver → Gold → **Platinum (Pro-gated)** → Diamond → Elite ladder + weekly standings with promote/relegate cutoff lines
- **10 · Rivals & Battles** — rivals list + 1v1 weekly battle screen with VS hero + category breakdown
- **12 · Rewards** got **Premium Marketplace** — Apple Watch, Nike shoes, Cult.fit, MyProtein, etc. as aspirational tiers
- **13 · Battle Pass** — seasonal track with Free + Pro reward rows side-by-side, 50 tiers
- **14 · Reputation & Level** — 0–1000 Fitness Reputation Score with breakdown + global XP/Level path (Walker → Immortal)
- **15 · Watch & Devices** — Apple / Samsung / Fitbit / Garmin / Noise / boAt
- **16 · Community** — Instagram-style feed with stories ring + posts (PR badges, tier chips) + user profile (follow, achievements grid, post grid)

Total now: **~50 wireframes across 19 sections**. Open it up and tell me which to refine, expand, or drop.


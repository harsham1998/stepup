/* canvas-mount.jsx — final App definition + render, sees all components on window */
/* eslint-disable */

const {
  // base
  Frame, DesignCanvas, DCSection, DCArtboard,
  // start
  Start_A, Start_B, Start_C, Auth_Login, Auth_OTP, Auth_Social,
  // onboarding
  Onb_Carousel, Onb_OnePage, Onb_GoalPicker, Onb_Permissions, Onb_PlanPicker,
  // profile setup
  Prof_Wizard, Prof_OneForm, Prof_QuickCards, Prof_Chat,
  // dashboard
  Dash_Ring, Dash_StatsGrid, Dash_Feed, Dash_Hub, Dash_CardStack,
  // activities
  Act_Types, Act_LogSession,
  // challenges
  Chal_Discover, Chal_MyChallenges, Chal_Detail, Chal_UpgradePrompt, Chal_Create, Chal_Share,
  // live tracking
  Live_DailyCheckin, Live_ConsistencyCal,
  // leaderboard
  Lead_Challenge, Lead_Friends,
  // coins
  Coins_Wallet, Coins_GiftCards, Coins_RedeemConfirm,
  // subscription
  Sub_Plans, Sub_Checkout,
  // profile
  Profile_Me, Profile_Achievements,
  // notifications
  Notif_Inbox,
  // PRO features
  League_Hub, League_Standings,
  Chal_Seasonal, Tournament_Detail,
  Rivals_List, Battle_Detail,
  Marketplace,
  Reputation, XP_Level,
  Streak_Shield, DailyMissions,
  BattlePass,
  Watch_Connect,
  Community_Feed, User_Profile,
} = window;

const App = () => (
  <DesignCanvas
    title="StepUp · Wireframes"
    subtitle="Full app — wellness · subscription · league · battle pass · community"
  >
    {/* ===== ORIGINAL FLOW ===== */}
    <DCSection id="start" title="01 · App start" subtitle="Splash, login, OTP, social signup">
      <DCArtboard id="start-a" label="A · Logo splash" width={340} height={680}><Frame note="Minimal · brand-first · tap to begin"><Start_A /></Frame></DCArtboard>
      <DCArtboard id="start-b" label="B · Loading splash" width={340} height={680}><Frame note="Auto-advancing while pre-fetching health data"><Start_B /></Frame></DCArtboard>
      <DCArtboard id="start-c" label="C · Hero + sign-up" width={340} height={680}><Frame note="Value prop + Get started / sign in"><Start_C /></Frame></DCArtboard>
      <DCArtboard id="auth-login" label="D · Login (phone)" width={340} height={680}><Frame note="Phone-first with Google/Apple fallback"><Auth_Login /></Frame></DCArtboard>
      <DCArtboard id="auth-otp" label="E · OTP verify" width={340} height={680}><Frame note="6-digit · auto-detect · resend timer"><Auth_OTP /></Frame></DCArtboard>
      <DCArtboard id="auth-social" label="F · Social signup" width={340} height={680}><Frame note="Google · Apple · Phone"><Auth_Social /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="onb" title="02 · Onboarding" subtitle="Value prop, goal, permissions, plan">
      <DCArtboard id="onb-a" label="A · 3-slide carousel" width={340} height={680}><Frame note="Classic — track, join, earn"><Onb_Carousel /></Frame></DCArtboard>
      <DCArtboard id="onb-b" label="B · Single page" width={340} height={680}><Frame note="All 4 value props on one screen"><Onb_OnePage /></Frame></DCArtboard>
      <DCArtboard id="onb-c" label="C · Activity picker" width={340} height={680}><Frame note="What activities do you do? — drives feed"><Onb_GoalPicker /></Frame></DCArtboard>
      <DCArtboard id="onb-d" label="D · Permissions" width={340} height={680}><Frame note="Health, notif, location"><Onb_Permissions /></Frame></DCArtboard>
      <DCArtboard id="onb-e" label="E · Plan picker" width={340} height={680}><Frame note="Free vs Beginner ₹149/mo"><Onb_PlanPicker /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="prof" title="03 · Profile setup" subtitle="Name, body, goal, activities">
      <DCArtboard id="prof-a" label="A · Wizard" width={340} height={680}><Frame note="4 steps · progress bar"><Prof_Wizard /></Frame></DCArtboard>
      <DCArtboard id="prof-b" label="B · Single form" width={340} height={680}><Frame note="All fields visible · skip what you want"><Prof_OneForm /></Frame></DCArtboard>
      <DCArtboard id="prof-c" label="C · Quick cards" width={340} height={680}><Frame note="3 large tap-targets"><Prof_QuickCards /></Frame></DCArtboard>
      <DCArtboard id="prof-d" label="D · Conversational" width={340} height={680}><Frame note="Chat-style · lighter feel"><Prof_Chat /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="dash" title="04 · Dashboard" subtitle="Multi-activity overview">
      <DCArtboard id="dash-a" label="A · Activity ring" width={340} height={680}><Frame note="Ring + active challenge + streak + coins"><Dash_Ring /></Frame></DCArtboard>
      <DCArtboard id="dash-b" label="B · Stats grid" width={340} height={680}><Frame note="Data-rich · weekly chart"><Dash_StatsGrid /></Frame></DCArtboard>
      <DCArtboard id="dash-c" label="C · Activity feed" width={340} height={680}><Frame note="Every event of your day"><Dash_Feed /></Frame></DCArtboard>
      <DCArtboard id="dash-d" label="D · Hub of tiles" width={340} height={680}><Frame note="Bento — easy nav to each feature"><Dash_Hub /></Frame></DCArtboard>
      <DCArtboard id="dash-e" label="E · Card stack" width={340} height={680}><Frame note="Swipeable · today · streak · challenge · coins"><Dash_CardStack /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="act" title="05 · Activities" subtitle="Multi-category — gym, sport, yoga, run, walk">
      <DCArtboard id="act-a" label="A · Activity types" width={340} height={680}><Frame note="All categories · today's status per type"><Act_Types /></Frame></DCArtboard>
      <DCArtboard id="act-b" label="B · Log a session" width={340} height={680}><Frame note="Quick log · duration · intensity"><Act_LogSession /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="missions" title="06 · Daily Missions" subtitle="Steps · water · sleep · stretch — micro-goals refresh daily">
      <DCArtboard id="missions-a" label="A · Daily missions" width={340} height={680}><Frame note="5 goals · resets at midnight · finish all for bonus"><DailyMissions /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="chal" title="07 · Challenges" subtitle="Discover, join, create, share">
      <DCArtboard id="chal-a" label="A · Discover" width={340} height={680}><Frame note="By category · for you · '+ Create your own' CTA up top"><Chal_Discover /></Frame></DCArtboard>
      <DCArtboard id="chal-seasonal" label="B · Daily/Weekly/Seasonal" width={340} height={680}><Frame note="Tabbed by cadence · featured tournament hero"><Chal_Seasonal /></Frame></DCArtboard>
      <DCArtboard id="chal-tournament" label="C · Tournament detail" width={340} height={680}><Frame note="Seasonal event — Battle-pass tied"><Tournament_Detail /></Frame></DCArtboard>
      <DCArtboard id="chal-b" label="D · My challenges" width={340} height={680}><Frame note="Active + done + saved · day-by-day grid"><Chal_MyChallenges /></Frame></DCArtboard>
      <DCArtboard id="chal-c" label="E · Challenge detail" width={340} height={680}><Frame note="Rules · participants · reward · how it works"><Chal_Detail /></Frame></DCArtboard>
      <DCArtboard id="chal-d" label="F · Upgrade prompt" width={340} height={680}><Frame note="Shown when free user taps a paid challenge"><Chal_UpgradePrompt /></Frame></DCArtboard>
      <DCArtboard id="chal-create" label="G · Create custom challenge" width={340} height={680}><Frame note="Pick category, difficulty, system auto-rewards"><Chal_Create /></Frame></DCArtboard>
      <DCArtboard id="chal-share" label="H · Invite friends" width={340} height={680}><Frame note="Share link + tap-to-invite"><Chal_Share /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="live" title="08 · Live tracking" subtitle="Daily check-in · consistency calendar">
      <DCArtboard id="live-a" label="A · Daily check-in" width={340} height={680}><Frame note="Today's status in active challenge"><Live_DailyCheckin /></Frame></DCArtboard>
      <DCArtboard id="live-b" label="B · Consistency calendar" width={340} height={680}><Frame note="Github-style heatmap"><Live_ConsistencyCal /></Frame></DCArtboard>
      <DCArtboard id="live-c" label="C · Streak protection / revive" width={340} height={680}><Frame note="Pro shield · or revive ₹15 within 2 days"><Streak_Shield /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="league" title="09 · League system" subtitle="Bronze → Elite · Platinum is Pro-gated · resets weekly">
      <DCArtboard id="league-hub" label="A · League hub" width={340} height={680}><Frame note="Your tier + ladder · season indicator"><League_Hub /></Frame></DCArtboard>
      <DCArtboard id="league-standings" label="B · Standings" width={340} height={680}><Frame note="Your rank · promote/relegate cutoffs"><League_Standings /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="rivals" title="10 · Rivals & Battles" subtitle="1v1 weekly battles — emotional rivalry">
      <DCArtboard id="rivals-a" label="A · Rivals list" width={340} height={680}><Frame note="Live battle banner + your rivals"><Rivals_List /></Frame></DCArtboard>
      <DCArtboard id="rivals-b" label="B · Battle detail" width={340} height={680}><Frame note="Head-to-head breakdown by category"><Battle_Detail /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="lead" title="11 · Leaderboards" subtitle="Per-challenge + friends">
      <DCArtboard id="lead-a" label="A · Challenge leaderboard" width={340} height={680}><Frame note="Your rank · top 50% cutoff"><Lead_Challenge /></Frame></DCArtboard>
      <DCArtboard id="lead-b" label="B · Friends ranking" width={340} height={680}><Frame note="Invite friends · monthly consistency %"><Lead_Friends /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="rewards" title="12 · Rewards" subtitle="Coins, gift cards, premium marketplace">
      <DCArtboard id="coins-a" label="A · Coins wallet" width={340} height={680}><Frame note="Balance · history · how to earn more"><Coins_Wallet /></Frame></DCArtboard>
      <DCArtboard id="market" label="B · Premium marketplace" width={340} height={680}><Frame note="Smartwatches · shoes · protein · memberships · vouchers — aspirational catalog"><Marketplace /></Frame></DCArtboard>
      <DCArtboard id="coins-b" label="C · Gift card catalog" width={340} height={680}><Frame note="Brands · cost in coins"><Coins_GiftCards /></Frame></DCArtboard>
      <DCArtboard id="coins-c" label="D · Redeem confirm" width={340} height={680}><Frame note="Preview · cost · balance after · confirm"><Coins_RedeemConfirm /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="battlepass" title="13 · Battle Pass" subtitle="Seasonal · gaming-inspired progression">
      <DCArtboard id="bp-a" label="A · Battle pass track" width={340} height={680}><Frame note="Free + Pro reward rows · tier progression"><BattlePass /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="rep" title="14 · Reputation & Level" subtitle="Fitness score + XP/global level">
      <DCArtboard id="rep-a" label="A · Fitness reputation" width={340} height={680}><Frame note="Score 0–1000 · breakdown · top X% nationally"><Reputation /></Frame></DCArtboard>
      <DCArtboard id="rep-b" label="B · XP & level path" width={340} height={680}><Frame note="Walker → Challenger → Athlete → Elite → Legend → Immortal"><XP_Level /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="watch" title="15 · Watch & Devices" subtitle="Apple · Samsung · Fitbit · Garmin · Noise · boAt">
      <DCArtboard id="watch-a" label="A · Connect device" width={340} height={680}><Frame note="Active sync + available devices to pair"><Watch_Connect /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="community" title="16 · Community" subtitle="Instagram-style feed · stories · user profiles">
      <DCArtboard id="community-a" label="A · Community feed" width={340} height={680}><Frame note="Stories at top · posts with PR badges + tier chips"><Community_Feed /></Frame></DCArtboard>
      <DCArtboard id="community-b" label="B · User profile" width={340} height={680}><Frame note="Follow · stats · achievements · post grid"><User_Profile /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="sub" title="17 · Subscription" subtitle="Plans, checkout, billing">
      <DCArtboard id="sub-a" label="A · Plans" width={340} height={680}><Frame note="Free · Beginner ₹149"><Sub_Plans /></Frame></DCArtboard>
      <DCArtboard id="sub-b" label="B · Checkout" width={340} height={680}><Frame note="UPI / card / netbanking · welcome perks"><Sub_Checkout /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="me" title="18 · Profile" subtitle="Me, achievements, settings">
      <DCArtboard id="profile-a" label="A · Me" width={340} height={680}><Frame note="Avatar · stats · badges · settings list"><Profile_Me /></Frame></DCArtboard>
      <DCArtboard id="profile-b" label="B · Achievements" width={340} height={680}><Frame note="Earned / locked grid"><Profile_Achievements /></Frame></DCArtboard>
    </DCSection>

    <DCSection id="notif" title="19 · Notifications" subtitle="Inbox · in-app feed">
      <DCArtboard id="notif-a" label="A · Inbox" width={340} height={680}><Frame note="Rewards · reminders · social · system"><Notif_Inbox /></Frame></DCArtboard>
    </DCSection>
  </DesignCanvas>
);

ReactDOM.createRoot(document.getElementById('root')).render(<App />);

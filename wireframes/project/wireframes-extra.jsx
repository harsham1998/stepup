/* StepUp wireframes — extra sections: plans, activities, challenges, coins, subscription, profile */
/* eslint-disable */

const {
  Phone, Squiggle, Bar, HandIcon, Icon, Sticky, TabBar, StepRing, Frame,
  Start_A, Start_B, Start_C, Auth_Login, Auth_OTP, Auth_Social,
  Onb_Carousel, Onb_OnePage, Onb_GoalPicker, Onb_Permissions,
  Prof_Wizard, Prof_OneForm, Prof_QuickCards, Prof_Chat,
  Dash_Ring, Dash_StatsGrid, Dash_Feed, Dash_Hub, Dash_CardStack,
} = window;

// ============================================================
// PLAN PICKER (end of onboarding)
// ============================================================

const Onb_PlanPicker = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between sm muted"><span>Skip</span><span>5/5</span></div>
      <div className="hand xl" style={{ marginTop: 4 }}>Pick your plan</div>
      <div className="sm muted">Upgrade anytime · cancel anytime</div>
      <div className="col gap-3" style={{ marginTop: 8 }}>
        <div className="box" style={{ padding: 12, borderColor:'var(--ink-3)' }}>
          <div className="row between middle">
            <div className="hand lg">Free</div>
            <div className="hand b">₹0</div>
          </div>
          <div className="tiny muted">Forever · for trying out</div>
          <div className="col gap-2" style={{ marginTop: 8 }}>
            <div className="tiny">✓ Track all activities</div>
            <div className="tiny">✓ Join free challenges</div>
            <div className="tiny muted">✗ No coin rewards</div>
            <div className="tiny muted">✗ Free user pool only</div>
          </div>
        </div>
        <div className="box" style={{
          padding: 14, borderColor:'var(--matcha)',
          background:'rgba(212,255,58,0.08)', position:'relative'
        }}>
          <span className="chip lime" style={{ position:'absolute', top:-10, right:14 }}>Recommended</span>
          <div className="row between middle">
            <div className="hand lg">Beginner</div>
            <div>
              <span className="hand b">₹149</span>
              <span className="tiny muted"> / Mo</span>
            </div>
          </div>
          <div className="tiny muted">Consistency rewards</div>
          <div className="col gap-2" style={{ marginTop: 8 }}>
            <div className="tiny">✓ Everything in Free</div>
            <div className="tiny">✓ 2 Paid challenges / month</div>
            <div className="tiny">✓ Earn coins for consistency</div>
            <div className="tiny">✓ Top 50% rewarded with coins</div>
            <div className="tiny">✓ Redeem for gift cards</div>
          </div>
        </div>
      </div>
      <div className="grow" />
      <div className="row gap-2">
        <button className="btn ghost full">Stay free</button>
        <button className="btn gold full">Start Beginner →</button>
      </div>
    </div>
  </Phone>
);

// ============================================================
// ACTIVITIES — multi-category tracking
// ============================================================

const Act_Types = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Activities</div>
        <span className="chip">Today</span>
      </div>
      <div className="sm muted">Tap a category to log</div>
      <div className="col gap-2" style={{ marginTop: 4 }}>
        {[
          ['Walking',     'walk',  '7,832 steps · 5.4 km', true],
          ['Gym',         'gym',   '1 session · 48 min',   true],
          ['Yoga',        'yoga',  'Not logged',           false],
          ['Running',     'run',   '3.2 km · 19 min',      true],
          ['Sport',       'sport', 'Not logged',           false],
          ['Cycling',     'cycle', 'Not logged',           false],
          ['Mindfulness', 'mind',  '8 min meditation',     true],
        ].map(([t, ic, sub, on]) => (
          <div key={t} className="box row between middle" style={{
            padding: 12,
            borderColor: on ? 'var(--matcha)' : 'rgba(255,255,255,0.08)',
            background: on ? 'rgba(212,255,58,0.06)' : 'rgba(255,255,255,0.03)'
          }}>
            <div className="row middle gap-3">
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                display:'grid', placeItems:'center',
                background: on ? 'rgba(212,255,58,0.12)' : 'rgba(255,255,255,0.06)',
                color: on ? 'var(--matcha)' : 'var(--ink)'
              }}>
                <Icon name={ic} size={22} stroke={2} />
              </div>
              <div>
                <div className="md b">{t}</div>
                <div className="tiny muted">{sub}</div>
              </div>
            </div>
            {on ? <Icon name="check" size={18} color="var(--matcha)" /> : <Icon name="plus" size={18} color="var(--ink-3)" />}
          </div>
        ))}
      </div>
    </div>
    <TabBar active="home" />
  </Phone>
);

const Act_LogSession = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <div className="row middle gap-2"><span>←</span><span className="sm">Log session</span></div>
        <span className="tiny muted">Save</span>
      </div>
      <div className="row gap-2" style={{ overflowX:'auto' }}>
        {[['Gym','G',true],['Yoga','Y',false],['Sport','S',false],['Run','R',false],['Cycle','C',false]].map(([t,e,on]) => (
          <span key={t} className={'chip' + (on ? ' Lime' : '')} style={{ padding: '6px 12px' }}>{e} {t}</span>
        ))}
      </div>
      <div className="box" style={{ padding: 12, marginTop: 6 }}>
        <div className="tiny muted">Duration</div>
        <div className="hand display" style={{ fontSize: 44, lineHeight: 1, color:'var(--matcha)' }}>48 Min</div>
        <div className="row gap-2 between" style={{ marginTop: 8 }}>
          {['15','30','45','60','90'].map(v => (
            <span key={v} className={'chip' + (v==='45' ? ' lime' : '')}>{v}m</span>
          ))}
        </div>
      </div>
      <div className="row gap-2">
        <div className="box grow"><div className="tiny muted">Intensity</div><div className="md b">High ★</div></div>
        <div className="box grow"><div className="tiny muted">Calories</div><div className="md b">~ 380</div></div>
      </div>
      <div className="box dashed" style={{ padding: 10 }}>
        <div className="tiny muted">Notes (optional)</div>
        <div className="sm muted" style={{ fontFamily: 'Big Shoulders Display', fontSize:18 }}>Chest + triceps · felt strong</div>
      </div>
      <div className="grow" />
      <div className="box" style={{ padding: 10, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)' }}>
        <div className="row between middle">
          <div className="tiny">Earns toward "Gym 4x/week" challenge</div>
          <span className="chip lime tiny">+40 ¢</span>
        </div>
      </div>
      <button className="btn gold full">Save session →</button>
    </div>
  </Phone>
);

// ============================================================
// CHALLENGES — discover, by category, my challenges
// ============================================================

const Chal_Discover = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Challenges</div>
        <span className="chip">🔍</span>
      </div>
      <div className="row gap-2" style={{ overflowX:'auto', paddingBottom: 2 }}>
        {[['All',true],['Steps',false],['Gym',false],['Yoga',false],['Sport',false],['Streak',false]].map(([t,on]) => (
          <span key={t} className={'chip' + (on ? ' lime' : '')}>{t}</span>
        ))}
      </div>
      <div className="row middle" style={{
        padding: '12px 14px',
        background: 'rgba(212,255,58,0.08)',
        borderRadius: 12,
        border: '1px dashed var(--matcha)'
      }}>
        <div className="grow">
          <div className="sm b">+ Create your own challenge</div>
          <div className="tiny muted">Invite friends · system sets the reward</div>
        </div>
        <span style={{ color:'var(--matcha)', fontSize: 22 }}>→</span>
      </div>
      <div className="tiny muted">For you</div>
      <div className="col gap-2">
        <div className="box" style={{ padding: 12, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)' }}>
          <div className="row between middle">
            <div>
              <div className="md b">7-Day Gym Consistency</div>
              <div className="tiny muted">Gym · 4 sessions/week · paid</div>
            </div>
            <span className="chip gold tiny">+200 ¢</span>
          </div>
          <div className="row between middle" style={{ marginTop: 6 }}>
            <div className="tiny muted">92 Joined · starts mon</div>
            <span className="chip lime tiny">Join →</span>
          </div>
        </div>
        <div className="box" style={{ padding: 12 }}>
          <div className="row between middle">
            <div>
              <div className="md b">10K Steps · 14 days</div>
              <div className="tiny muted">Steps · free</div>
            </div>
            <span className="chip tiny">+Free</span>
          </div>
          <div className="row between middle" style={{ marginTop: 6 }}>
            <div className="tiny muted">340 Joined · live</div>
            <span className="chip tiny">Join →</span>
          </div>
        </div>
        <div className="box" style={{ padding: 12 }}>
          <div className="row between middle">
            <div>
              <div className="md b">Yoga 5x/week</div>
              <div className="tiny muted">Yoga · 4 weeks · paid</div>
            </div>
            <span className="chip gold tiny">+500 ¢</span>
          </div>
          <div className="row between middle" style={{ marginTop: 6 }}>
            <div className="tiny muted">128 Joined · starts fri</div>
            <span className="chip tiny">Join →</span>
          </div>
        </div>
        <div className="box" style={{ padding: 12 }}>
          <div className="row between middle">
            <div>
              <div className="md b">Mindful Mornings</div>
              <div className="tiny muted">Meditate 10 min · 21 days</div>
            </div>
            <span className="chip gold tiny">+300 ¢</span>
          </div>
          <div className="row between middle" style={{ marginTop: 6 }}>
            <div className="tiny muted">76 Joined · paid</div>
            <span className="chip tiny">Join →</span>
          </div>
        </div>
      </div>
    </div>
    <TabBar active="chal" />
  </Phone>
);

const Chal_MyChallenges = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="hand xl">My challenges</div>
      <div className="row gap-2">
        <span className="chip lime">Active · 2</span>
        <span className="chip">Done · 8</span>
        <span className="chip">Saved · 3</span>
      </div>
      <div className="tiny muted" style={{ marginTop: 4 }}>Active</div>
      <div className="col gap-2">
        <div className="box" style={{ padding: 12, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)' }}>
          <div className="row between middle">
            <div>
              <div className="md b">7-Day Gym Consistency</div>
              <div className="tiny muted">Day 4 / 7 · on track</div>
            </div>
            <span className="chip lime tiny">100%</span>
          </div>
          <div className="row gap-2" style={{ marginTop: 8 }}>
            {[1,1,1,1,0,0,0].map((v,i) => (
              <div key={i} style={{
                flex:1, height: 8,
                background: v ? 'var(--matcha)' : 'var(--paper-3)',
                border:'1px solid ' + (v ? 'var(--matcha)' : 'var(--ink-3)'),
                borderRadius: 2
              }} />
            ))}
          </div>
          <div className="row between" style={{ marginTop: 6 }}>
            <span className="tiny muted">M T W T F S S</span>
            <span className="tiny" style={{ color:'var(--ochre)' }}>+200 ¢ On finish</span>
          </div>
        </div>
        <div className="box" style={{ padding: 12 }}>
          <div className="row between middle">
            <div>
              <div className="md b">10K Steps · 14 days</div>
              <div className="tiny muted">Day 9 / 14 · missed 1</div>
            </div>
            <span className="chip tiny">86%</span>
          </div>
          <div className="row gap-2" style={{ marginTop: 8 }}>
            {[1,1,1,1,1,1,0,1,1,0,0,0,0,0].map((v,i) => (
              <div key={i} style={{
                flex:1, height: 8,
                background: v ? 'var(--matcha)' : 'var(--paper-3)',
                border:'1px solid ' + (v ? 'var(--matcha)' : 'var(--ink-3)'),
                borderRadius: 2
              }} />
            ))}
          </div>
        </div>
      </div>
    </div>
    <TabBar active="chal" />
  </Phone>
);

const Chal_Detail = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">Share</span>
      </div>
      <div className="box dashed" style={{
        height: 100, display:'grid', placeItems:'center',
        background:'rgba(212,255,58,0.06)', borderColor:'var(--matcha)'
      }}>
        <div className="callout" style={{ color:'var(--matcha)' }}>[ Challenge cover ]</div>
      </div>
      <div className="row gap-2">
        <span className="chip lime">Gym</span>
        <span className="chip">Paid · Beginner+</span>
      </div>
      <div className="hand" style={{ fontSize: 26, lineHeight: 1 }}>
        7-day Gym <span className="marker">Consistency</span>
      </div>
      <div className="sm muted">Complete 4 gym sessions in 7 days · be in top 50% to earn coins</div>
      <div className="row gap-2">
        <div className="box grow tac" style={{ padding: 8 }}><div className="tiny muted">Duration</div><div className="b sm">7 Days</div></div>
        <div className="box grow tac" style={{ padding: 8 }}><div className="tiny muted">Pool</div><div className="b sm">92 Ppl</div></div>
        <div className="box grow tac" style={{ padding: 8, borderColor:'var(--ochre)' }}><div className="tiny muted">Reward</div><div className="b sm" style={{ color:'var(--ochre)' }}>+200 ¢</div></div>
      </div>
      <div className="box" style={{ padding: 10 }}>
        <div className="tiny muted">How it works</div>
        <div className="sm" style={{ marginTop: 4 }}>· Log a gym session 4 days out of 7</div>
        <div className="sm">· Check in each day to keep streak</div>
        <div className="sm">· Top 50% by consistency win coins</div>
      </div>
      <div className="grow" />
      <button className="btn gold full">Join challenge →</button>
    </div>
  </Phone>
);

const Chal_UpgradePrompt = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">Close</span>
      </div>
      <div className="grow" style={{ maxHeight: 24 }} />
      <div className="col center" style={{ gap: 10 }}>
        <div style={{
          width: 70, height: 70,
          border: '2px solid var(--ochre)', borderRadius: '50%',
          display: 'grid', placeItems: 'center',
          fontSize: 32, color: 'var(--ochre)'
        }}>◆</div>
        <div className="hand" style={{ fontSize: 26, lineHeight: 1.1, textAlign:'center' }}>
          Unlock <span className="marker gold">Coin rewards</span>
        </div>
        <div className="sm muted tac" style={{ maxWidth: 240 }}>
          Paid challenges reward you with coins for staying consistent
        </div>
      </div>
      <div className="box" style={{ padding: 14, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)' }}>
        <div className="row between middle">
          <div className="hand lg">Beginner plan</div>
          <div><span className="hand b">₹149</span><span className="tiny muted"> / Mo</span></div>
        </div>
        <div className="col gap-2" style={{ marginTop: 8 }}>
          <div className="tiny">✓ 2 Paid challenges / month</div>
          <div className="tiny">✓ Consistency-based coin rewards</div>
          <div className="tiny">✓ Top 50% earn extra coins</div>
          <div className="tiny">✓ Redeem coins for gift cards</div>
        </div>
      </div>
      <div className="grow" />
      <button className="btn gold full">Upgrade — ₹149/mo</button>
      <button className="btn ghost full">Maybe later</button>
    </div>
  </Phone>
);

// ============================================================
// CUSTOM CHALLENGE — create + share with friends
// ============================================================

const Chal_Create = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14, overflowY:'auto' }}>
      <div className="row between middle">
        <span className="sm muted">← Cancel</span>
        <span className="tiny muted">1 / 2</span>
      </div>
      <div>
        <div className="display" style={{ fontSize: 28 }}>CREATE A</div>
        <div className="display" style={{ fontSize: 28, color:'var(--matcha)' }}>CHALLENGE</div>
      </div>

      <div>
        <div className="tiny muted" style={{ letterSpacing:0.5, textTransform:'uppercase', marginBottom: 6 }}>Title</div>
        <div className="hand" style={{ fontSize: 22, borderBottom:'1.5px solid rgba(255,255,255,0.18)', paddingBottom: 4 }}>
          Sunrise Squad
        </div>
      </div>

      <div>
        <div className="tiny muted" style={{ letterSpacing:0.5, textTransform:'uppercase', marginBottom: 6 }}>Category</div>
        <div className="row gap-2" style={{ flexWrap:'wrap' }}>
          {[['Walk','walk',false],['Gym','gym',true],['Yoga','yoga',false],['Run','run',false],['Cycle','cycle',false],['Sport','sport',false]].map(([t,ic,on]) => (
            <span key={t} className={'chip' + (on ? ' lime' : '')} style={{ padding:'8px 12px', gap: 6 }}>
              <Icon name={ic} size={14} stroke={2.2} />
              {t}
            </span>
          ))}
        </div>
      </div>

      <div>
        <div className="row between middle" style={{ marginBottom: 6 }}>
          <span className="tiny muted" style={{ letterSpacing:0.5, textTransform:'uppercase' }}>Difficulty</span>
          <span className="tiny" style={{ color:'var(--matcha)' }}>Auto-rewarded ✓</span>
        </div>
        <div className="row gap-2">
          {[['Easy', 60], ['Medium', 200], ['Hard', 500]].map(([t, r]) => (
            <div key={t} className="box" style={{
              flex: 1, padding: 12, textAlign:'center',
              background: t==='Medium' ? 'rgba(212,255,58,0.08)' : 'rgba(255,255,255,0.04)',
              borderColor: t==='Medium' ? 'var(--matcha)' : 'transparent'
            }}>
              <div className="sm b">{t}</div>
              <div className="hand display" style={{ fontSize: 20, color:'var(--ochre)', marginTop: 4 }}>+{r} ¢</div>
            </div>
          ))}
        </div>
      </div>

      <div>
        <div className="tiny muted" style={{ letterSpacing:0.5, textTransform:'uppercase', marginBottom: 6 }}>Duration</div>
        <div className="row gap-2">
          {['3d','7d','14d','21d','30d'].map(d => (
            <span key={d} className={'chip' + (d==='7d' ? ' lime' : '')} style={{ padding:'6px 12px' }}>{d}</span>
          ))}
        </div>
      </div>

      <div>
        <div className="tiny muted" style={{ letterSpacing:0.5, textTransform:'uppercase', marginBottom: 6 }}>Frequency</div>
        <div className="hand" style={{ fontSize: 22, borderBottom:'1.5px solid rgba(255,255,255,0.18)', paddingBottom: 4 }}>
          4 sessions / week
        </div>
      </div>

      <div className="grow" />
      <button className="btn gold full" style={{ marginTop: 6 }}>Next — Invite friends →</button>
    </div>
  </Phone>
);

const Chal_Share = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14 }}>
      <div className="row between middle">
        <span className="sm muted">← Back</span>
        <span className="tiny muted">2 / 2</span>
      </div>
      <div>
        <div className="display" style={{ fontSize: 28 }}>INVITE</div>
        <div className="display" style={{ fontSize: 28, color:'var(--matcha)' }}>YOUR SQUAD</div>
      </div>

      {/* Challenge summary */}
      <div className="box" style={{
        padding: 14,
        background:'rgba(212,255,58,0.06)',
        borderColor:'var(--matcha)'
      }}>
        <div className="row between middle">
          <div>
            <div className="md b">Sunrise Squad</div>
            <div className="row middle gap-2 tiny muted" style={{ marginTop: 2 }}>
              <Icon name="gym" size={12} stroke={2.2} />
              <span>Medium · 7 days · 4×/week</span>
            </div>
          </div>
          <div className="hand display" style={{ fontSize: 18, color:'var(--ochre)' }}>+200 ¢</div>
        </div>
      </div>

      {/* Invite link */}
      <div>
        <div className="tiny muted" style={{ letterSpacing:0.5, textTransform:'uppercase', marginBottom: 6 }}>Share link</div>
        <div className="row middle" style={{
          padding:'10px 12px',
          background: 'rgba(255,255,255,0.05)',
          borderRadius: 10
        }}>
          <span className="sm grow" style={{ fontFamily:'Inter', opacity: 0.85 }}>stepup.app/c/sunrise-squad</span>
          <span className="chip lime" style={{ padding:'4px 10px' }}>Copy</span>
        </div>
        <div className="row gap-2" style={{ marginTop: 8 }}>
          <span className="chip" style={{ padding:'6px 12px' }}>WhatsApp</span>
          <span className="chip" style={{ padding:'6px 12px' }}>Instagram</span>
          <span className="chip" style={{ padding:'6px 12px' }}>Telegram</span>
          <span className="chip" style={{ padding:'6px 12px' }}>More</span>
        </div>
      </div>

      <div>
        <div className="tiny muted" style={{ letterSpacing:0.5, textTransform:'uppercase', marginBottom: 6 }}>From your friends</div>
        <div className="col gap-2">
          {[
            ['Priya S',  '12d streak',  true],
            ['Aarav M',  'Top 5% · gym', true],
            ['Rohit K',  '9d streak',   false],
            ['Megha T',  'Yoga · 7d',   true],
            ['Vikram R', '5d streak',   false],
          ].map(([n, sub, on]) => (
            <div key={n} className="row between middle" style={{ padding:'6px 2px' }}>
              <div className="row middle gap-3">
                <div className="circ" style={{
                  width: 36, height: 36,
                  background:'rgba(255,255,255,0.06)',
                  display:'grid', placeItems:'center',
                  borderColor:'transparent',
                  fontSize: 14
                }}>{n[0]}</div>
                <div>
                  <div className="sm b">{n}</div>
                  <div className="tiny muted">{sub}</div>
                </div>
              </div>
              <span className={'chip' + (on ? ' lime' : '')} style={{ padding:'4px 10px' }}>
                {on ? '✓ Invited' : '+ Invite'}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="grow" />
      <div className="tiny muted tac">System will track everyone's consistency automatically</div>
      <button className="btn gold full">Launch challenge →</button>
    </div>
  </Phone>
);

// ============================================================
// LIVE TRACKING — daily check-in & consistency calendar
// ============================================================

const Live_DailyCheckin = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">Day 4 of 7</span>
      </div>
      <div className="hand xl">Check in</div>
      <div className="sm muted">7-Day Gym Consistency · today's status</div>
      <div className="col center" style={{ marginTop: 12, gap: 8 }}>
        <div style={{
          width: 130, height: 130,
          border:'3px solid var(--matcha)', borderRadius:'50%',
          display:'grid', placeItems:'center',
          background:'rgba(212,255,58,0.08)'
        }}>
          <div className="hand" style={{ fontSize: 36, color:'var(--matcha)', lineHeight:1 }}>✓</div>
        </div>
        <div className="hand lg">Done today!</div>
        <div className="sm muted tac">Gym session · 48 min · logged 2 hrs ago</div>
      </div>
      <Squiggle />
      <div className="tiny muted">Your week</div>
      <div className="row gap-2 between">
        {['M','T','W','T','F','S','S'].map((d,i) => {
          const state = i < 3 ? 'Done' : i === 3 ? 'Today' : 'Future';
          return (
            <div key={i} className="col center" style={{ flex: 1, gap: 4 }}>
              <div className="tiny muted">{d}</div>
              <div style={{
                width: 28, height: 28, borderRadius: 8,
                border: '1.5px solid ' + (state==='Future' ? 'var(--ink-3)' : 'var(--matcha)'),
                background: state==='Done' ? 'var(--matcha)' : state==='Today' ? 'rgba(212,255,58,0.2)' : 'transparent',
                color: state==='Done' ? '#0f0f1a' : 'var(--matcha)',
                display:'grid', placeItems:'center', fontSize: 12, fontWeight: 700
              }}>{state==='Done' ? '✓' : state==='Today' ? '●' : ''}</div>
            </div>
          );
        })}
      </div>
      <div className="grow" />
      <div className="box" style={{ padding: 10, borderColor:'var(--ochre)', background:'rgba(255,181,71,0.06)' }}>
        <div className="row between middle">
          <div className="tiny">Finish in top 50% to earn</div>
          <span className="chip gold">+200 ¢</span>
        </div>
      </div>
      <button className="btn ghost full">View consistency leaderboard →</button>
    </div>
  </Phone>
);

const Live_ConsistencyCal = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">May</span>
      </div>
      <div className="hand xl">Consistency</div>
      <div className="sm muted">Your streak across all challenges</div>
      <div className="box" style={{ padding: 12, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)' }}>
        <div className="row between middle">
          <div>
            <div className="tiny muted">Current streak</div>
            <div className="hand display" style={{ fontSize: 36, lineHeight: 1, color:'var(--matcha)' }}>12 Days ★</div>
          </div>
          <div className="col tac">
            <div className="tiny muted">Best</div>
            <div className="hand lg">28D</div>
          </div>
        </div>
      </div>
      <div className="tiny muted" style={{ marginTop: 4 }}>This month · 21 / 21 days active</div>
      <div className="row gap-2" style={{ flexWrap:'wrap' }}>
        {Array.from({length:30}).map((_,i) => {
          const intensity = [0,1,2,3,1,2,3,2,1,0,2,3,3,2,1,2,3,3,2,1,2,1,3,2,3,3,2,0,0,0][i % 30];
          const bg = intensity === 0 ? 'var(--paper-3)' :
                     intensity === 1 ? 'rgba(212,255,58,0.25)' :
                     intensity === 2 ? 'rgba(212,255,58,0.6)' : 'var(--matcha)';
          return (
            <div key={i} style={{
              width: 28, height: 28,
              background: bg,
              border: '1px solid var(--ink-3)',
              borderRadius: 4
            }} />
          );
        })}
      </div>
      <div className="row between tiny muted" style={{ marginTop: 4 }}>
        <span>Less</span>
        <div className="row gap-2">
          {['var(--paper-3)','rgba(212,255,58,0.25)','rgba(212,255,58,0.6)','var(--matcha)'].map((c,i) => (
            <div key={i} style={{ width:12, height:12, background: c, border:'1px solid var(--ink-3)', borderRadius:2 }} />
          ))}
        </div>
        <span>More</span>
      </div>
      <div className="grow" />
    </div>
  </Phone>
);

// ============================================================
// LEADERBOARD
// ============================================================

const Lead_Challenge = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="hand xl">Leaderboard</div>
      <div className="sm muted">7-Day Gym · day 4 of 7</div>
      <div className="row gap-2">
        <span className="chip lime">This challenge</span>
        <span className="chip">Friends</span>
        <span className="chip">Global</span>
      </div>
      <div className="box" style={{ padding: 10, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)' }}>
        <div className="row between middle">
          <div>
            <div className="tiny muted">You · #14 of 92</div>
            <div className="hand lg">Top 16% ★</div>
          </div>
          <div className="chip gold">On track for +200¢</div>
        </div>
      </div>
      <div className="tiny muted">Top 50% earn coins · cutoff at #46</div>
      <div className="col gap-2" style={{ overflow:'hidden' }}>
        {[
          ['#1',  'Aarav M', '100%', true],
          ['#2',  'Sneha R', '100%', true],
          ['#3',  'Vikram K','100%', true],
          ['#14', 'You',     '100%', true],
          ['#46', 'Last in top 50%','75%', true],
          ['cut', '',         '',     'line'],
          ['#47', 'Rohit S',  '71%',  false],
          ['#48', 'Kavya P',  '71%',  false],
        ].map(([r, n, c, on], i) => (
          on === 'line' ? (
            <div key={i} className="row middle gap-2" style={{ marginTop: 2, marginBottom: 2 }}>
              <div style={{ flex:1, height:1, background:'var(--clay)' }} />
              <span className="tiny" style={{ color:'var(--clay)' }}>Top 50% cutoff</span>
              <div style={{ flex:1, height:1, background:'var(--clay)' }} />
            </div>
          ) : (
            <div key={r} className={'row between middle box'} style={{
              padding: 8,
              borderColor: n === 'You' ? 'var(--matcha)' : 'var(--ink-3)',
              background: n === 'You' ? 'rgba(212,255,58,0.08)' : 'var(--paper-2)'
            }}>
              <div className="row middle gap-2">
                <span className="sm b" style={{ width: 32 }}>{r}</span>
                <span className="circ" style={{ width:22, height:22, display:'grid', placeItems:'center', fontSize:10, background:'var(--paper-3)' }}>
                  {n[0]}
                </span>
                <span className="sm">{n}</span>
              </div>
              <span className="sm b" style={{ color: on ? 'var(--matcha)' : 'var(--ink-3)' }}>{c}</span>
            </div>
          )
        ))}
      </div>
    </div>
    <TabBar active="lead" />
  </Phone>
);

const Lead_Friends = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="hand xl">Friends</div>
      <div className="sm muted">Consistency this month</div>
      <div className="row gap-2">
        <span className="chip">This challenge</span>
        <span className="chip lime">Friends</span>
        <span className="chip">Global</span>
      </div>
      <div className="box dashed" style={{ padding: 10 }}>
        <div className="row between middle">
          <div className="sm">Invite friends to compete</div>
          <span className="chip gold tiny">+50¢ Each</span>
        </div>
      </div>
      <div className="col gap-2">
        {[
          ['#1','Aarav M',  '28d streak', '94%'],
          ['#2','You',      '12d Streak', '88%', true],
          ['#3','Priya S',  '14d streak', '82%'],
          ['#4','Rohit K',  '9d streak',  '74%'],
          ['#5','Megha T',  '6d streak',  '63%'],
        ].map(([r, n, sub, c, me], i) => (
          <div key={r} className="row between middle box" style={{
            padding: 10,
            borderColor: me ? 'var(--matcha)' : 'var(--ink-3)',
            background: me ? 'rgba(212,255,58,0.08)' : 'var(--paper-2)'
          }}>
            <div className="row middle gap-3">
              <span className="sm b" style={{ width: 24 }}>{r}</span>
              <span className="circ" style={{ width:30, height:30, display:'grid', placeItems:'center', background:'var(--paper-3)' }}>{n[0]}</span>
              <div>
                <div className="sm b">{n}</div>
                <div className="tiny muted">{sub}</div>
              </div>
            </div>
            <span className="hand b" style={{ color:'var(--matcha)', fontSize:18 }}>{c}</span>
          </div>
        ))}
      </div>
    </div>
    <TabBar active="lead" />
  </Phone>
);

// ============================================================
// COINS & REWARDS
// ============================================================

const Coins_Wallet = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Coins</div>
        <span className="chip">History</span>
      </div>
      <div className="box" style={{ padding: 16, borderColor:'var(--ochre)', background:'rgba(255,181,71,0.06)' }}>
        <div className="tiny muted">Balance</div>
        <div className="row middle gap-2">
          <span style={{ color:'var(--ochre)', fontSize: 36 }}>¢</span>
          <span className="hand display" style={{ fontSize: 52, lineHeight:1, color:'var(--ochre)' }}>1,240</span>
        </div>
        <div className="tiny muted">≈ ₹240 In gift cards · 12 expire in 90 days</div>
      </div>
      <div className="row gap-2">
        <button className="btn gold full">Redeem →</button>
        <button className="btn ghost full">Earn more</button>
      </div>
      <Squiggle />
      <div className="tiny muted">Recent activity</div>
      <div className="col gap-2" style={{ overflow:'hidden' }}>
        {[
          ['Today',     'Finished "Yoga 5x"',       '+200', 'in'],
          ['Yesterday', 'Redeemed Amazon ₹100',     '-500', 'out'],
          ['2d ago',    'Daily check-in bonus',     '+10',  'in'],
          ['3d ago',    'Invited Priya',            '+50',  'in'],
          ['4d ago',    'Top 50% — "10k Steps"',    '+150', 'in'],
          ['5d ago',    'Streak bonus · 7 days',    '+70',  'in'],
        ].map(([d, msg, amt, dir]) => (
          <div key={d+msg} className="row between middle">
            <div>
              <div className="sm">{msg}</div>
              <div className="tiny muted">{d}</div>
            </div>
            <div className={dir==='in' ? '' : ''} style={{
              color: dir==='in' ? 'var(--matcha)' : 'var(--clay)',
              fontWeight: 700,
              fontFamily: 'Big Shoulders Display',
              fontSize: 18
            }}>{amt} ¢</div>
          </div>
        ))}
      </div>
    </div>
    <TabBar active="coins" />
  </Phone>
);

const Coins_GiftCards = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Redeem</div>
        <span className="chip gold">¢ 1,240</span>
      </div>
      <div className="row gap-2" style={{ overflowX:'auto' }}>
        {[['All',true],['Shopping',false],['Food',false],['Wellness',false],['Travel',false]].map(([t,on]) => (
          <span key={t} className={'chip' + (on ? ' lime' : '')}>{t}</span>
        ))}
      </div>
      <div className="row gap-2" style={{ flexWrap:'wrap' }}>
        {[
          ['Amazon',    '₹100', '500 ¢', true],
          ['Flipkart',  '₹100', '500 ¢', true],
          ['Swiggy',    '₹150', '750 ¢', true],
          ['Zomato',    '₹150', '750 ¢', true],
          ['Cult.fit',  '₹250', '1200¢', true],
          ['Decathlon', '₹500', '2400¢', false],
          ['Uber',      '₹100', '500 ¢', true],
          ['BookMyShow','₹200', '1000¢', true],
        ].map(([brand, value, cost, can]) => (
          <div key={brand} className="box" style={{
            flex:'1 1 45%', padding: 10,
            borderColor: can ? 'var(--ink-3)' : 'var(--ink-3)',
            opacity: can ? 1 : 0.5
          }}>
            <div className="box dashed" style={{
              height: 44, display:'grid', placeItems:'center',
              background: 'var(--paper-3)', borderColor: 'var(--ink-3)'
            }}>
              <span className="callout" style={{ fontSize: 13 }}>{brand}</span>
            </div>
            <div className="row between middle" style={{ marginTop: 6 }}>
              <span className="md b">{value}</span>
              <span className="chip gold tiny" style={{ padding:'2px 8px' }}>{cost}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
    <TabBar active="coins" />
  </Phone>
);

const Coins_RedeemConfirm = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">Redeem</span>
      </div>
      <div className="grow" style={{ maxHeight: 20 }} />
      <div className="col center" style={{ gap: 8 }}>
        <div className="box" style={{
          width: 200, height: 110,
          background: 'linear-gradient(135deg, rgba(255,181,71,0.2), rgba(212,255,58,0.15))',
          borderColor: 'var(--ochre)',
          display:'grid', placeItems:'center'
        }}>
          <div className="hand" style={{ fontSize: 28, color:'var(--ochre)' }}>Amazon ₹100</div>
        </div>
        <div className="hand lg">Amazon Gift Card</div>
        <div className="sm muted tac">Delivered to your email · valid for 1 year</div>
      </div>
      <Squiggle />
      <div className="col gap-2">
        <div className="row between"><span className="sm muted">Value</span><span className="sm b">₹100</span></div>
        <div className="row between"><span className="sm muted">Cost</span><span className="sm b" style={{ color:'var(--ochre)' }}>500 ¢</span></div>
        <div className="row between"><span className="sm muted">Balance after</span><span className="sm b">740 ¢</span></div>
        <div className="row between"><span className="sm muted">Deliver to</span><span className="sm b">Riya@gmail.com</span></div>
      </div>
      <div className="box dashed" style={{ padding: 8, marginTop: 4 }}>
        <div className="tiny muted">⚠ Once redeemed, coins cannot be refunded</div>
      </div>
      <div className="grow" />
      <button className="btn gold full">Confirm redeem →</button>
    </div>
  </Phone>
);

// ============================================================
// SUBSCRIPTION
// ============================================================

const Sub_Plans = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">Plans</span>
      </div>
      <div className="hand xl">Choose a plan</div>
      <div className="sm muted">Consistency rewards · cancel anytime</div>
      <div className="row gap-2" style={{ marginTop: 4 }}>
        <span className="chip lime">Monthly</span>
        <span className="chip">Yearly (save 20%)</span>
      </div>
      <div className="col gap-3" style={{ marginTop: 4 }}>
        <div className="box" style={{ padding: 12 }}>
          <div className="row between middle">
            <div className="hand lg">Free</div>
            <div className="hand b">₹0</div>
          </div>
          <div className="tiny muted">Forever</div>
          <div className="col gap-2" style={{ marginTop: 6 }}>
            <div className="tiny">✓ Track all activities</div>
            <div className="tiny">✓ Free challenges</div>
            <div className="tiny muted">✗ No coin rewards</div>
          </div>
          <div className="chip" style={{ marginTop: 8 }}>Current plan</div>
        </div>
        <div className="box" style={{ padding: 14, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)', position:'relative' }}>
          <span className="chip lime" style={{ position:'absolute', top:-10, right:14 }}>★ Recommended</span>
          <div className="row between middle">
            <div className="hand lg">Beginner</div>
            <div><span className="hand b">₹149</span><span className="tiny muted">/Mo</span></div>
          </div>
          <div className="tiny muted">Consistency rewards</div>
          <div className="col gap-2" style={{ marginTop: 6 }}>
            <div className="tiny">✓ 2 Paid challenges / month</div>
            <div className="tiny">✓ Earn coins for consistency</div>
            <div className="tiny">✓ Top 50% bonus</div>
            <div className="tiny">✓ Gift card redemption</div>
          </div>
        </div>
        <div className="box dashed" style={{ padding: 12, opacity: 0.7 }}>
          <div className="row between middle">
            <div className="hand lg">Pro</div>
            <div><span className="hand b">₹299</span><span className="tiny muted">/Mo</span></div>
          </div>
          <div className="tiny muted">Unlimited · coming soon</div>
        </div>
      </div>
      <div className="grow" />
      <button className="btn gold full">Start Beginner — ₹149/mo</button>
    </div>
  </Phone>
);

const Sub_Checkout = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">Secure checkout ◆</span>
      </div>
      <div className="hand xl">Beginner plan</div>
      <div className="box" style={{ padding: 12, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)' }}>
        <div className="row between">
          <span className="sm">Monthly subscription</span>
          <span className="sm b">₹149</span>
        </div>
        <div className="row between">
          <span className="tiny muted">GST (18%)</span>
          <span className="tiny muted">₹27</span>
        </div>
        <div className="row between" style={{ marginTop: 6, paddingTop: 6, borderTop: '1px dashed var(--ink-3)' }}>
          <span className="md b">Total today</span>
          <span className="md b" style={{ color:'var(--matcha)' }}>₹176</span>
        </div>
      </div>
      <div className="tiny muted">Payment method</div>
      <div className="col gap-2">
        {[['UPI', '●', true],['Card', '▢', false],['Net Banking', '▢', false]].map(([t,e,on]) => (
          <div key={t} className="box row between middle" style={{
            padding: 10,
            borderColor: on ? 'var(--matcha)' : 'var(--ink-3)',
            background: on ? 'rgba(212,255,58,0.06)' : 'var(--paper-2)'
          }}>
            <div className="row middle gap-2"><span>{e}</span><span className="sm b">{t}</span></div>
            <span className="circ" style={{ width: 18, height: 18, background: on ? 'var(--matcha)' : 'transparent' }} />
          </div>
        ))}
      </div>
      <div className="box dashed" style={{ padding: 8 }}>
        <div className="tiny muted">◈ First month perks</div>
        <div className="tiny">+ 100 Welcome coins</div>
        <div className="tiny">+ Early access to new challenges</div>
      </div>
      <div className="grow" />
      <button className="btn gold full">Pay ₹176 →</button>
      <div className="tiny muted tac">Renews monthly · cancel anytime in settings</div>
    </div>
  </Phone>
);

// ============================================================
// PROFILE
// ============================================================

const Profile_Me = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Me</div>
        <span>⚙</span>
      </div>
      <div className="row middle gap-3" style={{ marginTop: 4 }}>
        <div className="circ" style={{ width: 56, height: 56, display:'grid', placeItems:'center', background:'var(--paper-3)', borderColor:'var(--matcha)', borderWidth: 2, color:'var(--matcha)', fontSize: 24, fontFamily: 'Big Shoulders Display', fontWeight:700 }}>R</div>
        <div>
          <div className="hand lg">Riya M.</div>
          <div className="tiny muted">Joined apr 2024 · India</div>
          <span className="chip lime" style={{ marginTop:4 }}>Beginner plan</span>
        </div>
      </div>
      <div className="row gap-2" style={{ marginTop: 4 }}>
        <div className="box grow tac" style={{ padding: 8 }}><div className="tiny muted">Streak</div><div className="hand lg">12D</div></div>
        <div className="box grow tac" style={{ padding: 8 }}><div className="tiny muted">Challenges</div><div className="hand lg">10</div></div>
        <div className="box grow tac" style={{ padding: 8, borderColor:'var(--ochre)' }}><div className="tiny muted">Coins</div><div className="hand lg" style={{ color:'var(--ochre)' }}>1.2K</div></div>
      </div>
      <Squiggle />
      <div className="tiny muted">Recent badges</div>
      <div className="row gap-2" style={{ overflowX:'auto', paddingBottom: 4 }}>
        {[['★','12d Streak'],['G','Gym Pro'],['Y','Zen Master'],['W','10k Club'],['🎯','First Win']].map(([e,t]) => (
          <div key={t} className="box tac" style={{ minWidth: 70, padding: 8 }}>
            <div style={{ fontSize: 22 }}>{e}</div>
            <div className="tiny">{t}</div>
          </div>
        ))}
      </div>
      <div className="col gap-2" style={{ marginTop: 4 }}>
        {['Activity history','Achievements','Friends · 14','Plan & billing','Notifications','Help & support','Sign out'].map(t => (
          <div key={t} className="row between middle box" style={{ padding: 10 }}>
            <span className="sm">{t}</span>
            <span className="muted">→</span>
          </div>
        ))}
      </div>
    </div>
    <TabBar active="me" />
  </Phone>
);

const Profile_Achievements = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <span>←</span>
        <span className="tiny muted">14 / 36</span>
      </div>
      <div className="hand xl">Achievements</div>
      <div className="row gap-2">
        <span className="chip lime">Earned</span>
        <span className="chip">Locked</span>
      </div>
      <div className="row gap-3" style={{ flexWrap:'wrap', marginTop: 4 }}>
        {[
          ['★','7-Day Streak',true],
          ['R','10k Club',true],
          ['G','Gym Pro',true],
          ['Y','Zen Master',true],
          ['🎯','First Challenge',true],
          ['👑','Top 10%',false],
          ['💯','30-Day Streak',false],
          ['W','Early Bird',false],
          ['💪','Iron Will',false],
        ].map(([e,t,on]) => (
          <div key={t} className="box col center tac" style={{
            flex:'1 1 28%', height: 90, padding: 8,
            borderColor: on ? 'var(--matcha)' : 'var(--ink-3)',
            background: on ? 'rgba(212,255,58,0.06)' : 'var(--paper-2)',
            opacity: on ? 1 : 0.55
          }}>
            <div style={{ fontSize: 28, marginBottom: 4 }}>{e}</div>
            <div className="tiny">{t}</div>
          </div>
        ))}
      </div>
    </div>
  </Phone>
);

// ============================================================
// NOTIFICATIONS
// ============================================================

const Notif_Inbox = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="row between middle">
        <div className="hand xl">Activity</div>
        <span className="tiny muted">Mark all read</span>
      </div>
      <div className="row gap-2">
        <span className="chip lime">All</span>
        <span className="chip">Challenges</span>
        <span className="chip">Friends</span>
        <span className="chip">Coins</span>
      </div>
      <div className="col gap-2" style={{ overflow:'hidden' }}>
        {[
          ['Just now', 'trophy', 'You finished "10k Steps" — top 50%!', '+150 ¢', 'in'],
          ['1h ago',   'flame',  'You hit a 12-day streak!',             '+20 ¢',  'in'],
          ['3h ago',   'gym',    'Time to log your gym session',         '',       'remind'],
          ['Yest.',    'user',   'Priya joined "7-day Gym Consistency"', '',       'social'],
          ['Yest.',    'chart',  'Aarav passed you on the leaderboard',  '',       'social'],
          ['2d ago',   'coin',   '500 coins added — referred Megha',     '+500 ¢', 'in'],
          ['3d ago',   'gift',   'New gift card: Cult.fit ₹250 added',   '',       'system'],
        ].map(([t, ic, msg, amt, kind], i) => (
          <div key={i} className="row middle gap-2" style={{
            padding: 10,
            borderRadius: 12,
            background: i < 2 ? 'rgba(212,255,58,0.06)' : 'rgba(255,255,255,0.03)'
          }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              display:'grid', placeItems:'center',
              background: i < 2 ? 'rgba(212,255,58,0.12)' : 'rgba(255,255,255,0.06)',
              color: i < 2 ? 'var(--matcha)' : 'var(--ink)'
            }}>
              <Icon name={ic} size={18} stroke={2} />
            </div>
            <div className="grow">
              <div className="sm">{msg}</div>
              <div className="tiny muted">{t}</div>
            </div>
            {amt && <span className="chip gold" style={{ padding:'2px 8px' }}>{amt}</span>}
          </div>
        ))}
      </div>
    </div>
  </Phone>
);

// ============================================================
// FINAL APP — assemble all sections
// ============================================================

const App = () => (
  <DesignCanvas
    title="StepUp · Wireframes"
    subtitle="End-to-end wellness app · subscription-based · earn coins → redeem gift cards"
  >
    <DCSection id="start" title="01 · App start" subtitle="Splash, login, OTP, social signup">
      <DCArtboard id="start-a" label="A · Logo splash" width={340} height={680}>
        <Frame note="Minimal · brand-first · tap to begin">
          <Start_A />
        </Frame>
      </DCArtboard>
      <DCArtboard id="start-b" label="B · Loading splash" width={340} height={680}>
        <Frame note="Auto-advancing while pre-fetching health data">
          <Start_B />
        </Frame>
      </DCArtboard>
      <DCArtboard id="start-c" label="C · Hero + sign-up" width={340} height={680}>
        <Frame note="value prop + 'Get started' / 'Sign In'">
          <Start_C />
        </Frame>
      </DCArtboard>
      <DCArtboard id="auth-login" label="D · Login (phone)" width={340} height={680}>
        <Frame note="Phone-first with Google/Apple fallback">
          <Auth_Login />
        </Frame>
      </DCArtboard>
      <DCArtboard id="auth-otp" label="E · OTP verify" width={340} height={680}>
        <Frame note="6-Digit · auto-detect · resend timer">
          <Auth_OTP />
        </Frame>
      </DCArtboard>
      <DCArtboard id="auth-social" label="F · Social signup" width={340} height={680}>
        <Frame note="Google · Apple · Phone">
          <Auth_Social />
        </Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="onb" title="02 · Onboarding" subtitle="Value prop, goal, permissions, plan">
      <DCArtboard id="onb-a" label="A · 3-slide carousel" width={340} height={680}>
        <Frame note="Classic — track, join, earn"><Onb_Carousel /></Frame>
      </DCArtboard>
      <DCArtboard id="onb-b" label="B · Single page" width={340} height={680}>
        <Frame note="All 4 value props on one screen"><Onb_OnePage /></Frame>
      </DCArtboard>
      <DCArtboard id="onb-c" label="C · Activity picker" width={340} height={680}>
        <Frame note="What activities do you do? — drives feed"><Onb_GoalPicker /></Frame>
      </DCArtboard>
      <DCArtboard id="onb-d" label="D · Permissions" width={340} height={680}>
        <Frame note="Health, notif, location"><Onb_Permissions /></Frame>
      </DCArtboard>
      <DCArtboard id="onb-e" label="E · Plan picker" width={340} height={680}>
        <Frame note="Free vs Beginner ₹149/mo — last step in onboarding"><Onb_PlanPicker /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="prof" title="03 · Profile setup" subtitle="Name, body, goal, activities">
      <DCArtboard id="prof-a" label="A · Wizard" width={340} height={680}>
        <Frame note="4 Steps · progress bar"><Prof_Wizard /></Frame>
      </DCArtboard>
      <DCArtboard id="prof-b" label="B · Single form" width={340} height={680}>
        <Frame note="All fields visible · skip what you want"><Prof_OneForm /></Frame>
      </DCArtboard>
      <DCArtboard id="prof-c" label="C · Quick cards" width={340} height={680}>
        <Frame note="3 Large tap-targets"><Prof_QuickCards /></Frame>
      </DCArtboard>
      <DCArtboard id="prof-d" label="D · Conversational" width={340} height={680}>
        <Frame note="Chat-style · lighter feel"><Prof_Chat /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="dash" title="04 · Dashboard" subtitle="multi-activity overview · today's wellness">
      <DCArtboard id="dash-a" label="A · Activity ring" width={340} height={680}>
        <Frame note="Ring + active challenge + streak + coins"><Dash_Ring /></Frame>
      </DCArtboard>
      <DCArtboard id="dash-b" label="B · Stats grid" width={340} height={680}>
        <Frame note="Data-rich · weekly chart"><Dash_StatsGrid /></Frame>
      </DCArtboard>
      <DCArtboard id="dash-c" label="C · Activity feed" width={340} height={680}>
        <Frame note="Every event of your day"><Dash_Feed /></Frame>
      </DCArtboard>
      <DCArtboard id="dash-d" label="D · Hub of tiles" width={340} height={680}>
        <Frame note="Bento — easy nav to each feature"><Dash_Hub /></Frame>
      </DCArtboard>
      <DCArtboard id="dash-e" label="E · Card stack" width={340} height={680}>
        <Frame note="Swipeable · today · streak · challenge · coins"><Dash_CardStack /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="act" title="05 · Activities" subtitle="Multi-category — gym, sport, yoga, run, walk">
      <DCArtboard id="act-a" label="A · Activity types" width={340} height={680}>
        <Frame note="all categories · today's status per type"><Act_Types /></Frame>
      </DCArtboard>
      <DCArtboard id="act-b" label="B · Log a session" width={340} height={680}>
        <Frame note="Quick log · duration · intensity · auto-link to challenge"><Act_LogSession /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="chal" title="06 · Challenges" subtitle="Discover, join, create, share">
      <DCArtboard id="chal-a" label="A · Discover" width={340} height={680}>
        <Frame note="By category · for you · '+ Create your own' CTA up top"><Chal_Discover /></Frame>
      </DCArtboard>
      <DCArtboard id="chal-b" label="B · My challenges" width={340} height={680}>
        <Frame note="Active + done + saved · day-by-day grid"><Chal_MyChallenges /></Frame>
      </DCArtboard>
      <DCArtboard id="chal-c" label="C · Challenge detail" width={340} height={680}>
        <Frame note="Rules · participants · reward · how it works"><Chal_Detail /></Frame>
      </DCArtboard>
      <DCArtboard id="chal-d" label="D · Upgrade prompt" width={340} height={680}>
        <Frame note="Shown when free user taps a paid challenge"><Chal_UpgradePrompt /></Frame>
      </DCArtboard>
      <DCArtboard id="chal-create" label="E · Create custom challenge" width={340} height={680}>
        <Frame note="Pick category, difficulty (system auto-rewards), duration, frequency"><Chal_Create /></Frame>
      </DCArtboard>
      <DCArtboard id="chal-share" label="F · Invite friends" width={340} height={680}>
        <Frame note="Share link + tap-to-invite from friends list"><Chal_Share /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="live" title="07 · Live tracking" subtitle="Daily check-in · consistency calendar">
      <DCArtboard id="live-a" label="A · Daily check-in" width={340} height={680}>
        <Frame note="today's status in active challenge · week strip"><Live_DailyCheckin /></Frame>
      </DCArtboard>
      <DCArtboard id="live-b" label="B · Consistency calendar" width={340} height={680}>
        <Frame note="Github-style heatmap · streak history"><Live_ConsistencyCal /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="lead" title="08 · Leaderboard" subtitle="Consistency ranking · top 50% earn coins">
      <DCArtboard id="lead-a" label="A · Challenge leaderboard" width={340} height={680}>
        <Frame note="Your rank · top 50% cutoff line · no money shown"><Lead_Challenge /></Frame>
      </DCArtboard>
      <DCArtboard id="lead-b" label="B · Friends ranking" width={340} height={680}>
        <Frame note="Invite friends · monthly consistency %"><Lead_Friends /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="coins" title="09 · Coins & Rewards" subtitle="Balance, gift cards, redeem">
      <DCArtboard id="coins-a" label="A · Coins wallet" width={340} height={680}>
        <Frame note="Balance · history · how to earn more"><Coins_Wallet /></Frame>
      </DCArtboard>
      <DCArtboard id="coins-b" label="B · Gift card catalog" width={340} height={680}>
        <Frame note="brands · cost in coins · greyed if can't afford"><Coins_GiftCards /></Frame>
      </DCArtboard>
      <DCArtboard id="coins-c" label="C · Redeem confirm" width={340} height={680}>
        <Frame note="Preview · cost · balance after · confirm"><Coins_RedeemConfirm /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="sub" title="10 · Subscription" subtitle="Plans, checkout, billing">
      <DCArtboard id="sub-a" label="A · Plans" width={340} height={680}>
        <Frame note="Free · Beginner ₹149 · Pro (coming)"><Sub_Plans /></Frame>
      </DCArtboard>
      <DCArtboard id="sub-b" label="B · Checkout" width={340} height={680}>
        <Frame note="UPI / card / netbanking · welcome perks"><Sub_Checkout /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="me" title="11 · Profile" subtitle="Me, achievements, settings">
      <DCArtboard id="profile-a" label="A · Me" width={340} height={680}>
        <Frame note="Avatar · stats · badges · settings list"><Profile_Me /></Frame>
      </DCArtboard>
      <DCArtboard id="profile-b" label="B · Achievements" width={340} height={680}>
        <Frame note="Earned / locked grid"><Profile_Achievements /></Frame>
      </DCArtboard>
    </DCSection>

    <DCSection id="notif" title="12 · Notifications" subtitle="Inbox · in-app feed">
      <DCArtboard id="notif-a" label="A · Inbox" width={340} height={680}>
        <Frame note="Rewards · reminders · social · system"><Notif_Inbox /></Frame>
      </DCArtboard>
    </DCSection>
  </DesignCanvas>
);

// Export all extra components to window so canvas-mount can use them
Object.assign(window, {
  Onb_PlanPicker,
  Act_Types, Act_LogSession,
  Chal_Discover, Chal_MyChallenges, Chal_Detail, Chal_UpgradePrompt, Chal_Create, Chal_Share,
  Live_DailyCheckin, Live_ConsistencyCal,
  Lead_Challenge, Lead_Friends,
  Coins_Wallet, Coins_GiftCards, Coins_RedeemConfirm,
  Sub_Plans, Sub_Checkout,
  Profile_Me, Profile_Achievements,
  Notif_Inbox,
  App,
});

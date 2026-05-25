/* StepUp wireframes — PRO features: League, Battles, Rewards, Battle Pass, Community */
/* eslint-disable */

const {
  Phone, Squiggle, Icon, TabBar, Frame,
} = window;

// ============================================================
// LEAGUE SYSTEM
// ============================================================

const TIERS = [
  ['Bronze',   '#a86a3a', false],
  ['Silver',   '#9aa3ad', false],
  ['Gold',     '#d9a93a', true],     // current
  ['Platinum', '#7ed4d4', false],    // paid gate
  ['Diamond',  '#a8c4ff', false],
  ['Elite',    '#d4ff3a', false],
];

const TierBadge = ({ color, size = 60, label, glow = false }) => (
  <div style={{
    width: size, height: size,
    borderRadius: '50%',
    background: `radial-gradient(circle at 30% 30%, ${color}, ${color}66 60%, transparent)`,
    border: `2px solid ${color}`,
    boxShadow: glow ? `0 0 24px ${color}55` : 'none',
    display: 'grid', placeItems: 'center',
    position: 'relative'
  }}>
    <Icon name="medal" size={size * 0.45} stroke={2.2} color="#0a0a14" />
    {label && (
      <div style={{
        position:'absolute', bottom: -18, left: '50%', transform:'translateX(-50%)',
        fontFamily: "'Big Shoulders Display', sans-serif",
        fontWeight: 800, fontSize: 11, letterSpacing: 1, color: color,
        textTransform: 'uppercase'
      }}>{label}</div>
    )}
  </div>
);

const League_Hub = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">League</div>
        <span className="chip">Season 4</span>
      </div>

      {/* Current tier hero */}
      <div className="col center" style={{
        padding:'20px 16px 18px',
        background:'radial-gradient(circle at 50% 0%, rgba(217,169,58,0.16), transparent 70%)',
        borderRadius: 16
      }}>
        <TierBadge color="#d9a93a" size={88} glow />
        <div className="hand display" style={{ fontSize: 28, color:'#d9a93a', marginTop: 24, letterSpacing: 1 }}>GOLD III</div>
        <div className="tiny muted" style={{ marginTop: 2 }}>Rank 142 of 8,420 in your league</div>
        <div style={{ width:'100%', marginTop: 14 }}>
          <div className="row between tiny muted" style={{ marginBottom: 6 }}>
            <span>1,840 XP</span>
            <span>→ Platinum (2,500 XP)</span>
          </div>
          <div style={{ height: 6, background:'rgba(255,255,255,0.06)', borderRadius: 4 }}>
            <div style={{ height:'100%', width:'73%', background:'#d9a93a', borderRadius: 4 }} />
          </div>
        </div>
      </div>

      {/* Ladder */}
      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Tier Ladder</div>
      <div className="col gap-2">
        {TIERS.map(([name, color, current], i) => {
          const locked = i > 2;
          const paidGate = name === 'Platinum';
          return (
            <div key={name} className="row middle gap-3" style={{
              padding:'10px 12px',
              borderRadius: 12,
              background: current ? 'rgba(217,169,58,0.12)' : 'rgba(255,255,255,0.03)',
              border: '1.5px solid ' + (current ? color : 'transparent')
            }}>
              <TierBadge color={color} size={36} />
              <div className="grow">
                <div className="row middle gap-2">
                  <span className="md b" style={{ color: current ? color : 'var(--ink)' }}>{name}</span>
                  {paidGate && <span className="chip gold" style={{ padding:'2px 8px' }}>PRO</span>}
                  {current && <span className="chip lime" style={{ padding:'2px 8px' }}>YOU</span>}
                </div>
                <div className="tiny muted">{['Tier I–III', 'Tier I–III', 'Tier I–III', 'Premium only', 'Top 10%', 'Top 1%'][i]}</div>
              </div>
              {locked && !current && <Icon name="lock" size={16} stroke={2.2} color="var(--ink-3)" />}
            </div>
          );
        })}
      </div>
    </div>
    <TabBar active="lead" />
  </Phone>
);

const League_Standings = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <span className="row middle gap-2"><Icon name="arrowLeft" size={18} /><span className="sm muted">Back</span></span>
        <span className="chip" style={{ background:'rgba(217,169,58,0.15)', color:'#d9a93a' }}>GOLD III</span>
      </div>
      <div className="hand xl">Standings</div>
      <div className="row middle gap-2">
        <Icon name="clock" size={14} color="var(--ink-3)" />
        <span className="tiny muted">Resets in 4d 12h · top 25% promote · bottom 15% relegate</span>
      </div>

      {/* You card */}
      <div style={{
        padding:'12px 14px',
        background:'rgba(212,255,58,0.08)',
        borderRadius: 12,
        border:'1.5px solid var(--matcha)'
      }}>
        <div className="row between middle">
          <div className="row middle gap-3">
            <div className="hand display" style={{ fontSize: 24, color:'var(--matcha)' }}>#142</div>
            <div>
              <div className="md b">You · Riya</div>
              <div className="tiny muted">1,840 XP this week</div>
            </div>
          </div>
          <div className="col" style={{ alignItems:'flex-end' }}>
            <span className="tiny" style={{ color:'var(--matcha)' }}>▲ 12</span>
            <span className="tiny muted">since yest.</span>
          </div>
        </div>
      </div>

      <div className="col">
        {[
          ['#1',   'Aarav M',    '4,820 XP', 'promote'],
          ['#2',   'Sneha R',    '4,610 XP', 'promote'],
          ['#3',   'Vikram K',   '4,480 XP', 'promote'],
          ['#142', 'You',        '1,840 XP', 'you'],
          ['#143', 'Karthik N',  '1,820 XP', ''],
          ['#144', 'Priya S',    '1,795 XP', ''],
          ['cut',  '',           '',         'cut'],
          ['#7156','Drift Zone', '',         'relegate'],
        ].map(([r, n, xp, k], i) => (
          k === 'cut' ? (
            <div key={i} className="row middle gap-2" style={{ padding:'10px 0' }}>
              <div style={{ flex:1, height:1, background:'var(--clay)' }} />
              <span className="tiny" style={{ color:'var(--clay)', letterSpacing:0.6, textTransform:'uppercase' }}>Relegation zone</span>
              <div style={{ flex:1, height:1, background:'var(--clay)' }} />
            </div>
          ) : (
            <div key={r} className="row between middle" style={{
              padding:'10px 12px',
              borderRadius: 10,
              background: n==='You' ? 'rgba(212,255,58,0.06)' : 'transparent'
            }}>
              <div className="row middle gap-3">
                <span className="hand display" style={{ fontSize: 16, width: 44, color: k==='promote' ? 'var(--matcha)' : 'var(--ink-3)' }}>{r}</span>
                <span style={{
                  width: 26, height: 26, borderRadius:'50%',
                  background:'rgba(255,255,255,0.06)',
                  display:'grid', placeItems:'center', fontSize: 11, fontWeight: 700
                }}>{n[0]}</span>
                <span className="sm">{n}</span>
              </div>
              <span className="sm muted">{xp}</span>
            </div>
          )
        ))}
      </div>
    </div>
    <TabBar active="lead" />
  </Phone>
);

// ============================================================
// SEASONAL CHALLENGES + TOURNAMENT
// ============================================================

const Chal_Seasonal = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Challenges</div>
        <Icon name="search" size={20} stroke={2.2} />
      </div>
      <div className="row gap-2" style={{ overflowX:'auto' }}>
        {[['Daily',false],['Weekly',true],['Monthly',false],['Seasonal',false]].map(([t,on]) => (
          <span key={t} className={'chip' + (on ? ' lime' : '')} style={{ padding:'6px 14px' }}>{t}</span>
        ))}
      </div>

      {/* Featured tournament */}
      <div style={{
        padding: 16, borderRadius: 14,
        background:'linear-gradient(135deg, rgba(212,255,58,0.12), rgba(255,181,71,0.08))',
        border:'1px solid rgba(212,255,58,0.3)',
        position:'relative', overflow:'hidden'
      }}>
        <span className="chip lime" style={{ position:'absolute', top: 12, right: 12, padding:'3px 10px' }}>FEATURED</span>
        <Icon name="trophy" size={36} stroke={2.2} color="var(--matcha)" />
        <div className="display" style={{ fontSize: 26, marginTop: 8, lineHeight: 1, color:'var(--matcha)' }}>
          HYDERABAD<br/>STEP CUP
        </div>
        <div className="sm muted" style={{ marginTop: 4 }}>City-wide tournament · 2 weeks</div>
        <div className="row middle gap-3" style={{ marginTop: 12 }}>
          <div><div className="tiny muted">Prize pool</div><div className="hand display" style={{ fontSize: 20, color:'var(--ochre)' }}>50K ¢</div></div>
          <div><div className="tiny muted">Joined</div><div className="hand display" style={{ fontSize: 20 }}>3,240</div></div>
          <div><div className="tiny muted">Starts</div><div className="hand display" style={{ fontSize: 20 }}>2d</div></div>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>This week</div>
      <div className="col gap-2">
        {[
          ['Summer Shred',          'fire',   '14 days · gym 4×/wk', '+800 ¢', '2,140 joined'],
          ['Sunrise Streak',        'flame',  '7 days · wake before 7AM', '+200 ¢', '480 joined'],
          ['Step Sprint Weekend',   'run',    '2 days · 25k steps', '+150 ¢', '1,820 joined'],
          ['Mindful Mornings',      'mind',   '21 days · meditate', '+400 ¢', '320 joined'],
        ].map(([t, ic, sub, reward, joined]) => (
          <div key={t} className="row middle gap-3" style={{
            padding:'12px 14px',
            background:'rgba(255,255,255,0.04)',
            borderRadius: 12
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background:'rgba(255,255,255,0.06)',
              display:'grid', placeItems:'center'
            }}>
              <Icon name={ic} size={20} stroke={2.2} />
            </div>
            <div className="grow">
              <div className="md b">{t}</div>
              <div className="tiny muted">{sub} · {joined}</div>
            </div>
            <span className="chip gold" style={{ padding:'4px 10px' }}>{reward}</span>
          </div>
        ))}
      </div>
    </div>
    <TabBar active="chal" />
  </Phone>
);

const Tournament_Detail = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12 }}>
      <div className="row between middle">
        <Icon name="arrowLeft" size={22} stroke={2.2} />
        <Icon name="share" size={20} stroke={2.2} />
      </div>

      {/* Cover */}
      <div style={{
        borderRadius: 14, padding: 18,
        background:'linear-gradient(160deg, #1a2410 0%, #0a0a14 100%)',
        border:'1px solid rgba(212,255,58,0.25)',
        minHeight: 130
      }}>
        <span className="chip lime" style={{ padding:'3px 10px' }}>NEW YEAR TRANSFORMATION</span>
        <div className="display" style={{ fontSize: 30, lineHeight: 0.95, marginTop: 10, color:'var(--matcha)' }}>
          21-DAY<br/>RESET
        </div>
        <div className="sm muted" style={{ marginTop: 6 }}>Jan 1 — Jan 21 · Seasonal Battle Pass tied</div>
      </div>

      <div className="row gap-2">
        <div style={{ flex:1, padding:10, background:'rgba(255,255,255,0.04)', borderRadius: 10 }}>
          <div className="tiny muted">Duration</div>
          <div className="hand display" style={{ fontSize: 20 }}>21D</div>
        </div>
        <div style={{ flex:1, padding:10, background:'rgba(255,255,255,0.04)', borderRadius: 10 }}>
          <div className="tiny muted">Players</div>
          <div className="hand display" style={{ fontSize: 20 }}>12.4K</div>
        </div>
        <div style={{ flex:1, padding:10, background:'rgba(255,181,71,0.08)', borderRadius: 10 }}>
          <div className="tiny muted">Reward</div>
          <div className="hand display" style={{ fontSize: 20, color:'var(--ochre)' }}>2K ¢</div>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Daily Goals</div>
      <div className="col gap-2">
        {[
          ['walk',   '10,000 steps'],
          ['gym',    '30 min gym OR 1 sport session'],
          ['droplet','Hit 2.5L water'],
          ['moon',   'Sleep 7+ hours'],
        ].map(([ic, msg]) => (
          <div key={msg} className="row middle gap-3" style={{ padding:'10px 0' }}>
            <Icon name={ic} size={18} stroke={2.2} color="var(--matcha)" />
            <span className="sm">{msg}</span>
          </div>
        ))}
      </div>

      <div style={{
        padding:'10px 14px', borderRadius: 10,
        background:'rgba(255,181,71,0.08)',
        border:'1px solid rgba(255,181,71,0.2)'
      }}>
        <div className="row middle gap-2">
          <Icon name="info" size={14} color="var(--ochre)" />
          <span className="tiny">Battle Pass exclusive · finish top 50% for Pro frame</span>
        </div>
      </div>

      <div className="grow" />
      <button className="btn lime full">Join Tournament</button>
    </div>
  </Phone>
);

// ============================================================
// RIVALS + BATTLES
// ============================================================

const Rivals_List = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Rivals</div>
        <Icon name="userPlus" size={20} stroke={2.2} />
      </div>
      <div className="sm muted">Compete head-to-head this week</div>

      {/* Active battle */}
      <div style={{
        padding: 14, borderRadius: 14,
        background:'rgba(212,255,58,0.06)',
        border:'1.5px solid var(--matcha)'
      }}>
        <div className="row between middle">
          <span className="chip lime" style={{ padding:'3px 8px' }}>LIVE BATTLE</span>
          <span className="tiny muted">2d 14h left</span>
        </div>
        <div className="row middle" style={{ marginTop: 10 }}>
          <div className="col center grow">
            <div style={{ width: 48, height: 48, borderRadius:'50%', background:'rgba(212,255,58,0.15)', display:'grid', placeItems:'center', color:'var(--matcha)' }}>R</div>
            <div className="sm b" style={{ marginTop: 4 }}>You</div>
            <div className="hand display" style={{ fontSize: 26, color:'var(--matcha)' }}>4.2K</div>
          </div>
          <div className="hand display" style={{ fontSize: 20, color:'var(--ink-3)' }}>VS</div>
          <div className="col center grow">
            <div style={{ width: 48, height: 48, borderRadius:'50%', background:'rgba(255,255,255,0.06)', display:'grid', placeItems:'center' }}>A</div>
            <div className="sm b" style={{ marginTop: 4 }}>Aarav</div>
            <div className="hand display" style={{ fontSize: 26 }}>3.8K</div>
          </div>
        </div>
        <button className="btn lime full" style={{ marginTop: 12, padding:'10px 16px' }}>View battle →</button>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Your rivals</div>
      <div className="col gap-2">
        {[
          ['Priya S',   '12d streak',  'You lead +840', 'win'],
          ['Karthik N', 'Gold II',     'Behind by 220', 'lose'],
          ['Megha T',   'Yoga master', 'Tied',          'tie'],
          ['Vikram R',  'Platinum I',  'Behind by 1.4K','lose'],
        ].map(([n, sub, status, k]) => (
          <div key={n} className="row middle gap-3" style={{ padding:'10px 12px', background:'rgba(255,255,255,0.03)', borderRadius: 12 }}>
            <div style={{ width: 38, height: 38, borderRadius:'50%', background:'rgba(255,255,255,0.06)', display:'grid', placeItems:'center', fontWeight: 700 }}>{n[0]}</div>
            <div className="grow">
              <div className="sm b">{n}</div>
              <div className="tiny muted">{sub}</div>
            </div>
            <span className="chip" style={{
              padding:'3px 10px',
              background: k==='win' ? 'rgba(212,255,58,0.12)' : k==='lose' ? 'rgba(201,122,78,0.12)' : 'rgba(255,255,255,0.06)',
              color: k==='win' ? 'var(--matcha)' : k==='lose' ? 'var(--clay)' : 'var(--ink-2)'
            }}>{status}</span>
          </div>
        ))}
      </div>

      <div style={{
        padding:'12px 14px', borderRadius: 12,
        background:'rgba(255,255,255,0.03)',
        border:'1px dashed rgba(255,255,255,0.12)'
      }}>
        <div className="row middle gap-2">
          <Icon name="swords" size={16} color="var(--matcha)" />
          <span className="sm b">Find a rival</span>
        </div>
        <div className="tiny muted" style={{ marginTop: 2 }}>Match with someone your level for a weekly battle</div>
      </div>
    </div>
    <TabBar active="lead" />
  </Phone>
);

const Battle_Detail = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14 }}>
      <div className="row between middle">
        <Icon name="arrowLeft" size={22} stroke={2.2} />
        <span className="chip lime" style={{ padding:'3px 10px' }}>WEEK 21 · LIVE</span>
      </div>
      <div className="display" style={{ fontSize: 24, color:'var(--matcha)' }}>WEEKLY BATTLE</div>

      {/* Versus */}
      <div className="row middle" style={{ padding:'18px 0' }}>
        <div className="col center grow">
          <div style={{ width: 70, height: 70, borderRadius:'50%', background:'radial-gradient(circle, rgba(212,255,58,0.25), transparent 70%)', border:'2px solid var(--matcha)', display:'grid', placeItems:'center', color:'var(--matcha)', fontSize: 28, fontFamily:"'Big Shoulders Display'", fontWeight: 800 }}>R</div>
          <div className="md b" style={{ marginTop: 6 }}>You</div>
          <div className="tiny muted">Gold III</div>
          <div className="hand display" style={{ fontSize: 36, color:'var(--matcha)', marginTop: 6 }}>4,240</div>
        </div>
        <div className="col center" style={{ width: 50 }}>
          <Icon name="swords" size={26} stroke={2.2} color="var(--clay)" />
          <div className="hand display" style={{ fontSize: 14, color:'var(--ink-3)', marginTop: 4 }}>VS</div>
        </div>
        <div className="col center grow">
          <div style={{ width: 70, height: 70, borderRadius:'50%', background:'rgba(255,255,255,0.05)', border:'2px solid rgba(255,255,255,0.15)', display:'grid', placeItems:'center', fontSize: 28, fontFamily:"'Big Shoulders Display'", fontWeight: 800 }}>A</div>
          <div className="md b" style={{ marginTop: 6 }}>Aarav</div>
          <div className="tiny muted">Gold III</div>
          <div className="hand display" style={{ fontSize: 36, marginTop: 6 }}>3,890</div>
        </div>
      </div>

      <div style={{ height: 8, background:'rgba(255,255,255,0.06)', borderRadius: 4, overflow:'hidden' }}>
        <div style={{ height:'100%', width:'52%', background:'var(--matcha)' }} />
      </div>
      <div className="row between tiny muted">
        <span>52%</span>
        <span>2d 14h left</span>
        <span>48%</span>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase', marginTop: 4 }}>Breakdown</div>
      <div className="col gap-2">
        {[
          ['Steps',     '32,400', '28,800'],
          ['Gym',       '4 sessions', '3 sessions'],
          ['Mindful',   '90 min', '40 min'],
          ['Streak',    '12d', '9d'],
        ].map(([cat, you, them]) => (
          <div key={cat} className="row between middle" style={{ padding:'6px 0', borderBottom:'1px solid rgba(255,255,255,0.05)' }}>
            <span className="sm muted" style={{ width: 80 }}>{cat}</span>
            <span className="sm b" style={{ color:'var(--matcha)' }}>{you}</span>
            <span className="tiny muted">vs</span>
            <span className="sm">{them}</span>
          </div>
        ))}
      </div>

      <div className="grow" />
      <div style={{ padding:'10px 12px', borderRadius: 10, background:'rgba(255,181,71,0.08)' }}>
        <div className="row middle gap-2">
          <Icon name="award" size={14} color="var(--ochre)" />
          <span className="tiny">Winner takes +150 ¢ and reputation bonus</span>
        </div>
      </div>
    </div>
  </Phone>
);

// ============================================================
// REWARDS MARKETPLACE — aspirational
// ============================================================

const Marketplace = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Rewards</div>
        <span className="chip gold" style={{ padding:'4px 10px' }}>1,240 ¢</span>
      </div>
      <div className="row gap-2" style={{ overflowX:'auto' }}>
        {[['All',true],['Tech',false],['Apparel',false],['Nutrition',false],['Memberships',false],['Vouchers',false]].map(([t,on]) => (
          <span key={t} className={'chip' + (on ? ' lime' : '')} style={{ padding:'6px 14px' }}>{t}</span>
        ))}
      </div>

      {/* Featured aspirational */}
      <div style={{
        padding: 16, borderRadius: 14,
        background:'linear-gradient(135deg, rgba(255,181,71,0.10) 0%, rgba(212,255,58,0.06) 100%)',
        border:'1px solid rgba(255,181,71,0.25)',
        position:'relative', overflow:'hidden'
      }}>
        <span className="chip" style={{ position:'absolute', top: 12, right: 12, padding:'3px 8px', background:'rgba(255,181,71,0.2)', color:'var(--ochre)' }}>ELITE</span>
        <Icon name="watch" size={36} stroke={2.2} color="var(--ochre)" />
        <div className="display" style={{ fontSize: 22, marginTop: 8, lineHeight: 1 }}>APPLE WATCH<br/>SERIES 10</div>
        <div className="tiny muted" style={{ marginTop: 6 }}>Elite tier exclusive · ships in 5 days</div>
        <div className="row between middle" style={{ marginTop: 12 }}>
          <div className="hand display" style={{ fontSize: 22, color:'var(--ochre)' }}>48,000 ¢</div>
          <span className="chip" style={{ padding:'4px 10px', background:'rgba(255,255,255,0.06)' }}>Reach Elite →</span>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>You can redeem</div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap: 10 }}>
        {[
          ['Nike Run Shoes',   'sport',    '12,000 ¢', false],
          ['Cult.fit · 3mo',   'gym',      '8,400 ¢',  false],
          ['MyProtein · 1kg',  'activity', '3,200 ¢',  false],
          ['Amazon ₹500',      'gift',     '2,500 ¢',  false],
          ['boAt Watch',       'watch',    '4,800 ¢',  false],
          ['Yoga Mat · Premium','yoga',    '1,200 ¢',  true],
        ].map(([name, ic, cost, can]) => (
          <div key={name} style={{
            padding: 12, borderRadius: 12,
            background:'rgba(255,255,255,0.04)',
            opacity: can ? 1 : 0.6
          }}>
            <div style={{
              height: 60, borderRadius: 8,
              background:'rgba(255,255,255,0.04)',
              display:'grid', placeItems:'center', marginBottom: 8
            }}>
              <Icon name={ic} size={28} stroke={2} color="var(--ink-2)" />
            </div>
            <div className="sm b" style={{ lineHeight: 1.2 }}>{name}</div>
            <div className="row between middle" style={{ marginTop: 4 }}>
              <span className="tiny" style={{ color: can ? 'var(--matcha)' : 'var(--ochre)' }}>{cost}</span>
              {can && <Icon name="check" size={12} color="var(--matcha)" />}
            </div>
          </div>
        ))}
      </div>
    </div>
    <TabBar active="coins" />
  </Phone>
);

// ============================================================
// FITNESS REPUTATION + XP
// ============================================================

const Reputation = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14, paddingBottom: 44 }}>
      <div className="row between middle">
        <Icon name="arrowLeft" size={22} stroke={2.2} />
        <span className="chip">Public</span>
      </div>

      <div className="display" style={{ fontSize: 24 }}>FITNESS REPUTATION</div>

      {/* Big score */}
      <div className="col center" style={{
        padding:'24px 16px',
        background:'radial-gradient(circle at 50% 0%, rgba(212,255,58,0.12), transparent 70%)',
        borderRadius: 14
      }}>
        <div className="hand display" style={{ fontSize: 84, color:'var(--matcha)', lineHeight: 0.9 }}>847</div>
        <div className="tiny muted" style={{ letterSpacing: 1.5, textTransform:'uppercase', marginTop: 8 }}>Top 8% nationally</div>
        <div className="row middle gap-2" style={{ marginTop: 6 }}>
          <Icon name="arrowUpRight" size={14} color="var(--matcha)" />
          <span className="tiny" style={{ color:'var(--matcha)' }}>+42 this month</span>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Breakdown</div>
      <div className="col gap-3">
        {[
          ['Consistency',   92, 'var(--matcha)'],
          ['Challenge wins',78, 'var(--matcha)'],
          ['Streak depth',  85, 'var(--ochre)'],
          ['Activity mix',  64, 'var(--ochre)'],
          ['Social',        51, 'var(--ink-2)'],
        ].map(([cat, val, color]) => (
          <div key={cat}>
            <div className="row between tiny" style={{ marginBottom: 4 }}>
              <span className="b" style={{ letterSpacing: 0.3 }}>{cat}</span>
              <span className="hand display" style={{ fontSize: 14, color }}>{val}</span>
            </div>
            <div style={{ height: 4, background:'rgba(255,255,255,0.06)', borderRadius: 2 }}>
              <div style={{ height:'100%', width: val + '%', background: color, borderRadius: 2 }} />
            </div>
          </div>
        ))}
      </div>

      <div className="row gap-2">
        <div style={{ flex:1, padding: 12, background:'rgba(255,255,255,0.04)', borderRadius: 10 }}>
          <Icon name="flame" size={16} color="var(--matcha)" />
          <div className="hand display" style={{ fontSize: 20, marginTop: 4 }}>28D</div>
          <div className="tiny muted">Best streak</div>
        </div>
        <div style={{ flex:1, padding: 12, background:'rgba(255,255,255,0.04)', borderRadius: 10 }}>
          <Icon name="trophy" size={16} color="var(--matcha)" />
          <div className="hand display" style={{ fontSize: 20, marginTop: 4 }}>42</div>
          <div className="tiny muted">Challenges done</div>
        </div>
        <div style={{ flex:1, padding: 12, background:'rgba(255,255,255,0.04)', borderRadius: 10 }}>
          <Icon name="medal" size={16} color="var(--matcha)" />
          <div className="hand display" style={{ fontSize: 20, marginTop: 4 }}>8</div>
          <div className="tiny muted">Top 50%</div>
        </div>
      </div>
    </div>
    <TabBar active="me" />
  </Phone>
);

const XP_Level = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14, paddingBottom: 44 }}>
      <div className="row between middle">
        <Icon name="arrowLeft" size={22} stroke={2.2} />
        <span className="tiny muted">LV 23 → 24</span>
      </div>

      <div className="display" style={{ fontSize: 22 }}>LEVEL</div>

      <div style={{
        padding:'20px 16px', borderRadius: 14,
        background:'linear-gradient(135deg, rgba(212,255,58,0.10), rgba(255,181,71,0.04))'
      }}>
        <div className="row middle gap-3">
          <div style={{
            width: 70, height: 70, borderRadius:'50%',
            background:'radial-gradient(circle, var(--matcha) 0%, rgba(212,255,58,0.2) 70%)',
            display:'grid', placeItems:'center',
            color:'#0a0a14', fontFamily:"'Big Shoulders Display'", fontWeight: 900, fontSize: 32,
            fontStyle:'italic'
          }}>23</div>
          <div className="grow">
            <div className="display" style={{ fontSize: 20, color:'var(--matcha)' }}>CHALLENGER</div>
            <div className="tiny muted">Level 20 — 35 · Mid-tier athlete</div>
            <div style={{ height: 6, background:'rgba(255,255,255,0.08)', borderRadius: 3, marginTop: 8 }}>
              <div style={{ height:'100%', width:'68%', background:'var(--matcha)', borderRadius: 3 }} />
            </div>
            <div className="row between tiny muted" style={{ marginTop: 4 }}>
              <span>14,200 / 21,000 XP</span>
              <span>6.8K to LV 24</span>
            </div>
          </div>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Level Path</div>
      <div className="col gap-2">
        {[
          [1,   'Walker',     true],
          [10,  'Mover',      true],
          [20,  'Challenger', true],
          [35,  'Athlete',    false],
          [50,  'Elite',      false],
          [75,  'Legend',     false],
          [100, 'Immortal',   false],
        ].map(([lv, title, done]) => (
          <div key={lv} className="row middle gap-3" style={{
            padding:'10px 12px',
            background: lv===20 ? 'rgba(212,255,58,0.08)' : 'rgba(255,255,255,0.03)',
            borderRadius: 10,
            opacity: done ? 1 : 0.55,
            border: lv===20 ? '1px solid var(--matcha)' : '1px solid transparent'
          }}>
            <div className="hand display" style={{ width: 36, fontSize: 18, color: done ? 'var(--matcha)' : 'var(--ink-3)' }}>LV{lv}</div>
            <div className="grow">
              <div className="sm b">{title}</div>
            </div>
            {done ? <Icon name="check" size={16} color="var(--matcha)" /> : <Icon name="lock" size={14} color="var(--ink-3)" />}
          </div>
        ))}
      </div>
    </div>
    <TabBar active="me" />
  </Phone>
);

// ============================================================
// STREAK PROTECTION + REVIVE
// ============================================================

const Streak_Shield = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14 }}>
      <div className="row between middle">
        <Icon name="arrowLeft" size={22} stroke={2.2} />
        <span className="tiny muted">Streak Protection</span>
      </div>

      <div className="col center" style={{
        padding:'22px 16px',
        background:'radial-gradient(circle at 50% 0%, rgba(212,255,58,0.10), transparent 70%)',
        borderRadius: 14
      }}>
        <Icon name="shieldCheck" size={72} stroke={2} color="var(--matcha)" />
        <div className="hand display" style={{ fontSize: 28, color:'var(--matcha)', marginTop: 14 }}>12 DAY STREAK</div>
        <div className="tiny muted" style={{ marginTop: 2 }}>Protected · 1 of 1 shield available</div>
      </div>

      <div style={{ padding: 14, background:'rgba(255,255,255,0.04)', borderRadius: 12 }}>
        <div className="row middle gap-3">
          <div style={{ width: 40, height: 40, borderRadius: 10, background:'rgba(212,255,58,0.12)', display:'grid', placeItems:'center' }}>
            <Icon name="shield" size={22} color="var(--matcha)" />
          </div>
          <div className="grow">
            <div className="sm b">Monthly shield</div>
            <div className="tiny muted">Auto-saves your streak if you miss a day</div>
          </div>
          <span className="chip gold" style={{ padding:'3px 10px' }}>PRO</span>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Or revive a lost streak</div>
      <div style={{
        padding: 14, borderRadius: 12,
        background:'rgba(255,181,71,0.06)',
        border:'1px solid rgba(255,181,71,0.25)'
      }}>
        <div className="row middle gap-3">
          <Icon name="fire" size={32} stroke={2.2} color="var(--ochre)" />
          <div className="grow">
            <div className="sm b">Revive streak</div>
            <div className="tiny muted">Available up to 2 days after losing</div>
          </div>
        </div>
        <div className="row between middle" style={{ marginTop: 12 }}>
          <div>
            <div className="hand display" style={{ fontSize: 28, color:'var(--ochre)' }}>₹15</div>
            <div className="tiny muted">UPI / wallet</div>
          </div>
          <button className="btn gold" style={{ padding:'10px 20px' }}>Revive →</button>
        </div>
      </div>

      <div style={{
        padding: 12, borderRadius: 10,
        background:'rgba(255,255,255,0.03)'
      }}>
        <div className="row middle gap-2">
          <Icon name="info" size={14} color="var(--ink-3)" />
          <span className="tiny muted">Free users · Pro users · same revive cost</span>
        </div>
      </div>

      <div className="grow" />
      <button className="btn full" style={{ background:'var(--matcha)', color:'#0a0a14' }}>Use shield (1 left)</button>
    </div>
  </Phone>
);

// ============================================================
// DAILY MISSIONS
// ============================================================

const DailyMissions = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Daily Missions</div>
        <span className="chip">3 / 5</span>
      </div>
      <div className="row middle gap-2">
        <Icon name="clock" size={14} color="var(--ink-3)" />
        <span className="tiny muted">Resets in 14h · finish all for +60 ¢</span>
      </div>

      <div className="col gap-3">
        {[
          ['Walk 8,000 steps',     'walk',    7832, 8000,  true,  '+15 ¢'],
          ['Drink 2.5L water',     'droplet', 1.8,  2.5,   false, '+10 ¢'],
          ['Sleep 7+ hours',       'moon',    7.2,  7,     true,  '+15 ¢'],
          ['10 min stretching',    'yoga',    10,   10,    true,  '+10 ¢'],
          ['Log a workout',        'gym',     0,    1,     false, '+20 ¢'],
        ].map(([t, ic, cur, target, done, reward]) => {
          const pct = Math.min(100, (cur/target)*100);
          return (
            <div key={t} style={{
              padding:'12px 14px', borderRadius: 12,
              background: done ? 'rgba(212,255,58,0.08)' : 'rgba(255,255,255,0.04)',
              border: '1.5px solid ' + (done ? 'var(--matcha)' : 'transparent')
            }}>
              <div className="row middle gap-3">
                <div style={{
                  width: 36, height: 36, borderRadius: 10,
                  background: done ? 'rgba(212,255,58,0.15)' : 'rgba(255,255,255,0.05)',
                  display:'grid', placeItems:'center',
                  color: done ? 'var(--matcha)' : 'var(--ink)'
                }}>
                  <Icon name={ic} size={20} stroke={2.2} />
                </div>
                <div className="grow">
                  <div className="row between middle">
                    <span className="sm b">{t}</span>
                    <span className="tiny" style={{ color:'var(--ochre)' }}>{reward}</span>
                  </div>
                  <div style={{ height: 4, background:'rgba(255,255,255,0.06)', borderRadius: 2, marginTop: 8 }}>
                    <div style={{ height:'100%', width: pct + '%', background: done ? 'var(--matcha)' : 'var(--ochre)', borderRadius: 2 }} />
                  </div>
                  <div className="tiny muted" style={{ marginTop: 4 }}>
                    {cur === Math.floor(cur) ? cur.toLocaleString() : cur} / {target.toLocaleString()}
                    {done ? ' · done' : ''}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
    <TabBar active="home" />
  </Phone>
);

// ============================================================
// SEASONAL BATTLE PASS
// ============================================================

const BattlePass = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="display" style={{ fontSize: 22 }}>SEASON 4</div>
        <span className="chip lime" style={{ padding:'4px 10px' }}>14D LEFT</span>
      </div>

      {/* Progress strip */}
      <div style={{
        padding:'14px 16px', borderRadius: 14,
        background:'linear-gradient(135deg, rgba(212,255,58,0.10), rgba(255,181,71,0.06))'
      }}>
        <div className="row between middle">
          <div className="hand display" style={{ fontSize: 24, color:'var(--matcha)' }}>TIER 18 / 50</div>
          <span className="chip" style={{ background:'rgba(255,181,71,0.15)', color:'var(--ochre)' }}>PRO</span>
        </div>
        <div style={{ height: 6, background:'rgba(255,255,255,0.08)', borderRadius: 3, marginTop: 10 }}>
          <div style={{ height:'100%', width:'36%', background:'var(--matcha)', borderRadius: 3 }} />
        </div>
        <div className="row between tiny muted" style={{ marginTop: 4 }}>
          <span>360 / 500 XP this tier</span>
          <span>Tier 19 →</span>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Rewards Track</div>

      {/* Battle pass track — 2 rows: free + pro */}
      <div className="row gap-2" style={{ overflowX:'auto', paddingBottom: 8 }}>
        {[16, 17, 18, 19, 20, 21, 22].map(tier => {
          const isCurrent = tier === 18;
          const claimed = tier < 18;
          return (
            <div key={tier} className="col gap-2" style={{ flexShrink: 0, width: 76 }}>
              <div className="tac">
                <div className="hand display" style={{ fontSize: 14, color: isCurrent ? 'var(--matcha)' : 'var(--ink-3)' }}>T{tier}</div>
              </div>
              {/* Free row */}
              <div style={{
                height: 70, borderRadius: 10,
                background: claimed ? 'rgba(212,255,58,0.08)' : 'rgba(255,255,255,0.04)',
                border: '1.5px solid ' + (isCurrent ? 'var(--matcha)' : 'transparent'),
                display:'grid', placeItems:'center',
                position:'relative'
              }}>
                <Icon name={tier % 2 ? 'coin' : 'star'} size={26} stroke={2.2} color={claimed ? 'var(--matcha)' : 'var(--ink-2)'} />
                <div className="tiny muted" style={{ position:'absolute', bottom: 4 }}>+50 ¢</div>
              </div>
              {/* Pro row */}
              <div style={{
                height: 70, borderRadius: 10,
                background:'rgba(255,181,71,0.06)',
                border:'1.5px solid rgba(255,181,71,0.2)',
                display:'grid', placeItems:'center',
                position:'relative'
              }}>
                <Icon name={tier === 20 ? 'crown' : tier === 18 ? 'medal' : 'shield'} size={26} stroke={2.2} color="var(--ochre)" />
                <div className="tiny" style={{ position:'absolute', bottom: 4, color:'var(--ochre)' }}>Frame</div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="row gap-2 tiny" style={{ paddingLeft: 4 }}>
        <span style={{ color:'var(--matcha)' }}>● Free</span>
        <span style={{ color:'var(--ochre)' }}>● Pro</span>
      </div>

      <div className="grow" />
      <div className="row gap-2">
        <button className="btn ghost" style={{ flex: 1 }}>Free Pass</button>
        <button className="btn gold" style={{ flex: 1 }}>Unlock Pro · ₹299</button>
      </div>
    </div>
  </Phone>
);

// ============================================================
// SMARTWATCH ECOSYSTEM
// ============================================================

const Watch_Connect = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 14 }}>
      <div className="row between middle">
        <Icon name="arrowLeft" size={22} stroke={2.2} />
        <span className="tiny muted">Devices</span>
      </div>

      <div className="display" style={{ fontSize: 24 }}>CONNECT A DEVICE</div>
      <div className="sm muted">Sync workouts, heart rate & sleep automatically</div>

      {/* Connected */}
      <div style={{
        padding: 14, borderRadius: 12,
        background:'rgba(212,255,58,0.08)',
        border:'1.5px solid var(--matcha)'
      }}>
        <div className="row middle gap-3">
          <Icon name="watch" size={28} color="var(--matcha)" />
          <div className="grow">
            <div className="md b">Apple Watch S9</div>
            <div className="tiny muted">Connected · synced 2 min ago</div>
          </div>
          <Icon name="check" size={20} color="var(--matcha)" />
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Available</div>
      <div className="col gap-2">
        {[
          ['Samsung Galaxy Watch', 'watch'],
          ['Fitbit',               'activity'],
          ['Garmin',               'target'],
          ['Noise ColorFit',       'watch'],
          ['boAt Storm',           'watch'],
          ['Google Health',        'heart'],
        ].map(([name, ic]) => (
          <div key={name} className="row middle gap-3" style={{
            padding:'12px 14px', background:'rgba(255,255,255,0.04)', borderRadius: 12
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background:'rgba(255,255,255,0.05)',
              display:'grid', placeItems:'center'
            }}>
              <Icon name={ic} size={20} stroke={2.2} />
            </div>
            <span className="sm b grow">{name}</span>
            <span className="chip" style={{ padding:'3px 10px' }}>Connect</span>
          </div>
        ))}
      </div>
    </div>
  </Phone>
);

// ============================================================
// COMMUNITY — feed + stories + user profile
// ============================================================

const Community_Feed = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      {/* Top bar */}
      <div className="row between middle">
        <div className="display" style={{ fontSize: 22, color:'var(--matcha)' }}>STEPUP</div>
        <div className="row gap-3 middle">
          <Icon name="bell" size={20} stroke={2.2} />
          <Icon name="chat" size={20} stroke={2.2} />
        </div>
      </div>

      {/* Stories */}
      <div className="row gap-3" style={{ overflowX:'auto', paddingBottom: 4 }}>
        {[
          ['You',     true,  true],
          ['Priya',   false, true],
          ['Aarav',   false, true],
          ['Megha',   false, false],
          ['Vikram',  false, true],
          ['Karthik', false, false],
        ].map(([n, isMe, hasNew], i) => (
          <div key={i} className="col center" style={{ flexShrink: 0, width: 56 }}>
            <div style={{
              width: 54, height: 54, borderRadius:'50%',
              padding: 2,
              background: hasNew ? 'conic-gradient(from 0deg, var(--matcha), var(--ochre), var(--matcha))' : 'rgba(255,255,255,0.1)',
              position:'relative'
            }}>
              <div style={{
                width:'100%', height:'100%', borderRadius:'50%',
                background:'#1a1a26',
                display:'grid', placeItems:'center',
                border:'2px solid var(--paper)',
                fontWeight: 700, fontSize: 16
              }}>{n[0]}</div>
              {isMe && (
                <div style={{
                  position:'absolute', bottom: -2, right: -2,
                  width: 18, height: 18, borderRadius:'50%',
                  background:'var(--matcha)',
                  border:'2px solid var(--paper)',
                  display:'grid', placeItems:'center',
                  color:'#0a0a14'
                }}>
                  <Icon name="plus" size={10} stroke={3} />
                </div>
              )}
            </div>
            <div className="tiny" style={{ marginTop: 4 }}>{n}</div>
          </div>
        ))}
      </div>

      {/* Posts */}
      <div className="col gap-3">
        <div style={{ borderRadius: 14, background:'rgba(255,255,255,0.04)', overflow:'hidden' }}>
          <div className="row middle gap-2" style={{ padding:'10px 12px' }}>
            <div style={{ width: 32, height: 32, borderRadius:'50%', background:'rgba(212,255,58,0.15)', color:'var(--matcha)', display:'grid', placeItems:'center', fontWeight: 700 }}>A</div>
            <div className="grow">
              <div className="sm b">Aarav M</div>
              <div className="tiny muted">Hyderabad · 2h</div>
            </div>
            <span className="chip" style={{ background:'rgba(212,255,58,0.1)', color:'var(--matcha)', padding:'3px 8px' }}>Gold III</span>
          </div>
          <div style={{
            height: 140,
            background:'linear-gradient(135deg, rgba(212,255,58,0.15), rgba(255,181,71,0.08))',
            display:'grid', placeItems:'center',
            position:'relative'
          }}>
            <div className="tac">
              <Icon name="run" size={36} stroke={2} color="var(--matcha)" />
              <div className="hand display" style={{ fontSize: 28, color:'var(--matcha)', marginTop: 4 }}>10K · 42:18</div>
              <div className="tiny muted">Morning run</div>
            </div>
            <span className="chip lime" style={{ position:'absolute', top: 10, right: 10, padding:'3px 8px' }}>NEW PR</span>
          </div>
          <div className="col gap-2" style={{ padding:'10px 12px' }}>
            <div className="sm">First 10K under 45 min! Big shoutout to <span style={{color:'var(--matcha)'}}>@priya</span> for pacing 🏃</div>
            <div className="row middle gap-4 tiny muted">
              <span className="row middle gap-1"><Icon name="heart" size={14} /> 142</span>
              <span className="row middle gap-1"><Icon name="chat" size={14} /> 18</span>
              <span className="grow" />
              <Icon name="bookmark" size={14} />
            </div>
          </div>
        </div>

        <div style={{ borderRadius: 14, background:'rgba(255,255,255,0.04)', overflow:'hidden' }}>
          <div className="row middle gap-2" style={{ padding:'10px 12px' }}>
            <div style={{ width: 32, height: 32, borderRadius:'50%', background:'rgba(255,181,71,0.15)', color:'var(--ochre)', display:'grid', placeItems:'center', fontWeight: 700 }}>P</div>
            <div className="grow">
              <div className="sm b">Priya S</div>
              <div className="tiny muted">5h</div>
            </div>
          </div>
          <div style={{
            padding:'14px 14px 0',
            display:'flex', alignItems:'center', gap: 10
          }}>
            <Icon name="trophy" size={28} color="var(--ochre)" />
            <div className="grow">
              <div className="hand display" style={{ fontSize: 18, color:'var(--ochre)' }}>SUMMER SHRED · DONE</div>
              <div className="tiny muted">Top 12% of 2,140 athletes</div>
            </div>
          </div>
          <div style={{ padding:'10px 12px' }}>
            <div className="sm">14 days, zero misses. Onto the next one ✦</div>
            <div className="row middle gap-4 tiny muted" style={{ marginTop: 8 }}>
              <span className="row middle gap-1"><Icon name="heart" size={14} /> 87</span>
              <span className="row middle gap-1"><Icon name="chat" size={14} /> 6</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <TabBar active="home" />
  </Phone>
);

const User_Profile = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <Icon name="arrowLeft" size={22} stroke={2.2} />
        <Icon name="info" size={18} stroke={2.2} />
      </div>

      <div className="row middle gap-3">
        <div style={{
          width: 64, height: 64, borderRadius:'50%',
          padding: 2,
          background:'conic-gradient(from 0deg, var(--matcha), var(--ochre), var(--matcha))'
        }}>
          <div style={{
            width:'100%', height:'100%', borderRadius:'50%',
            background:'rgba(212,255,58,0.15)', color:'var(--matcha)',
            display:'grid', placeItems:'center', fontWeight: 800, fontSize: 22
          }}>A</div>
        </div>
        <div className="grow">
          <div className="md b">Aarav M.</div>
          <div className="tiny muted">@aarav_runs · Hyderabad</div>
          <div className="row gap-2" style={{ marginTop: 6 }}>
            <span className="chip" style={{ background:'rgba(217,169,58,0.15)', color:'#d9a93a', padding:'3px 8px' }}>GOLD III</span>
            <span className="chip" style={{ padding:'3px 8px' }}>LV 24</span>
          </div>
        </div>
        <button className="btn" style={{ background:'var(--matcha)', color:'#0a0a14', padding:'8px 16px' }}>Follow</button>
      </div>

      <div className="row gap-2">
        <div style={{ flex:1, padding:10, background:'rgba(255,255,255,0.04)', borderRadius: 10 }} className="tac">
          <div className="hand display" style={{ fontSize: 18 }}>847</div>
          <div className="tiny muted">Reputation</div>
        </div>
        <div style={{ flex:1, padding:10, background:'rgba(255,255,255,0.04)', borderRadius: 10 }} className="tac">
          <div className="hand display" style={{ fontSize: 18 }}>28D</div>
          <div className="tiny muted">Streak</div>
        </div>
        <div style={{ flex:1, padding:10, background:'rgba(255,255,255,0.04)', borderRadius: 10 }} className="tac">
          <div className="hand display" style={{ fontSize: 18 }}>1.2K</div>
          <div className="tiny muted">Followers</div>
        </div>
      </div>

      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Recent Achievements</div>
      <div className="row gap-2" style={{ overflowX:'auto', paddingBottom: 4 }}>
        {[
          ['fire',    '28D Streak'],
          ['trophy',  'Top 1% HYD'],
          ['medal',   'Summer Shred'],
          ['lightning','New 10K PR'],
          ['shield',  'Marathon'],
        ].map(([ic, t]) => (
          <div key={t} className="col center" style={{
            flexShrink: 0, width: 78, padding:'10px 6px',
            background:'rgba(255,255,255,0.04)', borderRadius: 10
          }}>
            <Icon name={ic} size={22} stroke={2} color="var(--matcha)" />
            <div className="tiny tac" style={{ marginTop: 4, lineHeight: 1.2 }}>{t}</div>
          </div>
        ))}
      </div>

      <div className="row between middle">
        <span className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Posts</span>
        <Icon name="grid" size={14} stroke={2.2} color="var(--ink-3)" />
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap: 2 }}>
        {[0,1,2,3,4,5].map(i => (
          <div key={i} style={{
            aspectRatio:'1', borderRadius: 4,
            background: i % 2 ? 'linear-gradient(135deg, rgba(212,255,58,0.15), rgba(255,181,71,0.08))' : 'rgba(255,255,255,0.05)',
            display:'grid', placeItems:'center'
          }}>
            <Icon name={['run','trophy','gym','walk','flame','yoga'][i]} size={18} stroke={2} color="var(--ink-2)" />
          </div>
        ))}
      </div>
    </div>
    <TabBar active="me" />
  </Phone>
);

// ============================================================
// EXPORT to window
// ============================================================

Object.assign(window, {
  League_Hub, League_Standings,
  Chal_Seasonal, Tournament_Detail,
  Rivals_List, Battle_Detail,
  Marketplace,
  Reputation, XP_Level,
  Streak_Shield, DailyMissions,
  BattlePass,
  Watch_Connect,
  Community_Feed, User_Profile,
});

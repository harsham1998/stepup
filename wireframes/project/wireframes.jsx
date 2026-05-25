/* StepUp wireframes — onboarding + dashboard set */
/* eslint-disable */

const { useState } = React;

// =========== Reusable bits ===========

const Phone = ({ children, label, sub }) => (
  <div className="phone">
    <div className="phone-screen">
      <div className="phone-status">
        <span>9:41</span>
        <span>●●●  ▮</span>
      </div>
      <div className="phone-body">{children}</div>
    </div>
  </div>
);

const Squiggle = () => <div className="squiggle" />;

const Bar = ({ w = 60, t = false, d = false }) => (
  <span className={'bar' + (t ? ' Thick' : '') + (d ? ' dark' : '')} style={{ width: w + 'px' }} />
);

const HandIcon = ({ ch = '✦', size = 26 }) => (
  <div
    className="circ"
    style={{
      width: size, height: size,
      display: 'grid', placeItems: 'center',
      fontFamily: "'Big Shoulders Display', sans-serif", fontWeight: 700, fontSize: size * 0.55,
    }}
  >{ch}</div>
);

const Sticky = ({ children, style }) => (
  <div className="sticky" style={style}>{children}</div>
);

const TabBar = ({ active = 'home' }) => {
  const tabs = [
    ['home',  'home',     'Home'],
    ['chal',  'trophy',   'Chal'],
    ['lead',  'chart',    'Lead'],
    ['coins', 'coin',     'Coins'],
    ['me',    'user',     'Me'],
  ];
  return (
    <div className="tabbar" style={{ position: 'absolute', left: 0, right: 0, bottom: 0 }}>
      {tabs.map(([k, icon, label]) => (
        <div key={k} className={'tab' + (active === k ? ' active' : '')}>
          <div className="ic"><Icon name={icon} size={20} stroke={2} /></div>
          <span>{label}</span>
        </div>
      ))}
    </div>
  );
};

// Bold line-style SVG icon set
const Icon = ({ name, size = 20, color = 'currentColor', stroke = 2 }) => {
  const props = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth: stroke,
    strokeLinecap: 'round', strokeLinejoin: 'round',
    style: { flexShrink: 0 }
  };
  const P = {
    walk: <g><circle cx="13" cy="4" r="1.5" /><path d="M11 8l-3 6 4 1 1 5" /><path d="M12 15l4-2 2-3" /></g>,
    run:  <g><circle cx="14" cy="4" r="1.5" /><path d="M11 8L7 13l4 2 1 5" /><path d="M12 14l4-1 2-4" /></g>,
    gym:  <g><path d="M3 9v6M6 6v12M9 9v6M15 9v6M18 6v12M21 9v6" /><path d="M9 12h6" /></g>,
    yoga: <g><circle cx="12" cy="5" r="1.5" /><path d="M12 7v6" /><path d="M5 12c2-1 5-1 7 0s5 1 7 0" /><path d="M9 16l-3 5M15 16l3 5" /></g>,
    cycle:<g><circle cx="6" cy="17" r="3" /><circle cx="18" cy="17" r="3" /><path d="M6 17l5-8h5l-2 8M14 5l2 4" /><circle cx="16" cy="5" r="1" /></g>,
    sport:<g><circle cx="12" cy="12" r="9" /><path d="M4 12h16M12 3v18" /></g>,
    mind: <g><path d="M12 21c-4-2-7-6-7-10s3-7 7-7 7 3 7 7-3 8-7 10z" /><path d="M12 12c-2-1-3-3-2-5M12 12c2-1 3-3 2-5" /></g>,
    flame:<g><path d="M12 22c-4 0-7-3-7-7 0-3 2-5 4-7 0-2 1-4 0-5 5 2 9 7 9 12 0 5-2 7-6 7z" /><path d="M12 18c-2 0-3-1-3-3 0-1 1-2 2-3 1 1 3 2 3 4 0 2-1 2-2 2z" /></g>,
    coin: <g><circle cx="12" cy="12" r="9" /><path d="M14 9h-3a2 2 0 0 0 0 4h2a2 2 0 0 1 0 4h-3M12 7v10" /></g>,
    trophy: <g><path d="M7 4h10v4a5 5 0 0 1-10 0V4z" /><path d="M5 6H3a4 4 0 0 0 4 4M19 6h2a4 4 0 0 1-4 4M9 18h6v3H9z" /><path d="M12 12v6" /></g>,
    bell: <g><path d="M6 10v-1a6 6 0 0 1 12 0v1l2 5H4z" /><path d="M10 19a2 2 0 0 0 4 0" /></g>,
    check:<g><polyline points="4 13 9 18 20 6" /></g>,
    plus: <g><path d="M12 5v14M5 12h14" /></g>,
    arrow:<g><path d="M5 12h14M12 5l7 7-7 7" /></g>,
    arrowLeft:<g><path d="M19 12H5M12 5l-7 7 7 7" /></g>,
    target: <g><circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="5" /><circle cx="12" cy="12" r="1.5" fill={color} stroke="none" /></g>,
    clock: <g><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></g>,
    settings: <g><circle cx="12" cy="12" r="3" /><path d="M19 15l1-2-1-1 1-2-2-2-2 1-1-1-2 1-2-1-1 1-2-1-2 2 1 2-1 1 1 2-1 2 2 2 2-1 1 1 2-1 2 1 1-1 2 1 2-2-1-2z" strokeLinejoin="miter" /></g>,
    user: <g><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-7 8-7s8 3 8 7" /></g>,
    map: <g><path d="M3 6v15l6-2 6 2 6-2V4l-6 2-6-2-6 2z" /><path d="M9 4v15M15 6v15" /></g>,
    chart: <g><path d="M3 20h18M6 16v-4M10 16v-7M14 16v-2M18 16v-9" /></g>,
    calendar: <g><rect x="3" y="5" width="18" height="16" rx="1" /><path d="M3 10h18M8 3v4M16 3v4" /></g>,
    star: <g><polygon points="12 3 14 9 21 10 16 14 17 21 12 17 7 21 8 14 3 10 10 9" /></g>,
    heart: <g><path d="M12 21c-4-4-9-7-9-12a5 5 0 0 1 9-3 5 5 0 0 1 9 3c0 5-5 8-9 12z" /></g>,
    search: <g><circle cx="11" cy="11" r="7" /><path d="M21 21l-5-5" /></g>,
    edit: <g><path d="M4 20h4l12-12-4-4-12 12v4z" /></g>,
    share: <g><circle cx="6" cy="12" r="3" /><circle cx="18" cy="6" r="3" /><circle cx="18" cy="18" r="3" /><path d="M9 11l6-3M9 13l6 3" /></g>,
    gift: <g><rect x="3" y="9" width="18" height="12" rx="1" /><path d="M3 13h18M12 9v12" /><path d="M12 9c-2-3-6-3-6 0M12 9c2-3 6-3 6 0" /></g>,
    home: <g><path d="M3 12l9-8 9 8v9H3z" /><path d="M9 21v-6h6v6" /></g>,
    list: <g><path d="M8 6h13M8 12h13M8 18h13M4 6h.01M4 12h.01M4 18h.01" /></g>,
    lock: <g><rect x="5" y="11" width="14" height="10" rx="1" /><path d="M8 11V8a4 4 0 0 1 8 0v3" /></g>,
    phone: <g><rect x="6" y="2" width="12" height="20" rx="2" /><circle cx="12" cy="18" r="1" /></g>,
    activity: <g><polyline points="3 12 7 12 10 4 14 20 17 12 21 12" /></g>,
    bolt: <g><path d="M13 2L4 14h7l-2 8 9-12h-7l2-8z" /></g>,
    shield: <g><path d="M12 2l8 3v6c0 5-3 9-8 11-5-2-8-6-8-11V5l8-3z" /></g>,
    shieldCheck: <g><path d="M12 2l8 3v6c0 5-3 9-8 11-5-2-8-6-8-11V5l8-3z" /><polyline points="8.5 12 11 14.5 16 9.5" /></g>,
    watch: <g><rect x="6" y="6" width="12" height="12" rx="2" /><path d="M9 6V3h6v3M9 18v3h6v-3M12 9v3l2 1" /></g>,
    medal: <g><circle cx="12" cy="15" r="5" /><path d="M8 3l4 7 4-7M12 15v-2M12 17v-1" /></g>,
    crown: <g><path d="M3 8l3 9h12l3-9-5 3-4-6-4 6-5-3z" /><path d="M3 19h18" /></g>,
    droplet: <g><path d="M12 3c-4 5-7 8-7 12a7 7 0 0 0 14 0c0-4-3-7-7-12z" /></g>,
    moon: <g><path d="M19 15a8 8 0 0 1-10-10 8 8 0 1 0 10 10z" /></g>,
    image: <g><rect x="3" y="4" width="18" height="16" rx="2" /><circle cx="9" cy="10" r="2" /><path d="M21 16l-5-5-8 9" /></g>,
    play: <g><polygon points="6 4 20 12 6 20 6 4" /></g>,
    swords: <g><path d="M14 4l6 6-6 6M10 20l-6-6 6-6M5 14l7-7M19 10l-7 7" /></g>,
    flag: <g><path d="M5 21V4M5 4h13l-3 4 3 4H5" /></g>,
    fire: <g><path d="M12 22c-4 0-7-3-7-7 0-3 2-5 4-7 0-2 1-4 0-5 5 2 9 7 9 12 0 5-2 7-6 7z" /><path d="M12 18c-2 0-3-1-3-3 0-1 1-2 2-3 1 1 3 2 3 4 0 2-1 2-2 2z" /></g>,
    grid: <g><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></g>,
    plus2: <g><path d="M12 5v14M5 12h14" /></g>,
    bookmark: <g><path d="M6 3h12v18l-6-4-6 4V3z" /></g>,
    chat: <g><path d="M21 12a8 8 0 0 1-12 7l-5 1 1-4a8 8 0 1 1 16-4z" /></g>,
    info: <g><circle cx="12" cy="12" r="9" /><path d="M12 11v6M12 7h.01" /></g>,
    award: <g><circle cx="12" cy="9" r="6" /><path d="M9 14l-2 8 5-3 5 3-2-8" /></g>,
    lightning: <g><polygon points="13 2 4 14 11 14 11 22 20 10 13 10 13 2" /></g>,
    feed: <g><circle cx="6" cy="18" r="2" /><path d="M4 4a16 16 0 0 1 16 16M4 11a9 9 0 0 1 9 9" /></g>,
    eye: <g><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></g>,
    userPlus: <g><circle cx="9" cy="8" r="4" /><path d="M2 21c0-4 4-7 7-7s7 3 7 7M18 8v6M15 11h6" /></g>,
    arrowUpRight: <g><path d="M7 17L17 7M9 7h8v8" /></g>,
  };
  return <svg {...props}>{P[name] || P.target}</svg>;
};


const StepRing = ({ size = 150, value = 0.72, label = '7,832', sub = 'Of 10,000', color = '#c97b54' }) => {
  const r = size / 2 - 8;
  const c = 2 * Math.PI * r;
  const off = c * (1 - value);
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ overflow: 'visible' }}>
        <circle
          cx={size / 2} cy={size / 2} r={r}
          fill="none" stroke="#2a2e26" strokeWidth="2" strokeDasharray="2 3" opacity="0.4"
        />
        <circle
          cx={size / 2} cy={size / 2} r={r}
          fill="#d4ff3a" opacity="0.28"
          stroke="none"
        />
        <circle
          cx={size / 2} cy={size / 2} r={r}
          fill="none" stroke={color} strokeWidth="6" strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={off}
          transform={`rotate(-90 ${size/2} ${size/2})`}
          style={{ filter: 'url(#wobble)' }}
        />
        <defs>
          <filter id="wobble">
            <feTurbulence baseFrequency="0.04" numOctaves="2" result="t" />
            <feDisplacementMap in="SourceGraphic" in2="t" scale="1.5" />
          </filter>
        </defs>
      </svg>
      <div style={{
        position:'absolute', inset:0, display:'flex',
        flexDirection:'column', alignItems:'center', justifyContent:'center'
      }}>
        <div className="hand" style={{ fontSize: size * 0.28, lineHeight: 1, fontWeight:700 }}>{label}</div>
        <div className="tiny muted" style={{ marginTop: 2 }}>{sub}</div>
        <div className="tiny" style={{ marginTop: 4 }}>Steps today</div>
      </div>
    </div>
  );
};

// =========== APP START (3) ===========

const Start_A = () => (
  <Phone>
    <div className="col center" style={{ height:'100%', textAlign:'center', gap: 14, position:'relative' }}>
      <div className="grow" />
      {/* logo mark — abstract circle + arrow up */}
      <div style={{ position:'relative', width: 90, height: 90 }}>
        <div className="circ" style={{ position:'absolute', inset: 0, borderColor: 'var(--matcha)', borderWidth: 2 }} />
        <div style={{
          position:'absolute', inset: 18,
          border: '2px solid var(--ochre)', borderRadius: '50%',
          borderTopColor: 'transparent', borderRightColor: 'transparent',
          transform: 'rotate(-45deg)'
        }} />
        <div className="hand" style={{
          position:'absolute', inset: 0, display:'grid', placeItems:'center',
          fontSize: 38, color: 'var(--ink)'
        }}>↑</div>
      </div>
      <div className="hand" style={{ fontSize: 56, lineHeight: 0.9, letterSpacing: 1 }}>
        Step<span style={{ color: 'var(--matcha)' }}>Up</span>
      </div>
      <div className="sm muted">Walk · compete · cash in</div>
      <div className="grow" />
      <div className="col gap-2" style={{ alignItems:'center', width:'100%' }}>
        <div className="sm muted">Tap anywhere to begin</div>
        <div style={{ width: 60, height: 3, background:'var(--matcha)', borderRadius: 2, marginTop: 4 }} />
        <div className="muted tiny" style={{ marginTop: 14 }}>V 1.0  ·  india</div>
      </div>
    </div>
  </Phone>
);

const Start_B = () => (
  <Phone>
    <div className="col center" style={{ height:'100%', gap: 14, textAlign:'center' }}>
      <div className="grow" />
      <StepRing size={130} value={0.4} label="..." sub="loading" color="#d4ff3a" />
      <div className="hand xl" style={{ marginTop: 8 }}>Step<span style={{color:'var(--matcha)'}}>Up</span></div>
      <div className="muted tiny">Syncing your steps…</div>
      <div className="grow" />
      <div className="row gap-2 center">
        {[0,1,2].map(i => (
          <span key={i} className="circ" style={{
            width:7, height:7,
            background: i===1 ? 'var(--matcha)' : 'transparent',
            borderColor: i===1 ? 'var(--matcha)' : 'var(--ink-3)'
          }} />
        ))}
      </div>
      <div style={{ height: 10 }} />
    </div>
  </Phone>
);

const Start_C = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12 }}>
      <div className="grow box dashed" style={{
        display:'grid', placeItems:'center', minHeight: 220, position:'relative',
        background:'linear-gradient(160deg, rgba(212,255,58,0.08), rgba(214,138,94,0.06))',
        borderColor:'var(--ink-3)'
      }}>
        <div className="callout" style={{ color:'var(--ink-2)' }}>[Hero illustration]<br/>Runner / city skyline</div>
        <div style={{ position:'absolute', top:10, right:10 }} className="chip gold">NEW</div>
        <div style={{ position:'absolute', bottom:10, left:10 }} className="chip lime">200+ Challenges</div>
      </div>
      <div className="hand" style={{ fontSize: 30, lineHeight: 1, marginTop: 6 }}>
        Move. <span className="marker gold">Earn coins.</span>
      </div>
      <div className="sm muted">Wellness challenges · redeem for gift cards</div>
      <div className="col gap-2" style={{ marginTop: 4 }}>
        <button className="btn gold full">Get started →</button>
        <button className="btn ghost full">I already have an account</button>
      </div>
    </div>
  </Phone>
);

// =========== AUTH (3) — Login, OTP, Social ===========

const Auth_Login = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12 }}>
      <div className="row middle gap-2">
        <div className="circ" style={{ width: 28, height: 28, display:'grid', placeItems:'center', fontSize: 14 }}>←</div>
        <div className="sm muted">Back</div>
      </div>
      <div className="grow" style={{ maxHeight: 30 }} />
      <div className="hand" style={{ fontSize: 30, lineHeight: 1 }}>Let's go.</div>
      <div className="sm muted">Enter your phone, we'll send an OTP</div>
      <div className="col gap-2" style={{ marginTop: 8 }}>
        <div className="tiny muted">Phone number</div>
        <div className="box row middle gap-2" style={{ padding: 12 }}>
          <span className="sm b">+91</span>
          <span style={{ width: 1, height: 16, background: 'var(--ink-3)', opacity: 0.4 }} />
          <span className="md" style={{ fontFamily: 'Big Shoulders Display', fontSize: 20 }}>98765 43210</span>
          <span className="grow" />
          <span style={{ color: 'var(--mint)', fontSize: 14 }}>✓</span>
        </div>
        <div className="tiny" style={{ color: 'var(--ink-3)' }}>By continuing you agree to our terms</div>
      </div>
      <button className="btn gold full" style={{ marginTop: 10 }}>Send OTP →</button>
      <div className="row middle gap-3" style={{ margin: '10px 0' }}>
        <div className="grow" style={{ height: 1, background: 'var(--ink-3)', opacity: 0.3 }} />
        <span className="tiny muted">Or</span>
        <div className="grow" style={{ height: 1, background: 'var(--ink-3)', opacity: 0.3 }} />
      </div>
      <div className="col gap-2">
        <button className="social-btn"><span className="glyph">G</span>Continue with Google</button>
        <button className="social-btn"><span className="glyph" style={{ background:'var(--ink)', color:'var(--paper)' }}></span>Continue with Apple</button>
      </div>
      <div className="grow" />
      <div className="tiny muted tac">New here? <span style={{ color: 'var(--matcha)' }}>Create account</span></div>
    </div>
  </Phone>
);

const Auth_OTP = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12 }}>
      <div className="row middle gap-2">
        <div className="circ" style={{ width: 28, height: 28, display:'grid', placeItems:'center', fontSize: 14 }}>←</div>
        <div className="sm muted">+91 98765 43210 · Edit</div>
      </div>
      <div className="grow" style={{ maxHeight: 24 }} />
      <div className="hand" style={{ fontSize: 30, lineHeight: 1 }}>Verify it's you.</div>
      <div className="sm muted">6-digit code sent · auto-detecting</div>
      <div className="row gap-2 center" style={{ marginTop: 16 }}>
        <div className="otp-cell filled">4</div>
        <div className="otp-cell filled">8</div>
        <div className="otp-cell filled">2</div>
        <div className="otp-cell active" style={{ position: 'relative' }}>
          <span style={{
            position:'absolute', top:8, bottom:8, left:'50%',
            width: 1, background:'var(--matcha)',
            animation:'Blink 1s steps(2) infinite'
          }} />
        </div>
        <div className="otp-cell">·</div>
        <div className="otp-cell">·</div>
      </div>
      <div className="tac sm muted" style={{ marginTop: 12 }}>Didn't get it? <span style={{ color: 'var(--matcha)' }}>Resend in 0:24</span></div>
      <div className="grow" />
      <div className="box dashed" style={{ padding: 8, textAlign:'center' }}>
        <span className="tiny muted">↑ Keyboard</span>
      </div>
      <div className="row gap-2">
        <button className="btn ghost full">Resend</button>
        <button className="btn gold full">Verify →</button>
      </div>
      <style>{`@keyframes blink { 50% { opacity: 0; } }`}</style>
    </div>
  </Phone>
);

const Auth_Social = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12 }}>
      <div className="grow" style={{ maxHeight: 30 }} />
      <div style={{ position: 'relative', width: 70, height: 70 }}>
        <div className="circ" style={{ position:'absolute', inset: 0, borderColor: 'var(--matcha)', borderWidth: 2 }} />
        <div className="hand" style={{
          position:'absolute', inset: 0, display:'grid', placeItems:'center',
          fontSize: 30, color: 'var(--matcha)'
        }}>↑</div>
      </div>
      <div className="hand" style={{ fontSize: 28, lineHeight: 1.1 }}>
        Join <span style={{ color: 'var(--matcha)' }}>StepUp</span>
      </div>
      <div className="sm muted">Pick your fav way to sign up</div>
      <div className="col gap-2" style={{ marginTop: 16 }}>
        <button className="social-btn" style={{ padding: 14 }}>
          <span className="glyph">G</span>
          <span>Continue with Google</span>
        </button>
        <button className="social-btn" style={{ padding: 14, background: 'var(--ink)', color: 'var(--paper)' }}>
          <span className="glyph" style={{ background:'var(--paper)', color:'var(--ink)' }}></span>
          <span>Continue with Apple</span>
        </button>
        <button className="social-btn" style={{ padding: 14 }}>
          <span className="glyph">☐</span>
          <span>Continue with phone</span>
        </button>
      </div>
      <div className="grow" />
      <div className="box dashed" style={{ padding: 10, background: 'rgba(212,255,58,0.05)', borderColor: 'var(--matcha)' }}>
        <div className="row middle gap-2">
          <span className="chip lime tiny" style={{ padding: '2px 8px' }}>✓</span>
          <div className="tiny">Free to join · cash out anytime</div>
        </div>
      </div>
      <div className="tiny muted tac" style={{ marginTop: 4 }}>
        By signing up you agree to our <span style={{ textDecoration: 'underline' }}>Terms</span> & <span style={{ textDecoration: 'underline' }}>Privacy</span>
      </div>
    </div>
  </Phone>
);

// =========== ONBOARDING (4) ===========

const Onb_Carousel = () => (
  <Phone>
    <div className="col" style={{ height:'100%' }}>
      <div className="row between sm muted"><span>Skip</span><span>1/3</span></div>
      <div className="grow col center" style={{ gap: 14, textAlign:'center', padding:'10px 6px' }}>
        <div className="box dashed" style={{ width: 170, height: 150, display:'grid', placeItems:'center', background:'rgba(212,255,58,0.06)', borderColor:'var(--matcha)' }}>
          <span className="callout" style={{ color:'var(--matcha)' }}>[ Illo — feet ]</span>
        </div>
        <div className="hand" style={{ fontSize: 28, lineHeight: 1.1 }}>Every <span className="marker">Step</span><br/>Counts. 👟</div>
        <div className="sm muted" style={{ maxWidth: 230 }}>Auto-sync from your phone or wearable. No manual logging.</div>
      </div>
      <div className="row gap-2 center" style={{ marginBottom: 10 }}>
        {[0,1,2].map(i => <span key={i} className="circ" style={{width:8,height:8,background:i===0?'var(--matcha)':'transparent', borderColor:i===0?'var(--matcha)':'var(--ink-3)'}} />)}
      </div>
      <button className="btn gold full">Next →</button>
    </div>
  </Phone>
);

const Onb_OnePage = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="hand" style={{ fontSize: 28, lineHeight: 1 }}>Here's the<br/>Deal 👟</div>
      <Squiggle />
      <div className="col gap-3" style={{ marginTop: 4 }}>
        {[
          ['1', 'Track every activity', 'Steps, gym, sport, yoga — auto-sync'],
          ['2', 'Join wellness challenges', 'By category · your level'],
          ['3', 'Stay consistent', 'Daily check-ins · earn coins'],
          ['4', 'Redeem rewards', 'Coins → gift cards (Amazon, Flipkart…)'],
        ].map(([n, t, s]) => (
          <div key={n} className="row gap-3 middle">
            <div className="circ" style={{ width: 34, height: 34, display:'grid', placeItems:'center', fontFamily: 'Big Shoulders Display', fontWeight:700, fontSize:20, color:'var(--matcha)', borderColor:'var(--matcha)' }}>{n}</div>
            <div className="col" style={{ gap: 2 }}>
              <div className="md b">{t}</div>
              <div className="tiny muted">{s}</div>
            </div>
          </div>
        ))}
      </div>
      <div className="grow" />
      <button className="btn gold full">Let's go →</button>
      <div className="tiny muted tac">Already have an account? sign in</div>
    </div>
  </Phone>
);

const Onb_GoalPicker = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="hand xl">What's your vibe?</div>
      <div className="sm muted">Pick what you do · we'll match challenges</div>
      <div className="col gap-2" style={{ marginTop: 6 }}>
        {[
          ['Walking & steps',           'walk',  true],
          ['Gym & strength',            'gym',   true],
          ['Running',                   'run',   false],
          ['Yoga & mindfulness',        'yoga',  false],
          ['Sport (badminton, cricket…)','sport', false],
          ['Cycling & swimming',        'cycle', false],
        ].map(([t, ic, on]) => (
          <div key={t} className="row between middle" style={{
            padding:'14px 16px',
            borderRadius: 12,
            background: on ? 'rgba(212,255,58,0.08)' : 'rgba(255,255,255,0.03)',
            border: '1.5px solid ' + (on ? 'var(--matcha)' : 'transparent')
          }}>
            <div className="row middle gap-3">
              <div style={{
                width: 32, height: 32, borderRadius: 9,
                display:'grid', placeItems:'center',
                background: on ? 'rgba(212,255,58,0.15)' : 'rgba(255,255,255,0.06)',
                color: on ? 'var(--matcha)' : 'var(--ink)',
                flexShrink: 0
              }}>
                <Icon name={ic} size={18} stroke={2.2} />
              </div>
              <span className="md b">{t}</span>
            </div>
            <span style={{
              width: 22, height: 22, borderRadius: '50%',
              background: on ? 'var(--matcha)' : 'transparent',
              border: '1.5px solid ' + (on ? 'var(--matcha)' : 'rgba(255,255,255,0.2)'),
              display:'grid', placeItems:'center',
              color:'#0a0a14',
              flexShrink: 0
            }}>{on ? <Icon name="check" size={12} stroke={3} /> : null}</span>
          </div>
        ))}
      </div>
      <div className="grow" />
      <button className="btn gold full">Continue (2 picked) →</button>
    </div>
  </Phone>
);

const Onb_Permissions = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="hand xl">A few asks 🙏</div>
      <div className="sm muted">We only use these to track & remind</div>
      <div className="col gap-3" style={{ marginTop: 8 }}>
        {[
          ['Health data', 'Count your steps', '✓ on', true],
          ['Notifications', 'Streak reminders', 'Allow →', false],
          ['Location', 'Detect runs (optional)', 'Skip if u want', false],
        ].map(([t, s, status, ok]) => (
          <div key={t} className="box" style={{ padding: 12, borderColor: ok ? 'var(--matcha)' : 'var(--ink-3)', background: ok ? 'rgba(212,255,58,0.08)' : 'var(--paper-2)' }}>
            <div className="row between middle">
              <div className="col" style={{ gap: 2 }}>
                <div className="md b">{t}</div>
                <div className="tiny muted">{s}</div>
              </div>
              <span className={'chip ' + (ok ? 'lime' : '')}>{status}</span>
            </div>
          </div>
        ))}
      </div>
      <div className="grow" />
      <div className="tac sm muted">You can change these later in Settings</div>
      <button className="btn gold full" style={{ marginTop: 8 }}>Continue →</button>
    </div>
  </Phone>
);

// =========== PROFILE SETUP (4) ===========

const Prof_Wizard = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 8 }}>
      <div className="row between sm muted"><span>← Back</span><span></span></div>
      <div className="col gap-2" style={{ marginTop: 2 }}>
        <div className="row gap-2">
          {[1,1,0,0].map((v, i) => (
            <div key={i} className="grow" style={{ height: 4, background: v ? 'var(--matcha)' : 'var(--grid)', borderRadius: 3 }} />
          ))}
        </div>
        <div className="tiny muted">Step 2 of 4</div>
      </div>
      <div className="hand" style={{ fontSize: 26, marginTop: 8 }}>About you</div>
      <div className="sm muted">Helps us calc your calories & pace</div>
      <div className="col gap-3" style={{ marginTop: 8 }}>
        <div className="box dashed">
          <div className="tiny muted">Date of birth</div>
          <div className="md">14 / 03 / 1994</div>
        </div>
        <div className="row gap-2">
          <div className="box dashed grow">
            <div className="tiny muted">Height</div>
            <div className="md">172 Cm</div>
          </div>
          <div className="box dashed grow">
            <div className="tiny muted">Weight</div>
            <div className="md">68 Kg</div>
          </div>
        </div>
        <div className="box dashed">
          <div className="tiny muted">Sex</div>
          <div className="row gap-2" style={{ marginTop: 4 }}>
            <span className="chip lime">Male</span>
            <span className="chip">Female</span>
            <span className="chip">Other</span>
          </div>
        </div>
      </div>
      <div className="grow" />
      <button className="btn gold full">Next →</button>
    </div>
  </Phone>
);

const Prof_OneForm = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 8 }}>
      <div className="hand xl">Set up profile</div>
      <div className="sm muted">All in one go · skip what you want</div>
      <div className="col gap-2" style={{ marginTop: 6 }}>
        <div className="row gap-2 middle">
          <div className="circ thick" style={{ width:48, height:48, display:'grid', placeItems:'center' }}>+</div>
          <div className="col">
            <input className="box dashed" placeholder="Display name" style={{ fontFamily: 'Inter', border:'1.5px dashed #2a2e26', background:'transparent' }} />
            <div className="tiny muted" style={{ marginTop: 2 }}>Tap photo to add</div>
          </div>
        </div>
        <Squiggle />
        <div className="tiny b">Body</div>
        <div className="row gap-2">
          <div className="box grow tiny">DOB · 14/3/94</div>
          <div className="box grow tiny">172Cm · 68kg</div>
        </div>
        <div className="tiny b" style={{ marginTop: 4 }}>Daily goal</div>
        <div className="row gap-2">
          {['5k','8k','10k','12k','15k'].map(g => (
            <span key={g} className={'chip' + (g==='10k' ? ' lime' : '')}>{g}</span>
          ))}
        </div>
        <div className="tiny b" style={{ marginTop: 4 }}>I do</div>
        <div className="row gap-2" style={{ flexWrap:'wrap' }}>
          {[['Walk',1],['Run',1],['Gym',0],['Cycle',1],['Yoga',0]].map(([t, on]) => (
            <span key={t} className={'chip' + (on ? ' lime' : '')}>{on ? '✓ ' : ''}{t}</span>
          ))}
        </div>
      </div>
      <div className="grow" />
      <button className="btn gold full">Save & continue →</button>
    </div>
  </Phone>
);

const Prof_QuickCards = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10 }}>
      <div className="hand xl">3 Quick taps</div>
      <div className="sm muted">We'll fill the rest later</div>
      <div className="col gap-3" style={{ marginTop: 6 }}>
        <div className="box" style={{ padding: 14, borderColor: 'var(--ink-3)' }}>
          <div className="row between middle">
            <div>
              <div className="hand lg">1 · Who</div>
              <div className="tiny muted">Name + photo</div>
            </div>
            <span className="callout">Tap →</span>
          </div>
        </div>
        <div className="box" style={{ padding: 14, borderColor: 'var(--matcha)', background: 'rgba(212,255,58,0.08)' }}>
          <div className="row between middle">
            <div>
              <div className="hand lg">2 · Goal</div>
              <div className="tiny">10,000 Steps / day ✓</div>
            </div>
            <span className="chip lime">Edit</span>
          </div>
        </div>
        <div className="box" style={{ padding: 14, borderColor: 'var(--ink-3)' }}>
          <div className="row between middle">
            <div>
              <div className="hand lg">3 · Activities</div>
              <div className="tiny muted">Walk · run · cycle</div>
            </div>
            <span className="callout">Tap →</span>
          </div>
        </div>
      </div>
      <div className="grow" />
      <div className="row gap-2">
        <button className="btn ghost full">Skip all</button>
        <button className="btn gold full">Done →</button>
      </div>
    </div>
  </Phone>
);

const Prof_Chat = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 6 }}>
      <div className="row between sm">
        <span className="hand lg">Setup chat</span>
        <span className="tiny muted">3 Of 6</span>
      </div>
      <Squiggle />
      <div className="col gap-2 grow" style={{ overflow:'hidden', marginTop: 4 }}>
        <div className="box" style={{ alignSelf:'flex-start', maxWidth:'80%', background:'var(--paper-3)', borderColor:'var(--ink-3)' }}>
          <div className="sm">Hey! What should I call you? </div>
        </div>
        <div className="box fill-lime" style={{ alignSelf:'flex-end', maxWidth:'70%' }}>
          <div className="sm">Riya</div>
        </div>
        <div className="box" style={{ alignSelf:'flex-start', maxWidth:'80%', background:'var(--paper-3)', borderColor:'var(--ink-3)' }}>
          <div className="sm">Nice. What's your daily goal?</div>
        </div>
        <div className="box fill-lime" style={{ alignSelf:'flex-end', maxWidth:'60%' }}>
          <div className="sm">10K steps ✨</div>
        </div>
        <div className="box" style={{ alignSelf:'flex-start', maxWidth:'80%', background:'var(--paper-3)', borderColor:'var(--ink-3)' }}>
          <div className="sm">Got it. Pick the stuff you do →</div>
        </div>
        <div className="row gap-2" style={{ flexWrap:'wrap', alignSelf:'flex-end' }}>
          {['Walk','Run','Gym','Cycle','Yoga'].map(t => (
            <span key={t} className="chip">{t}</span>
          ))}
        </div>
      </div>
      <div className="box dashed row between middle">
        <span className="tiny muted">Type or pick…</span>
        <span className="hand">↵</span>
      </div>
    </div>
  </Phone>
);

// =========== DASHBOARD (5) ===========

const Dash_Ring = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 10, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="col">
          <div className="tiny muted">Tuesday · may 21</div>
          <div className="hand lg">Hey <span style={{ color:'var(--matcha)' }}>Riya</span> </div>
        </div>
        <div className="chip" style={{ gap: 6 }}><Icon name="flame" size={12} stroke={2.2} />12D</div>
      </div>
      <div className="col center" style={{ marginTop: 6 }}>
        <StepRing size={140} color="#d4ff3a" />
        <div className="row gap-2" style={{ marginTop: 10 }}>
          <span className="chip">5.4 Km</span>
          <span className="chip">412 Kcal</span>
          <span className="chip">52 Min</span>
        </div>
      </div>
      <Squiggle />
      <div className="col gap-2">
        <div className="row between middle">
          <div className="sm b">Active challenge</div>
          <div className="tiny muted">2 More →</div>
        </div>
        <div className="box" style={{ padding: 14, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.08)' }}>
          <div className="row between middle">
            <div>
              <div className="md b">7-Day consistency · Gym</div>
              <div className="tiny muted" style={{ marginTop: 2 }}>Day 4 of 7 · 92 members</div>
            </div>
            <span className="tiny b" style={{
              color:'var(--matcha)',
              letterSpacing: 0.6,
              textTransform: 'uppercase',
              flexShrink: 0,
              marginLeft: 8
            }}>On Track</span>
          </div>
          <div style={{ height: 5, background:'rgba(255,255,255,0.1)', borderRadius: 4, marginTop: 10 }}>
            <div style={{ height:'100%', width:'57%', background:'var(--matcha)', borderRadius: 4 }} />
          </div>
        </div>
        <div className="row gap-2">
          <div className="box grow" style={{ padding: 12, background:'rgba(255,255,255,0.04)' }}>
            <div className="row middle gap-2 tiny muted" style={{ letterSpacing: 0.5, textTransform:'uppercase' }}>
              <Icon name="flame" size={12} stroke={2.2} color="var(--matcha)" />
              <span>Streak</span>
            </div>
            <div className="hand display" style={{ fontSize: 22, marginTop: 4 }}>12 Days</div>
          </div>
          <div className="box grow" style={{ padding: 12, background:'rgba(255,181,71,0.06)' }}>
            <div className="row middle gap-2 tiny muted" style={{ letterSpacing: 0.5, textTransform:'uppercase' }}>
              <Icon name="coin" size={12} stroke={2.2} color="var(--ochre)" />
              <span style={{ color:'var(--ochre)' }}>Coins</span>
            </div>
            <div className="hand display" style={{ fontSize: 22, marginTop: 4, color:'var(--ochre)' }}>1,240</div>
          </div>
        </div>
      </div>
    </div>
    <TabBar active="home" />
  </Phone>
);

const Dash_StatsGrid = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 8, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Today</div>
        <div className="tiny muted">May 21</div>
      </div>
      <div className="box" style={{ padding: 14, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.08)' }}>
        <div className="tiny muted">Steps</div>
        <div className="hand display" style={{ fontSize: 56, lineHeight: 1, color:'var(--matcha)' }}>7,832</div>
        <div className="tiny muted">78% Of 10,000 goal</div>
        <div style={{ height: 6, background:'var(--paper-3)', borderRadius: 4, marginTop: 10, border:'1px solid var(--ink-3)' }}>
          <div style={{ height:'100%', width:'78%', background:'var(--matcha)', borderRadius: 3 }} />
        </div>
      </div>
      <div className="row gap-2">
        <div className="box grow" style={{ padding: 10 }}><div className="tiny muted">Distance</div><div className="hand lg">5.4 Km</div></div>
        <div className="box grow" style={{ padding: 10 }}><div className="tiny muted">Calories</div><div className="hand lg">412</div></div>
      </div>
      <div className="row gap-2">
        <div className="box grow" style={{ padding: 10 }}><div className="tiny muted">Active min</div><div className="hand lg">52</div></div>
        <div className="box grow" style={{ padding: 10 }}><div className="tiny muted">Floors</div><div className="hand lg">14</div></div>
      </div>
      <Squiggle />
      <div className="row between middle">
        <div className="sm b">This week</div>
        <div className="tiny muted">View →</div>
      </div>
      <div className="row gap-2 between" style={{ alignItems:'flex-end', height: 60, padding:'0 4px' }}>
        {[40,70,55,90,60,45,30].map((h, i) => (
          <div key={i} className="col center" style={{ flex: 1, gap: 3 }}>
            <div style={{
              width:'70%', height: h+'%',
              background: i===3 ? 'var(--matcha)' : 'var(--ink-3)',
              opacity: i===3 ? 1 : 0.55,
              borderRadius:'3px 3px 0 0'
            }} />
            <div className="tiny muted">{'MTWTFSS'[i]}</div>
          </div>
        ))}
      </div>
    </div>
    <TabBar active="home" />
  </Phone>
);

const Dash_Feed = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Activity</div>
        <div className="row gap-2 tiny"><span className="b" style={{ color:'var(--matcha)' }}>TODAY</span><span className="muted">·  WEEK</span></div>
      </div>
      <div className="box" style={{ padding: 14, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.08)' }}>
        <div className="row between middle">
          <div className="row middle gap-2">
            <Icon name="walk" size={20} stroke={2.2} color="var(--matcha)" />
            <span className="hand lg">7,832 Steps</span>
          </div>
          <div className="chip lime">▲ 78%</div>
        </div>
      </div>
      <div className="tiny muted" style={{ letterSpacing: 0.6, textTransform:'uppercase' }}>Timeline</div>
      <div className="col" style={{ overflow:'hidden' }}>
        {[
          ['7:20 AM','walk','Morning walk · 22 min'],
          ['9:05 AM','gym', 'Gym · chest day · 48 min'],
          ['1:14 PM','walk','Lunch walk · 14 min'],
          ['4:30 PM','flame','Joined "7-day yoga"'],
          ['6:00 PM','run', 'Run · 3.2 km · +40 coins'],
        ].map(([t, ic, msg]) => (
          <div key={t} className="row gap-3 middle" style={{ padding:'10px 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
            <div className="tiny muted" style={{ width: 54, letterSpacing: 0.4 }}>{t}</div>
            <div style={{
              width: 32, height: 32, borderRadius: 10,
              display:'grid', placeItems:'center',
              background:'rgba(255,255,255,0.06)',
              color: 'var(--ink)', flexShrink: 0
            }}>
              <Icon name={ic} size={18} stroke={2} />
            </div>
            <div className="sm grow" style={{ lineHeight: 1.4 }}>{msg}</div>
          </div>
        ))}
      </div>
      <div className="grow" />
    </div>
    <TabBar active="home" />
  </Phone>
);

const Dash_Hub = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 12, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">StepUp</div>
        <div className="circ" style={{ width: 30, height: 30, display:'grid', placeItems:'center', background:'rgba(255,255,255,0.06)', borderColor:'transparent' }}>R</div>
      </div>
      <div className="box" style={{ padding: 14, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.08)' }}>
        <div className="tiny muted">Today</div>
        <div className="hand display" style={{ fontSize: 38, lineHeight: 1, color:'var(--matcha)' }}>7,832 / 10K</div>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap: 8 }}>
        <div className="box" style={{ padding: 12, background:'rgba(255,255,255,0.04)' }}>
          <div className="row middle gap-2"><Icon name="trophy" size={16} stroke={2.2} color="var(--matcha)" /><span className="hand lg">Challenges</span></div>
          <div className="tiny muted" style={{ marginTop: 4 }}>2 Active · 8 open</div>
        </div>
        <div className="box" style={{ padding: 12, borderColor:'var(--ochre)', background:'rgba(255,181,71,0.06)' }}>
          <div className="row middle gap-2"><Icon name="coin" size={16} stroke={2.2} color="var(--ochre)" /><span className="hand lg" style={{ color:'var(--ochre)' }}>Coins</span></div>
          <div className="tiny" style={{ marginTop: 4 }}>1,240 · Redeem</div>
        </div>
        <div className="box" style={{ padding: 12, background:'rgba(255,255,255,0.04)' }}>
          <div className="row middle gap-2"><Icon name="chart" size={16} stroke={2.2} /><span className="hand lg">Leaderboard</span></div>
          <div className="tiny muted" style={{ marginTop: 4 }}>You're #14</div>
        </div>
        <div className="box" style={{ padding: 12, background:'rgba(255,255,255,0.04)' }}>
          <div className="row middle gap-2"><Icon name="user" size={16} stroke={2.2} /><span className="hand lg">Friends</span></div>
          <div className="tiny muted" style={{ marginTop: 4 }}>3 Invites ↑</div>
        </div>
      </div>
      <div className="grow" />
      <div className="row middle gap-2" style={{ padding:'10px 12px', background:'rgba(255,255,255,0.04)', borderRadius: 12 }}>
        <Icon name="flame" size={16} stroke={2.2} color="var(--matcha)" />
        <span className="sm b">Day 12 streak</span>
        <span className="grow" />
        <span className="tiny muted">Don't break it →</span>
      </div>
    </div>
    <TabBar active="home" />
  </Phone>
);

const Dash_CardStack = () => (
  <Phone>
    <div className="col" style={{ height:'100%', gap: 8, paddingBottom: 44 }}>
      <div className="row between middle">
        <div className="hand xl">Hi Riya</div>
        <div className="tiny muted">May 21</div>
      </div>
      <div className="tiny muted">Swipe →</div>
      <div style={{ position:'relative', height: 260 }}>
        <div className="box" style={{
          position:'absolute', left: 18, right: -10, top: 16, bottom: 0,
          opacity: 0.4, borderColor: 'var(--ink-3)'
        }} />
        <div className="box" style={{
          position:'absolute', left: 10, right: -4, top: 8, bottom: 0,
          opacity: 0.7, borderColor: 'var(--ink-3)'
        }} />
        <div className="box" style={{
          position:'absolute', left: 0, right: 4, top: 0, bottom: 8,
          padding: 16, borderColor:'var(--matcha)', background:'rgba(212,255,58,0.06)'
        }}>
          <div className="row between middle">
            <div className="chip lime">TODAY · 1/4</div>
            <div className="tiny muted">○ ● ○ ○</div>
          </div>
          <div className="col center" style={{ gap: 6, marginTop: 14 }}>
            <StepRing size={130} color="#d4ff3a" />
          </div>
          <div className="row between" style={{ marginTop: 12 }}>
            <span className="chip">5.4 Km</span>
            <span className="chip">412 Kcal</span>
            <span className="chip">52 Min</span>
          </div>
        </div>
      </div>
      <div className="row gap-2 center" style={{ marginTop: 4 }}>
        {['Today','Streak','Challenge','Coins'].map((t, i) => (
          <span key={t} className={'tiny' + (i===0 ? ' b' : ' muted')} style={{ color: i===0 ? 'var(--matcha)' : undefined }}>{t}</span>
        ))}
      </div>
      <div className="grow" />
      <button className="btn gold full">Log activity +</button>
    </div>
    <TabBar active="home" />
  </Phone>
);

// =========== Helper: artboard wrapper with caption ===========

const Frame = ({ note, children }) => (
  <div className="col" style={{ alignItems:'center', gap: 10, padding: 16 }}>
    {children}
    {note && <div className="callout tac" style={{ maxWidth: 280 }}>{note}</div>}
  </div>
);

// =========== EXPORT ALL TO WINDOW (consumed by wireframes-extra.jsx) ===========

Object.assign(window, {
  Phone, Squiggle, Bar, HandIcon, Icon, Sticky, TabBar, StepRing, Frame,
  // expose canvas primitives too so canvas-mount.jsx can use them
  DesignCanvas: window.DesignCanvas, DCSection: window.DCSection, DCArtboard: window.DCArtboard,
  // start
  Start_A, Start_B, Start_C, Auth_Login, Auth_OTP, Auth_Social,
  // onboarding
  Onb_Carousel, Onb_OnePage, Onb_GoalPicker, Onb_Permissions,
  // profile setup
  Prof_Wizard, Prof_OneForm, Prof_QuickCards, Prof_Chat,
  // dashboard
  Dash_Ring, Dash_StatsGrid, Dash_Feed, Dash_Hub, Dash_CardStack,
});


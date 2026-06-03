<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { setLocale, getLocale } from '@/i18n'

/* ------------------------------------------------------------------ *
 * sms1.site 落地页 —— 企业级国际短信网关系统（SMSC）
 * 可私有化部署 · 源码级交付 · 深色霓虹 · 中英双语
 * ------------------------------------------------------------------ */

const router = useRouter()
const { locale } = useI18n()

const isZh = computed(() => (locale.value || 'zh-CN').startsWith('zh'))
const scrolled = ref(false)
const progress = ref(0)
const mobileMenu = ref(false)
const rotIdx = ref(0)
const openFaq = ref<number>(0)
const theme = ref<'dark' | 'light'>('dark')
const CONTACT_URL = 'https://t.me/jack9967'

const pageTitle = computed(() => isZh.value
  ? 'sms1.site · 企业级国际短信网关系统（可私有化部署 / 源码级交付）'
  : 'sms1.site · Enterprise SMS Gateway (Self-hosted / Source-code delivery)')

/* 性能数据滚动递增 */
const bandConf = [
  { v: 10000, dec: 0, suf: '+', pre: '', comma: true },
  { v: 200, dec: 0, suf: 'ms', pre: '<', comma: false },
  { v: 99.9, dec: 1, suf: '%', pre: '', comma: false },
  { v: 95, dec: 0, suf: '%+', pre: '', comma: false },
]
const bandDisp = ref<string[]>(bandConf.map(c => c.pre + '0' + c.suf))
let bandDone = false
function fmt(v: number, c: typeof bandConf[number]) {
  let s = c.dec ? v.toFixed(c.dec) : Math.round(v).toString()
  if (c.comma) s = s.replace(/\B(?=(\d{3})+(?!\d))/g, ',')
  return c.pre + s + c.suf
}
function runCountUp() {
  if (bandDone) return
  bandDone = true
  const dur = 1600
  const start = performance.now()
  const step = (now: number) => {
    const p = Math.min((now - start) / dur, 1)
    const e = 1 - Math.pow(1 - p, 3)
    bandDisp.value = bandConf.map(c => fmt(c.v * e, c))
    if (p < 1) requestAnimationFrame(step)
  }
  requestAnimationFrame(step)
}

let rotTimer: number | undefined
function onScroll() {
  scrolled.value = window.scrollY > 24
  const h = document.documentElement
  const max = h.scrollHeight - h.clientHeight
  progress.value = max > 0 ? Math.min(window.scrollY / max, 1) : 0
}
function toLogin() { router.push('/login') }
function toContact() { window.open(CONTACT_URL, '_blank', 'noopener') }
function toggleLang() { setLocale(isZh.value ? 'en-US' : 'zh-CN') }
function applyTheme() { document.documentElement.setAttribute('data-theme', theme.value); document.documentElement.classList.toggle('dark', theme.value === 'dark') }
function toggleTheme() {
  theme.value = theme.value === 'dark' ? 'light' : 'dark'
  try { localStorage.setItem('theme', theme.value) } catch { /* ignore */ }
  applyTheme()
}
function scrollTo(id: string) {
  mobileMenu.value = false
  document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  try {
    const savedTheme = localStorage.getItem('theme')
    if (savedTheme === 'light' || savedTheme === 'dark') {
      theme.value = savedTheme
    } else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      theme.value = 'dark'
    } else {
      theme.value = 'light'
    }
  } catch { /* ignore */ }
  applyTheme()
  const saved = getLocale()
  if (saved) setLocale(saved)
  document.title = pageTitle.value
  rotTimer = window.setInterval(() => {
    rotIdx.value = (rotIdx.value + 1) % rotWords.value.length
  }, 2200)
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (!e.isIntersecting) return
      e.target.classList.add('in')
      if ((e.target as HTMLElement).dataset.countup !== undefined) runCountUp()
    })
  }, { threshold: 0.12 })
  document.querySelectorAll('[data-reveal]').forEach(el => io.observe(el))
})
watch(pageTitle, (v) => { document.title = v })
onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
  if (rotTimer) window.clearInterval(rotTimer)
})

/* ---------------------------- 图标 ---------------------------- */
const ICONS: Record<string, string> = {
  cash: 'M2 6h20v12H2z M16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0',
  box: 'M21 8l-9-5-9 5 9 5 9-5z M3 8v8l9 5 9-5V8 M12 13v8',
  calc: 'M5 3h14v18H5z M8 7h8 M8 11h3 M13 11h3 M8 15h3 M13 15h3',
  wall: 'M3 4h18v16H3z M3 9h18 M3 15h18 M9 4v5 M15 9v6 M9 15v5',
  route: 'M6 19a2 2 0 1 0 0-4 2 2 0 0 0 0 4z M18 9a2 2 0 1 0 0-4 2 2 0 0 0 0 4z M8 17h6a3 3 0 0 0 3-3V9 M6 15V8a3 3 0 0 1 3-3h3',
  globe: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z M3 12h18 M12 3a14 14 0 0 1 0 18 M12 3a14 14 0 0 0 0 18',
  robot: 'M12 2v3 M7 8h10a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z M9 13h.01 M15 13h.01 M9 17h6',
  shield: 'M12 3l8 3v6c0 5-3.5 8-8 11-4.5-3-8-6-8-11V6l8-3z',
  link: 'M9 15l6-6 M10 6l1-1a4 4 0 0 1 6 6l-1 1 M14 18l-1 1a4 4 0 0 1-6-6l1-1',
  folder: 'M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
  code: 'M8 9l-4 3 4 3 M16 9l4 3-4 3 M13 5l-2 14',
  cpu: 'M6 6h12v12H6z M9 9h6v6H9z M9 2v3 M15 2v3 M9 19v3 M15 19v3 M2 9h3 M2 15h3 M19 9h3 M19 15h3',
  doc: 'M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z M14 3v5h5 M9 13h6 M9 17h6',
  rocket: 'M9 13l-2-2c1-5 5-9 12-9 0 7-4 11-9 12l-2-2 M9 13c-1.5.5-2.5 2-3 4 2-.5 3.5-1.5 4-3 M15 8h.01',
  cart: 'M3 4h2l2 12h11l2-8H6 M9 20a1 1 0 1 0 .01 0 M18 20a1 1 0 1 0 .01 0',
  bank: 'M3 10l9-6 9 6 M5 10v8 M9 10v8 M15 10v8 M19 10v8 M3 21h18',
  wrench: 'M21 4a5 5 0 0 1-6 6l-7 7-3-3 7-7a5 5 0 0 1 6-6l-3 3 2 2 3-3z',
  phone: 'M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2z',
  key: 'M14 7a4 4 0 1 0-3.5 4L4 17.5V20h2.5l1-1v-2h2l1.5-1.5A4 4 0 0 0 14 7z',
  chart: 'M4 20V10 M10 20V4 M16 20v-7 M22 20H2',
  check: 'M20 6L9 17l-5-5',
  lock: 'M5 11h14v10H5z M8 11V7a4 4 0 0 1 8 0v4',
  layers: 'M12 3l9 5-9 5-9-5 9-5z M3 13l9 5 9-5',
}

/* ---------------------------- 文案 ---------------------------- */
const rotWords = computed(() => isZh.value
  ? ['核心资产', '护城河', '定价权', '二次开发权']
  : ['core asset', 'a moat', 'pricing power', 'your own stack'])

const t = computed(() => isZh.value ? zh : en)

const navLinks = computed(() => isZh.value
  ? [{ id: 'problem', label: '痛点' }, { id: 'killers', label: '核心能力' }, { id: 'tech', label: '技术' }, { id: 'delivery', label: '交付' }, { id: 'plans', label: '购买方案' }, { id: 'faq', label: '常见问题' }]
  : [{ id: 'problem', label: 'Problem' }, { id: 'killers', label: 'Core' }, { id: 'tech', label: 'Tech' }, { id: 'delivery', label: 'Delivery' }, { id: 'plans', label: 'Plans' }, { id: 'faq', label: 'FAQ' }])

const heroTags = computed(() => isZh.value
  ? ['智能路由', '三级计费', '全球合规 Sender ID', 'Telegram 深度集成', '源码级交付']
  : ['Smart routing', 'Three-tier billing', 'Global Sender ID', 'Telegram integration', 'Source-code delivery'])

const heroStats = computed(() => isZh.value
  ? [{ n: '200+', l: '国家与地区' }, { n: '300+', l: '直连通道' }, { n: '10K+', l: '并发 TPS' }, { n: '源码', l: '级交付' }]
  : [{ n: '200+', l: 'Countries' }, { n: '300+', l: 'Direct routes' }, { n: '10K+', l: 'Peak TPS' }, { n: 'Source', l: 'code' }])

const countryRaw = [
  ['🇺🇸', '+1', 'USA'], ['🇬🇧', '+44', 'UK'], ['🇮🇳', '+91', 'India'], ['🇮🇩', '+62', 'Indonesia'],
  ['🇧🇷', '+55', 'Brazil'], ['🇳🇬', '+234', 'Nigeria'], ['🇵🇭', '+63', 'Philippines'], ['🇻🇳', '+84', 'Vietnam'],
  ['🇹🇭', '+66', 'Thailand'], ['🇲🇽', '+52', 'Mexico'], ['🇸🇦', '+966', 'Saudi'], ['🇦🇪', '+971', 'UAE'],
  ['🇩🇪', '+49', 'Germany'], ['🇫🇷', '+33', 'France'], ['🇷🇺', '+7', 'Russia'], ['🇯🇵', '+81', 'Japan'],
  ['🇰🇷', '+82', 'Korea'], ['🇹🇷', '+90', 'Türkiye'], ['🇪🇬', '+20', 'Egypt'], ['🇿🇦', '+27', 'S.Africa'],
  ['🇵🇰', '+92', 'Pakistan'], ['🇲🇾', '+60', 'Malaysia'], ['🇸🇬', '+65', 'Singapore'], ['🇦🇷', '+54', 'Argentina'],
]
const marqueeList = computed(() => [...countryRaw, ...countryRaw])

const problems = computed(() => isZh.value ? [
  { ic: 'cash', t: '价格是一笔糊涂账', d: '上游层层加价，国家与运营商差价巨大，月底对账永远对不平——到底亏在哪，没人说得清。' },
  { ic: 'box', t: '送达率是一个黑盒', d: '钱花了，用户没收到。通道一抖动，验证码大面积超时，客诉爆炸，却查不到卡在哪一跳。' },
  { ic: 'calc', t: '计费复杂到无法自助', d: '长短信怎么拆？多币种怎么结算？逐运营商定价靠 Excel 人肉算账，根本无法规模化。' },
  { ic: 'wall', t: '对接门槛劝退一切', d: 'SMPP 协议、长连接保活、DLR 回执、各国合规——每项都是墙，上线动辄数月。' },
] : [
  { ic: 'cash', t: 'Pricing is a black hole', d: 'Upstream markups stack up, per-country/carrier spreads are huge — reconciliation never balances.' },
  { ic: 'box', t: 'Delivery is a black box', d: 'You paid, users got nothing. One flaky route and OTPs time out at scale — no idea which hop failed.' },
  { ic: 'calc', t: 'Billing too complex to self-serve', d: 'Segment long SMS? Multi-currency? Per-carrier pricing in Excel by hand — impossible to scale.' },
  { ic: 'wall', t: 'Integration walls everyone off', d: 'SMPP, keep-alive, DLR receipts, per-country compliance — every one a wall, months to launch.' },
])

const rights = computed(() => isZh.value
  ? [{ ic: 'key', t: '定价权' }, { ic: 'chart', t: '数据权' }, { ic: 'shield', t: '合规掌控权' }, { ic: 'code', t: '二次开发权' }]
  : [{ ic: 'key', t: 'Pricing power' }, { ic: 'chart', t: 'Data ownership' }, { ic: 'shield', t: 'Compliance control' }, { ic: 'code', t: 'Dev freedom' }])

const killers = computed(() => isZh.value ? [
  { ic: 'route', tag: '#01 智能路由', title: '智能路由引擎', desc: '短信成本与质量，70% 由"选路"决定。四种策略一键切换、自动决策，主通道异常毫秒级容灾。',
    pts: ['成本优先 → 自动选最便宜合规通道', '质量优先 → 自动选送达率最高通道', '优先级优先 → 核心通道优先跑量', '负载均衡 → 多通道分摊避免限速'] },
  { ic: 'cash', tag: '#02 三级计费', title: '精细化三级计费', desc: '通道 × 国家 × 运营商 三维定价颗粒度，把每一分钱算到底，对集成商就是"印钞机"。',
    pts: ['三维定价：通道 / 国家 / 运营商', '长短信自动拆分计费，不多收不漏算', '多币种结算：USD / CNY / EUR', '多级套餐：主账户 + 子账户分权分额'] },
  { ic: 'globe', tag: '#03 全球合规', title: 'Sender ID 动态合规', desc: '4 级优先级智能匹配：用户指定 › 专属 › 通用 › 系统默认，一套系统覆盖全球。',
    pts: ['完美适配美国字母 Sender ID', '适配印度 DLT 等各国合规政策', '发错一步整批被拦？自动兜底', '合规从拦路虎变成竞争优势'] },
  { ic: 'robot', tag: '#04 TG 集成', title: 'Telegram Bot 深度集成', desc: '业内首创，业务全流程在聊天框里闭环，销售与客户再也不用守着电脑。',
    pts: ['零门槛 TG 内注册开户', '一句话查余额 / 流水', '聊天框内单发 / 批量发送', '发送结果与 DLR 回执主动推送'] },
] : [
  { ic: 'route', tag: '#01 Routing', title: 'Smart routing engine', desc: '70% of cost & quality is the route. Four strategies, auto-decided, millisecond failover.',
    pts: ['Cost-first → cheapest compliant route', 'Quality-first → highest delivery route', 'Priority → core routes run first', 'Load balance → spread to avoid throttling'] },
  { ic: 'cash', tag: '#02 Billing', title: 'Three-tier billing', desc: 'Channel × Country × Carrier pricing granularity — every cent accounted for.',
    pts: ['3D pricing: channel / country / carrier', 'Auto long-SMS segmentation', 'Multi-currency: USD / CNY / EUR', 'Tiered plans, master + sub-accounts'] },
  { ic: 'globe', tag: '#03 Compliance', title: 'Dynamic Sender ID', desc: '4-level priority match: user › dedicated › shared › default — one system, worldwide.',
    pts: ['US alphabetic Sender ID ready', 'India DLT & per-country policies', 'Auto fallback so batches don\'t fail', 'Compliance becomes an advantage'] },
  { ic: 'robot', tag: '#04 Telegram', title: 'Deep Telegram Bot', desc: 'Industry-first: the whole workflow closes inside a chat — no desktop needed.',
    pts: ['Zero-friction sign-up in TG', 'Check balance / ledger in one line', 'Single / bulk send in chat', 'Results & DLR pushed to TG'] },
])

const signature = computed(() => isZh.value ? [
  { ic: 'shield', t: '违禁词检测 · 发送前拦截', d: '全局 + 通道 + 国家三级词表按优先级合并，发送前实时校验，命中即拦，Redis 零延迟。', b: '→ 从源头规避运营商罚单与封号' },
  { ic: 'link', t: '短链转换 · 点击可追踪', d: '文案内链接自动替换为短链；专属域名 + 自定义 SSL；点击计数、IP/UA 记录、Bot 识别。', b: '→ 营销短信也能像广告一样看转化' },
  { ic: 'folder', t: '私有库发送 · 私域沉淀', d: '客户专属私有号码库，批量导入统一管理；发送时直接取号，号码资产沉淀在自己手里。', b: '→ 复购客群可反复触达，越用越值钱' },
] : [
  { ic: 'shield', t: 'Banned-word filter', d: 'Global + channel + country word-lists merged by priority, checked pre-send, blocked on hit. Redis-fast.', b: '→ Avoid carrier fines & bans at the source' },
  { ic: 'link', t: 'Short links · trackable', d: 'Auto-rewrite links to short URLs; custom domain + SSL; clicks, IP/UA logs, bot detection.', b: '→ Measure campaigns like ads' },
  { ic: 'folder', t: 'Private number pools', d: 'Per-customer private pools, bulk import & manage; numbers stay your asset.', b: '→ Re-engage buyers, value compounds' },
])

const perfLabels = computed(() => isZh.value
  ? ['TPS 高并发', 'API 响应 P95', '系统可用性', '短信送达率']
  : ['Peak TPS', 'API P95', 'Uptime', 'Delivery rate'])

const techStack = computed(() => isZh.value
  ? ['后端 · Python FastAPI（全异步）', '网关 · Go SMPP（长连接 / 保活 / 重连）', '前端 · Vue 3 + Vite（中英双语）', '队列 · RabbitMQ + Celery（多队列削峰）', '存储 · MySQL 8 + ProxySQL + Redis 7', '部署 · Docker / K8s 全容器化']
  : ['Backend · Python FastAPI (async)', 'Gateway · Go SMPP (keep-alive / reconnect)', 'Frontend · Vue 3 + Vite (bilingual)', 'Queue · RabbitMQ + Celery', 'Storage · MySQL 8 + ProxySQL + Redis 7', 'Deploy · Docker / K8s'])

const security = computed(() => isZh.value
  ? ['JWT + API Key 双鉴权', '全量操作审计 + 配置变更时间线', '敏感配置默认锁定二次确认', '登录与安全日志可追溯可问责']
  : ['JWT + API Key dual auth', 'Full audit + config change timeline', 'Sensitive config locked by default', 'Login & security logs, accountable'])

const delivery = computed(() => isZh.value ? [
  { ic: 'code', t: '完整前后端源码', d: 'FastAPI 后端 + Vue3 前端 + Go SMPP 网关，全部可读、可改、可二次开发。' },
  { ic: 'cpu', t: '全套部署脚本', d: 'Docker Compose / K8s 编排文件，一键拉起，环境一致。' },
  { ic: 'doc', t: '10 万字 · 9 份文档', d: 'PRD / 架构 / 数据字典 / API / 部署 / TG 集成 / 路由计费…… 交接零障碍。' },
] : [
  { ic: 'code', t: 'Full source code', d: 'FastAPI backend + Vue3 frontend + Go SMPP gateway — readable, editable, extensible.' },
  { ic: 'cpu', t: 'Deployment scripts', d: 'Docker Compose / K8s manifests — one command, consistent environments.' },
  { ic: 'doc', t: '9 docs · 100k words', d: 'PRD / architecture / schema / API / deploy / TG / routing & billing — zero-friction handover.' },
])

const audiences = computed(() => isZh.value ? [
  { ic: 'globe', t: '出海互联网企业', d: '全球验证码 / 通知，送达与合规双保障。' },
  { ic: 'cart', t: '跨境电商平台', d: '订单 / 物流 / 大促批量群发，降本增效。' },
  { ic: 'bank', t: '金融科技公司', d: '高可用 + 高送达 + 全审计，满足强合规。' },
  { ic: 'wrench', t: '短信 / 营销集成商', d: '现成通道调度 + 三级计费，加价变现。' },
] : [
  { ic: 'globe', t: 'Global internet firms', d: 'Worldwide OTP / notifications, delivery + compliance.' },
  { ic: 'cart', t: 'Cross-border e-commerce', d: 'Order / logistics / peak campaigns, lower cost.' },
  { ic: 'bank', t: 'Fintech companies', d: 'High availability + delivery + full audit for compliance.' },
  { ic: 'wrench', t: 'SMS / marketing resellers', d: 'Ready routing + three-tier billing, mark up & profit.' },
])

const plans = computed(() => isZh.value ? [
  { name: '源码买断', price: '买断', unit: '核心资产', badge: '最高', desc: '全部源代码 + 部署文档，永久自主、自由二次开发、可协商转售。', feats: ['完整前后端 + 网关源码', '永久自主二次开发', '可协商转售下游'], hot: true },
  { name: '永久授权部署', price: '永久', unit: '使用权', badge: '中', desc: '部署好的运行环境，绑定服务器 / 域名，永久有效。', feats: ['交付即用运行环境', '绑定服务器 / 域名', '永久使用权'], hot: false },
  { name: '1 年授权部署', price: '1 年', unit: '门槛最低', badge: '入门', desc: '部署好的运行环境，授权期内含支持与安全更新，可续费。', feats: ['含支持与安全更新', '授权期内可续费', '入门门槛最低'], hot: false },
] : [
  { name: 'Source buyout', price: 'Buyout', unit: 'core asset', badge: 'Top', desc: 'Full source + deploy docs. Own it forever, extend freely, resell by agreement.', feats: ['Full FE/BE + gateway source', 'Perpetual self-development', 'Resale by agreement'], hot: true },
  { name: 'Perpetual license', price: 'Perpetual', unit: 'license', badge: 'Mid', desc: 'Deployed runtime bound to your server / domain, valid forever.', feats: ['Ready-to-run deployment', 'Bound to server / domain', 'Perpetual usage right'], hot: false },
  { name: '1-year license', price: '1 year', unit: 'entry', badge: 'Entry', desc: 'Deployed runtime with support & security updates during the term, renewable.', feats: ['Support & security updates', 'Renewable term', 'Lowest entry barrier'], hot: false },
])

const testimonials = computed(() => isZh.value ? [
  { q: '从对接到跑通自有通道不到一周，三级计费让我们终于能对下游差异化加价，通道差价稳稳落袋。', n: 'Marco R.', r: '创始人 · 短信集成商' },
  { q: '私有化部署后数据全在自己服务器，合规与定价权拿回手里，再也不看上游脸色。', n: 'Lin Wei', r: '技术负责人 · 出海平台' },
  { q: 'TG Bot 让销售在手机上就能开户、发送、对账，签客户时这一手非常惊艳。', n: '陈晓', r: '运营总监 · 跨境电商' },
] : [
  { q: 'Live on our own routes in under a week. Three-tier billing finally lets us mark up downstream — spread secured.', n: 'Marco R.', r: 'Founder · SMS reseller' },
  { q: 'Self-hosted means data stays on our servers — compliance and pricing power back in our hands.', n: 'Lin Wei', r: 'Tech Lead · Global platform' },
  { q: 'The TG bot lets sales open accounts, send and reconcile from a phone — a stunning closer.', n: 'Chen Xiao', r: 'Ops Director · Cross-border' },
])

const ctaActions = computed(() => isZh.value ? [
  { ic: 'phone', t: '预约 30 分钟演示', d: '看智能路由与 TG Bot 实跑' },
  { ic: 'doc', t: '索取文档与报价', d: '完整技术文档 + 购买方案' },
  { ic: 'rocket', t: '申请试部署', d: '用你自己的上游跑真实流量' },
] : [
  { ic: 'phone', t: 'Book a 30-min demo', d: 'See routing & the TG bot live' },
  { ic: 'doc', t: 'Request docs & quote', d: 'Full tech docs + plans' },
  { ic: 'rocket', t: 'Apply for a trial deploy', d: 'Run real traffic on your upstream' },
])

const faqs = computed(() => isZh.value ? [
  { q: '可以私有化部署吗？', a: '可以。系统全容器化，提供 Docker Compose 与 K8s 编排，部署在你自己的服务器，数据与定价权 100% 在你手里。' },
  { q: '是源码级交付吗？', a: '是。源码买断方案提供 FastAPI 后端、Vue3 前端与 Go SMPP 网关全部源码，可读、可改、可二次开发。' },
  { q: '支持哪些上游对接？', a: '支持 SMPP 协议上游通道接入，多供应商多通道并存，按成本与覆盖由智能路由统一调度。' },
  { q: '计费颗粒度有多细？', a: '通道 × 国家 × 运营商三维定价，长短信自动拆分，多币种结算，主子账户分权分额。' },
  { q: '全球合规怎么解决？', a: 'Sender ID 4 级优先级智能匹配，适配美国字母 SID、印度 DLT 等各国合规政策。' },
  { q: '交付后能独立维护吗？', a: '能。随交付提供 10 万字 9 份文档（架构 / 数据字典 / API / 部署 / 路由计费等），团队零障碍接手。' },
] : [
  { q: 'Can it be self-hosted?', a: 'Yes. Fully containerized with Docker Compose and K8s manifests — deploy on your own servers; data & pricing power stay 100% yours.' },
  { q: 'Is it source-code delivery?', a: 'Yes. The buyout plan ships the full FastAPI backend, Vue3 frontend and Go SMPP gateway source — readable, editable, extensible.' },
  { q: 'Which upstreams are supported?', a: 'SMPP upstream binding, multiple suppliers/routes coexisting, unified by smart routing on cost & coverage.' },
  { q: 'How granular is billing?', a: 'Channel × country × carrier 3D pricing, auto long-SMS segmentation, multi-currency, master/sub-account quotas.' },
  { q: 'How is global compliance handled?', a: '4-level Sender ID matching, adapting to US alphabetic SID, India DLT and per-country policies.' },
  { q: 'Can we maintain it ourselves?', a: 'Yes — delivery includes 9 docs / 100k words (architecture, schema, API, deploy, routing & billing) for zero-friction handover.' },
])

const zh = {
  eyebrow: '可私有化部署 · 源码级交付 · SMSC',
  heroLead: '把"发全球短信"，',
  heroMid: '变成你自己的',
  heroDesc: '一套可私有化部署的企业级国际短信网关——把上游通道接进来，按客户 / 价格 / 国家智能分发，客户自助充值发送，平台全程计费、回执、风控、对账，一切都在你自己的服务器里。',
  ctaPrimary: '预约演示',
  ctaSecondary: '登录控制台',
  trusted: '把通信基础设施，彻底变成你自己的资产',
  problemEyebrow: 'THE PROBLEM',
  problemTitle: '出海通信，你正在为看不见的损耗买单',
  problemDesc: '短信是全球触达成本最低、覆盖最广的通道——但"发短信"这件小事，藏着四个让人血压飙升的坑。',
  problemFoot: '本质不是"短信"，而是你没有一套真正属于自己的、透明可控的通信基础设施。',
  solEyebrow: 'THE SOLUTION',
  solTitle: '把通信能力，变成你自己的资产',
  solDesc: 'sms1.site SMSC 不是又一个"短信 API 中间商"——而是一套可完整私有化部署、源码级交付的企业级国际短信网关。',
  solQuote: '你买到的不是"用量"，而是一整条护城河：定价权、数据权、合规掌控权、二次开发权，全部回到自己手中。',
  killersEyebrow: 'CORE CAPABILITIES',
  killersTitle: '四大核心杀手锏',
  killersDesc: '智能路由 · 三级计费 · 全球合规 Sender ID · 业内首创 Telegram 深度集成',
  sigEyebrow: 'SIGNATURE FEATURES',
  sigTitle: '不止于"能发"——把合规、转化、私域一并交付',
  sigDesc: '通用网关只解决"把短信发出去"，这里把出海运营真正头疼的环节做成了开箱即用的内建能力。',
  techEyebrow: 'ENGINEERING & PERFORMANCE',
  techTitle: '硬核技术与性能保障 —— 用数据说话',
  techStackTitle: '现代化技术栈',
  techSecTitle: '为什么扛得住 & 安全内建',
  techNote: '* 性能指标为系统架构设计目标，实际表现受上游通道质量、网络环境与部署规格影响。',
  delEyebrow: 'ASSET-GRADE DELIVERY',
  delTitle: '资产级交付清单 —— 零障碍接手',
  delDesc: '很多"系统"卖的是黑盒，出问题只能求原厂。这里交付的，是一份能让你团队独立掌控的完整技术资产。',
  delQuote: '你不再被任何供应商绑架。团队能看懂、能改、能扩展——无论自用还是转售下游，主动权 100% 在你手里。',
  audEyebrow: 'WHO IT\'S FOR',
  audTitle: '谁最该拥有它',
  plansEyebrow: 'HOW TO BUY',
  plansTitle: '三种购买方案',
  plansDesc: '从一年授权到源码买断，按你的掌控深度自由选择。',
  choose: '索取报价',
  tstTitle: '他们已经把通信变成了资产',
  faqTitle: '常见问题',
  ctaTitle: '让我们用一场演示，证明给你看',
  ctaDesc: '通信基础设施的主动权，越早拿回越值钱。每多依赖一天第三方黑盒，你就多付一天看不见的损耗。',
  ctaContact: 'Telegram 在线咨询',
  login: '登录',
  getStarted: '预约演示',
  contact: '联系我们',
  footTagline: '企业级国际短信网关系统 —— 把全球通信能力，变成你自己的核心资产。',
  colProduct: '能力', colRes: '资源', colCompany: '方案', rights2: '保留所有权利。',
}
const en = {
  eyebrow: 'Self-hosted · Source-code · SMSC',
  heroLead: 'Turn “global SMS”',
  heroMid: 'into your own',
  heroDesc: 'A self-hostable enterprise SMS gateway: plug in upstream routes, dispatch by customer / price / country, let customers top up and send, while the platform handles billing, receipts, risk and reconciliation — all on your own servers.',
  ctaPrimary: 'Book a demo',
  ctaSecondary: 'Console login',
  trusted: 'Turn communication infrastructure into an asset you own',
  problemEyebrow: 'THE PROBLEM',
  problemTitle: 'Going global, you pay for losses you can\'t see',
  problemDesc: 'SMS is the cheapest, widest reach channel — yet "just send a text" hides four blood-pressure-raising traps.',
  problemFoot: 'The real issue isn\'t "SMS" — it\'s that you don\'t own a transparent, controllable communication stack.',
  solEyebrow: 'THE SOLUTION',
  solTitle: 'Turn communication into an asset you own',
  solDesc: 'sms1.site SMSC isn\'t another "SMS API middleman" — it\'s a fully self-hostable, source-code-delivered enterprise SMS gateway.',
  solQuote: 'You don\'t buy "usage" — you buy a moat: pricing power, data ownership, compliance control and dev freedom, all back in your hands.',
  killersEyebrow: 'CORE CAPABILITIES',
  killersTitle: 'Four core killer features',
  killersDesc: 'Smart routing · Three-tier billing · Global Sender ID · Industry-first deep Telegram integration',
  sigEyebrow: 'SIGNATURE FEATURES',
  sigTitle: 'Beyond "it sends" — compliance, conversion & private pools built in',
  sigDesc: 'Generic gateways only "send the text". Here, the parts that actually hurt are built-in and ready to use.',
  techEyebrow: 'ENGINEERING & PERFORMANCE',
  techTitle: 'Hardcore engineering — proven by numbers',
  techStackTitle: 'Modern tech stack',
  techSecTitle: 'Why it holds up & security built-in',
  techNote: '* Figures are architectural design targets; actual results depend on upstream quality, network and deployment specs.',
  delEyebrow: 'ASSET-GRADE DELIVERY',
  delTitle: 'Asset-grade delivery — take over with zero friction',
  delDesc: 'Many "systems" sell a black box. Here you get a complete technical asset your team can fully control.',
  delQuote: 'No vendor lock-in. Your team can read, change and extend it — for your own use or resale, control is 100% yours.',
  audEyebrow: 'WHO IT\'S FOR',
  audTitle: 'Who should own it',
  plansEyebrow: 'HOW TO BUY',
  plansTitle: 'Three ways to buy',
  plansDesc: 'From a 1-year license to a full source buyout — choose your depth of control.',
  choose: 'Request a quote',
  tstTitle: 'They already turned comms into an asset',
  faqTitle: 'Frequently asked questions',
  ctaTitle: 'Let a live demo prove it to you',
  ctaDesc: 'The sooner you take back control of your comms stack, the more it\'s worth. Every day on a third-party black box is a day of hidden loss.',
  ctaContact: 'Chat on Telegram',
  login: 'Login',
  getStarted: 'Book a demo',
  contact: 'Contact us',
  footTagline: 'Enterprise SMS gateway — turn global communication into your own core asset.',
  colProduct: 'Capabilities', colRes: 'Resources', colCompany: 'Plans', rights2: 'All rights reserved.',
}

const year = new Date().getFullYear()
</script>

<template>
  <div class="lp" :class="{ light: theme === 'light' }">
    <div class="lp-bg" aria-hidden="true">
      <div class="glow glow-a"></div>
      <div class="glow glow-b"></div>
      <div class="glow glow-c"></div>
      <div class="grid-mesh"></div>
      <div class="noise"></div>
    </div>

    <div class="scroll-prog" :style="{ transform: `scaleX(${progress})` }" aria-hidden="true"></div>

    <!-- 导航 -->
    <header class="hd" :class="{ scrolled }">
      <div class="wrap hd-in">
        <a class="brand" href="#" @click.prevent="scrollTo('top')">
          <span class="brand-mark"><i></i><i></i><i></i></span>
          <span class="brand-name">SMS<b>1</b></span><span class="brand-dot">.site</span>
        </a>
        <nav class="hd-nav" :class="{ open: mobileMenu }">
          <a v-for="l in navLinks" :key="l.id" @click="scrollTo(l.id)">{{ l.label }}</a>
          <div class="hd-mob-actions">
            <button class="btn-ghost" @click="toggleTheme">{{ theme === 'dark' ? '☀ 浅色' : '☾ 深色' }}</button>
            <button class="btn-ghost" @click="toggleLang">{{ isZh ? 'EN' : '中文' }}</button>
            <button class="btn-line" @click="toLogin">{{ t.login }}</button>
            <button class="btn-neon" @click="toContact">{{ t.getStarted }}</button>
          </div>
        </nav>
        <div class="hd-actions">
          <button class="lang ico" @click="toggleTheme" :aria-label="theme === 'dark' ? 'Light mode' : 'Dark mode'">
            <svg v-if="theme === 'dark'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="4.2"/><path d="M12 2v2.5M12 19.5V22M4.2 4.2l1.8 1.8M18 18l1.8 1.8M2 12h2.5M19.5 12H22M4.2 19.8l1.8-1.8M18 6l1.8-1.8"/></svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 12.8A8.5 8.5 0 1 1 11.2 3a6.5 6.5 0 0 0 9.8 9.8z"/></svg>
          </button>
          <button class="lang" @click="toggleLang">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>
            <span>{{ isZh ? 'EN' : '中文' }}</span>
          </button>
          <button class="btn-line" @click="toLogin">{{ t.login }}</button>
          <button class="btn-neon" @click="toContact">{{ t.getStarted }}</button>
        </div>
        <button class="burger" :class="{ on: mobileMenu }" @click="mobileMenu = !mobileMenu" aria-label="menu"><i></i><i></i><i></i></button>
      </div>
    </header>

    <main id="top">
      <!-- HERO -->
      <section class="hero wrap">
        <div class="hero-l">
          <div class="eyebrow"><span class="dot"></span>{{ t.eyebrow }}</div>
          <h1 class="hero-title">
            {{ t.heroLead }}<br />{{ t.heroMid }}
            <span class="rot" :key="rotIdx">{{ rotWords[rotIdx] }}</span>
          </h1>
          <p class="hero-desc">{{ t.heroDesc }}</p>
          <div class="tag-row">
            <span v-for="tg in heroTags" :key="tg" class="tag">{{ tg }}</span>
          </div>
          <div class="hero-cta">
            <button class="btn-neon lg" @click="toContact">
              {{ t.ctaPrimary }}
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
            </button>
            <button class="btn-line lg" @click="toLogin">{{ t.ctaSecondary }}</button>
          </div>
          <div class="hero-stats">
            <div v-for="s in heroStats" :key="s.l" class="hs">
              <div class="hs-n">{{ s.n }}</div><div class="hs-l">{{ s.l }}</div>
            </div>
          </div>
        </div>
        <div class="hero-r" aria-hidden="true">
          <div class="orb">
            <div class="orb-core">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20M4.5 6.5h15M4.5 17.5h15"/></svg>
            </div>
            <div class="ring r1"></div><div class="ring r2"></div><div class="ring r3"></div>
            <span class="sat s1"></span><span class="sat s2"></span><span class="sat s3"></span>
            <div class="bubble b1">SMPP · bound</div>
            <div class="bubble b2">route · cost-first</div>
            <div class="bubble b3">DLR · delivered</div>
          </div>
        </div>
      </section>

      <!-- 国家滚动条 -->
      <section class="marquee" data-reveal aria-hidden="true">
        <div class="marquee-fade l"></div><div class="marquee-fade r"></div>
        <div class="marquee-track">
          <span v-for="(c, i) in marqueeList" :key="i" class="m-chip">
            <span class="m-flag">{{ c[0] }}</span><span class="m-code">{{ c[1] }}</span><span class="m-name">{{ c[2] }}</span>
          </span>
        </div>
      </section>

      <!-- THE PROBLEM -->
      <section id="problem" class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.problemEyebrow }}</div>
          <h2 class="sec-title">{{ t.problemTitle }}</h2>
          <p class="sec-desc">{{ t.problemDesc }}</p>
        </div>
        <div class="svc-grid g2">
          <article v-for="p in problems" :key="p.t" class="svc prob">
            <div class="svc-ico bad"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path :d="ICONS[p.ic]"/></svg></div>
            <h3 class="svc-title">{{ p.t }}</h3>
            <p class="svc-desc">{{ p.d }}</p>
          </article>
        </div>
        <p class="sec-foot">{{ t.problemFoot }}</p>
      </section>

      <!-- THE SOLUTION -->
      <section class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.solEyebrow }}</div>
          <h2 class="sec-title">{{ t.solTitle }}</h2>
          <p class="sec-desc">{{ t.solDesc }}</p>
        </div>
        <div class="quote-box">{{ t.solQuote }}</div>
        <div class="rights">
          <span v-for="r in rights" :key="r.t" class="right-chip">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path :d="ICONS[r.ic]"/></svg>{{ r.t }}
          </span>
        </div>
      </section>

      <!-- 四大杀手锏 -->
      <section id="killers" class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.killersEyebrow }}</div>
          <h2 class="sec-title">{{ t.killersTitle }}</h2>
          <p class="sec-desc">{{ t.killersDesc }}</p>
        </div>
        <div class="killer-grid">
          <article v-for="k in killers" :key="k.title" class="killer">
            <div class="killer-top">
              <div class="killer-ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path :d="ICONS[k.ic]"/></svg></div>
              <span class="killer-tag">{{ k.tag }}</span>
            </div>
            <h3 class="killer-title">{{ k.title }}</h3>
            <p class="killer-desc">{{ k.desc }}</p>
            <ul class="killer-pts">
              <li v-for="pt in k.pts" :key="pt"><i></i>{{ pt }}</li>
            </ul>
          </article>
        </div>
      </section>

      <!-- 签名能力 -->
      <section class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.sigEyebrow }}</div>
          <h2 class="sec-title">{{ t.sigTitle }}</h2>
          <p class="sec-desc">{{ t.sigDesc }}</p>
        </div>
        <div class="svc-grid">
          <article v-for="s in signature" :key="s.t" class="svc">
            <div class="svc-ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path :d="ICONS[s.ic]"/></svg></div>
            <h3 class="svc-title">{{ s.t }}</h3>
            <p class="svc-desc">{{ s.d }}</p>
            <p class="svc-benefit">{{ s.b }}</p>
          </article>
        </div>
      </section>

      <!-- 技术与性能 -->
      <section id="tech" class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.techEyebrow }}</div>
          <h2 class="sec-title">{{ t.techTitle }}</h2>
        </div>
        <div class="perf-grid" data-reveal data-countup>
          <div v-for="(lab, i) in perfLabels" :key="lab" class="perf">
            <div class="perf-n">{{ bandDisp[i] }}</div><div class="perf-l">{{ lab }}</div>
          </div>
        </div>
        <div class="tech-grid">
          <div class="tech-panel">
            <h4><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path :d="ICONS.layers"/></svg>{{ t.techStackTitle }}</h4>
            <ul><li v-for="x in techStack" :key="x">{{ x }}</li></ul>
          </div>
          <div class="tech-panel">
            <h4><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path :d="ICONS.lock"/></svg>{{ t.techSecTitle }}</h4>
            <ul><li v-for="x in security" :key="x">{{ x }}</li></ul>
          </div>
        </div>
        <p class="sec-note">{{ t.techNote }}</p>
      </section>

      <!-- 资产级交付 -->
      <section id="delivery" class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.delEyebrow }}</div>
          <h2 class="sec-title">{{ t.delTitle }}</h2>
          <p class="sec-desc">{{ t.delDesc }}</p>
        </div>
        <div class="svc-grid">
          <article v-for="d in delivery" :key="d.t" class="svc">
            <div class="svc-ico amber"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path :d="ICONS[d.ic]"/></svg></div>
            <h3 class="svc-title">{{ d.t }}</h3>
            <p class="svc-desc">{{ d.d }}</p>
          </article>
        </div>
        <div class="quote-box">{{ t.delQuote }}</div>
      </section>

      <!-- 适用对象 -->
      <section class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.audEyebrow }}</div>
          <h2 class="sec-title">{{ t.audTitle }}</h2>
        </div>
        <div class="svc-grid g4">
          <article v-for="a in audiences" :key="a.t" class="svc aud">
            <div class="svc-ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path :d="ICONS[a.ic]"/></svg></div>
            <h3 class="svc-title sm">{{ a.t }}</h3>
            <p class="svc-desc">{{ a.d }}</p>
          </article>
        </div>
      </section>

      <!-- 购买方案 -->
      <section id="plans" class="sec wrap" data-reveal>
        <div class="sec-head">
          <div class="eyebrow c"><span class="dot"></span>{{ t.plansEyebrow }}</div>
          <h2 class="sec-title">{{ t.plansTitle }}</h2>
          <p class="sec-desc">{{ t.plansDesc }}</p>
        </div>
        <div class="plan-grid">
          <article v-for="p in plans" :key="p.name" class="plan" :class="{ hot: p.hot }">
            <span class="plan-badge" :class="{ ghost: !p.hot }">{{ p.badge }}</span>
            <h3 class="plan-name">{{ p.name }}</h3>
            <div class="plan-price">{{ p.price }}<small>{{ p.unit }}</small></div>
            <p class="plan-desc">{{ p.desc }}</p>
            <ul class="plan-feats">
              <li v-for="f in p.feats" :key="f"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M5 12.5l4 4 10-10"/></svg>{{ f }}</li>
            </ul>
            <button :class="p.hot ? 'btn-neon' : 'btn-line'" @click="toContact">{{ t.choose }}</button>
          </article>
        </div>
      </section>

      <!-- 评价 -->
      <section class="sec wrap" data-reveal>
        <div class="sec-head"><h2 class="sec-title center">{{ t.tstTitle }}</h2></div>
        <div class="tst-grid">
          <figure v-for="(tm, i) in testimonials" :key="i" class="tst">
            <div class="tst-stars">★★★★★</div>
            <blockquote>{{ tm.q }}</blockquote>
            <figcaption><span class="tst-av">{{ tm.n.charAt(0) }}</span><span class="tst-meta"><b>{{ tm.n }}</b><small>{{ tm.r }}</small></span></figcaption>
          </figure>
        </div>
      </section>

      <!-- FAQ -->
      <section id="faq" class="sec wrap narrow" data-reveal>
        <h2 class="sec-title center">{{ t.faqTitle }}</h2>
        <div class="faq-list">
          <div v-for="(f, i) in faqs" :key="i" class="faq" :class="{ open: openFaq === i }">
            <button class="faq-q" @click="openFaq = openFaq === i ? -1 : i"><span>{{ f.q }}</span><i class="faq-pm"></i></button>
            <div class="faq-a"><p>{{ f.a }}</p></div>
          </div>
        </div>
      </section>

      <!-- 结尾 CTA -->
      <section class="cta-band wrap" data-reveal>
        <div class="cta-inner">
          <div class="cta-glow"></div>
          <h2>{{ t.ctaTitle }}</h2>
          <p>{{ t.ctaDesc }}</p>
          <div class="cta-actions">
            <button v-for="a in ctaActions" :key="a.t" class="cta-act" @click="toContact">
              <div class="cta-act-ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path :d="ICONS[a.ic]"/></svg></div>
              <div class="cta-act-txt"><b>{{ a.t }}</b><small>{{ a.d }}</small></div>
            </button>
          </div>
          <div class="cta-btns">
            <button class="btn-neon lg" @click="toContact">{{ t.ctaContact }}</button>
            <button class="btn-line lg" @click="toLogin">{{ t.ctaSecondary }}</button>
          </div>
        </div>
      </section>
    </main>

    <!-- 页脚 -->
    <footer class="ft">
      <div class="wrap ft-in">
        <div class="ft-brand">
          <a class="brand"><span class="brand-mark"><i></i><i></i><i></i></span><span class="brand-name">SMS<b>1</b></span><span class="brand-dot">.site</span></a>
          <p>{{ t.footTagline }}</p>
          <div class="tag-row sm"><span class="tag">SMPP</span><span class="tag">FastAPI</span><span class="tag">Go</span><span class="tag">Vue3</span><span class="tag">Docker / K8s</span></div>
        </div>
        <div class="ft-cols">
          <div class="ft-col">
            <h5>{{ t.colProduct }}</h5>
            <a @click="scrollTo('killers')">{{ isZh ? '智能路由' : 'Routing' }}</a>
            <a @click="scrollTo('killers')">{{ isZh ? '三级计费' : 'Billing' }}</a>
            <a @click="scrollTo('killers')">Sender ID</a>
            <a @click="scrollTo('killers')">Telegram Bot</a>
          </div>
          <div class="ft-col">
            <h5>{{ t.colRes }}</h5>
            <a @click="scrollTo('tech')">{{ isZh ? '技术架构' : 'Architecture' }}</a>
            <a @click="scrollTo('delivery')">{{ isZh ? '交付清单' : 'Delivery' }}</a>
            <a @click="scrollTo('faq')">{{ isZh ? '常见问题' : 'FAQ' }}</a>
          </div>
          <div class="ft-col">
            <h5>{{ t.colCompany }}</h5>
            <a @click="scrollTo('plans')">{{ isZh ? '购买方案' : 'Plans' }}</a>
            <a :href="CONTACT_URL" target="_blank" rel="noopener">{{ t.contact }}</a>
            <a @click="toLogin">{{ t.login }}</a>
          </div>
        </div>
      </div>
      <div class="wrap ft-bottom">
        <span>© {{ year }} sms1.site · {{ t.rights2 }}</span>
        <button class="lang" @click="toggleLang"><span>{{ isZh ? 'English' : '中文' }}</span></button>
      </div>
    </footer>
  </div>
</template>

<style scoped>
.lp{
  --bg:#070b16; --bg2:#0a1124; --panel:rgba(255,255,255,.035);
  --line:rgba(255,255,255,.09); --line2:rgba(255,255,255,.14);
  --txt:#eaf0ff; --mut:#9aa6c4; --mut2:#6b769a;
  --neon:#00ffd5; --neon2:#1fd1e8; --amber:#fdb52a; --coral:#fa5b68; --blue:#3b82f6;
  --r:18px;
  position:relative; min-height:100vh; background:var(--bg); color:var(--txt);
  font-family:'Plus Jakarta Sans','Inter',-apple-system,BlinkMacSystemFont,'Segoe UI','PingFang SC','Microsoft YaHei',sans-serif;
  overflow-x:hidden; -webkit-font-smoothing:antialiased;
}
.wrap{ width:min(1180px,92vw); margin-inline:auto; }
.lp-bg{ position:fixed; inset:0; z-index:0; pointer-events:none; }
.glow{ position:absolute; border-radius:50%; filter:blur(110px); }
.glow-a{ width:560px; height:560px; top:-160px; left:-120px; background:radial-gradient(circle,#00ffd5,transparent 70%); opacity:.30; }
.glow-b{ width:620px; height:620px; top:240px; right:-180px; background:radial-gradient(circle,#3b82f6,transparent 70%); opacity:.26; }
.glow-c{ width:520px; height:520px; bottom:-160px; left:30%; background:radial-gradient(circle,#fa5b68,transparent 70%); opacity:.14; }
.grid-mesh{ position:absolute; inset:0;
  background-image:linear-gradient(rgba(255,255,255,.045) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.045) 1px,transparent 1px);
  background-size:54px 54px; -webkit-mask-image:radial-gradient(ellipse 80% 60% at 50% 0%,#000 30%,transparent 75%); mask-image:radial-gradient(ellipse 80% 60% at 50% 0%,#000 30%,transparent 75%); }
.noise{ position:absolute; inset:0; opacity:.04; mix-blend-mode:overlay;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='3'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E"); }
main,.hd,.ft{ position:relative; z-index:1; }

/* 按钮 */
.btn-neon,.btn-line,.btn-ghost{ font:inherit; font-weight:700; cursor:pointer; border:none; border-radius:999px; display:inline-flex; align-items:center; gap:.5em; transition:.25s cubic-bezier(.2,.7,.3,1); white-space:nowrap; }
.btn-neon{ padding:.66em 1.3em; color:#04201c; background:linear-gradient(135deg,var(--neon),var(--neon2)); box-shadow:0 8px 26px -8px rgba(0,255,213,.6), inset 0 0 0 1px rgba(255,255,255,.25); }
.btn-neon:hover{ transform:translateY(-2px); box-shadow:0 14px 34px -8px rgba(0,255,213,.75); }
.btn-neon svg{ width:1.05em; height:1.05em; }
.btn-line{ padding:.62em 1.25em; color:var(--txt); background:rgba(255,255,255,.04); border:1px solid var(--line2); }
.btn-line:hover{ border-color:var(--neon); color:var(--neon); box-shadow:0 0 0 3px rgba(0,255,213,.08); }
.btn-ghost{ padding:.5em 1em; color:var(--mut); background:transparent; }
.lg{ padding:.92em 1.7em; font-size:1.02rem; }

/* 滚动进度 */
.scroll-prog{ position:fixed; top:0; left:0; right:0; height:3px; z-index:60; transform-origin:0 50%; transform:scaleX(0); background:linear-gradient(90deg,var(--neon),var(--blue),var(--coral)); box-shadow:0 0 12px rgba(0,255,213,.6); transition:transform .1s linear; }
section[id]{ scroll-margin-top:88px; }

/* 导航 */
.hd{ position:sticky; top:0; z-index:50; transition:.3s; }
.hd.scrolled{ background:rgba(8,12,24,.78); backdrop-filter:blur(16px) saturate(140%); border-bottom:1px solid var(--line); }
.hd-in{ display:flex; align-items:center; gap:1.4rem; height:72px; }
.brand{ display:inline-flex; align-items:center; gap:.55rem; font-weight:800; letter-spacing:-.02em; cursor:pointer; text-decoration:none; color:var(--txt); }
.brand-mark{ display:inline-flex; gap:3px; align-items:flex-end; height:22px; }
.brand-mark i{ width:4px; border-radius:2px; background:linear-gradient(var(--neon),var(--neon2)); box-shadow:0 0 10px rgba(0,255,213,.7); }
.brand-mark i:nth-child(1){ height:11px; } .brand-mark i:nth-child(2){ height:22px; } .brand-mark i:nth-child(3){ height:15px; animation:eq 1.4s ease-in-out infinite; }
@keyframes eq{ 50%{ height:9px; } }
.brand-name{ font-size:1.3rem; } .brand-name b{ color:var(--neon); }
.brand-dot{ color:var(--mut2); font-weight:600; font-size:.95rem; margin-left:-.3rem; }
.hd-nav{ display:flex; align-items:center; gap:1.4rem; margin-left:1rem; }
.hd-nav>a{ color:var(--mut); font-weight:600; font-size:.92rem; cursor:pointer; transition:.2s; }
.hd-nav>a:hover{ color:var(--txt); }
.hd-actions{ margin-left:auto; display:flex; align-items:center; gap:.7rem; }
.lang{ display:inline-flex; align-items:center; gap:.35rem; background:transparent; border:1px solid var(--line2); color:var(--mut); padding:.42em .7em; border-radius:999px; font:inherit; font-size:.85rem; font-weight:600; cursor:pointer; transition:.2s; }
.lang:hover{ color:var(--txt); border-color:var(--neon); }
.lang.ico{ padding:.42em; }
.lang.ico svg{ width:16px; height:16px; }
.lang svg{ width:15px; height:15px; }
.hd-mob-actions{ display:none; }
.burger{ display:none; margin-left:auto; width:40px; height:40px; border:1px solid var(--line2); border-radius:11px; background:transparent; flex-direction:column; gap:4px; align-items:center; justify-content:center; cursor:pointer; }
.burger i{ width:18px; height:2px; background:var(--txt); border-radius:2px; transition:.25s; }
.burger.on i:nth-child(1){ transform:translateY(6px) rotate(45deg); }
.burger.on i:nth-child(2){ opacity:0; }
.burger.on i:nth-child(3){ transform:translateY(-6px) rotate(-45deg); }

/* HERO */
.hero{ display:grid; grid-template-columns:1.08fr .92fr; gap:2.5rem; align-items:center; padding:3.8rem 0 2.6rem; }
.eyebrow{ display:inline-flex; align-items:center; gap:.5rem; font-size:.8rem; font-weight:700; letter-spacing:.04em; text-transform:uppercase; color:var(--neon); background:rgba(0,255,213,.07); border:1px solid rgba(0,255,213,.2); padding:.4em .85em; border-radius:999px; }
.eyebrow .dot{ width:6px; height:6px; border-radius:50%; background:var(--neon); box-shadow:0 0 8px var(--neon); animation:pulse 1.8s infinite; }
@keyframes pulse{ 50%{ opacity:.35; } }
.hero-title{ font-size:clamp(2.3rem,5vw,3.7rem); line-height:1.1; font-weight:800; letter-spacing:-.03em; margin:1.1rem 0 0; }
.rot{ display:inline-block; background:linear-gradient(105deg,var(--neon),var(--neon2) 40%,var(--blue)); -webkit-background-clip:text; background-clip:text; color:transparent; animation:rotin .5s cubic-bezier(.2,.8,.2,1); }
@keyframes rotin{ from{ opacity:0; transform:translateY(12px); } to{ opacity:1; transform:none; } }
.hero-desc{ margin:1.3rem 0 0; color:var(--mut); font-size:1.04rem; line-height:1.7; max-width:34em; }
.tag-row{ display:flex; flex-wrap:wrap; gap:.5rem; margin-top:1.4rem; }
.tag{ font-size:.78rem; font-weight:700; color:var(--mut); padding:.4em .8em; border:1px solid var(--line2); border-radius:8px; background:rgba(255,255,255,.025); }
.tag-row.sm .tag{ font-size:.72rem; }
.hero-cta{ display:flex; gap:.9rem; margin-top:1.8rem; flex-wrap:wrap; }
.hero-stats{ display:grid; grid-template-columns:repeat(4,auto); gap:2rem; margin-top:2.4rem; }
.hs-n{ font-size:1.6rem; font-weight:800; letter-spacing:-.02em; background:linear-gradient(var(--txt),var(--mut)); -webkit-background-clip:text; background-clip:text; color:transparent; }
.hs-l{ font-size:.8rem; color:var(--mut2); margin-top:.15rem; }
.hero-r{ display:flex; justify-content:center; }
.orb{ position:relative; width:min(400px,80vw); aspect-ratio:1; display:grid; place-items:center; }
.orb-core{ width:38%; aspect-ratio:1; border-radius:50%; display:grid; place-items:center; color:var(--neon); background:radial-gradient(circle at 35% 30%,rgba(0,255,213,.32),rgba(10,17,36,.7)); box-shadow:0 0 60px -6px rgba(0,255,213,.55), inset 0 0 30px rgba(0,255,213,.25); border:1px solid rgba(0,255,213,.4); }
.orb-core svg{ width:54%; height:54%; opacity:.9; }
.ring{ position:absolute; inset:0; margin:auto; border-radius:50%; border:1px solid var(--line2); }
.ring.r1{ width:55%; height:55%; border-color:rgba(0,255,213,.35); animation:spin 14s linear infinite; }
.ring.r2{ width:78%; height:78%; border-color:rgba(59,130,246,.3); border-style:dashed; animation:spin 26s linear infinite reverse; }
.ring.r3{ width:100%; height:100%; border-color:rgba(255,255,255,.08); }
@keyframes spin{ to{ transform:rotate(360deg); } }
.sat{ position:absolute; width:11px; height:11px; border-radius:50%; top:50%; left:50%; }
.sat.s1{ background:var(--neon); box-shadow:0 0 12px var(--neon); animation:orbit1 14s linear infinite; }
.sat.s2{ background:var(--amber); box-shadow:0 0 12px var(--amber); animation:orbit2 26s linear infinite; }
.sat.s3{ background:var(--coral); box-shadow:0 0 12px var(--coral); animation:orbit3 20s linear infinite; }
@keyframes orbit1{ from{ transform:rotate(0) translateX(110px) rotate(0); } to{ transform:rotate(360deg) translateX(110px) rotate(-360deg); } }
@keyframes orbit2{ from{ transform:rotate(0) translateX(155px) rotate(0); } to{ transform:rotate(-360deg) translateX(155px) rotate(360deg); } }
@keyframes orbit3{ from{ transform:rotate(120deg) translateX(134px) rotate(0); } to{ transform:rotate(480deg) translateX(134px) rotate(-360deg); } }
.bubble{ position:absolute; font-size:.74rem; font-weight:700; padding:.42em .7em; border-radius:10px; white-space:nowrap; background:rgba(10,17,36,.85); border:1px solid var(--line2); backdrop-filter:blur(6px); box-shadow:0 8px 22px -10px rgba(0,0,0,.7); }
.bubble.b1{ top:8%; left:-6%; color:var(--neon); border-color:rgba(0,255,213,.4); animation:flo 5s ease-in-out infinite; }
.bubble.b2{ bottom:16%; left:-9%; color:var(--amber); border-color:rgba(253,181,42,.4); animation:flo 6s ease-in-out infinite .8s; }
.bubble.b3{ bottom:5%; right:-3%; color:#cfe0ff; animation:flo 5.5s ease-in-out infinite .4s; }
@keyframes flo{ 50%{ transform:translateY(-9px); } }

/* 国家滚动条 */
.marquee{ position:relative; margin:2rem 0 .5rem; padding:.2rem 0; overflow:hidden; }
.marquee-fade{ position:absolute; top:0; bottom:0; width:90px; z-index:2; pointer-events:none; }
.marquee-fade.l{ left:0; background:linear-gradient(90deg,var(--bg),transparent); }
.marquee-fade.r{ right:0; background:linear-gradient(270deg,var(--bg),transparent); }
.marquee-track{ display:flex; gap:.7rem; width:max-content; animation:scrollx 48s linear infinite; }
.marquee:hover .marquee-track{ animation-play-state:paused; }
@keyframes scrollx{ to{ transform:translateX(-50%); } }
.m-chip{ display:inline-flex; align-items:center; gap:.5rem; padding:.5rem .9rem; border:1px solid var(--line); border-radius:999px; background:rgba(255,255,255,.025); white-space:nowrap; font-size:.86rem; }
.m-flag{ font-size:1.05rem; line-height:1; }
.m-code{ color:var(--neon); font-weight:700; }
.m-name{ color:var(--mut); font-weight:600; }

/* section 通用 */
.sec{ padding:4.6rem 0; }
.sec.narrow{ width:min(820px,92vw); }
.sec-head{ text-align:center; max-width:44rem; margin:0 auto 2.8rem; display:flex; flex-direction:column; align-items:center; gap:.9rem; }
.sec-title{ font-size:clamp(1.7rem,3.3vw,2.45rem); font-weight:800; letter-spacing:-.025em; line-height:1.16; }
.sec-title.center{ text-align:center; margin-bottom:2.2rem; }
.sec-desc{ color:var(--mut); font-size:1.02rem; line-height:1.6; }
.sec-foot{ text-align:center; margin-top:2.2rem; color:var(--mut); font-size:1.02rem; }
.sec-note{ text-align:center; margin-top:1.6rem; color:var(--mut2); font-size:.8rem; }
[data-reveal]{ opacity:0; transform:translateY(26px); transition:opacity .7s ease, transform .7s cubic-bezier(.2,.7,.3,1); }
[data-reveal].in{ opacity:1; transform:none; }

/* 卡片 svc */
.svc-grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:1.1rem; }
.svc-grid.g2{ grid-template-columns:repeat(2,1fr); }
.svc-grid.g4{ grid-template-columns:repeat(4,1fr); }
.svc{ position:relative; padding:1.7rem 1.5rem; border:1px solid var(--line); border-radius:var(--r); overflow:hidden; background:linear-gradient(160deg,rgba(255,255,255,.045),rgba(255,255,255,.012)); transition:.3s; }
.svc::before{ content:''; position:absolute; inset:0; border-radius:inherit; padding:1px; background:linear-gradient(140deg,rgba(0,255,213,.5),transparent 45%); -webkit-mask:linear-gradient(#000 0 0) content-box,linear-gradient(#000 0 0); -webkit-mask-composite:xor; mask-composite:exclude; opacity:0; transition:.3s; }
.svc:hover{ transform:translateY(-5px); border-color:var(--line2); }
.svc:hover::before{ opacity:1; }
.svc-ico{ width:48px; height:48px; border-radius:13px; display:grid; place-items:center; color:var(--neon); background:radial-gradient(circle at 30% 25%,rgba(0,255,213,.22),rgba(0,255,213,.04)); border:1px solid rgba(0,255,213,.25); }
.svc-ico.bad{ color:var(--coral); background:radial-gradient(circle at 30% 25%,rgba(250,91,104,.2),rgba(250,91,104,.03)); border-color:rgba(250,91,104,.25); }
.svc-ico.amber{ color:var(--amber); background:radial-gradient(circle at 30% 25%,rgba(253,181,42,.2),rgba(253,181,42,.03)); border-color:rgba(253,181,42,.25); }
.svc-ico svg{ width:24px; height:24px; }
.svc-title{ font-size:1.16rem; font-weight:700; margin:1.1rem 0 .45rem; letter-spacing:-.01em; }
.svc-title.sm{ font-size:1.04rem; }
.svc-desc{ color:var(--mut); font-size:.93rem; line-height:1.6; }
.svc-benefit{ margin-top:.9rem; color:var(--neon); font-size:.86rem; font-weight:600; }

/* 引用框 / 权利 */
.quote-box{ max-width:60rem; margin:0 auto; padding:1.5rem 1.8rem; border:1px solid rgba(0,255,213,.25); border-radius:var(--r); color:var(--txt); font-size:1.04rem; line-height:1.7; background:linear-gradient(120deg,rgba(0,255,213,.06),rgba(59,130,246,.04)); }
.rights{ display:flex; justify-content:center; flex-wrap:wrap; gap:.7rem; margin-top:1.6rem; }
.right-chip{ display:inline-flex; align-items:center; gap:.5rem; padding:.6em 1.1em; border:1px solid var(--line2); border-radius:999px; font-weight:700; font-size:.92rem; background:rgba(255,255,255,.03); }
.right-chip svg{ width:17px; height:17px; color:var(--neon); }

/* 杀手锏 */
.killer-grid{ display:grid; grid-template-columns:repeat(2,1fr); gap:1.2rem; }
.killer{ position:relative; padding:1.9rem 1.8rem; border:1px solid var(--line); border-radius:var(--r); background:linear-gradient(165deg,rgba(255,255,255,.045),rgba(255,255,255,.012)); transition:.3s; overflow:hidden; }
.killer:hover{ transform:translateY(-4px); border-color:rgba(0,255,213,.4); box-shadow:0 24px 60px -34px rgba(0,255,213,.5); }
.killer-top{ display:flex; align-items:center; gap:.9rem; }
.killer-ico{ width:50px; height:50px; flex:none; border-radius:14px; display:grid; place-items:center; color:var(--neon); background:radial-gradient(circle at 30% 25%,rgba(0,255,213,.24),rgba(0,255,213,.04)); border:1px solid rgba(0,255,213,.3); }
.killer-ico svg{ width:26px; height:26px; }
.killer-tag{ font-size:.74rem; font-weight:800; letter-spacing:.05em; color:var(--neon); background:rgba(0,255,213,.08); border:1px solid rgba(0,255,213,.22); padding:.3em .7em; border-radius:7px; }
.killer-title{ font-size:1.3rem; font-weight:800; letter-spacing:-.02em; margin:1.1rem 0 .5rem; }
.killer-desc{ color:var(--mut); font-size:.95rem; line-height:1.65; }
.killer-pts{ list-style:none; padding:0; margin:1.2rem 0 0; display:grid; gap:.6rem; }
.killer-pts li{ display:flex; align-items:flex-start; gap:.6rem; font-size:.9rem; color:var(--txt); }
.killer-pts i{ flex:none; width:7px; height:7px; margin-top:.5em; border-radius:50%; background:var(--neon); box-shadow:0 0 8px var(--neon); }

/* 性能 + 技术 */
.perf-grid{ display:grid; grid-template-columns:repeat(4,1fr); gap:1rem; text-align:center; padding:2.2rem 0; margin-bottom:2.2rem; border-block:1px solid var(--line); background:linear-gradient(120deg,rgba(0,255,213,.05),rgba(59,130,246,.05)); border-radius:var(--r); }
.perf-n{ font-size:clamp(1.9rem,4vw,2.8rem); font-weight:800; letter-spacing:-.03em; background:linear-gradient(135deg,var(--neon),var(--neon2),var(--blue)); -webkit-background-clip:text; background-clip:text; color:transparent; }
.perf-l{ color:var(--mut); font-size:.9rem; margin-top:.3rem; font-weight:600; }
.tech-grid{ display:grid; grid-template-columns:repeat(2,1fr); gap:1.2rem; }
.tech-panel{ padding:1.7rem 1.7rem; border:1px solid var(--line); border-radius:var(--r); background:linear-gradient(160deg,rgba(255,255,255,.04),rgba(255,255,255,.01)); }
.tech-panel h4{ display:flex; align-items:center; gap:.55rem; font-size:1.05rem; font-weight:700; margin-bottom:1.1rem; }
.tech-panel h4 svg{ width:20px; height:20px; color:var(--neon); }
.tech-panel ul{ list-style:none; padding:0; margin:0; display:grid; gap:.7rem; }
.tech-panel li{ position:relative; padding-left:1.2rem; color:var(--mut); font-size:.92rem; line-height:1.5; }
.tech-panel li::before{ content:''; position:absolute; left:0; top:.5em; width:6px; height:6px; border-radius:50%; background:var(--neon); opacity:.7; }

/* 定价 */
.plan-grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:1.2rem; align-items:stretch; }
.plan{ position:relative; padding:2rem 1.7rem; border:1px solid var(--line); border-radius:var(--r); background:linear-gradient(165deg,rgba(255,255,255,.04),rgba(255,255,255,.01)); display:flex; flex-direction:column; transition:.3s; }
.plan:hover{ transform:translateY(-4px); border-color:var(--line2); }
.plan.hot{ border-color:rgba(0,255,213,.5); background:linear-gradient(165deg,rgba(0,255,213,.08),rgba(255,255,255,.015)); box-shadow:0 20px 50px -22px rgba(0,255,213,.5); }
.plan-badge{ position:absolute; top:-11px; left:1.7rem; font-size:.7rem; font-weight:800; letter-spacing:.05em; color:#04201c; background:linear-gradient(135deg,var(--neon),var(--neon2)); padding:.3em .8em; border-radius:7px; }
.plan-badge.ghost{ color:var(--mut); background:rgba(255,255,255,.06); border:1px solid var(--line2); }
.plan-name{ font-size:1.15rem; font-weight:700; }
.plan-price{ font-size:1.9rem; font-weight:800; letter-spacing:-.02em; margin:.5rem 0 .2rem; }
.plan-price small{ font-size:.82rem; font-weight:600; color:var(--mut2); margin-left:.4rem; }
.plan-desc{ color:var(--mut); font-size:.9rem; line-height:1.55; min-height:3.4em; }
.plan-feats{ list-style:none; padding:0; margin:1.3rem 0; display:flex; flex-direction:column; gap:.7rem; flex:1; }
.plan-feats li{ display:flex; align-items:center; gap:.6rem; font-size:.92rem; }
.plan-feats svg{ width:16px; height:16px; color:var(--neon); flex:none; }
.plan .btn-neon,.plan .btn-line{ justify-content:center; width:100%; }

/* 评价 */
.tst-grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:1.2rem; }
.tst{ margin:0; padding:1.8rem 1.6rem; border:1px solid var(--line); border-radius:var(--r); display:flex; flex-direction:column; gap:1rem; background:linear-gradient(165deg,rgba(255,255,255,.04),rgba(255,255,255,.01)); transition:.3s; }
.tst:hover{ transform:translateY(-4px); border-color:var(--line2); }
.tst-stars{ color:var(--amber); letter-spacing:2px; font-size:.95rem; }
.tst blockquote{ margin:0; color:var(--txt); font-size:.96rem; line-height:1.7; flex:1; }
.tst figcaption{ display:flex; align-items:center; gap:.8rem; }
.tst-av{ width:42px; height:42px; flex:none; border-radius:50%; display:grid; place-items:center; font-weight:800; color:#04201c; background:linear-gradient(135deg,var(--neon),var(--neon2)); }
.tst-meta{ display:flex; flex-direction:column; }
.tst-meta b{ font-size:.95rem; } .tst-meta small{ color:var(--mut2); font-size:.82rem; }

/* FAQ */
.faq-list{ display:flex; flex-direction:column; gap:.7rem; }
.faq{ border:1px solid var(--line); border-radius:14px; background:rgba(255,255,255,.02); overflow:hidden; transition:.25s; }
.faq.open{ border-color:var(--line2); background:var(--panel); }
.faq-q{ width:100%; display:flex; align-items:center; justify-content:space-between; gap:1rem; padding:1.15rem 1.3rem; font:inherit; font-weight:700; font-size:1rem; color:var(--txt); background:transparent; border:none; cursor:pointer; text-align:left; }
.faq-pm{ position:relative; flex:none; width:16px; height:16px; }
.faq-pm::before,.faq-pm::after{ content:''; position:absolute; background:var(--neon); border-radius:2px; transition:.25s; }
.faq-pm::before{ top:7px; left:0; width:16px; height:2px; }
.faq-pm::after{ left:7px; top:0; width:2px; height:16px; }
.faq.open .faq-pm::after{ transform:rotate(90deg); opacity:0; }
.faq-a{ max-height:0; overflow:hidden; transition:max-height .3s ease; }
.faq.open .faq-a{ max-height:220px; }
.faq-a p{ padding:0 1.3rem 1.2rem; color:var(--mut); font-size:.94rem; line-height:1.65; }

/* CTA */
.cta-band{ padding:1rem 0 5rem; }
.cta-inner{ position:relative; text-align:center; padding:3.6rem 2rem; border:1px solid var(--line2); border-radius:26px; overflow:hidden; background:linear-gradient(150deg,rgba(0,255,213,.1),rgba(59,130,246,.08),rgba(250,91,104,.06)); }
.cta-glow{ position:absolute; width:500px; height:500px; top:-260px; left:50%; transform:translateX(-50%); border-radius:50%; background:radial-gradient(circle,rgba(0,255,213,.4),transparent 65%); filter:blur(60px); }
.cta-inner h2{ position:relative; font-size:clamp(1.8rem,3.6vw,2.6rem); font-weight:800; letter-spacing:-.025em; }
.cta-inner p{ position:relative; color:var(--mut); margin:1rem auto 2rem; font-size:1.02rem; max-width:42em; line-height:1.6; }
.cta-actions{ position:relative; display:grid; grid-template-columns:repeat(3,1fr); gap:1rem; max-width:48rem; margin:0 auto 2rem; }
.cta-act{ display:flex; align-items:center; gap:.9rem; text-align:left; padding:1rem 1.2rem; border:1px solid var(--line2); border-radius:14px; background:rgba(8,12,24,.5); cursor:pointer; font:inherit; transition:.25s; }
.cta-act:hover{ border-color:var(--neon); transform:translateY(-3px); }
.cta-act-ico{ width:40px; height:40px; flex:none; border-radius:11px; display:grid; place-items:center; color:var(--neon); background:rgba(0,255,213,.1); border:1px solid rgba(0,255,213,.25); }
.cta-act-ico svg{ width:20px; height:20px; }
.cta-act-txt{ display:flex; flex-direction:column; } .cta-act-txt b{ font-size:.95rem; color:var(--txt); } .cta-act-txt small{ color:var(--mut2); font-size:.8rem; }
.cta-btns{ position:relative; display:flex; gap:1rem; justify-content:center; flex-wrap:wrap; }

/* 页脚 */
.ft{ border-top:1px solid var(--line); padding-top:3.2rem; background:rgba(7,11,22,.6); }
.ft-in{ display:grid; grid-template-columns:1.4fr 2fr; gap:2.5rem; padding-bottom:2.4rem; }
.ft-brand .brand{ margin-bottom:1rem; }
.ft-brand p{ color:var(--mut); font-size:.92rem; line-height:1.6; max-width:26em; margin-bottom:1.1rem; }
.ft-cols{ display:grid; grid-template-columns:repeat(3,1fr); gap:1.5rem; }
.ft-col h5{ font-size:.8rem; text-transform:uppercase; letter-spacing:.06em; color:var(--mut2); margin-bottom:1rem; }
.ft-col a{ display:block; color:var(--mut); font-size:.92rem; margin-bottom:.7rem; cursor:pointer; text-decoration:none; transition:.2s; }
.ft-col a:hover{ color:var(--neon); }
.ft-bottom{ display:flex; align-items:center; justify-content:space-between; gap:1rem; padding:1.4rem 0; border-top:1px solid var(--line); color:var(--mut2); font-size:.85rem; flex-wrap:wrap; }

/* ============================ 浅色主题 ============================ */
.lp.light{
  --bg:#eef2f8; --bg2:#ffffff; --panel:rgba(15,25,50,.04);
  --line:rgba(15,25,50,.10); --line2:rgba(15,25,50,.17);
  --txt:#0a1425; --mut:#4a546b; --mut2:#7c87a1;
  --neon:#0bb39c; --neon2:#1597c9; --amber:#c9870b; --coral:#e54653; --blue:#2563eb;
}
.lp.light .glow-a{ opacity:.16; } .lp.light .glow-b{ opacity:.14; } .lp.light .glow-c{ opacity:.08; }
.lp.light .grid-mesh{ background-image:linear-gradient(rgba(15,25,50,.05) 1px,transparent 1px),linear-gradient(90deg,rgba(15,25,50,.05) 1px,transparent 1px); }
.lp.light .noise{ mix-blend-mode:multiply; opacity:.025; }
.lp.light .hd.scrolled{ background:rgba(255,255,255,.82); }
.lp.light .brand-dot{ color:var(--mut2); }
/* 卡片类表面：浅色下用白底 + 柔和投影 */
.lp.light .svc,
.lp.light .killer,
.lp.light .plan,
.lp.light .tst,
.lp.light .tech-panel,
.lp.light .cta-act{ background:#fff; box-shadow:0 12px 30px -20px rgba(15,25,50,.30); }
.lp.light .faq,
.lp.light .m-chip,
.lp.light .tag,
.lp.light .right-chip{ background:#fff; }
.lp.light .faq.open{ background:#f4f7fc; }
.lp.light .bubble{ background:rgba(255,255,255,.92); }
.lp.light .perf-grid{ background:linear-gradient(120deg,rgba(11,179,156,.09),rgba(37,99,235,.06)); }
.lp.light .quote-box{ background:linear-gradient(120deg,rgba(11,179,156,.09),rgba(37,99,235,.05)); }
.lp.light .plan.hot{ background:#fff; box-shadow:0 22px 50px -24px rgba(11,179,156,.45); }
.lp.light .plan-badge.ghost{ color:var(--mut); background:rgba(15,25,50,.06); }
.lp.light .cta-inner{ background:linear-gradient(150deg,rgba(11,179,156,.14),rgba(37,99,235,.08),rgba(229,70,83,.05)); }
.lp.light .hs-n{ background:linear-gradient(120deg,var(--txt),var(--mut)); -webkit-background-clip:text; background-clip:text; }
.lp.light .btn-line{ background:rgba(15,25,50,.02); }
.lp.light .burger i{ background:var(--txt); }

@media (prefers-reduced-motion: reduce){
  *{ animation-duration:.001ms !important; animation-iteration-count:1 !important; transition-duration:.001ms !important; }
  [data-reveal]{ opacity:1 !important; transform:none !important; }
}

/* 响应式 */
@media (max-width:980px){
  .hero{ grid-template-columns:1fr; padding-top:2.6rem; }
  .hero-r{ order:-1; } .orb{ width:min(300px,68vw); }
  .svc-grid,.svc-grid.g4,.plan-grid,.tst-grid{ grid-template-columns:repeat(2,1fr); }
  .killer-grid,.tech-grid{ grid-template-columns:1fr; }
  .cta-actions{ grid-template-columns:1fr; }
  .ft-in{ grid-template-columns:1fr; }
}
@media (max-width:680px){
  .hd-nav{ position:fixed; inset:72px 0 auto; flex-direction:column; align-items:stretch; gap:0; background:rgba(8,12,24,.97); backdrop-filter:blur(18px); border-bottom:1px solid var(--line); padding:1rem 6vw 1.5rem; transform:translateY(-130%); transition:.32s cubic-bezier(.2,.7,.3,1); margin-left:0; }
  .lp.light .hd-nav{ background:rgba(255,255,255,.97); }
  .hd-nav.open{ transform:none; }
  .hd-nav>a{ padding:.9rem 0; border-bottom:1px solid var(--line); font-size:1rem; }
  .hd-mob-actions{ display:flex; gap:.7rem; margin-top:1rem; }
  .hd-mob-actions .btn-line,.hd-mob-actions .btn-neon{ flex:1; justify-content:center; }
  .hd-actions{ display:none; } .burger{ display:flex; }
  .hero-stats{ grid-template-columns:repeat(2,1fr); gap:1.3rem; }
  .svc-grid,.svc-grid.g2,.svc-grid.g4,.plan-grid,.tst-grid,.perf-grid{ grid-template-columns:1fr; }
  .perf-grid{ gap:1.6rem; }
}
</style>

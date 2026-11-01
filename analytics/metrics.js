(function(root) {
  'use strict';
  const DAY = 86400000;
  const stamp = d => Date.parse(d + 'T00:00:00Z');
  const add = (d,n) => new Date(stamp(d)+n*DAY).toISOString().slice(0,10);
  const diff = (a,b) => Math.round((stamp(a)-stamp(b))/DAY);
  const unique = rows => new Set(rows.map(r=>r.user_id)).size;
  function validate(data) {
    if (!data || !['users','sessions','workouts'].every(k=>Array.isArray(data[k]))) throw Error('Нужны массивы users, sessions и workouts.');
    const validDate = d => typeof d==='string' && /^\d{4}-\d{2}-\d{2}$/.test(d) && Number.isFinite(stamp(d)) && new Date(stamp(d)).toISOString().slice(0,10)===d;
    if (!validDate(data.observed_until)) throw Error('Укажите observed_until в формате YYYY-MM-DD.');
    if (!data.users.length || data.users.length>100000 || data.sessions.length+data.workouts.length>1000000) throw Error('Допустимы 1–100 000 пользователей и до 1 млн событий.');
    const users=new Map();
    for(const u of data.users) {
      if(typeof u.id!=='string' || !u.id || users.has(u.id) || !validDate(u.signup) || u.signup>data.observed_until || typeof u.segment!=='string') throw Error('Некорректный или повторяющийся пользователь.');
      users.set(u.id,u);
    }
    for(const kind of ['sessions','workouts']) {
      const ids=new Set();
      for(const e of data[kind]) {
        const u=users.get(e.user_id);
        if(typeof e.id!=='string' || !e.id || ids.has(e.id) || !u || !validDate(e.date) || e.date<u.signup || e.date>data.observed_until) throw Error('Некорректное событие: проверьте ID, даты и пользователя.');
        if(kind==='workouts' && (typeof e.completed!=='boolean' || !Number.isFinite(e.duration) || e.duration<0)) throw Error('Тренировка: completed — boolean, duration — минуты ≥ 0.');
        ids.add(e.id);
      }
    }
    return data;
  }
  function calculate(data,start,end,segment='Все') {
    if(start>end || end>data.observed_until) throw Error('Проверьте период и дату окончания наблюдения.');
    const users=data.users.filter(u=>u.signup<=end && (segment==='Все'||u.segment===segment));
    const userById=new Map(users.map(u=>[u.id,u]));
    const ids=new Set(users.map(u=>u.id));
    const sessions=data.sessions.filter(e=>ids.has(e.user_id)&&e.date<=end);
    const workouts=data.workouts.filter(e=>ids.has(e.user_id)&&e.date<=end&&e.completed);
    const selected=sessions.filter(e=>e.date>=start);
    const activeDays=new Set(sessions.map(e=>e.user_id+'|'+e.date));
    const signups=users.filter(u=>u.signup>=start);
    const activeAt=(from,to)=>unique(sessions.filter(e=>e.date>=from&&e.date<=to));
    const dau=activeAt(end,end), wau=activeAt(add(end,-6),end), mau=activeAt(add(end,-29),end);
    const retention=(list,day)=>{
      const eligible=list.filter(u=>add(u.signup,day)<=end);
      const retained=eligible.filter(u=>activeDays.has(u.id+'|'+add(u.signup,day))).length;
      return {eligible:eligible.length,retained,rate:eligible.length?retained/eligible.length:null};
    };
    const trend=[];
    for(let date=start;date<=end;date=add(date,1)) trend.push({date,active:activeAt(date,date),sessions:sessions.filter(e=>e.date===date).length});
    const cohorts=new Map();
    for(const u of signups) {
      const monday=add(u.signup,-((new Date(stamp(u.signup)).getUTCDay()+6)%7));
      if(!cohorts.has(monday)) cohorts.set(monday,[]);
      cohorts.get(monday).push(u);
    }
    const heatmap=[...cohorts.entries()].sort(([a],[b])=>a.localeCompare(b)).map(([cohort,list])=>({cohort,size:list.length,values:Array.from({length:7},(_,week)=>{
      if(list.some(u=>add(u.signup,week*7+6)>end)) return null;
      const retained=list.filter(u=>Array.from({length:7},(_,d)=>add(u.signup,week*7+d)).some(d=>activeDays.has(u.id+'|'+d))).length;
      return retained/list.length;
    })}));
    const mature=signups.filter(u=>add(u.signup,30)<=end);
    const firstWeek=new Map();
    for(const w of workouts) { const u=userById.get(w.user_id); if(diff(w.date,u.signup)<7) firstWeek.set(u.id,(firstWeek.get(u.id)||0)+1); }
    const groups=[{name:'≥3 тренировок за первые 7 дней',users:mature.filter(u=>(firstWeek.get(u.id)||0)>=3)},{name:'<3 тренировок за первые 7 дней',users:mature.filter(u=>(firstWeek.get(u.id)||0)<3)}].map(g=>({name:g.name,...retention(g.users,30)}));
    const weekly=[];
    for(let from=start;from<=end;from=add(from,7)) {
      const to=add(from,6)>end?end:add(from,6);
      const active=new Set(sessions.filter(s=>s.date>=from&&s.date<=to).map(s=>s.user_id));
      const counts=new Map();
      workouts.filter(w=>w.date>=from&&w.date<=to).forEach(w=>counts.set(w.user_id,(counts.get(w.user_id)||0)+1));
      const achieved=[...active].filter(id=>(counts.get(id)||0)>=3).length;
      weekly.push({from,to,active:active.size,achieved,rate:active.size?achieved/active.size:null,partial:diff(to,from)<6});
    }
    return {dau,wau,mau,stickiness:mau?dau/mau:null,active:unique(selected),frequency:unique(selected)?selected.length/unique(selected):null,sessionCount:selected.length,newUsers:signups.length,d7:retention(signups,7),d30:retention(signups,30),trend,heatmap,groups,weekly,workouts:workouts.filter(w=>w.date>=start).length,minutes:workouts.filter(w=>w.date>=start).reduce((n,w)=>n+w.duration,0)};
  }
  const api={validate,calculate,add};
  if(typeof module!=='undefined'&&module.exports) module.exports=api; else root.PlusAuraMetrics=api;
})(typeof globalThis!=='undefined'?globalThis:this);

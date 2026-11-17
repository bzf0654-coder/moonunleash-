// Functional corpus v1; deterministic inputs, not performance measurement.
export const planVersion = 1;
export const seed = 0x6d2b79f5;
export function buildCorpus(fixtures) {
  const groups = fixtures.map(({file, spec}) => ({
    id: file,
    state: spec.state,
    cases: [...(spec.tests ?? []).map((c,i) => ({id:`official:${file}:bool:${i}`, profile:'official', name:c.toggleName, context:c.context, kind:'boolean', expected:c.expectedResult})), ...(spec.variantTests ?? []).map((c,i) => ({id:`official:${file}:variant:${i}`, profile:'official', name:c.toggleName, context:c.context, kind:'variant', expected:c.expectedResult}))],
  }));
  const features = [];
  const strategy = (name, parameters={}, constraints=[]) => ({name, parameters, constraints});
  const flag = (name, strategies=[strategy('default')], variants=[], enabled=true) => { features.push({name, enabled, strategies, variants}); };
  flag('always'); flag('off', undefined, undefined, false); flag('no-strategies', []);
  flag('whitelist', [strategy('userWithId', {userIds:'user-1, user-7, user-31'})]);
  flag('multiple', [strategy('userWithId', {userIds:'user-7'}), strategy('flexibleRollout', {rollout:'37',groupId:'shared',stickiness:'userId'})]);
  for (const rollout of [0,1,37,50,99,100]) flag(`user-${rollout}`, [strategy('flexibleRollout', {rollout:String(rollout),groupId:'shared',stickiness:'userId'})]);
  for (const rollout of [17,50,83]) flag(`session-${rollout}`, [strategy('flexibleRollout', {rollout:String(rollout),groupId:'sessions',stickiness:'sessionId'})]);
  flag('legacy-user', [strategy('gradualRolloutUserId',{percentage:'37',groupId:'legacy'})]);
  flag('legacy-session', [strategy('gradualRolloutSessionId',{percentage:'63',groupId:'legacy'})]);
  flag('custom', [strategy('flexibleRollout',{rollout:'43',groupId:'plans',stickiness:'account'})]);
  for (const operator of ['STR_STARTS_WITH','STR_ENDS_WITH','STR_CONTAINS']) for (const caseInsensitive of [false,true]) {
    flag(`${operator}-${caseInsensitive}`, [strategy('default',{},[{contextName:'tag',operator,values:['Ab','xy'],caseInsensitive}])]);
  }
  for (const operator of ['IN','NOT_IN']) for (const inverted of [false,true]) {
    flag(`${operator}-${inverted}`, [strategy('default',{},[{contextName:'tier',operator,values:['free','enterprise'],inverted}])]);
  }
  for (const operator of ['NUM_EQ','NUM_GT','NUM_GTE','NUM_LT','NUM_LTE']) {
    flag(operator, [strategy('default',{},[{contextName:'score',operator,value:'17.5'}])]);
  }
  flag('segmented', [ {...strategy('default'),segments:[1]} ]);
  const variants = [{name:'control',weight:250},{name:'treatment',weight:750,payload:{type:'string',value:'blue'}}];
  flag('variants', undefined, variants);
  flag('variants-custom', undefined, variants.map(v=>({...v,stickiness:'account'})));
  flag('variants-override', undefined, variants.map((v,i)=>i===0?{...v,overrides:[{contextName:'userId',values:['user-7','user-31']}]}:{...v}));
  const state = {version:2,features,segments:[{id:1,constraints:[{contextName:'tier',operator:'IN',values:['enterprise']}]}]};
  let rng = seed >>> 0;
  const next = () => { rng ^= rng << 13; rng ^= rng >>> 17; rng ^= rng << 5; return rng >>> 0; };
  const cases = [];
  for (let i=0;i<64;i++) {
    const context={userId:`user-${i}`,sessionId:`session-${next()%19}`,properties:{account:`account-${next()%11}`,tag:['Abcxy','ABcXY','prefix','xAbmid',''][i%5],tier:['free','pro','enterprise'][i%3],score:String((next()%701-200)/10)}};
    for (const feature of features) for (const kind of ['boolean','variant']) cases.push({id:`common:${i}:${feature.name}:${kind}`,profile:'common',name:feature.name,context,kind});
  }
  groups.push({id:'generated-ascii-v1',state,cases});
  const unicodeState = {version:2, features:[{name:'unicode-rollout',enabled:true,strategies:[strategy('flexibleRollout',{rollout:'37',groupId:'共享组-🌍',stickiness:'userId'})]},{name:'全局变体-ø',enabled:true,strategies:[strategy('default')],variants}]};
  const unicodeCases=[];
  for (const [i,userId] of ['用户甲','用户乙','é','e\u0301','😊','φriend','مرحبا','नमस्ते','a\u0000b','東京','ø','🌍'].entries()) for (const feature of unicodeState.features) for (const kind of ['boolean','variant']) unicodeCases.push({id:`unicode:${i}:${feature.name}:${kind}`,profile:'unicode-diagnostic',name:feature.name,context:{userId},kind});
  groups.push({id:'unicode-hash-diagnostic-v1',state:unicodeState,cases:unicodeCases});
  return {planVersion,seed,groups};
}

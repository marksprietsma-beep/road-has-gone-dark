/** Tuning scenarios only. Never writes route, source scale, gameplay or saves. */
export const TIME_PRESETS=[0,15,30,60];
export function formatMovingTime(minutes){
 const h=Math.floor(minutes/60),m=minutes%60;
 return h?(m?`${h}h ${m}m`:`${h}h`):`${m}m`;
}
export function estimateRouteTime(route,minutesPerEffort=0){
 if(!TIME_PRESETS.includes(minutesPerEffort))throw Error('Choose an explicit supported timing scenario');
 const base={meaning:'PROVISIONAL_MOVING_TIME_SCENARIO',minutes_per_effort:minutesPerEffort,physical_km:'UNCALIBRATED',total_journey_minutes:null};
 if(minutesPerEffort===0)return {...base,status:'UNSET',moving_minutes:null};
 if(route?.status!=='PREVIEW_ROUTE')return {...base,status:'NO_ROUTE',moving_minutes:null};
 if(!Number.isFinite(route.effort)||route.effort<0||!Number.isInteger(route.route_steps)||route.route_steps<0)throw Error('Invalid route effort');
 if(route.route_steps===0)return {...base,status:'WITHIN_HEX_TIME_UNKNOWN',moving_minutes:null};
 if(route.effort===0)throw Error('A nonzero route needs positive effort');
 const raw=route.effort*minutesPerEffort,minutes=Math.ceil(raw/5)*5;
 return {...base,status:'SCENARIO_ONLY',raw_moving_minutes:raw,moving_minutes:minutes,display:'~'+formatMovingTime(minutes),crossing_delay:route.river_crossings.length?'UNKNOWN':'NOT_ASSESSED',rests:'NOT_INCLUDED'};
}

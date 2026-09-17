from pathlib import Path
p=Path('assets/ui');p.mkdir(exist_ok=True)
icons={
'carrot':'<path d="M28 22 49 34 15 59Z" fill="#EE8A35"/><path d="m33 24 2-17m4 21 16-15m-24 8-9-12" stroke="#649E4A" stroke-width="7"/><path d="m27 34 9 5m-13 3 6 3" stroke="#C06025" stroke-width="3"/>',
'wheat':'<path d="M31 58V12" stroke="#AC7830" stroke-width="5"/><path d="M31 24Q10 23 16 9Q32 10 31 24M31 36Q8 34 14 22Q31 22 31 36M31 48Q7 46 13 34Q30 34 31 48M33 24Q53 23 48 9Q32 10 33 24M33 36Q55 34 50 22Q33 22 33 36M33 48Q55 46 51 34Q33 34 33 48" fill="#E5B748"/>',
'corn':'<ellipse cx="32" cy="29" rx="13" ry="24" fill="#EBC34D"/><path d="M15 22Q37 34 32 60Q10 46 15 22M51 27Q27 36 32 60Q54 45 51 27" fill="#5E9B4A"/><path d="M29 10v24m7-24v24m-14-16h20m-20 7h20" stroke="#C79031" stroke-width="2"/>',
'egg':'<path d="M32 5C46 5 57 34 52 47C47 62 17 63 11 48C5 34 18 5 32 5Z" fill="#FFF0C9" stroke="#BA9660" stroke-width="3"/><path d="M21 22q-7 12-4 17" stroke="#FFFFFF" stroke-width="5" fill="none"/>',
'water':'<path d="M32 5C28 17 10 31 10 42a22 19 0 0 0 44 0C54 31 36 17 32 5Z" fill="#65BCD1" stroke="#2F758C" stroke-width="3"/><path d="M21 35q-7 15 7 17" fill="none" stroke="#D2F0F3" stroke-width="4"/>',
'seed':'<path d="M31 58V25M30 35Q9 35 8 15Q32 14 31 35M32 27Q34 7 55 9Q55 28 32 27" stroke="#427348" stroke-width="4" fill="#8FBE58"/><path d="M8 58q23-12 48 0" stroke="#AE784D" stroke-width="8"/>',
'harvest':'<path d="M8 28h48l-6 29H15Z" fill="#C99650" stroke="#7E582F" stroke-width="3"/><path d="M16 27q0-31 32 0M18 35l4 19m10-20v20m14-19-4 19" fill="none" stroke="#7E582F" stroke-width="4"/><path d="M13 40h39m-37 9h35" stroke="#E8BC76" stroke-width="3"/>',
'coins':'<ellipse cx="26" cy="48" rx="22" ry="10" fill="#C49335"/><ellipse cx="26" cy="40" rx="22" ry="10" fill="#EDC660"/><circle cx="40" cy="24" r="18" fill="#EEC663" stroke="#AD7D2B" stroke-width="3"/><path d="M40 12v24m7-21c-14-7-18 10-5 9s11 16-8 8" fill="none" stroke="#9D7024" stroke-width="3"/>',
'barn':'<path d="m6 24 26-20 26 20v35H6Z" fill="#BC634A" stroke="#704E35" stroke-width="3"/><path d="m3 24 29-22 29 22M8 26h48" stroke="#F9E6B5" stroke-width="5" fill="none"/><path d="M21 58V34h22v24M22 35l20 22m0-22L22 57" stroke="#F9E6B5" stroke-width="3"/>',
'chicken':'<path d="m24 14 1-8q6-8 11 0q8-5 10 3l-4 11" fill="#C85443"/><path d="M47 25Q48 9 34 12Q21 13 26 30Q5 22 8 43Q12 58 35 52Q48 48 47 25Z" fill="#F9ECCA" stroke="#B89B65" stroke-width="3"/><path d="m46 24 14 6-13 4" fill="#DD9F35"/><circle cx="38" cy="23" r="3" fill="#323E30"/><path d="m24 52-1 10m12-10 2 10" stroke="#BD8033" stroke-width="4"/>',
'workshop':'<path d="M41 5q-19 0-13 20L7 46q-8 14 7 14l25-27q22 4 21-18l-12 9-10-8Z" fill="#85A5A4" stroke="#426563" stroke-width="3"/><circle cx="13" cy="52" r="3" fill="#E5D5B0"/>',
'worker':'<path d="M12 60V48q3-12 20-12t20 12v12" fill="#4D8B94"/><circle cx="32" cy="27" r="16" fill="#E8B785"/><path d="M8 22h48M18 20V7h28v13" stroke="#947041" stroke-width="5" fill="#DABC70"/><path d="M25 38v22m14-22v22" stroke="#E8C069" stroke-width="5"/><circle cx="26" cy="27" r="2"/><circle cx="38" cy="27" r="2"/><path d="M27 33q5 5 10 0" fill="none" stroke="#976343" stroke-width="2"/>',
'upgrade':'<path d="m32 4 25 27H43v28H21V31H7Z" fill="#E7B657" stroke="#9F762D" stroke-width="3"/>',
'check':'<path d="m10 33 14 14L55 15" fill="none" stroke="#649657" stroke-width="9"/>',
'lock':'<path d="M19 26V17q0-23 26 0v9" fill="none" stroke="#678583" stroke-width="7"/><rect x="10" y="25" width="44" height="35" rx="6" fill="#8AA09A"/><circle cx="32" cy="41" r="5" fill="#3D5550"/><path d="M32 43v8" stroke="#3D5550" stroke-width="4"/>',
'book':'<path d="M9 8h44v48H13q-7-2-4-10Z" fill="#B7774C" stroke="#6F4D36" stroke-width="3"/><path d="M17 8v39h37M21 18h23m-23 9h18m-23 21v8h40" fill="none" stroke="#F1DAA5" stroke-width="4"/>'}
for name,body in icons.items():
 (p/(name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g stroke-linejoin="round" stroke-linecap="round">'+body+'</g></svg>',encoding='utf-8')
print('UI_ICONS_OK',len(icons))

(function(){
"use strict";
const $=id=>document.getElementById(id);
const states={
  idle:[8,140,true],remind:[12,120,false],happy:[12,95,true],overloaded:[12,115,true],
  resting:[10,205,true],alarm:[12,95,false],sleepy:[12,180,true],recovering:[12,125,false],
  focus:[8,160,true],study:[12,120,true],done:[12,95,false],thinking:[8,140,true],
  sad:[8,160,false],balanced:[8,140,true],strained:[10,160,true]
};
const pages=[
 ["home","Trang chủ","⌂"],["tasks","Công việc","☑"],["schedule","Lịch & báo thức","◷"],
 ["habits","Thói quen","◴"],["assistant","Trợ lý","✧"],["characters","Nhân vật","♡"],
 ["settings","Cài đặt","⚙"],["onboarding","Bắt đầu","✦"],["overlay","Overlay Android","◎"],
 ["splash","Splash","✿"]
];
const tasks=[{id:1,title:"Chuẩn bị kế hoạch hôm nay",time:"09:00",done:false},
             {id:2,title:"Nhớ uống nước và nghỉ mắt",time:"11:30",done:false},
             {id:3,title:"Đi bộ 10 phút",time:"17:30",done:true}];
let current="home",state="idle",animation=true,frame=0,last=0,image=new Image(),ready=false;
let useConsent=false,goal=90,minutes=55,dark=false,selectedCharacter="brain",breakMode=false;
const reducedMedia=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if(reducedMedia)animation=false;
function escapeText(s){return String(s).replace(/[&<>"']/g,ch=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[ch]))}
function setState(next){if(!states[next])next="idle";state=next;frame=0;last=0;ready=false;image=new Image();
  image.onload=()=>{ready=true;draw()};image.onerror=()=>{ready=false};
  image.src="../../assets/characters-v2/brain/"+next+"/sheet.png";
  for(const sel of document.querySelectorAll("[data-state-select]"))sel.value=next;
}
function draw(){if(!ready)return;for(const c of document.querySelectorAll(".mascotCanvas")){const n=c.width,ctx=c.getContext("2d");ctx.clearRect(0,0,n,n);ctx.imageSmoothingEnabled=true;
  ctx.drawImage(image,(frame%4)*256,Math.floor(frame/4)*256,256,256,0,0,n,n);}}
function tick(t){const cfg=states[state];if(ready&&animation&&!document.hidden){if(!last)last=t;if(t-last>=cfg[1]){
 const steps=Math.max(1,Math.floor((t-last)/cfg[1]));if(!cfg[2]&&frame+steps>=cfg[0])frame=cfg[0]-1;else frame=(frame+steps)%cfg[0];
 last+=steps*cfg[1];draw();}}else last=t;requestAnimationFrame(tick)}
function canvas(size=180){return '<canvas class="mascotCanvas" width="'+size+'" height="'+size+'" role="img" aria-label="Brain OneLife, trạng thái '+state+'"></canvas>'}
function button(label,action,cls="secondary-btn"){return '<button class="'+cls+'" data-action="'+action+'">'+label+'</button>'}
function intro(title,desc){return '<div class="heading-block"><h2 class="section-title">'+title+'</h2><p class="muted minor">'+desc+'</p></div>'}
function tasksMarkup(){return '<ul class="task-list">'+tasks.map(t=>'<li class="task-line '+(t.done?'done':'')+'"><input type="checkbox" data-task="'+t.id+'" aria-label="Hoàn thành '+escapeText(t.title)+'" '+(t.done?'checked':'')+'><span class="task-title">'+escapeText(t.title)+'</span><span class="pill">'+t.time+'</span></li>').join("")+'</ul>'}
function home(){return '<div class="dash-grid"><div><section class="hero"><div class="eyebrow">BẠN VÀ ONE LIFE</div><h2>Nhẹ nhàng hoàn thành từng việc nhỏ.</h2><p>Mọi thứ đáng nhớ, trong một nơi riêng tư của bạn.</p><div class="mascot-wrap">'+canvas(190)+'</div><div class="bubble">Hôm nay mình có thể giúp gì? 💜</div></section><div class="stats-row"><div class="mini-stat"><b>'+tasks.filter(x=>!x.done).length+'</b><span>Việc cần làm (mẫu)</span></div><div class="mini-stat"><b>09:00</b><span>Nhắc gần nhất (mẫu)</span></div><div class="mini-stat"><b>100%</b><span>Dữ liệu giữ cục bộ (định hướng)</span></div></div></div><div class="stack"><section class="card"><div class="row-between"><h2 class="section-title">Hôm nay</h2>'+button("Xem tất cả","goto:tasks")+'</div>'+tasksMarkup()+'</section><section class="card"><div class="row-between"><h2 class="section-title">Nhắc nhở dịu dàng</h2><span class="pill mint">Đề xuất</span></div><div class="feature-card" style="margin-top:14px"><span class="feature-icon">☀</span><div><strong>Nghỉ mắt 5 phút</strong><div class="minor muted">Tùy chọn, không làm gián đoạn.</div></div></div><div class="action-row">'+button("Thử nhắc việc","state:remind","primary-btn")+button("Xem thói quen","goto:habits")+'</div></section></div></div>'}
function taskPage(){return '<div class="grid-2"><section class="card">'+intro("Việc cần làm","Danh sách minh họa, không được lưu khi tải lại trang.")+tasksMarkup()+'</section><section class="card">'+intro("Ghi việc nhanh","Thử giao diện thêm công việc mới.")+'<form id="task-form"><div class="field"><label for="task-name">Tên công việc</label><input id="task-name" type="text" maxlength="100" required placeholder="Ví dụ: Gọi điện cho gia đình"></div><button class="primary-btn" type="submit">+ Thêm việc mẫu</button></form><p class="minor muted">Ứng dụng thật sẽ lưu công việc trong SQLite trên điện thoại.</p></section></div>'}
function schedule(){return '<div class="grid-2"><section class="card">'+intro("Lịch nhắc hôm nay","Các lịch dưới đây chỉ là ví dụ.")+'<div class="stack"><div class="feature-card"><span class="feature-icon">⏰</span><div><strong>07:00 · Dậy nhẹ nhàng</strong><div class="muted minor">Báo thức mẫu</div></div></div><div class="feature-card"><span class="feature-icon">📅</span><div><strong>09:00 · Kế hoạch hôm nay</strong><div class="muted minor">Nhắc công việc</div></div></div><div class="feature-card"><span class="feature-icon">☕</span><div><strong>11:30 · Nghỉ mắt</strong><div class="muted minor">Tùy chọn theo mục tiêu cá nhân</div></div></div></div></section><section class="card">'+intro("Biểu cảm khi có báo thức","Xem thử trạng thái chuông thật của Brain V2.")+'<div class="screen-stage">'+canvas(220)+'</div><div class="action-row">'+button("Thử báo thức","state:alarm","primary-btn")+button("Thử nhắc việc","state:remind")+'</div><p class="minor muted">Bản thiết kế này không lên lịch thông báo hệ điều hành.</p></section></div>'}
function habits(){const ratio=useConsent?Math.min(100,Math.round(minutes/goal*100)):0;const stage=!useConsent?"unknown":breakMode?"resting":ratio>=100?"overloaded":ratio>=80?"strained":"balanced";
return '<div class="grid-2"><section class="card">'+intro("Nhịp sử dụng của bạn","Người dùng tự đặt mục tiêu, không đánh giá tổn thương não.")+'<div class="intro-note">🛡️ Chỉ dùng dữ liệu khi người dùng cấp quyền. Hôm nay đây là <b>dữ liệu mẫu</b>; không có quyền hệ điều hành nào được yêu cầu.</div><div class="field"><label><input class="toggle" id="demo-consent" type="checkbox" '+(useConsent?'checked':'')+'> Bật mô phỏng dữ liệu sử dụng</label></div><div class="field"><label for="goal">Mục tiêu nhắc nghỉ: <b>'+goal+' phút</b></label><input id="goal" type="range" min="30" max="180" step="15" value="'+goal+'"></div><div class="field"><label for="usage">Thời lượng sử dụng mô phỏng: <b>'+minutes+' phút</b></label><input id="usage" type="range" min="0" max="210" step="5" value="'+minutes+'" '+(!useConsent?'disabled':'')+'></div><div class="progress-track"><div class="progress-fill" style="width:'+ratio+'%"></div></div><p class="muted minor">'+(!useConsent?'Chưa có dữ liệu. Mọi chức năng cơ bản vẫn dùng được.':minutes+'/'+goal+' phút · '+ratio+'% mục tiêu do bạn đặt.')+'</p><div class="action-row">'+button(breakMode?"Kết thúc giờ nghỉ demo":"Thử bắt đầu nghỉ","break","primary-btn")+button("Tắt gợi ý","mute")+'</div></section><section class="card">'+intro("Bộ não nhỏ của bạn",stage==='unknown'?'Trạng thái trung tính khi không có quyền':'Trạng thái hình ảnh minh họa, không phải sức khỏe thật')+'<div class="screen-stage">'+canvas(220)+'</div><div class="row-between"><span class="pill">'+(stage==='unknown'?'Không có dữ liệu':stage)+'</span><span class="micro">Không tự gửi dữ liệu lên mạng</span></div><p class="minor muted">Chỉ khi được cấp quyền, ứng dụng Android mới có thể đọc UsageStats; iOS có giới hạn Screen Time.</p></section></div>'}
function assistant(){return '<div class="grid-2"><section class="card">'+intro("Trợ lý bộ não nhỏ","Tương tác nhẹ, không cần gửi dữ liệu ra ngoài.")+'<div class="screen-stage">'+canvas(220)+'</div><div class="action-row">'+button("Mừng hoàn thành","state:done","primary-btn")+button("Mình đang suy nghĩ","state:thinking")+button("Tập trung","state:focus")+'</div></section><section class="card">'+intro("Trợ lý offline theo thiết kế","Đây là các gợi ý mẫu, không phải câu trả lời từ AI chạy thật.")+'<div class="stack"><div class="feature-card"><span class="feature-icon">✎</span><div>Ghi nhanh một ý tưởng</div></div><div class="feature-card"><span class="feature-icon">⏳</span><div>Đặt giờ nghỉ 5 phút</div></div><div class="feature-card"><span class="feature-icon">♧</span><div>Nhắc mình về công việc hôm nay</div></div></div><p class="minor muted">AI nội bộ và Gemini tùy chọn chỉ được phát triển sau khi có thiết kế dữ liệu & quyền riêng tư được duyệt.</p></section></div>'}
function characters(){
  const items=[
    {id:"brain",name:"Brain",asset:"../../assets/characters-v2/brain/master.png",animated:true},
    {id:"cat",name:"Mèo Tím",asset:"../../assets/characters-v2/cat/master.webp",animated:false},
    {id:"dog",name:"Cún Cam",asset:"../../assets/characters-v2/dog/master.webp",animated:false},
    {id:"robot",name:"Robot Xanh",asset:"../../assets/characters-v2/robot/master.webp",animated:false},
    {id:"sprout",name:"Mầm Xanh",asset:"../../assets/characters-v2/sprout/master.webp",animated:false}
  ];
  const cards=items.map(c=>'<div class="char-card '+(c.animated?'selected':'preview-only')+'">'
      +'<div class="figure"><img loading="lazy" src="'+c.asset+'" alt="'+escapeText(c.name)+' — Glossy V2"></div>'
      +'<strong>'+escapeText(c.name)+'</strong><small>'
      +(c.animated?'15 animation ứng viên':c.id==='cat'?'6 clip, 68 frame ứng viên · Chờ duyệt':'Chỉ có ảnh master — Chưa animation')
      +'</small>'+(c.id==='cat'?'<p class="minor"><a href="../review/glossy-cat-idle.html">▶ Xem 6 animation Mèo</a></p>':'')+'</div>').join('');
  return intro("Chọn người bạn đồng hành","Cả 5 nhân vật có master Glossy V2; Brain có 15 clip ứng viên, Mèo có 6 clip minh họa riêng (68 frame), Chó/Robot/Mầm còn chờ animation.")
    +'<div class="char-grid">'+cards+'</div>'
    +'<p class="muted minor" role="status">Các thẻ chỉ để xem trước. Chọn nhân vật thực tế sẽ khả dụng sau khi đủ animation, duyệt mỹ thuật và kiểm thử trên máy.</p>'
    +'<section class="card" style="margin-top:20px">'
    +intro("Xem đủ 15 biểu cảm Brain","Đây là sprite Brain PNG thật. Mèo có 6 clip và 68 frame ứng viên để duyệt tại thẻ riêng; Chó/Robot/Mầm mới có hình đại diện.")
    +'<div class="row-between"><select class="states-select" id="state-select" data-state-select>'
    +Object.keys(states).map(s=>'<option value="'+s+'" '+(state===s?'selected':'')+'>'+s+'</option>').join('')
    +'</select><span class="micro">256px nguồn · 64px overlay</span></div><div class="screen-stage" style="margin-top:12px">'+canvas(220)+'</div></section>';
}
function settings(){return '<div class="grid-2"><section class="card">'+intro("Trải nghiệm cá nhân","Các tùy chọn của bản xem thiết kế này chỉ lưu trong bộ nhớ trình duyệt.")+'<div class="permission-box"><span class="feature-icon">🎨</span><div><b>Chế độ giao diện</b><p>Chuyển sáng và tối để so sánh thiết kế.</p>'+button(dark?"Chuyển sáng":"Chuyển tối","theme")+'</div></div><div class="permission-box" style="margin-top:10px"><span class="feature-icon">◉</span><div><b>Giảm chuyển động</b><p>Tôn trọng thiết lập hệ điều hành và lựa chọn của bạn.</p>'+button(animation?"Tắt animation":"Bật animation","motion")+'</div></div><div class="permission-box" style="margin-top:10px"><span class="feature-icon">🔔</span><div><b>Thông báo và overlay</b><p>Không tự xin quyền khi chỉ xem thử giao diện.</p>'+button("Xem mẫu overlay","goto:overlay")+'</div></div></section><section class="card">'+intro("Dữ liệu thuộc về bạn","Mục tiêu của ứng dụng thật: offline-first, export/delete rõ ràng.")+'<div class="stack"><div class="feature-card"><span class="feature-icon">♙</span><div><strong>Không bắt buộc tài khoản</strong><div class="minor muted">SQLite nội bộ, dùng được khi offline</div></div></div><div class="feature-card"><span class="feature-icon">🔒</span><div><strong>AI từ xa là tùy chọn</strong><div class="minor muted">Không gửi lịch sử sử dụng mặc định</div></div></div><div class="feature-card"><span class="feature-icon">✧</span><div><strong>Cấp quyền theo ngữ cảnh</strong><div class="minor muted">Không đọc thông tin nhạy cảm khi chưa đồng ý</div></div></div></div></section></div>'}
function onboarding(){return '<div class="grid-2"><section class="card">'+intro("Rất vui được đồng hành 💜","Mọi thứ có thể bắt đầu mà không cần cấp quyền nào.")+'<div class="screen-stage">'+canvas(205)+'</div><div class="action-row">'+button("Bắt đầu dùng thử","goto:home","primary-btn")+'</div></section><section class="card">'+intro("Quyền quyết định nằm ở bạn","Không có quyền nào được yêu cầu từ trình xem thiết kế.")+'<div class="stack"><div class="feature-card"><span class="feature-icon">♧</span><div><strong>Ghi chú và công việc</strong><div class="minor muted">Hoạt động offline không cần truy cập ứng dụng khác</div></div></div><div class="feature-card"><span class="feature-icon">◷</span><div><strong>Thông báo</strong><div class="minor muted">Chỉ hỏi khi bạn thật sự đặt lời nhắc</div></div></div><div class="feature-card"><span class="feature-icon">◎</span><div><strong>Thói quen dùng điện thoại</strong><div class="minor muted">Tắt theo mặc định, chỉ dùng nếu đồng ý</div></div></div></div></section></div>'}
function overlay(){return '<div class="grid-2"><section class="card">'+intro("Nhân vật nổi trên Android","Bản mô phỏng; Android cần xin quyền SYSTEM_ALERT_WINDOW. iOS không hỗ trợ nổi tự do.")+'<div class="overlay-demo"><div class="demo-screenshot">Ứng dụng khác (mẫu)</div><p class="minor muted">Nhân vật phải không che thao tác quan trọng.</p><div class="tiny-nav"><span>⌂ Home</span><span>▦ Apps</span><span>◉ Profile</span></div><div class="floating-mascot">'+canvas(64)+'<span class="pill">Nhắc nhẹ</span></div></div><div class="action-row">'+button("Thử nhắc","state:remind")+button("Trạng thái nghỉ","state:resting")+'</div></section><section class="card">'+intro("Giới hạn hệ điều hành","Không được can thiệp màn hình khóa, đọc app khác hoặc che vùng hệ thống.")+'<div class="stack"><div class="feature-card"><span class="feature-icon">◷</span><div>Thả, kéo, đóng khi người dùng muốn</div></div><div class="feature-card"><span class="feature-icon">🔋</span><div>Dừng animation khi tắt màn hình</div></div><div class="feature-card"><span class="feature-icon">✳</span><div>Giảm chuyển động và tắt thông báo phiền</div></div></div></section></div>'}
function splash(){return '<section class="card" style="max-width:580px;text-align:center;margin:auto"><div class="screen-stage">'+canvas(235)+'</div><h2 class="section-title" style="font-size:29px;margin-top:15px">OneLife</h2><p class="muted">Một nơi để nhớ, tìm và hoàn thành việc.</p>'+button("Khám phá OneLife","goto:onboarding","primary-btn")+'</section>'}
const builders={home,tasks:taskPage,schedule,habits,assistant,characters,settings,onboarding,overlay,splash};
function render(){
  const cfg=pages.find(x=>x[0]===current);
  $("current-route").textContent=current.toUpperCase();$("page-title").textContent=cfg[1];
  $("page-content").innerHTML=builders[current]();
  for(const b of document.querySelectorAll("[data-page]"))b.classList.toggle("active",b.dataset.page===current);
  $("page-select").value=current;draw();
}
function navigate(p){if(!builders[p])return;current=p;render();$("page-content").focus({preventScroll:true})}
function menu(){const mainPages=["home","tasks","schedule","habits","assistant","characters","settings"];
 $("main-nav").innerHTML=mainPages.map(id=>{const p=pages.find(x=>x[0]===id);return '<button class="nav-button" data-page="'+id+'"><span class="emoji">'+p[2]+'</span>'+p[1]+'</button>'}).join("");
 $("mobile-nav").innerHTML=mainPages.slice(0,5).map(id=>{const p=pages.find(x=>x[0]===id);return '<button data-page="'+id+'"><span>'+p[2]+'</span>'+p[1]+'</button>'}).join("");
 $("page-select").innerHTML=pages.map(p=>'<option value="'+p[0]+'">'+p[1]+'</option>').join("");
}
document.addEventListener("click",e=>{
 const nav=e.target.closest("[data-page]");if(nav){navigate(nav.dataset.page);return}
 const btn=e.target.closest("[data-action]");if(!btn)return;
 const act=btn.dataset.action;
 if(act.startsWith("goto:"))navigate(act.slice(5));
 else if(act.startsWith("state:")){setState(act.slice(6));if(current!=="home"&&current!=="schedule"&&current!=="assistant"&&current!=="overlay")navigate("assistant")}
 else if(act==="break"){breakMode=!breakMode;setState(breakMode?"resting":"recovering");render()}
 else if(act==="mute"){useConsent=false;breakMode=false;setState("idle");render()}
 else if(act==="theme"){$("theme-toggle").click()}
 else if(act==="motion"){$("motion-toggle").click()}
});
document.addEventListener("change",e=>{
 const t=e.target;
 if(t.dataset.task){const v=tasks.find(x=>x.id===Number(t.dataset.task));if(v){v.done=t.checked;setState(v.done?"done":"idle");render()}}
 if(t.id==="demo-consent"){useConsent=t.checked;setState("idle");render()}
 if(t.id==="goal"){goal=Number(t.value);render()}
 if(t.id==="usage"){minutes=Number(t.value);const pct=minutes/goal;setState(pct>=1?"overloaded":pct>=.8?"strained":"balanced");render()}
 if(t.dataset.stateSelect){setState(t.value);render()}
});
document.addEventListener("input",e=>{if(e.target.id==="usage"||e.target.id==="goal"){e.target.dispatchEvent(new Event("change",{bubbles:true}))}});
document.addEventListener("submit",e=>{if(e.target.id==="task-form"){e.preventDefault();const title=$("task-name").value.trim();if(title){tasks.push({id:Date.now(),title,time:"Tùy chọn",done:false});navigate("tasks")}}});
$("page-select").addEventListener("change",e=>navigate(e.target.value));
$("theme-toggle").addEventListener("click",()=>{dark=!dark;document.body.dataset.theme=dark?"dark":"light";$("theme-toggle").textContent=dark?"☀":"☾"});
$("motion-toggle").addEventListener("click",()=>{animation=!animation;$("motion-toggle").textContent=animation?"◉":"◌";if(!animation){frame=0;draw()}});
menu();navigate("home");setState("idle");requestAnimationFrame(tick);
})();
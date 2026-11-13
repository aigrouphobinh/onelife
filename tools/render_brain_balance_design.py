#!/usr/bin/env python3
"""Create 12 editable Brain Balance screen designs (6 scenarios × light/dark).
Mock values are always labelled. These are source images, not working Flutter UI.
"""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from xml.sax.saxutils import escape
import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "design/wellbeing"
STATES = {
    "balanced": ("Cân bằng", "Bạn đang theo nhịp sử dụng mình đã chọn.", 0.45, "#57CFA4"),
    "strained": ("Hơi mệt", "Đến gần giờ nghỉ bạn đã đặt.", 0.82, "#E6AA60"),
    "overloaded": ("Vượt mục tiêu", "Đã đến lúc nghỉ nếu bạn muốn.", 1.0, "#B28BEA"),
    "resting": ("Đang nghỉ", "Nghỉ mắt, đi lại hoặc uống nước.", 0.60, "#73BFD8"),
    "recovering": ("Tươi tỉnh", "Bạn vừa hoàn thành thời gian nghỉ.", 0.32, "#57CFA4"),
    "permission": ("Cần sự cho phép", "Bạn có thể bật theo dõi hoặc dùng thủ công.", None, "#9C96B2"),
}
def rect(x,y,w,h,r,fill,stroke="none",sw=1):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def label(x,y,words,size,color,weight=500,anchor="start"):
    return f'<text x="{x}" y="{y}" font-size="{size}" font-family="DejaVu Sans, Arial, sans-serif" font-weight="{weight}" fill="{color}" text-anchor="{anchor}">{escape(words)}</text>'
def source_master():
    text=(ROOT/"assets/characters/brain/master.svg").read_text()
    m=re.search(r"<defs>(.*?)</defs>(.*?)</svg>",text,re.S)
    if not m:raise ValueError("Missing Brain master artwork")
    return m.group(1),m.group(2)
def make(state,theme,defs,master):
    title,explanation,fraction,accent=STATES[state]
    dark=theme=="dark"
    bg="#17152A" if dark else "#F8F6FD"
    card="#2B2641" if dark else "#FFFFFF"
    text="#F7F3FF" if dark else "#292448"
    muted="#C6BDDB" if dark else "#766D92"
    line="#504566" if dark else "#E7E0F2"
    tint="#413552" if dark else "#F1EAFB"
    bright="#B6A7FF" if dark else "#7759CB"
    root=[f'<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844" role="img" aria-label="Brain Balance {state} {theme} design only"><defs>{defs}</defs>']
    root += [rect(0,0,390,844,0,bg),
      label(24,29,"9:41",13,text,700),label(365,29,"●  ▰  ▮",10,muted,500,"end"),
      label(24,81,"Nhịp dùng điện thoại",23,text,700),
      label(24,110,"OneLife Brain Balance",12,muted,500),
      rect(24,138,342,294,23,card,line),
      rect(42,157,306,215,20,tint),
      label(195,396,title,20,text,700,"middle"),
      label(195,414,"DỮ LIỆU MẪU · KHÔNG ĐO SỨC KHỎE",8,muted,600,"middle")]
    # Place the actual OneLife Brain master artwork, with a per-state comic effect.
    root.append('<g transform="translate(93 114) scale(.80)">'+master+'</g>')
    if state=="overloaded":
        root.append('<g fill="none" stroke="#9879DE" stroke-width="4" stroke-linecap="round"><path d="M126 209l-9 -13 14 4 -5 -14 16 12"/><path d="M242 186l11 -12 -1 15 13 -2 -10 16"/></g>')
    elif state=="strained":
        root.append('<path d="M236 223q15 19 0 27q-10 -12 0 -27" fill="#85CCF5" stroke="#5FA0DB" stroke-width="2"/>')
    elif state=="resting":
        root.append('<circle cx="195" cy="246" r="85" stroke="#6ACDBF" stroke-width="3" fill="none" opacity=".4"/>')
    elif state=="recovering":
        root.append('<g fill="#74D8B9"><circle cx="114" cy="193" r="6"/><circle cx="264" cy="212" r="5"/><circle cx="233" cy="174" r="4"/></g>')
    elif state=="balanced":
        root.append('<path d="M253 175l5 13 13 5 -13 5 -5 13 -5 -13 -13 -5 13 -5Z" fill="#FFE386"/>')
    root += [label(24,472,explanation,12,text,600),rect(24,496,342,118,18,card,line)]
    if fraction is not None:
        root += [label(41,525,"Tiến độ tới mục tiêu cá nhân",11,muted,500),label(349,525,"Ví dụ",10,bright,600,"end"),
                 rect(41,544,308,12,6,tint),rect(41,544,round(308*fraction),12,6,accent),
                 label(41,581,"Nhắc nghỉ sau 90 phút · Tùy chỉnh",11,text,500)]
    else:
        root += [label(41,526,"Chưa có dữ liệu sử dụng",13,text,600),
                 label(41,554,"Dữ liệu chỉ có khi bạn đồng ý cấp quyền.",10,muted),
                 label(41,582,"Không cấp quyền vẫn dùng được lịch nhắc.",10,muted)]
    root += [rect(24,632,342,54,14,bright),
             label(195,665,"Bắt đầu nghỉ 5 phút" if state!="permission" else "Tìm hiểu quyền truy cập",13,"#FFFFFF",700,"middle"),
             rect(24,700,342,58,14,card,line),
             label(41,722,"🔒  Lưu trên điện thoại",12,text,600),
             label(41,743,"Có thể tắt và xóa lịch sử bất cứ lúc nào",10,muted),
             rect(0,781,390,63,16,card,line),
             label(55,822,"Trang chủ",10,muted,600,"middle"),
             label(141,822,"Công việc",10,muted,600,"middle"),
             label(224,822,"Lịch",10,muted,600,"middle"),
             label(326,822,"Thói quen",10,bright,700,"middle"),
             "</svg>"]
    return "".join(root)
def main():
    OUTPUT.mkdir(parents=True,exist_ok=True)
    defs,master=source_master()
    output=[]
    for theme in ("light","dark"):
        for state in STATES:
            stem=f"{theme}-{state}"
            source=OUTPUT/(stem+".svg")
            png=OUTPUT/(stem+".png")
            source.write_text(make(state,theme,defs,master))
            cairosvg.svg2png(url=str(source),write_to=str(png))
            with Image.open(png) as image:
                if image.size!=(390,844):raise ValueError(stem+" dimensions mismatch")
            output.append({"file":png.name,"source":source.name,"state":state,"theme":theme,
                           "sha256":hashlib.sha256(png.read_bytes()).hexdigest(),
                           "width":390,"height":844,"status":"design mockup only"})
            print("PASS",stem)
    (OUTPUT/"manifest.json").write_text(json.dumps({"schemaVersion":1,"files":output},indent=2,ensure_ascii=False)+"\n")
if __name__=="__main__":
    main()

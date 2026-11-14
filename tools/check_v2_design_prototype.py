#!/usr/bin/env python3
"""Visual smoke test and capture of static OneLife V2 prototype.
Pages are design references using sample data; no OS permissions or cloud calls.
"""
from __future__ import annotations
import json
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
APP=ROOT/"design/prototype-v2/index.html"
OUT=ROOT/"design/prototype-v2/screenshots"
PAGES=["home","tasks","schedule","habits","assistant","characters",
       "settings","onboarding","overlay","splash"]

def main():
    assert APP.is_file()
    OUT.mkdir(parents=True,exist_ok=True)
    manifest={"source":"design/prototype-v2/index.html",
              "status":"design prototype only, sample data, no OS permissions",
              "screens":[]}
    errors=[]
    with sync_playwright() as p:
        try:
            browser=p.chromium.launch(channel="chrome",headless=True,args=["--no-sandbox"])
        except Exception:
            browser=p.chromium.launch(headless=True,args=["--no-sandbox"])
        page=browser.new_page(viewport={"width":390,"height":844},device_scale_factor=1)
        page.on("pageerror",lambda exc:errors.append(str(exc)))
        page.goto(APP.as_uri(),wait_until="load")
        page.wait_for_timeout(350)
        assert page.locator("#page-select").count()==1
        for name in PAGES:
            page.evaluate("(name) => { const select=document.getElementById('page-select'); select.value=name; select.dispatchEvent(new Event('change',{bubbles:true})); }", name)
            page.wait_for_timeout(130)
            assert page.locator("#current-route").inner_text()==name.upper(),name
            file=OUT/(name+"-mobile.png")
            page.screenshot(path=str(file),full_page=False,animations="disabled")
            manifest["screens"].append({"page":name,"viewport":"390×844","capture":"viewport",
                                        "file":file.name,"bytes":file.stat().st_size})
            fullfile=OUT/(name+"-mobile-full.png")
            page.screenshot(path=str(fullfile),full_page=True,animations="disabled")
            manifest["screens"].append({"page":name,"viewport":"390×844","capture":"scroll",
                                        "file":fullfile.name,"bytes":fullfile.stat().st_size})
            print("CAPTURE",name,"mobile")
        page.set_viewport_size({"width":1280,"height":900})
        for name in ("home","habits","characters","settings"):
            page.evaluate("(name) => { const select=document.getElementById('page-select'); select.value=name; select.dispatchEvent(new Event('change',{bubbles:true})); }", name)
            page.wait_for_timeout(130)
            file=OUT/(name+"-desktop.png")
            page.screenshot(path=str(file),full_page=True,animations="disabled")
            manifest["screens"].append({"page":name,"viewport":"1280×900",
                                        "file":file.name,"bytes":file.stat().st_size})
        browser.close()
    assert not errors, "Browser runtime errors: "+repr(errors)
    assert len(manifest["screens"])==24
    (OUT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    print("PASS OneLife V2 prototype: 10 mobile pages, 4 desktop pages, no JS runtime exceptions")

if __name__=="__main__":
    main()

"""CI-only: set SDK paths after Godot creates its EditorSettings file."""
import os, pathlib, re
sdk=os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
java=os.environ.get('JAVA_HOME')
if not sdk or not java: raise SystemExit('Set ANDROID_HOME and JAVA_HOME first.')
p=pathlib.Path.home()/'.config/godot/editor_settings-4.7.tres'
s=p.read_text() if p.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
for k,v in [('export/android/android_sdk_path',sdk),('export/android/java_sdk_path',java)]:
 line=k+'="'+v.replace('\\','/').replace('"','\\"')+'"'
 s=re.sub('^'+re.escape(k)+'=.*$',lambda _:line,s,flags=re.M) if re.search('^'+re.escape(k)+'=',s,re.M) else s+'\n'+line+'\n'
p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)

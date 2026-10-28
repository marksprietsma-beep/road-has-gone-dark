"""Exact GAME-165 presentation exception, not a general historical guard bypass."""
from pathlib import Path
import subprocess,hashlib
ROOT=Path(__file__).resolve().parents[2]
BASE='37082d881b765aea70a3eee3794ce1304ab108ec'
UI='scripts/ui/first_adventure.gd'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def expected_ui():
 s=original(UI).decode('utf-8')
 old=''' var footer := HBoxContainer.new();column.add_child(footer)
 menu_button=GameUI.action("Main menu",func(): if thread==null: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"));footer.add_child(menu_button)
 retreat_button=GameUI.action("Withdraw · defeat",func(): send("retreat"));footer.add_child(retreat_button)
 footer.add_child(GameUI.spacer())
 end_button=GameUI.action("End turn",func(): send("end"),true);footer.add_child(end_button)
 return_button=GameUI.action("Return to regional play",return_region,true);footer.add_child(return_button)
'''
 new=''' var footer := HBoxContainer.new();column.add_child(footer)
 # Keep progression at the viewport's leading edge. Long ability descriptions
 # can widen the body; a spacer before End would push it outside the window.
 end_button=GameUI.action("End turn",func(): send("end"),true);footer.add_child(end_button)
 end_button.tooltip_text="Finish this actor's turn, even with no movement or action remaining."
 return_button=GameUI.action("Return to regional play",return_region,true);footer.add_child(return_button)
 menu_button=GameUI.action("Main menu",func(): if thread==null: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"));footer.add_child(menu_button)
 retreat_button=GameUI.action("Withdraw · defeat",func(): send("retreat"));footer.add_child(retreat_button)
 retreat_button.tooltip_text="Explicitly abandon this encounter as a defeat. This does not end your turn."
 retreat_button.add_theme_color_override("font_color",Color("d49486"))
 footer.add_child(GameUI.spacer())
'''
 assert s.count(old)==1;s=s.replace(old,new)
 marker='   if int(actor.record.runtime.temporary_hp)>0:detail.text+="\\nBuffer: %d temporary HP"%int(actor.record.runtime.temporary_hp)\n'
 assert s.count(marker)==1;s=s.replace(marker,'   if int(b.budget.move)==0 and int(b.budget.main)==0:detail.text+="\\nTurn spent · choose End turn to continue."\n'+marker)
 return s

def verify_ui():
 assert (ROOT/UI).read_text(encoding='utf-8')==expected_ui(),'Only the explicit footer ordering/hints may change'
 return dict(baseline=BASE,path=UI,sha256=hashlib.sha256((ROOT/UI).read_bytes()).hexdigest(),scope='Fixed leading-edge End/Return before utility controls and trailing spacer; distinct retreat warning and spent-turn hint. No gating, command or timing change.')

def expected_exporter():
 s=original('tools/release/export-game.mjs').decode('utf-8');old="'res://tests/grove_summoner/review.tscn'].includes(qaScene)";assert s.count(old)==1
 return s.replace(old,"'res://tests/grove_summoner/review.tscn','res://tests/sentinel_turn/review.tscn'].includes(qaScene)")

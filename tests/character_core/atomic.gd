extends SceneTree
class CountingBuilder extends CharacterBuilderService:
 var commits := 0
 var reject_helper := false
 func commit(slot: String,candidate: Dictionary,world: GameWorldTemplate) -> Dictionary:
  commits+=1;return super.commit(slot,candidate,world)
 func _helper(entry: Dictionary,input: Dictionary) -> Dictionary:
  if reject_helper and input.get('operation')=='generate':return fail('Injected interrupted generation')
  return super._helper(entry,input)
var checks := 0
var failures := 0
func check(ok: bool,why: String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred('run')
func run():
 var base := OS.get_environment('GAME103_TEST_ROOT')
 var service := CountingBuilder.new();service.store.save_root=base.path_join('atomic/saves');service.library.library_root=base.path_join('library')
 var entry: Dictionary=service.library.discover()[0]
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),'exact source profiles')
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,'fresh origin checkpoint')
 var path := service.store._slot_path(born.state.playthrough_id);var bytes := FileAccess.get_file_as_bytes(path)
 service.reject_helper=true
 check(not service.operate(entry,born.state.playthrough_id,'builder_open').ok,'interrupted generation fails visibly')
 check(service.commits==0 and FileAccess.get_file_as_bytes(path)==bytes,'failure leaves exact original save; no unpinned intermediate party')
 service.reject_helper=false
 var opened := service.operate(entry,born.state.playthrough_id,'builder_open')
 check(opened.ok and opened.state.character_builder.rules_ref.pack_id==RulesRecords.NEW_PACK,'retry still uses latest default')
 check(service.commits==1,'generation and rules pin use one journalled commit')
 var committed_bytes := FileAccess.get_file_as_bytes(path)
 var resumed := service.operate(entry,born.state.playthrough_id,'builder_open')
 check(resumed.ok and service.commits==1 and FileAccess.get_file_as_bytes(path)==committed_bytes,'reopening exact creator does not repin or write')
 print('GAME118 ATOMIC ',checks,' / ',failures)
 FileAccess.open(base.path_join('atomic-proof.json'),FileAccess.WRITE).store_string(JSON.stringify({'checks':checks,'failures':failures},'  '))
 quit(1 if failures else 0)

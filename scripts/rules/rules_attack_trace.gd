class_name RulesAttackTrace
extends RefCounted
## Scoped observation of existing authoritative attack results. Never rolls or resolves attacks.
## Synchronous, per-thread stacks keep worker/UI and nested observations independent.
static var _mutex := Mutex.new()
static var _scopes := {}

static func capture(operation: Callable) -> Array:
 var thread := OS.get_thread_caller_id()
 var events: Array=[]
 _mutex.lock()
 if not _scopes.has(thread):_scopes[thread]=[]
 _scopes[thread].append(events)
 _mutex.unlock()
 operation.call()
 _mutex.lock()
 _scopes[thread].pop_back()
 if _scopes[thread].is_empty():_scopes.erase(thread)
 _mutex.unlock()
 return events

static func observe(event: Dictionary) -> void:
 var thread := OS.get_thread_caller_id()
 _mutex.lock()
 if _scopes.has(thread):_scopes[thread].back().append(event.duplicate(true))
 _mutex.unlock()
